# Configurare ```lab.conf```

```bash
{nome-host}[{numero-interfaccia}]="{dominio-collisione}"
{nome-host}[image]="kathara/{immagine}"
```
Non è necessario configurare l'immagine per un router se la default è ```kathara/frr```, si può usare anche per il web server ```apache2```. 

Per configurare un data center, bisogna abilitare IPv6 ed il multipath su tutte le macchine relative, ovvero leaf, spine e ToF:
```bash
{nome-host}[ipv6]=True
{nome-host}[sysctl]="net.ipv4.fib_multipath_hash_policy=1"
```

# Generare File

Per creare facilmente un lab da terminale:
```bash
# crea i file di startup e lab.conf
touch lab.conf {host-1}.startup {...} {host-N}.startup
# crea le directory 
mkdir {host-1} {...} {host-N}
# copia il contenuto di etc (per router)
cp -r {$PATH_TO_THIS}/lab-template/router-template/etc {host-i}
# copia il contenuto di var (per web server)
cp -r {$PATH_TO_THIS}/lab-template/web-server-template/var {host-i}
```
Oppure usando lo [script](./generate-lab-rip-ospf.sh), solo per configurazioni di lab RIP o OSPF.  

# Debugging

Per debuggare i protocolli di routing, BGP, RIP e OSPF:
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
less /var/log/frr/frr.log | grep {codice-log}
# Codici rotte ricevute:
# T5AAP-5GA85  YCKEM-GB33T  RZMGQ-A03CG
# Codici rotte annunciate:
# HJD3A-QX9MN  TN0HX-6G1RR  HVRWP-5R9NQ  MBFVT-8GSC6
# Si possono passare più parametri a grep con l'opzione -e per ogni argomento

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

Script che restituisce informazioni sulle rotte annunciate o ricevute, dai log di FRR:
```bash
./shared/bgp-announcements.sh
```
