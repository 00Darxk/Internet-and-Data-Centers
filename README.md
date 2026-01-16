# Internet and Data Centers
Appunti tratti dal corso di Internet and Data Centers, Anno Accademico 2025/26, Dipartimento di Ingegneria Civile, Informatica e delle Tecnologie Aeronautiche.  

## Contenuti:
 - [Esercizi](Esercizi/): [soluzioni](Esercizi/labs) di esercizi, esami o esoneri. Le traccie dei singoli esercizi sono o nella directory del lab o nel [README](Esercizi/labs/README.md). Ed un [template](Esercizi/lab-template/) generico per un lab; 
 - [Appunti](Internet-and-Data-Centers.pdf) delle lezioni, tenute l'anno accademico 2025/26 dal professore Maurizio Patrignani e Lorenzo Ariemma;

## Contenuti del Corso

<details open><summary><em>Programma</em></summary>

 - Introduzione alla struttura di Internet e al rapporto tra Internet, Data Center e Cloud
 - Il Polo Strategico Nazionale: un grande Data Center in corso di realizzazione
 - Il Sistema Pubblico di Connettività: un insieme di grandi reti private connesse tra loro e connesse a Internet
 - Digital Sovereignty (seminario dell'Ing. Gabriele Lospoto)
 - Le metodologie e le tecnologie di routing:
    - Generalità sugli algoritmi di instradamento per l'infrastruttura di rete fissa
    - Algoritmi e protocolli di livello tre:
        - Algoritmi Distance Vector
        - Algoritmi Link-State-Packet
        - Protocolli di instradamento
        - *Kathará* Introduction
        - *Kathará* Static Routing  
        - *Kathará* ARP  
        - *Kathará* FFRouting Introduction  
        - *Kathará* RIP with FFRouting  
        - *Kathará* OSPF with FRRouting  
        - *Kathará* Web server  
    - Algoritmi e protocolli di livello due:
        - Calcolo dello spanning tree in reti con switch
        - VLAN: reti locali virtuali
        - Evoluzione dello spanning tree protocol
        - Software Defined Networks
        - Network Address Translation (NAT)
 - IPv6
    - Indirizzamento e aspetti di base del protocollo (richiami)
    - ICMPv6
    - Source address selection e multihoming
    - Meccanismi di transizione IPv4-IPv6
 - Il routing interdominio:
    - Border Gateway Protocol
    - *Kathará* BGP Simple Peering FRR  
    - *Kathará* BGP Announcement FRR  
    - *Kathará* Prefix Filtering  
    - *Kathará* Stub AS  
    - *Kathará* Stub AS Static  
    - *Kathará* Multi-homed Stub AS  
    - *Kathará* Multi-homed Stub AS Large  
    - *Kathará* Multi-homed AS 
    - BGP pitfalls
    - Scalabilità di BGP
    - La gerarchia di Internet
    - Uso del servizio RIPE Stat
    - Uso del servizio AS Rank
    - Uso dei Looking Glass - il caso Hurricane Electric
    - Anomalie in Internet
    - *Kathará* Transit AS
    - Routing di un ISP basato su MPLS
 - TCP e le tecniche per trasmissioni efficienti:
    - Efficienza di TCP nei servizi interattivi
    - TCP e controllo di congestione 
    - Comportamento self-clocking di TCP e il prodotto banda-latenza
    - Comportamento aimd di TCP
    - BBR TCP
 - Routing nei data centers
    - *Kathará* Data Center Routing using FRR
 - Servizi basati sul Web: dai Data center alle CDN:
    - Architetture, modelli e algoritmi per servizi basati sul Web
    - Distribuzione locale
    - Distribuzione globale
    - Content delivery networks
    - *Kathará* Load Balancer Random
</details>


## Materiale Aggiuntivo
 - [Appunti](https://github.com/00Darxk/Reti-di-Calcolatori) del corso di Reti di Calcolatori 2024/25;
 - [asrank](https://asrank.caida.org/asns) sito per classificare autonomous system;
 - [RIPEstat](https://stat.ripe.net/) tool per le statistiche BGP di RIPE;
 - [BGP Looking Glass](https://www.bgplookingglass.com/) database di looking glass per vari AS;
 - [*Kathará*](https://github.com/KatharaFramework/Kathara), emulatore di reti, utilizzato durante il corso, esoneri ed esame;
 - [*Kathará* Labs](https://github.com/KatharaFramework/Kathara-Labs), repository contenente lab ufficiali di *Kathará*, tutorial, esoneri ed esami passati;
 - [net-vis](https://github.com/Friscobuffo/net-vis-localhost) visualizzatore di reti per lab *Kathará*;
 - [Esami_IDC](https://github.com/xReniar/Esami_IDC), repository contenente soluzioni di esoneri ed esami passati per il corso;
 - [Sito del corso](http://impianti.inf.uniroma3.it), con i lucidi delle lezioni, esercizi, esoneri ed esami passati. 


#
Per segnalare eventuali refusi, correzioni o integrazioni aprite una [nuova issue](https://github.com/00Darxk/Internet-and-Data-Centers/issues/new/choose) o [pull request](https://github.com/00Darxk/Internet-and-Data-Centers/pulls), con le relative modifiche, nella repository.