#!/bin/bash
set -euo pipefail

NC=$'\e[0;0m'
RED=$'\e[1;31m'
GRN=$'\e[1;32m'
ORG=$'\e[0;33m'
YEL=$'\e[1;33m'
BLUE=$'\e[1;34m'
PRL=$'\e[1;35m'
CYAN=$'\e[1;36m'

echo -e "${BLUE}First parameter is path to create lab in (defaults to working dir)"
echo -e "Second parameter is path to lab-template (defaults to working dir)\n"

LABPATH="$(pwd)"
if ! [ -z "${1++}" ]; then
    LABPATH=$1
fi
LAB_TEMPLATE="$(pwd)"
if ! [ -z "${2++}" ]; then
    LAB_TEMPLATE=$2
fi

create_startups() {
    echo -e "${BLUE}NAMEs SYNTAX: "
    echo -e "Leaves, spines, and tofs are 'leaf...', 'spine...' and 'tof...'" 
    echo -e "Servers and containers are 's...' and 'c...'" 
    echo -e "${RED}Entering hostname will overwrite existing config(s)${NC}"
    while :
    do
        read -p "Enter hostname ('q' to quit): " HOSTNAME
        if [ "$HOSTNAME" = "q" ] || [ "$HOSTNAME" = "Q" ] || [ -z "${HOSTNAME}" ]; then
            break
        fi
        cp "$LAB_TEMPLATE/startup-templates/$( echo ${HOSTNAME:0:5} )-template.startup" "$LABPATH/$HOSTNAME.startup" > /dev/null 2>&1 ||
        cp "$LAB_TEMPLATE/startup-templates/$( echo ${HOSTNAME:0:4} )-template.startup" "$LABPATH/$HOSTNAME.startup" > /dev/null 2>&1 ||
        cp "$LAB_TEMPLATE/startup-templates/$( echo ${HOSTNAME:0:3} )-template.startup" "$LABPATH/$HOSTNAME.startup" > /dev/null 2>&1 ||
        cp "$LAB_TEMPLATE/startup-templates/$( echo ${HOSTNAME:0:1} )erver-template.startup" "$LABPATH/$HOSTNAME.startup" > /dev/null 2>&1 ||
        cp "$LAB_TEMPLATE/startup-templates/$( echo ${HOSTNAME:0:1} )ontainer-template.startup" "$LABPATH/$HOSTNAME.startup" > /dev/null 2>&1 ||
        ( echo -e "${RED}Invalid name${NC} (empty .startup)" ; touch "$LABPATH/$HOSTNAME.startup" )
        echo -e "${CYAN}Created $LABPATH/$HOSTNAME.startup${NC}"
    done
    
    echo -e "${CYAN}"
    ls "$LABPATH" | grep "[a-z]*\.startup" | sed "s/\.startup//"
    echo -e "${NC}"
}

configure_startup() {
    create_startups

    VXLANs=()
    VLANs=()
    LANs=()
    MASKs=()
    while :
    do
        printf "Enter, space separated, VNI, VLAN ID, LAN prefix (x.x.x.x) and netmask (y) ('q' to quit): " ; read -r VNI VLAN LAN MASK
        if [ "$VNI" = "q" ] || [ "$VNI" = "Q" ] || [ -z "${VNI}" ]; then
            break
        fi

        check="$( echo $LAN | sed 's/\./ /g' )"
        if [[ $MASK -gt 32 ]] || [[ $MASK -lt 0 ]] || 
            [[ "$( echo $check | awk '{print $1}' )" -gt 255 ]] || 
            [[ "$( echo $check | awk '{print $2}' )" -gt 255 ]] || 
            [[ "$( echo $check | awk '{print $3}' )" -gt 255 ]] || 
            [[ "$( echo $check | awk '{print $4}' )" -gt 255 ]] ; then
            echo -e "${RED}Invalid prefix ${NC}(${PRL}${LAN}/${MASK}${NC})"
            continue
        elif [[ $MASK -gt "30" ]] || [[ $MASK -lt "8" ]] ; then
            printf "${YEL}Prefix either too big or too small ${NC}(${PRL}${LAN}/${MASK}${NC}). ${YEL}Continue?${NC} [y/N] " ; read BIG
            if [ "$BIG" = "n" ] || [ "$BIG" = "N" ] || [ -z "${BIG}" ]; then
                continue
            fi
        fi

        printf "Add (VNI=${BLUE}${VNI}${NC}, VLAN ID=${CYAN}${VLAN}${NC}, LAN=${PRL}${LAN}/${MASK}${NC})? [Y/n]" ; read add
        if [ "$add" = "n" ] || [ "$add" = "N" ] ; then
            continue
        fi

        VXLANs+=("$VNI")
        VLANs+=("$VLAN")
        LANs+=("$LAN")
        MASKs+=("$MASK")
    done
    
    # config startup only for leafs, server and containers
    HOSTs="$( ls "$LABPATH" | grep "[a-z]*\.startup" | sed "s/\.startup//" | grep -v -e "spine" -e "tof" )" 
    for i in $( seq 1 $( echo "$HOSTs" | wc -l ) )
    do
        cur=$( sed -n ${i}p <<< "$HOSTs" )
        cur_path="$( echo "$LABPATH/$cur.startup" )"
        
        if [[ $cur == "leaf"* ]]; then

            while :
            do
                printf "[${CYAN}$cur${NC}]> Enter loopback IP address (x.x.x.x): " ; read IP
                
                check="$( echo $IP | sed 's/\./ /g' )"
                if  [[ "$( echo $check | awk '{print $1}' )" -gt 255 ]] || 
                    [[ "$( echo $check | awk '{print $2}' )" -gt 255 ]] || 
                    [[ "$( echo $check | awk '{print $3}' )" -gt 255 ]] || 
                    [[ "$( echo $check | awk '{print $4}' )" -gt 255 ]] ; then
                    echo -e "${RED}Invalid IP address '${IP}${NC}'"
                    continue
                else
                    break
                fi
            done
            sed -i "s/{indirizzo-lo}/${IP}/" "$cur_path"
            
            for i in "${!VXLANs[@]}"; do
                vni=${VXLANs[$i]}
                vlan=${VLANs[$i]}
                # un-commenta tutte le righe segnate con ##
                sed -r -i "s/^##(.*(\{vtep-vni-i\}|\{vni-i\}|\{vlan-id-i\}).*)/\1/" "$cur_path" 
                # duplica tutte le righe da completare, segnando la copia con ##
                sed -r -i "s/(^[^#]*(\{vtep-vni-i\}|\{vni-i\}|\{vlan-id-i\}).*)/\1\n##\1/" "$cur_path"

                # sostituisce nelle variabili vtep-vni-i, vlan-id-i e vni-i
                sed -r -i "s/(^[^#\n]*)(\{vtep-vni-i\})/\1vtep${vni}/" "$cur_path"
                sed -r -i "s/(^[^#\n]*)(\{vni-i\})/\1${vni}/" "$cur_path"
                sed -r -i "s/(^[^#\n]*)(\{vlan-id-i\})/\1${vlan}/" "$cur_path"
            done
            # elimina tutte le righe segnate con ##
            sed -r -i "s/^##(.*(\{vtep-vni-i\}|\{vni-i\}|\{vlan-id-i\}).*)//" "$cur_path"


            while :
            do
                s_eth0="$( grep -o "(eth[0-9]\{1,\})" "$cur_path" | sort -u | sed -r 's/.*(eth[0-9]*).*/\1/' | head -1 )" 
                s_eth1="$( grep -o "(eth[0-9]\{1,\})" "$cur_path" | sort -u | sed -r 's/.*(eth[0-9]*).*/\1/' | tail -1 )" 

                s_eth=""
                printf "[${CYAN}$cur${NC}]> Swap server-leaf link interface ${BLUE}$s_eth0${NC}? [y/N]: " ; read SWAP
                if ! [ "$SWAP" = "y" ] && ! [ "$SWAP" = "Y" ]; then
                    printf "[${CYAN}$cur${NC}]> Swap server-leaf link interface ${GRN}$s_eth1${NC}? [y/N]: " ; read SWAP

                    if ! [ "$SWAP" = "y" ] && ! [ "$SWAP" = "Y" ]; then
                        break
                    fi

                    s_eth=$s_eth1
                fi

                if [[ -z "${s_eth}" ]]; then
                    s_eth=$s_eth0
                fi
                
                echo "[${CYAN}$cur${NC}]> Interfaces: eth0 eth1 eth2 eth3" | sed -r "s/(${s_eth0})/${BLUE}\1${NC}/" | sed -r "s/(${s_eth1})/${GRN}\1${NC}/" 
                ( printf "[${CYAN}$cur${NC}]> Enter interface to swap with $s_eth${NC} " | sed -r "s/(${s_eth0})/${BLUE}\1/" | sed -r "s/(${s_eth1})/${GRN}\1/" ); read SWAP

                if [[ $SWAP == "eth"* ]]; then
                    sed -i "s/${SWAP}/\x0/g; s/${s_eth}/${SWAP}/g; s/\x0/${s_eth}/g" "$cur_path"
                else
                    echo "${RED}Invalid interface name '$SWAP'${NC}"
                fi
            done
        elif [[ $cur == "s"* ]] && [[ $cur != "spine"* ]]; then
            ETHs=()
            while :
            do
                printf "[${CYAN}$cur${NC}]> Enter interfaces, ${BLUE}eth0 already enabled${NC}, ('q' to quit): " ; read ETH
                if [ "$ETH" = "q" ] || [ "$ETH" = "Q" ] || [ -z "${ETH}" ]; then
                    break
                fi
                ETHs+=("$ETH")
            done

            for i in "${!VLANs[@]}"; do
                vlan=${VLANs[$i]}
                # un-commenta tutte le righe segnate con ##
                sed -r -i "s/^##(.*\{vlan-id-j\}.*)/\1/" "$cur_path" 
                # duplica tutte le righe da completare, segnando la copia con ##
                sed -r -i "s/(^[^#].*\{vlan-id-j\}.*)/\1\n##\1/" "$cur_path"

                # sostituisce nelle variabili vlan-id-j
                sed -r -i "s/(^[^#\n]*)(\{vlan-id-j\})/\1${vlan}/" "$cur_path"
            done
            # elimina tutte le righe segnate con ##
            sed -r -i '/\{eth-i\}/! s/^##(.*\{vlan-id-j\}.*)//' "$cur_path" 

            for i in "${!ETHs[@]}"; do
                eth=${ETHs[$i]}
                if [[ -z "${eth}" ]]; then
                    continue
                fi
                # un-commenta tutte le righe segnate con ##
                sed -r -i '/\{vlan-id-j\}/! s/^##(.*\{eth-i\}.*)/\1/' "$cur_path" 
                # duplica tutte le righe da completare, segnando la copia con ##
                sed -r -i "s/(^[^#].*\{eth-i\}.*)/\1\n##\1/" "$cur_path"

                # sostituisce nelle variabili eth-i
                sed -r -i "s/(^[^#\n]*)(\{eth-i\})/\1${eth}/" "$cur_path"
            done
            # elimina tutte le righe segnate con ##
            sed -r -i '/\(\{eth-i\}\)/! s/^(.*\{eth-i\}.*)//' "$cur_path" 

            while :
            do
                s_eth="$( grep -o "(eth[0-9]*)" "$cur_path" | sed -r 's/.*(eth[0-9]*).*/\1/' )"

                printf "[${CYAN}$cur${NC}]> Swap server-leaf link interface ${BLUE}$s_eth${NC}? [y/N]: "  ; read SWAP
                if ! [ "$SWAP" = "y" ] && ! [ "$SWAP" = "Y" ]; then
                    break
                fi
                
                ( printf "[${CYAN}$cur${NC}]> Interfaces: eth0 " ;  echo "${ETHs[*]}" ) | sed -r "s/(${s_eth})/${BLUE}\1${NC}/"

                printf "[${CYAN}$cur${NC}]> Enter interface to swap with ${BLUE}$s_eth${NC}: "  ; read SWAP

                if [[ $SWAP == "eth"* ]]; then
                    sed -i "s/${SWAP}/\x0/g; s/${s_eth}/${SWAP}/g; s/\x0/${s_eth}/g" "$cur_path"
                else
                    echo "${RED}Invalid interface name '$SWAP'${NC}"
                fi
            done
        elif [[ $cur == "c"* ]]; then
            echo -e "Virtual networks available:"
            for i in "${!VLANs[@]}"; do
                echo -e "[$i]: VNI=${BLUE}${VXLANs[$i]}${NC}, VLAN ID=${CYAN}${VLANs[$i]}${NC}, LAN=${PRL}${LANs[$i]}/${MASKs[$i]}${NC}"
            done
            printf "[${CYAN}$cur${NC}]> Select virtual LAN: " ; read j

            lan="${LANs[$j]}"
            mask="${MASKs[$j]}"
            
            if [[ $mask -ge "24" ]] || [ $mask -ge "24" ] ; then
                pref="$( echo "${lan}"| sed -r "s/(([0-9]{1,3}\.){3}).*/\1/" )"
            elif [[ $mask -ge "16" ]] || [ $mask -ge "16" ] ; then
                pref="$( echo "${lan}"| sed -r "s/(([0-9]{1,3}\.){2}).*/\1/" )"
            elif [[ $mask -ge "8" ]] || [ $mask -ge "8" ] ; then
                pref="$( echo "${lan}"| sed -r "s/([0-9]{1,3}\.).*/\1/" )"
            fi
            
            printf "[${CYAN}$cur${NC}]> Select address (${lan}${NC}/${mask}): " | sed -r "s/(${pref})/\1${BLUE}/" ; read ADR
            printf "[${CYAN}$cur${NC}]> Select default gateway address, or leave blank (${lan}${NC}/${mask}): " | sed -r "s/(${pref})/\1${BLUE}/" ; read gw

            sed -i "s/{indirizzo}/${pref}${ADR}/" "$cur_path"
            sed -i "s/{netmask}/${mask}/" "$cur_path"
            if ! [ -z "$gw" ] ; then
                sed -i "s/{indirizzo-gw}/${pref}${gw}/" "$cur_path"
                sed -i -r "s/^[#]{2}(.*${pref}${gw}[^#]*$)/\1/" "$cur_path"
            fi

            printf "[${CYAN}$cur${NC}]> Enable apache2 web server? [y/N]: " ; read APA
            if [ "$APA" = "y" ] || [ "$APA" = "Y" ]; then
                sed -r -i "s/^##(.*(apache2).*)/\1/" "$cur_path" 
                printf "[${CYAN}$cur${NC}]> Enter index.html body (eg: ${BLUE}hello i'm a server${NC}): " ; read -r WEB
                mkdir "$LABPATH/$cur" > /dev/null 2>&1 && echo -e "${CYAN}Directory '$LABPATH/$cur' created${NC}" || echo -e "${CYAN}Directory '$LABPATH/$cur' already exists${NC}"
                cp -r "$LAB_TEMPLATE/web-server-template/var" "$LABPATH/$cur"
                sed -i "s/{body}/${WEB}/" "$LABPATH/$cur/var/www/html/index.html"
                printf "[${CYAN}$cur${NC}]> Test web-server? [y/N] " ; read WEB
                if [ "$WEB" = "y" ] || [ "$WEB" = "Y" ]; then
                    links "$LABPATH/$cur/var/www/html/index.html" > /dev/null 2>&1 || echo -e "${RED}'links' not working or 'index.html' not present${NC}"
                fi
            fi  
        fi
    done
}

add_collision_domains() {
    printf "[${CYAN}$1${NC}]> Change collision domains? [y/N] " ; read change
    if [ "$change" = 'n' ] || [ "$change" = 'n' ] || [ -z "$change" ] ; then
        return 0
    fi

    echo "${BLUE}Enter tilde '~' to remove collision domain, leave blank ' ' to leave unchanged${NC}"

    check="$( grep -o "$1\[[0-9]\{1,\}" "$LABPATH/lab.conf" || echo "" )" 
    if [ -z "$check" ] ; then
        ( echo "" ; echo "##$1[$eth]=\"\"" ) >> "$LABPATH/lab.conf"
    fi

    for i in $( seq 1 "$( echo "$2" | wc -l )" )
    do  
        eth=$( sed -n ${i}p <<< "$2" | sed -r "s/[#]{0,2}([0-9]*)\=.*/\1/" )
        dom="$( sed -n ${i}p <<< "$2" | sed -r 's/[#]{0,2}[0-9]*\=\"(.*)\"/\1/' )"
        if [ -z "$dom" ] || [[ "$dom" == " " ]] ; then
            dom=$ORG"DISCONNECTED"
        fi

        printf "[${CYAN}$1${NC}:${PRL}eth$eth${NC}=${PRL}$dom${NC}]> Enter collision domain: " ; read dom
        if [ -z "$dom" ] || [[ "$dom" == " " ]] ; then
            continue
        elif [ "$dom" = '~' ] ; then
            sed -r -i "s/[##]{0,2}($1\[$eth\]\=).*/##\1\"\"/" "$LABPATH/lab.conf"
        fi
        sed -r -i "s/[##]{0,2}($1\[$eth\]\=).*/\1\"$dom\"/" "$LABPATH/lab.conf"
    done
}

configure_collision_domains() {
    DOMAINs=""
    while : 
    do
        # interfacce da .startup '0'
        ETHs="$( grep -oE "eth[0-9]{1,}" "$LABPATH/$1.startup" )" || ETHs=""
        ETHs="$( echo -e "$ETHs" | sort -u )"
        # interfacce da lab.conf connesse e sconnesse '0=""'
        DOMAINs="$( grep -E "${1}\[[0-9]{1,}\]=\"[a-zA-Z0-9]*\"" "$LABPATH/lab.conf" | sed -r "s/${1}\[([0-9]{1,})\](.*)/\1\2/" | sort -u )" || DOMAINs=""

        missing=()
        if [[ $1 == "leaf"* ]] || [[ $1 == "spine"* ]] || [[ $1 == "tof"* ]] ; then
            missing=("eth0" "eth1" "eth2" "eth3")
        else
            while :
            do
                printf "[${CYAN}$1${NC}]> Enter interfaces ('q' to quit): " ; read add
                if ! [ "$add" = 'q' ] && ! [ "$add" = 'Q' ] && ! [ -z "$add" ] ; then
                    missing+=("$add")
                else
                    break
                fi
            done 
        fi

        echo -e "[${CYAN}$1${NC}]> Interfaces: "
        echo -e "STARTUP        LAB.CONF        DOMAIN"
        
        let "i=1"
        let "j=1"
        while : 
        do

            eth_i=$( sed -n ${i}p <<< "$ETHs" | sed 's/eth//' )
            eth_j=$( sed -n ${j}p <<< "$DOMAINs" | sed -r 's/[##]*(.*)\=.*/\1/' )
            domain=$( sed -n ${j}p <<< "$DOMAINs" | sed -r 's/.*\"(.*)\"/\1/' )
            
            if [ -z "$eth_i" -a -z "$eth_j" ] ; then
                break
            elif [[ "$eth_i" -gt "$eth_j" ]] || [ -z "$eth_j" ] ; then
                missing=( ${missing[@]/"eth$eth_i"} )
                missing+=( "eth"$eth_i )
                eth_i=${RED}"eth"$eth_i${NC}
                eth_j=""
                domain=""
                let "i=i+1"
            elif [[ "$eth_i" -lt "$eth_j" ]] || [ -z "$eth_i" ]; then
                missing=( ${missing[@]/"eth$eth_j"} )
                eth_i=${YEL}""
                eth_j="eth"$eth_j
                if [[ -z $domain ]] ; then
                    domain="${ORG}DISCONNECTED"
                fi
                domain=$domain${NC}
                let "j=j+1"
            else
                missing=( ${missing[@]/"eth$eth_j"} )
                eth_i=${GRN}"eth"$eth_i
                eth_j="eth"$eth_j
                if [[ -z $domain ]] ; then
                    domain="${ORG}DISCONNECTED"
                fi
                domain=$domain${NC}
                let "i=i+1"
                let "j=j+1"
            fi

            len_i=$(echo $eth_i | wc -c)
            len_j=$(echo $eth_j | wc -c)
            len_1=22
            len_2=16

            let "len_i=len_1-len_i+1"

            printf "$eth_i"
            printf '%*s' "$len_i"

            let "len_j=len_2-len_j+1"
            
            printf "$eth_j"
            printf '%*s' "$len_j"

            echo "$domain"
        done

        if [ ${#missing[@]} -eq 0 ] ; then
            break
        fi

        printf "[${CYAN}$1${NC}]> Add missing interfaces to lab.conf: ${RED}${missing[*]}${NC}? [Y/n] " ; read scan
        if [ "$scan" = 'Y' ] || [ "$scan" = 'y' ] || [ -z "$scan" ] ; then
            for miss in ${missing[*]}
            do
                miss=$( echo $miss | sed 's/eth//' )
                if ! grep -q $1 "$LABPATH/lab.conf" ; then
                    echo "##$1[$miss]=\"\"" >> "$LABPATH/lab.conf" 
                    continue
                fi
                sed -i -E "0,/$1/s/([#]{0,2}$1.*$)/##$1\[$miss\]\=\"\"\n\1/" "$LABPATH/lab.conf"
            done
        else 
            break
        fi
    done

    add_collision_domains $1 "$DOMAINs" 
}

change_image() {
    if grep -q "$1\[image" "$LABPATH/lab.conf" ; then
        sed -i -r "s|[#]{1,}($1\[image\]\=\"kathara/)[a-z]*\"|\1$2\"\n|" "$LABPATH/lab.conf"
    elif ! grep -q "$1\[" "$LABPATH/lab.conf" ; then
        echo "$1[image]=\"kathara/$2\"" >> "$LABPATH/lab.conf"
    else
        tail=$( grep "$1\[[0-9]\{1,\}" "$LABPATH/lab.conf" | tail -1 )
        tail=$( echo "$tail" | grep -o $1 )"\["$( echo "$tail" | grep -o "[0-9]*" | tail -1 )
        
        sed -i -E "s|($tail.*$)|\1\n$1\[image\]\=\"kathara/$2\"|" "$LABPATH/lab.conf"
    fi
}

configure_images() {
    if [[ $1 == "leaf"* ]] || [[ $1 == "spine"* ]] || [[ $1 == "tof"* ]] ; then 
        change_image $1 "frr"
    else
        while :
        do
            echo "${BLUE}Images: 'frr', 'base'. Leave blank to use default 'base'${NC}"
            image=$( grep "$1\[image" "$LABPATH/lab.conf" | sed -r 's|^.*kathara/([a-z]*)\"|\1|' || echo "" )
            echo "[${CYAN}$1${NC}]> Current image: ${PRL}$image${NC}"
            printf "[${CYAN}$1${NC}]> Choose image: " ; read image
            if [ -z "$image" ] ; then
                change_image $1 "base"
                break
            fi

            if ! [ "$image" = 'frr' ] && ! [ "$image" = 'base' ] ; then
                echo "${RED}Invalid image:${NC} ${YEL}$image${NC}"
                continue
            else
                change_image $1 "$image"
                break
            fi
        done
    fi
}

enable_ecmp() {
    if [[ $1 == "leaf"* ]] || [[ $1 == "spine"* ]] || [[ $1 == "tof"* ]] ; then 
        if grep -q "$1\[sysctl" "$LABPATH/lab.conf" ; then
            sed -r -i "s/[#]{1,}($1\[sysctl.*)/\1/" "$LABPATH/lab.conf"
        else
            sed -r -i "s|([#]{0,2}$1\[image.*$)|\1\n$1\[sysctl\]\=\"net\.ipv4\.fib\_multipath\_hash\_policy\=1\"|" "$LABPATH/lab.conf"
        fi
        if grep -q "$1\[ipv6" "$LABPATH/lab.conf" ; then
            sed -r -i "s/[#]{1,}($1\[ipv6\]\=)/\1\"True\"/" "$LABPATH/lab.conf"
        else
            sed -r -i "s|([#]{0,2}$1\[sysctl.*$)|\1\n$1\[ipv6\]\=\"True\"|" "$LABPATH/lab.conf"
        fi
    fi
}

configure_lab_conf () {
    HOSTs="$( ls "$LABPATH" | grep "[a-z]*\.startup" | sed "s/\.startup//"  )"
    
    if [ ! -f "$LABPATH/lab.conf" ] ; then
        touch "$LABPATH/lab.conf"
        echo -e "${CYAN}Created file '$LABPATH/lab.conf'${NC}"
    else
        echo -e "${CYAN}File '$LABPATH/lab.conf' already exists${NC}"
    fi
    
    
    for i in $( seq 1 $( echo "$HOSTs" | wc -l ) )
    do
        cur="$( sed -n ${i}p <<< "$HOSTs" )"
        configure_collision_domains $cur
        configure_images $cur
        enable_ecmp $cur
    done 
}

configure_bgp() {
    if [ -z "${1}" ]; then
        return
    fi
    for i in $( seq 1 $( echo "$1" | wc -l ) )
    do
        cur="$( sed -n ${i}p <<< "$1" )"
        ID=""
        ASN=""
        lo=""
        if [[ $1 == "leaf"* ]] ; then
            printf "[${CYAN}$cur${NC}]> Use loopback address for router ID? [Y/n] " ; read lo 
            if [ "$lo" = "y" ] || [ "$lo" = "Y" ] || [ -z "$lo" ] ; then
                lo=$( cat "$LABPATH/$cur.startup" | grep lo:1 | sed -r "s/.*(\b[0-9]{1,3}(\.[0-9]{1,3}){3}).*/\1/" | sed -n 1p || echo "" )
                if ! [ -z "$lo" ] ; then
                    ID=$lo
                    printf "[${CYAN}$cur${NC}]> Enter ASN (yyyyy): " ; read ASN
                else
                    echo "${RED}Invalid loopback address in '$LABPATH/$cur.startup'${NC}"
                    lo="n"
                fi
            fi
            
            if [ -z $ASN ] ; then
                printf "[${CYAN}$cur${NC}]> Enter ASN (yyyyy) and router ID (x.x.x.x): " ; read -r ASN ID
            fi
            down1="$( grep -o "(eth[0-9]\{1,\})" "$LABPATH/$cur.startup" | sort -u | sed -r 's/.*(eth[0-9]*).*/\1/' | head -1 )"
            down2="$( grep -o "(eth[0-9]\{1,\})" "$LABPATH/$cur.startup" | sort -u | sed -r 's/.*(eth[0-9]*).*/\1/' | head -2 | tail -1 )"
            
            defaults=( "eth0" "eth1" "eth2" "eth3" )
            defaults=( ${defaults[@]/"$down1"} )
            defaults=( ${defaults[@]/"$down2"} )
            tor=()

            for i in ${defaults[*]}
            do
                tor+=( "$i" )
            done
        else
            echo "${BLUE}The router ID usually uses the same prefixes as leaves' loopback${NC}"
            printf "[${CYAN}$cur${NC}]> Enter ASN (yyyyy) and router ID (x.x.x.x): " ; read -r ASN ID
        fi
        echo "[${CYAN}$cur${NC}]> ASN=${BLUE}$ASN${NC} Router-ID=${PRL}$ID${NC}"
        cp -r "$LAB_TEMPLATE/$( echo ${cur:0:5} )-template/etc" "$LABPATH/$cur" > /dev/null 2>&1 ||
        cp -r "$LAB_TEMPLATE/$( echo ${cur:0:4} )-template/etc" "$LABPATH/$cur" > /dev/null 2>&1 ||
        cp -r "$LAB_TEMPLATE/$( echo ${cur:0:3} )-template/etc" "$LABPATH/$cur" > /dev/null 2>&1 || 
        echo "${RED}Invalid hostname: $cur${NC}"
        sed -i "s/{ASN}/${ASN}/" "$LABPATH/$cur/etc/frr/frr.conf"
        sed -i "s/{router-id}/${ID}/" "$LABPATH/$cur/etc/frr/frr.conf"
        if [[ $1 == "leaf"* ]] ; then
            sed -r -i "0,/eth/s/eth[0-9]{1,}/~${tor[0]}/" "$LABPATH/$cur/etc/frr/frr.conf"
            sed -r -i "s/[^~]{1}eth[0-9]{1,}/ ${tor[1]}/" "$LABPATH/$cur/etc/frr/frr.conf"
            sed -r -i "s/~eth[0-9]{1,}/${tor[0]}/" "$LABPATH/$cur/etc/frr/frr.conf"
        fi
    done
}

create_directories() {
    for i in $( seq 1 $( echo "$1" | wc -l ) )
    do
        cur=$( sed -n ${i}p <<< "$1" )
        if [[ -z "${cur}" ]] ; then
            continue
        fi
        mkdir "$LABPATH/$cur" > /dev/null 2>&1 && echo -e "${CYAN}Directory '$LABPATH/$cur' created${NC}"  || echo -e "${CYAN}Directory '$LABPATH/$cur' already exists${NC}"
    done
}

main() {
    echo -e "###########################################"
    echo -e "Default lab configuration is 2x2 Fat-Tree"
    echo -e "Manually change configuration if needed"
    echo -e "Configuration order: "
    echo -e ".startup -> lab.conf -> frr.conf"
    echo -e "###########################################\n"

    echo -e "This script will search the current lab directory for .startup(s) files"
    echo -e "Leaves, spines, and tofs are 'leaf...', 'spine...' and 'tof...'" 
    echo -e "Servers and containers are 's...' and 'c...'${NC}\n" 
    read -p $"Configure .startup(s)? [Y/n] " CONT

    if  [ "$CONT" = "y" ] || [ "$CONT" = "Y" ] || [ -z "$CONT" ]; then
        configure_startup
    fi

    read -p $"Configure lab.conf? [Y/n] " CONT
    if  [ "$CONT" = "y" ] || [ "$CONT" = "Y" ] || [ -z "$CONT" ]; then
        configure_lab_conf
    fi

    echo -e "\nSearching '${LABPATH}'..."
    echo -e "Leaves found:${BLUE}"
    ls "$LABPATH" | grep "^leaf.*\.startup" | sed "s/\.startup//" || echo  -e "${NC}no leaves" 
    LEAVES="$( ls "$LABPATH" | grep "^leaf.*\.startup" | sed "s/\.startup//" )" || LEAVES=""

    echo -e "${NC}\nSpines found:${BLUE}"
    ls "$LABPATH" | grep "^spine.*\.startup" | sed "s/\.startup//" || echo  -e "${NC}no spines"
    SPINEs="$( ls "$LABPATH" | grep "^spine.*\.startup" | sed "s/\.startup//" )" || SPINEs=""

    echo -e "${NC}\nToFs found:${BLUE}"
    ls "$LABPATH" | grep "^tof.*\.startup" | sed "s/\.startup//" || echo -e "${NC}no tofs"
    TOFs="$( ls "$LABPATH" | grep "^tof.*\.startup" | sed "s/\.startup//" )" || TOFs=""

    echo -e "${NC}\nAttempting to create directories...\n"

    create_directories "$LEAVES"
    create_directories "$SPINEs"
    create_directories "$TOFs"
    
    printf "\n${RED}This will overwrite existing frr.conf(s). Continue?${NC} [Y/n] " ; read cont
    if  ! [ "$cont" = "y" ] && ! [ "$cont" = "Y" ] && ! [ -z "$cont" ]; then
        exit 0
    fi

    echo -e "\nConfiguring leaves..."
    configure_bgp "$LEAVES"

    echo -e "\nConfiguring spines..."
    configure_bgp "$SPINEs"

    echo -e "\nConfiguring tofs..."
    configure_bgp "$TOFs"

    read -p "Finished..." end
}

main
