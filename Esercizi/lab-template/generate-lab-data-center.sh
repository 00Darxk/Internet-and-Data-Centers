#!/bin/bash
set -euo pipefail
echo -e "\e[1;34mFirst parameter (\$1) is path to create lab in (defaults to working dir)"
echo -e "Second parameter (\$2) is path to lab-template (defaults to working dir)\n"

LABPATH="$(pwd)"
if ! [ -z "${1++}" ]; then
    LABPATH=$1
fi
LAB_TEMPLATE="$(pwd)"
if ! [ -z "${2++}" ]; then
    LAB_TEMPLATE=$2
fi

configure_startup() {
    echo -e "\e[1;36mNames syntax: leaf{...}, spine{...} , tof{...}, s{...} (server), c{...} (container)\e[0;0m"
    while :
    do
        read -p "Enter hostname ('q' to quit): " HOSTNAME
        if [ "$HOSTNAME" = "q" ] || [ "$HOSTNAME" = "Q" ] || [ -z "${HOSTNAME}" ]; then
            break;
        fi
        cp "$LAB_TEMPLATE/startup-templates/$( echo $HOSTNAME | sed -r "s/([a-z]*).*/\1/" )-template.startup" "$LABPATH/$HOSTNAME.startup" > /dev/null 2>&1 ||
        cp "$LAB_TEMPLATE/startup-templates/$( echo ${HOSTNAME:0:1} )erver-template.startup" "$LABPATH/$HOSTNAME.startup" > /dev/null 2>&1 ||
        cp "$LAB_TEMPLATE/startup-templates/$( echo ${HOSTNAME:0:1} )ontainer-template.startup" "$LABPATH/$HOSTNAME.startup" > /dev/null 2>&1 ||
        echo -e "\e[1;31mInvalid name\e[0;0m (empty .startup)"
        echo -e "\e[1;36mCreated $LABPATH/$HOSTNAME.startup\e[0;0m"
    done
    HOSTS="$(ls "$LABPATH" | grep "[a-z]*\.startup" | sed "s/\.startup//" )"
    echo -e "\e[1;36m"
    ls "$LABPATH" | grep "[a-z]*\.startup" | sed "s/\.startup//"
    echo -e "\e[0;0m"

    VXLANS=()
    VLANS=()
    while :
    do
        read -p "Enter VNI ('q' to quit): " VNI
        if [ "$VNI" = "q" ] || [ "$VNI" = "Q" ] || [ -z "${VNI}" ]; then
            break;
        fi
        read -p "[VNI] Enter VLAN ID ('q' to quit): " VLAN
        if [ "$VLAN" = "q" ] || [ "$VLAN" = "Q" ] || [ -z "${VLAN}" ]; then
            break;
        fi
        echo -e "Added (${VNI})-(${VLAN})"
        VXLANS+=("$VNI")
        VLANS+=("$VLAN")
    done
    
    HOSTS="$( echo "$HOSTS" | grep -v -e "spine" -e "tof" )" 
    for i in $( seq 1 $( echo "$HOSTS" | wc -l ) )
    do
        cur=$( sed -n ${i}p <<< "$HOSTS" )
        cur_path="$( echo "$LABPATH/$cur.startup" )"
        
        if [[ $cur == "leaf"* ]]; then

            read -p "[$cur]> Enter IP address (x.x.x.x): " IP
            sed -i "s/{indirizzo-lo}/${IP}/" "$cur_path"
            
            for i in "${!VXLANS[@]}"; do
                vni=${VXLANS[$i]}
                vlan=${VLANS[$i]}
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
        elif [[ $cur == "s"* ]] && [[ $cur != "spine"* ]]; then
            ETHS=()
            while :
            do
                read -p "[$cur]> Enter interfaces ('q' to quit): " ETH
                if [ "$ETH" = "q" ] || [ "$ETH" = "Q" ] || [ -z "${ETH}" ]; then
                    break;
                fi
                ETHS+=("$ETH")
            done

            for i in "${!VLANS[@]}"; do
                vlan=${VLANS[$i]}
                # un-commenta tutte le righe segnate con ##
                sed -r -i "s/^##(.*\{vlan-id-j\}.*)/\1/" "$cur_path" 
                # duplica tutte le righe da completare, segnando la copia con ##
                sed -r -i "s/(^[^#].*\{vlan-id-j\}.*)/\1\n##\1/" "$cur_path"

                # sostituisce nelle variabili vlan-id-j
                sed -r -i "s/(^[^#\n]*)(\{vlan-id-j\})/\1${vlan}/" "$cur_path"
            done
            # elimina tutte le righe segnate con ##
            sed -r -i '/\{eth-i\}/! s/^##(.*\{vlan-id-j\}.*)//' "$cur_path" 

            for i in "${!ETHS[@]}"; do
                eth=${ETHS[$i]}
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
            sed -r -i '/\{vlan-id-j\}/! s/^##(.*\{eth-i\}.*)//' "$cur_path" 

        elif [[ $cur == "c"* ]]; then
            read -p "[$cur]> Enter IP address (x.x.x.x): " IP
            sed -i "s/{indirizzo}/${IP}/" "$cur_path"
            read -p "[$cur]> Enter netmask (${IP}/y): " NET
            sed -i "s/{netmask}/${NET}/" "$cur_path"

            read -p "[$cur]> Enable apache2 web server? [Y/n]: " APA
            if [ "$APA" = "y" ] || [ "$APA" = "Y" ] || [ -z "$APA" ]; then
                sed -r -i "s/^##(.*(apache2).*)/\1/" "$cur_path" 
                read -p "[$cur]> Enter identifier: " WEB
                mkdir "$LABPATH/$cur" > /dev/null 2>&1 && echo -e "\e[1;36mDirectory '$LABPATH/$cur' created\e[0;0m" || echo -e "\e[1;36mDirectory '$LABPATH/$cur' already exists\e[0;0m"
                cp -r "$LAB_TEMPLATE/web-server-template/var" "$LABPATH/$cur"
                sed -i "s/{HOSTNAME}/${WEB}/" "$LABPATH/$cur/var/www/html/index.html"
                read -p "[$cur]> Test web-server? [y/N] " WEB
                if [ "$WEB" = "y" ] || [ "$WEB" = "Y" ]; then
                    links "$LABPATH/$cur/var/www/html/index.html" > /dev/null 2>&1 || echo -e "\e[1;31m'links' not working or 'index.html' not present\e[0;0m"
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
        read -p "[$cur]> Enter ASN: " ASN
        ID=""
        if [[ $1 =~ "leaf" ]]; then
            read -p "[$cur]> Use loopback address for router ID? [Y/n] " ID 
            if [ "$ID" = "y" ] || [ "$ID" = "Y" ] || [ -z "$ID" ]; then
                ID=$( cat "$LABPATH/$cur.startup" | grep lo:1 | sed -r "s/.*(\b[0-9]{1,3}(\.[0-9]{1,3}){3}).*/\1/" | sed -n 1p )
            else
                read -p "[$cur]> Enter router ID: " ID
            fi
        else
            read -p "[$cur]> Enter router ID: " ID
        fi
        echo "[$cur]> ASN=$ASN Router-ID=$ID"
        cp -r "$LAB_TEMPLATE/$( echo $cur | sed -r "s/([a-z]*).*/\1/" )-template/etc" "$LABPATH/$cur"
        sed -i "s/{ASN}/${ASN}/" "$LABPATH/$cur/etc/frr/frr.conf"
        sed -i "s/{router-id}/${ID}/" "$LABPATH/$cur/etc/frr/frr.conf"
    done
}

main() {
    echo -e "###########################################"
    echo -e "Default lab configuration is 2x2 Fat-Tree"
    echo -e "Manually change configuration if needed"
    echo -e "Manually configure lab.conf"
    echo -e "###########################################\n"

    echo -e "This script will search the current lab directory for .startup(s) files"
    echo -e "Leaves, spines, and tofs are 'leaf*', 'spine*' and 'tof*'.\e[0;0m\n" 
    read -p $'Configure .startup(s)? (\e[1;31mTHIS WILL OVERWRITE THEM, CONTINUE?\e[0;0m) [Y/n] ' CONT

    if  [ "$CONT" = "y" ] || [ "$CONT" = "Y" ] || [ -z "$CONT" ]; then
        configure_startup
    fi

    echo -e "\nSearching directory..."
    echo -e "Leaves:\e[1;34m"
    ls "$LABPATH" | grep "leaf\S*\.startup" | sed "s/\.startup//" || echo  -e "\e[0;0mno leaves" 
    LEAVES="$( ls "$LABPATH" | grep "leaf\S*\.startup" | sed "s/\.startup//" )" || LEAVES=""

    echo -e "\e[0;0m\nSpines:\e[1;34m"
    ls "$LABPATH" | grep "spine\S*\.startup" | sed "s/\.startup//" || echo  -e "\e[0;0mno spines"
    SPINES="$( ls "$LABPATH" | grep "spine\S*\.startup" | sed "s/\.startup//" )" || SPINES=""

    echo -e "\e[0;0m\nToFs:\e[1;34m"
    ls "$LABPATH" | grep "tof\S*\.startup" | sed "s/\.startup//" || echo -e "\e[0;0mno tofs"
    TOFS="$( ls "$LABPATH" | grep "tof\S*\.startup" | sed "s/\.startup//" )" || TOFS=""

    echo -e "\e[0;0m\nAttempting to create directories...\n"

    declare -a nodes=( "LEAVES" "SPINES" "TOFS" )
    for j in "${nodes[@]}"
    do
        cur=$( eval "echo \"\${$j}\"" )
        if [ -z "${cur}" ]; then
            continue
        fi
        for i in $( seq 1 $( echo "$cur" | wc -l ) )
        do
            cur_i=$( sed -n ${i}p <<< "$cur" )
            mkdir "$LABPATH/$cur_i" > /dev/null 2>&1 && echo -e "\e[1;36mDirectory '$LABPATH/$cur_i' created\e[0;0m"  || echo -e "\e[1;36mDirectory '$LABPATH/$cur_i' already exists\e[0;0m"
        done
    done

    read -p $'\n\e[1;31mTHIS WILL OVERWRITE EXISTING CONFIG(S), CONTINUE?\e[0;0m [Y/n] ' CONT
    if  ! [ "$CONT" = "y" ] && ! [ "$CONT" = "Y" ] && ! [ -z "$CONT" ]; then
        exit 0
    fi

    echo -e "\nConfiguring leaves..."
    configure_bgp "$LEAVES"

    echo -e "\nConfiguring spines..."
    configure_bgp "$SPINES"

    echo -e "\nConfiguring tofs..."
    configure_bgp "$TOFS"

    read -p "Finished..." DUMP
}

main
