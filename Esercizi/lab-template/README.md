# Configurare Lab

## Configurare ```lab.conf```

Collegare a domini di collisione e configurare immagini:
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

## Configurare ```.startup``` e ```frr.conf```

Per creare velocemente un lab da terminale:
```bash
# crea i file di startup e lab.conf
touch lab.conf '{nome-host-1}.startup' {...} '{nome-host-n}.startup'
# oppure copiarli dalle template (da modificare)
cp "${PATH_TO_LAB_TEMPLATE}/startups-template/{tipo-host}-template.startup" '{nome-host}.startup'

# crea le directory 
mkdir '{host-1}' {...} '{host-N}'
# copia il contenuto di etc (per router)
mkdir '{nome-host}' && cp -r "${PATH_TO_LAB_TEMPLATE}/router-template/etc" '{nome-host}'
# copia il contenuto di var (per web server)
mkdir '{nome-host}' && cp -r "${PATH_TO_LAB_TEMPLATE}/web-server-template/var" '{nome-host}'

# abilitare i daemon necessari
# protocollo: 'ospf', 'rip', 'bgp'
sed -i 's/{protocollo}d=no/{protocollo}d=yes/' '{nome-host}/etc/frr/daemons'
```
Copiando dai template, bisogna sostituire dei valori a tutte le variabili tra parentesi graffe ```{var}```. Il file template per un [router BGP](./router-template/etc/frr/frr.conf) 

### Script
Oppure usando gli script [generate-lab-rip-ospf](generate-lab-rip-ospf.sh), solo per configurazioni di lab RIP o OSPF o [generate-lab-data-center](generate-lab-data-center.sh) per i data center. Entrambi questi script prendono come primo parametro il path dove generare il lab, il secondo script prende anche come secondo parametro il percorso a questo [lab-template](.). Di default questi percorsi puntano alla working directory (```pwd```). 
Non modificare i file ```*-template``` in questa directory per garantire il funzionamento di quest'ultimo script. Questo script può sovrascrivere le configurazioni già esistenti. 

# Debuggare un Lab

Per buttare giù un interfaccia: 
```bash
# rimuove gli indirizzi dall'interfaccia
ip address flush dev {interfaccia} 
# spegne l'interfaccia
ifconfig {interfaccia} down
```

Per visualizzare la tabella di instradamento di un bridge:
```bash
brctl showmacs '{nome-bridge}'
```
Per i data center, nei template il nome di default del bridge è ```br100```. 


## ```vtysh``` 

Si può aprire la shell ```vty``` digitando il comando ```vtysh``` su una macchina dov'è abilitato, oppure si possono eseguire comandi sulla shell con la flag ```-e```:
```bash
# lasciare il campo protocollo vuoto mostra informazioni complessive
# protocollo: 'ospf', 'rip', 'bgp', ' '
vtysh -e "sh ip {protocollo}"
vtysh -e "sh ip {protocollo} {indirizzo}"
vtysh -e "sh ip {protocollo} route"
vtysh -e "sh ip {protocollo} route {indirizzo}"
vtysh -e "sh ip {protocollo} route {prefisso}/{netmask}"
vtysh -e "sh ip database router"  # router ID
vtysh -e "sh ip database network" | grep "{prefisso LAN}" # LAN ID
vtysh -e "sh bgp sum"
vtysh -e "sh bgp nexthop"

# per visualizzare la tabella di instradamento mac-to-vtep
vtysh -e "sh evpn mac vni all"
```
Premendo ```Tab``` o ```?``` vengono mostrare alternative possibili per il comando parziale già inserito. 

## Zebra
Per avviare Zebra bisogna abilitarla nel file ```frr.conf``` corrispondente:
```bash
password zebra
enable password zebra
```
Dalla macchina ci si accede con:
```bash
telnet localhost zebra
```
Dentro ```telnet``` si possono eseguire comandi analoghi a ```vtysh```:
```bash
show ip route {prefisso}/{netmask}
show ip route {indirizzo}
```

## Logging BGP

Per abilitare il logging nelle macchine corrispondenti, bisogna inserire nel file ```frr.conf```:
```bash
log file /var/log/frr/frr.log
```
Si può accedere a questi log con ```less```:
```bash
less /var/log/frr/frr.log 
```
Con ```grep``` si possono cercare informazioni specifiche, come prefissi, router, o codici specifici:
```bash
# Codici rotte ricevute:
# T5AAP-5GA85  YCKEM-GB33T  RZMGQ-A03CG
# Codici rotte annunciate:
# HJD3A-QX9MN  TN0HX-6G1RR  HVRWP-5R9NQ  MBFVT-8GSC6
# Si possono passare più parametri a grep con l'opzione -e per ogni argomento
less /var/log/frr/frr.log | grep {indirizzo-peer}
less /var/log/frr/frr.log | grep {codice-log}
```
## Web Server
Per accedere al web server:
```bash
links {indirizzo}
```
Per controllare i log di accesso o di errore:
```bash
tail -f /var/log/apache2/access.log
tail -f /var/log/apache2/error.log
```
Per visualizzare tutti i moduli apache2 caricati
```bash
apache2 -l
```

# Programmi Utili

[net-vis](https://github.com/Friscobuffo/net-vis-localhost), utile per visualizzare graficamente le configurazione di un lab, sulla base dei file ```.startup``` e ```lab.conf```. 

```bash
alias net-vis="./net-vis-localhost-linux || ln -s '${PATH_TO_NET_VIS}/net-vis-localhost/out/net-vis-localhost-linux' . && ./net-vis-localhost-linux"
```

Script che restituisce informazioni sulle rotte annunciate e ricevute, dai log di FRR:
```bash
./shared/bgp-announcements.sh
```
