donc pour la partie 2 on veut faire un petit jeu de reflexe , le principe c est que on choisit une couleur pour notre led, rouge vert ou bleu 

le joueur doit appuyer sur le bon bouton a temps ,  ( le temps autorisé depend de la difficultée du jeu choisi )

si le joueur a appuyé sur le bon bouton le score augmente, si le joueur se trompe, appuie sur plusieurs bouton, ou si le temsp est depassé la partie s arrete

le joueur doit arriver a 15 points pour reussir la partie 

la led LD0 montre le resultat final
vert si 15, orange si entre 7 et 14, rouge si entre 0 et 6


roles des fichiers : 


lfsr4.vhd : gere le pseudo aleatoire , il donne des nombres qui semblent aleatoires, mais sont en realite produits par une regle fixe ( d ou le pseudo aleatoire) ces nombres servent a donner les couleurs

difficulty_timer.vhd : c est celui qui va chronometrer et definir la difficulté du jeu ( difficulté 00 : 4s , difficulté 01 : 2s , difficulté 10 : 1s et enfin difficulté 11 : 0,5s)

score_counter.vhd : garde le score en memoire, et ajoute 1 quand la reponse est correcte
il declenche aussi la fin du jeu quand il atteint 15

reponse_checker : il regarde quel(s) bouton(s) est/sont  pressé par le joueur et et dit si c est une bonne reponse ou une erreur, ensuite score_counter et game_controller decident quoi faire 


game_controler :  Il décide quand lancer une nouvelle manche, quand allumer la couleur, quand démarrer le chrono, quand attendre la réponse, et quand arrêter le jeu.

logigame_top.vhd : c est le fichier qui donne la realité physique et qui branche la vrai carte arty , il associe la realité physique aux signaux du jeu 


ensuite les fichiers -tb sont les fichiers de testbenchs









partie sur le pseudo aleatoire : 


Le “pseudo-random” de la partie 2 est en fait une suite de nombres fabriquée par une règle très simple, pas par du vrai hasard. Le fichier qui fait ça est part2/lfsr4.vhd.

L’idée de base est la suivante : on garde en mémoire 4 bits, par exemple 1011. À chaque fois qu’on veut une nouvelle valeur, on ne tire pas un nombre au hasard. On prend la valeur actuelle, on calcule un nouveau bit avec une petite règle, puis on décale tout. C’est comme une file de 4 cases qui glisse d’un cran.

Dans ce projet, la règle est :

on regarde les bits 3 et 2
on fait leur xor
ce résultat devient le nouveau bit qu’on ajoute à droite
Et en même temps, les 3 autres bits se décalent vers la gauche.

Donc si on part de 1011 :

bit 3 = 1
bit 2 = 0
1 xor 0 = 1
on décale 1011 vers la gauche en gardant les 3 derniers bits 011
on ajoute le nouveau bit 1
on obtient 0111
Puis on recommence :

0111
bit 3 = 0
bit 2 = 1
0 xor 1 = 1
nouvelle valeur : 1111
Puis encore :

1111
1 xor 1 = 0
nouvelle valeur : 1110
C’est exactement pour ça que dans le testbench on voit une suite comme :
1011 -> 0111 -> 1111 -> 1110 -> 1100 -> ...



proposition pour aller plus loin et faire un vrai random : 

Si on veut du vrai random, il faut exploiter un phénomène physique du FPGA, pas juste une formule.
La solution classique, c’est de faire tourner des oscillateurs libres, de lire leur état à des instants réguliers, puis d’utiliser ces lectures comme bits aléatoires.