description du systeme : 


on a un microcontrolleur dont l'execution d'une instruction complete prend 3 cycles (3 fronts montants )
    - 1er front montant : la memoire charge le code binaire de la ligne selectionnée 
    - 2eme front montant : il va passer les données a l'ual qui est l unité de calcul, et cette unité elle est combinatoire, donc elle calcule directement sans front montant et a le temps de se stabiliser avant le prochain front montant 
    - 3eme front montant : on capture le resultat du calcul de notre ual. 

C'est du pipeline, donc pendant qu'une instruction est à son 2ème front montant (calcul), l'instruction suivante en est à son 1er (lecture), et l'instruction précédente en est à son 3ème (sauvegarde).
l'idée c est que on attend pas un cycle complet pour en relancer un , on fait tout a la chaine 


 exemple : 

| Front Montant (Rising) | Instruction 1     | Instruction 2     | Instruction 3     |
| :--------------------- | :---------------- | :---------------- | :---------------- |
| Rising Edge 1          | Lecture ROM       | -                 | -                 |
| Rising Edge 2          | Calcul UAL        | Lecture ROM       | -                 |
| Rising Edge 3          | Sauvegarde        | Calcul UAL        | Lecture ROM       |
| Rising Edge 4          | Terminée          | Sauvegarde        | Calcul UAL        |
| Rising Edge 5          | Terminée          | Terminée          | Sauvegarde        |


role des differents fichiers : 

ual.vhd : 
c est celui qui calcule 
pas d'horloge, donc travaille en dehors des cycles de rising edge 
il sait faire 16 operations differentes 


datapath.vhd :

c est lui qui gere les flux de donnée 
il a l'ual a l'interieur de lui, et il gere comment l'ual est cablé au reste de l'entité


mcu_controller.vhd : 


c est lui qui donne la tempo ; il contient la memoire et le compteur qui sert a lire la memoire , puis il envoie ce qu'il a lu au datapath


mcu_top.vhd : 

c est le fichier qui fait le lien avec la carte physique, il englobe toute notre architecture et il branche les fils virtuels au vrai broches de la carte fpga 



les fichiers tb sont la pour tester les comportements et verifier que tout marche correctement 