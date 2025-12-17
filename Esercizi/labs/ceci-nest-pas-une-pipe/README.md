# 

La versione configurata è una variante corretta, disponibile sul [Moodle del corso](https://ingegneriacivileinformaticatecnologieaeronautiche.el.uniroma3.it/pluginfile.php/140083/mod_resource/content/0/2023-01-20-ceci-nest-pas-une-pipe.pdf)

Gli indirizzi di loopback per ```leaf1```, ```leaf2``` e ```leaf3``` sono ```192.168.0.1```, ```192.168.0.2``` e ```192.168.0.3```. Le LAN tra  ```tofspine``` e le foglie non hanno indirizzi IP. 

Il load balancer invia i pacchetti in maniera casuale tra i due servizi. I server non si occupano da switch, contenendo i web server. Essendo di livello applicativo, non devono avere conoscenze sul data center, quindi bisogna inviargli i pacchetti già decapsulati. 