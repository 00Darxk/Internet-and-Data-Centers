# Right-Weight

C'è un bug di frr, dove avere un quadrato di connessioni, due a due appartenenti a zone diverse, gli annunci non vengono gestiti correttamente. Per risolvere si è rimosso il link ```N``` dal [lab.conf](./lab.conf), simulando il comportamento voluto, che sfavorisce lo stesso link per avere un costo di 50000. 