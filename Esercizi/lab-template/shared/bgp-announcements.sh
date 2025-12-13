#!/bin/bash

LOG=$(cat /var/log/frr/frr.log)

NC=$'\e[0;0m'
RED=$'\e[1;31m'
YEL=$'\e[1;33m'
BLUE=$'\e[1;34m'
PRL=$'\e[1;35m'
CYAN=$'\e[1;36m'

echo -e "${BLUE}Announcements received:${NC}"
echo "$LOG" | grep -e T5AAP-5GA85 -e YCKEM-GB33T -e RZMGQ-A03CG | sed -r 's/( \[.*\])//' | sed -r "s/(\b[0-9]{1,3}(\.[0-9]{1,3}){3}\/[0-9]{1,2})/${PRL}\1${NC}/" | sed -r "s/(\b[0-9]{1,3}(\.[0-9]{1,3}){3})/${BLUE}\1${NC}/" | sed -r "s/(\b[0-9]{1,3}(\.[0-9]{1,3}){3})/${CYAN}\1${NC}/" | sed "s/DENIED/${RED}DENIED${NC}/" 

echo -e "\n${YEL}Announcements sent:${NC}"
echo "$LOG" | grep -e HJD3A-QX9MN -e TN0HX-6G1RR -e HVRWP-5R9NQ -e MBFVT-8GSC6 | sed -r 's/ \[\w*-\w*\]//' | sed -r "s/(\b[0-9]{1,3}(\.[0-9]{1,3}){3}\/[0-9]{1,2})/${PRL}\1${NC}/" | sed -r "s/(\b[0-9]{1,3}(\.[0-9]{1,3}){3})/${BLUE}\1${NC}/" | sed -r "s/(\b[0-9]{1,3}(\.[0-9]{1,3}){3})/${CYAN}\1${NC}/" | sed "s/filtered/${RED}filtered${NC}/" 
