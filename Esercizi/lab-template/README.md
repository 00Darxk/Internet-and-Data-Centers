# Configurare ```lab.conf```

```bash
<nome-host>[<numero-interfaccia>]="<dominio-collisione>"
<nome-host>[image]="kathara/<immagine>"
```
Non è necessario configurare l'immagine per un router se la default è ```kathara/frr```, si può usare anche per il web server ```apache2```. 

# Comandi Utili

Per creare facilmente un lab da terminale:
```bash
# crea i file di startup e lab.conf
touch lab.conf {host-1}.startup {...} {host-N}.startup
# crea le directory 
mkdir {host-1} {...} {host-N}
# copia il contenuto di etc (per router)
cp -r {$PATH_TO_THIS}/lab-template/etc {host-i}
# copia il contenuto di var (per web server)
cp -r {$PATH_TO_THIS}/lab-template/var {host-i}
```

Per debuggare:
```bash
ip address flush dev {interfaccia}
ifconfig {interfaccia} down

vtysh -e "sh ip route"
vtysh -e "sh ip route {prefisso}/{netmask}"
vtysh -e "sh ip route {indirizzo}"
vtysh -e "sh ip database router"  # router ID
vtysh -e "sh ip database network" | grep "{prefisso LAN}" # LAN ID
vtysh -e "sh ip ospf"
vtysh -e "sh ip rip"
vtysh -e "sh ip bgp"
vtysh -e "sh ip bgp {indirizzo}"
vtysh -e "sh bgp sum"
vtysh -e "sh bgp nexthop"

telnet localhost zebra
(telnet) show ip route {prefisso}/{netmask}
(telnet) show ip route {indirizzo}

less /var/log/frr/frr.log 
less /var/log/frr/frr.log | grep {indirizzo-peer}

links {indirizzo}

tail -f /var/log/apache2/access.log
tail -f /var/log/apache2/error.log
apache2 -l
```

# Programmi Utili

[net-vis], utile per visualizzare graficamente le configurazione di un lab, sulla base dei file ```.startup``` e ```lab.conf```. 

```bash
alias net-vis="./net-vis-localhost-linux || ln -s $PATH_TO_NET_VIS/net-vis-localhost/out/net-vis-localhost-linux . && ./net-vis-localhost-linux"
```
