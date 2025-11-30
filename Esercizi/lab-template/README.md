# Configurare ```lab.conf```

```bash
<nome-host>[<numero-interfaccia>]="<dominio-collisione>"
<nome-host>[image]="kathara/<immagine>"
```

# Comandi Utili

```bash
ip address add {indirizzo}/{netmask} dev {interfaccia}
ip route add {prefisso}/{netmask} via {indirizzo} dev {interfaccia}

vtysh -e "sh ip route"
vtysh -e "sh ip route" | grep "0/0" # default entries
vtysh -e "sh ip database router"  # router ID
vtysh -e "sh ip database network" | grep "{prefisso LAN}" # LAN ID
vtysh -e "sh ip ospf"
vtysh -e "sh ip rip"
vtysh -e "sh ip bgp"
vtysh -e "sh bgp sum"
vtysh -e "sh bgp nexthop"

telnet localhost zebra
(telnet) show ip route {prefisso}/{netmaks}
(telnet) show ip route {indirizzo}

less /var/log/frr/frr.log

links {indirizzo}
tail -f /var/log/apache2/access.log
tail -f /var/log/apache2/error.log
apache2 -l


alias net-vis="./net-vis-localhost-linux || ln -s IDC/Materiale-Corso/net-vis-localhost/out/net-vis-localhost-linux . && ./net-vis-localhost-linux"
```
