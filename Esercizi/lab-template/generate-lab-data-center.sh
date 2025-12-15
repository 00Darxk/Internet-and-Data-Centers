#!/bin/bash
set -euo pipefail

NC=$'\e[0;0m'
RED=$'\e[1;31m'
GRN=$'\e[1;32m'
YEL=$'\e[1;33m'
BLUE=$'\e[1;34m'
PRL=$'\e[1;35m'
CYAN=$'\e[1;36m'

echo -e "${BLUE}First parameter (\$1) is path to create lab in (defaults to working dir)"
echo -e "Second parameter (\$2) is path to lab-template (defaults to working dir)\n"

LABPATH="$(pwd)"
if ! [ -z "${1++}" ]; then
    LABPATH=$1
fi
LAB_TEMPLATE="$(pwd)"
if ! [ -z "${2++}" ]; then
    LAB_TEMPLATE=$2
fi

create_startups() {
    echo -e "${CYAN}Hostnames syntax: leaf... (leaf), spine... (spine), tof... (tof), s... (server), c... (container)"
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
        if [[ $MASK > 32 ]] || [[ $MASK < 0 ]] || 
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
                s_eth0="$( grep "(eth[0-9]*)" "$cur_path" | sed 's/^.*(\(eth[0-9]*\)).*(\(eth[0-9]*\)).*/\1\n\2/' | head -1 )" 
                s_eth1="$( grep "(eth[0-9]*)" "$cur_path" | sed 's/^.*(\(eth[0-9]*\)).*(\(eth[0-9]*\)).*/\1\n\2/' | head -2 | tail -1 )" 

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
                printf "[${CYAN}$cur${NC}]> Enter interfaces, eth0 already enabled, ('q' to quit): " ; read ETH
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
                s_eth="$( grep "(eth[0-9]*)" "$cur_path" | sed 's/.*(\(eth[0-9]*\)).*/\1/' )"

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

            sed -i "s/{indirizzo}/${pref}${ADR}/" "$cur_path"
            sed -i "s/{netmask}/${mask}/" "$cur_path"

            printf "[${CYAN}$cur${NC}]> Enable apache2 web server? [y/N]: " ; read APA
            if [ "$APA" = "y" ] || [ "$APA" = "Y" ]; then
                sed -r -i "s/^##(.*(apache2).*)/\1/" "$cur_path" 
                printf "[${CYAN}$cur${NC}]> Enter identifier: " ; read WEB
                mkdir "$LABPATH/$cur" > /dev/null 2>&1 && echo -e "${CYAN}Directory '$LABPATH/$cur' created${NC}" || echo -e "${CYAN}Directory '$LABPATH/$cur' already exists${NC}"
                cp -r "$LAB_TEMPLATE/web-server-template/var" "$LABPATH/$cur"
                sed -i "s/{HOSTNAME}/${WEB}/" "$LABPATH/$cur/var/www/html/index.html"
                printf "[${CYAN}$cur${NC}]> Test web-server? [y/N] " ; read WEB
                if [ "$WEB" = "y" ] || [ "$WEB" = "Y" ]; then
                    links "$LABPATH/$cur/var/www/html/index.html" > /dev/null 2>&1 || echo -e "${RED}'links' not working or 'index.html' not present${NC}"
                fi
            fi  
        fi
    done
}

configure_bgp() {
    if [ -z "${1}" ]; then
        return
    fi
    for i in $( seq 1 $( echo "$1" | wc -l ) )
    do
        cur="$( sed -n ${i}p <<< "$1" )"
        printf "[${CYAN}$cur${NC}]> Enter ASN: " ; read ASN
        ID=""
        if [[ $1 =~ "leaf" ]]; then
            printf "[${CYAN}$cur${NC}]> Use loopback address for router ID? [Y/n] " ; read ID 
            if [ "$ID" = "y" ] || [ "$ID" = "Y" ] || [ -z "$ID" ]; then
                ID=$( cat "$LABPATH/$cur.startup" | grep lo:1 | sed -r "s/.*(\b[0-9]{1,3}(\.[0-9]{1,3}){3}).*/\1/" | sed -n 1p )
            else
                printf "[${CYAN}$cur${NC}]> Enter router ID (x.x.x.x): " ; read ID
            fi
        else
            printf "[${CYAN}$cur${NC}]> Enter router ID, usually it uses the same prefixes as leaves' loopback (x.x.x.x): " ; read ID
        fi
        echo "[${CYAN}$cur${NC}]> ASN=$ASN Router-ID=$ID"
        cp -r "$LAB_TEMPLATE/$( echo $cur | sed -r "s/([a-z]*).*/\1/" )-template/etc" "$LABPATH/$cur"
        sed -i "s/{ASN}/${ASN}/" "$LABPATH/$cur/etc/frr/frr.conf"
        sed -i "s/{router-id}/${ID}/" "$LABPATH/$cur/etc/frr/frr.conf"
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
    echo -e "Manually configure lab.conf"
    echo -e "###########################################\n"

    echo -e "This script will search the current lab directory for .startup(s) files"
    echo -e "Leaves, spines, and tofs are 'leaf*', 'spine*' and 'tof*'.${NC}\n" 
    read -p $"Configure .startup(s)? [Y/n] " CONT

    if  [ "$CONT" = "y" ] || [ "$CONT" = "Y" ] || [ -z "$CONT" ]; then
        configure_startup
    fi

    echo -e "\nSearching '${LABPATH}'..."
    echo -e "Leaves found:${BLUE}"
    ls "$LABPATH" | grep "leaf\S*\.startup" | sed "s/\.startup//" || echo  -e "${NC}no leaves" 
    LEAVES="$( ls "$LABPATH" | grep "leaf\S*\.startup" | sed "s/\.startup//" )" || LEAVES=""

    echo -e "${NC}\nSpines found:${BLUE}"
    ls "$LABPATH" | grep "spine\S*\.startup" | sed "s/\.startup//" || echo  -e "${NC}no spines"
    SPINEs="$( ls "$LABPATH" | grep "spine\S*\.startup" | sed "s/\.startup//" )" || SPINEs=""

    echo -e "${NC}\nToFs found:${BLUE}"
    ls "$LABPATH" | grep "tof\S*\.startup" | sed "s/\.startup//" || echo -e "${NC}no tofs"
    TOFs="$( ls "$LABPATH" | grep "tof\S*\.startup" | sed "s/\.startup//" )" || TOFs=""

    echo -e "${NC}\nAttempting to create directories...\n"

    create_directories "$LEAVES"
    create_directories "$SPINEs"
    create_directories "$TOFs"
    
    printf "\n${RED}THIS WILL OVERWRITE EXISTING CONFIG(S), CONTINUE?${NC} [Y/n] " ; read cont
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
