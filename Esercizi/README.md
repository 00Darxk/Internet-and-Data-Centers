# Cose Utili

```bash

<nome-host>[<numero-interfaccia>]="<dominio-collisione>"
<nome-host>[image]="kathara/<immagine>"

ip address add {indirizzo}/{netmask} dev {interfaccia}
ip route add {prefisso}/{netmask} via {indirizzo} dev {interfaccia}

vtysh -e "show ip route"
vtysh -e "show ip route" | grep "0/0" # default entries
vtysh -e "show ip database router"  # router ID
vtysh -e "show ip database network" | grep "{prefisso LAN}" # LAN ID

alias net-vis="./net-vis-localhost-linux || ln -s IDC/Materiale-Corso/net-vis-localhost/out/net-vis-localhost-linux . && ./net-vis-localhost-linux"
```