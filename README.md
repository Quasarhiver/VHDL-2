# Projet LogiGame - TE608

## Vue d'ensemble

Ce depot contient une implementation VHDL du mini-projet **LogiGame** du module **TE608 - Conception de systemes numeriques 2**.

Le sujet fourni dans le PDF demande trois ensembles de travail :

1. construire un coeur de microcontroleur simple base sur une UAL, un datapath et une memoire d'instructions ;
2. construire un jeu de reflexe sur carte ARTY avec LFSR, timer, compteur de score et controleur de jeu ;
3. remplacer le LFSR VHDL du jeu par une version "programmee" via le coeur de microcontroleur.

Le depot est globalement bien structure et contient la majorite des briques demandees, mais il reste plusieurs points importants a corriger ou a clarifier avant de considerer le projet comme completement robuste pour la simulation, la soutenance et la synthese sur carte.

Ce README a deux objectifs :

1. documenter en detail l'architecture, les fichiers et l'utilisation du projet ;
2. faire un etat honnete du depot actuel, avec les ecarts identifies par rapport au sujet et les risques techniques.

## Source des consignes

Les consignes analysees proviennent du document :

- `TE608 - 25_26 - Conception de systemes numeriques 2 - v1.1.pdf`

Les points les plus structurants du sujet sont les suivants :

- Partie 1 :
  - coeur MCU 4 bits signes en entree, 8 bits en sortie ;
  - UAL 16 operations ;
  - datapath avec `Buffer_A`, `Buffer_B`, `MEM_CACHE_1`, `MEM_CACHE_2`, `MEM_SEL_FCT`, `MEM_SEL_OUT`, `MEM_SR_IN_L`, `MEM_SR_IN_R` ;
  - memoire d'instructions 128 x 10 bits ;
  - trois programmes a implementer :
    - `RES_OUT_1 = A * B`
    - `RES_OUT_2 = (A + B) xnor A`
    - `RES_OUT_3 = (A0 and B1) or (A1 and B0)`
- Partie 2 :
  - LFSR 4 bits a 1 kHz ;
  - timer selon `SW[3:2]` ;
  - score sur 4 bits jusqu'a 15 ;
  - verification du bouton correspondant a la couleur de `LD3` ;
  - FSM de jeu `IDLE -> NEW_ROUND -> WAIT_RESPONSE -> END_GAME`.
- Partie 3 :
  - remplacement du LFSR materiel par une generation pseudo-aleatoire via le coeur MCU ;
  - memoire d'instructions dediee a la generation de la suite pseudo-aleatoire ;
  - utilisation des registres internes du datapath pour reconstruire l'etat suivant.

## Arborescence du depot

Le depot est organise ainsi :

```text
.
|-- part1/
|   |-- ual.vhd
|   |-- datapath.vhd
|   |-- mcu_controller.vhd
|   |-- mcu_top.vhd
|   |-- tb_ual.vhd
|   |-- tb_datapath.vhd
|   `-- tb_mcu_controller.vhd
|
|-- part2/
|   |-- lfsr4.vhd
|   |-- difficulty_timer.vhd
|   |-- score_counter.vhd
|   |-- response_checker.vhd
|   |-- game_controller.vhd
|   |-- logigame_top.vhd
|   |-- tb_lfsr4.vhd
|   |-- tb_game_controller.vhd
|   |-- tb_difficulty_timer_and_score.vhd
|   `-- tb_response_checker.vhd
|
|-- part3/
|   |-- mcu_lfsr_program.vhd
|   |-- logigame_mcu_top.vhd
|   |-- tb_mcu_lfsr_program.vhd
|   |-- tb_logigame_mcu_top.vhd
|   `-- Arty_Digilent_TopLevel_Constraints.xdc
|
|-- student_package_vivado_comb_01/
|   `-- student_package_vivado_comb_01/
|       |-- Arty_Digilent_TopLevel_Empty.vhd
|       `-- Arty_Digilent_TopLevel_Constraints.xdc
|
`-- TE608 - 25_26 - Conception de systemes numeriques 2 - v1.1.pdf
```

## Etat global du depot

### Ce qui est present

- les fichiers VHDL principaux des trois parties ;
- les top-levels `Arty_Digilent_TopLevel` pour la synthese sur carte ;
- un fichier de contraintes ARTY ;
- plusieurs bancs de test ;
- une decomposition assez lisible par parties.

### Ce qui manque ou merite d'etre complete

- aucun `README` d'origine ;
- aucun script de simulation ;
- aucun script de synthese ;
- aucun projet Vivado exporte ;
- pas de separation explicite des "source sets" alors que **les trois parties definissent la meme entite top-level** `Arty_Digilent_TopLevel`.

## Important avant d'ouvrir dans Vivado

Le depot contient **plusieurs fichiers avec la meme entite top-level** :

- `part1/mcu_top.vhd`
- `part2/logigame_top.vhd`
- `part3/logigame_mcu_top.vhd`
- `student_package_vivado_comb_01/.../Arty_Digilent_TopLevel_Empty.vhd`

Ils definissent tous `entity Arty_Digilent_TopLevel`.

Consequence :

- il ne faut **pas** ajouter tous ces fichiers dans le meme projet Vivado actif ;
- il faut creer un projet ou un ensemble de sources **par partie** ;
- le fichier vide du package etudiant sert de modele de ports, pas de top final a conserver en meme temps que les tops reels.

## Contraintes et interface carte ARTY

Le sujet demande de respecter l'entite globale fournie dans le package etudiant. C'est globalement le cas : les trois tops utilisent le nom `Arty_Digilent_TopLevel` et les memes ports principaux.

### Fichier de contraintes de reference

Le fichier de contraintes de reference est fourni dans :

- `student_package_vivado_comb_01/student_package_vivado_comb_01/Arty_Digilent_TopLevel_Constraints.xdc`

Une copie simplifiee est aussi presente dans :

- `part3/Arty_Digilent_TopLevel_Constraints.xdc`

### Mapping physique retenu

- `CLK100MHZ` : horloge 100 MHz
- `sw[3:0]` : switches utilisateur
- `btn[3:0]` : boutons utilisateur
- `led[3:0]` : LED standard
- `led0_*` a `led3_*` : LED RGB

### Usage attendu selon le sujet

- Partie 1 :
  - `sw[3:0]` : operande 4 bits avec `A = B` sur la carte ;
  - `btn[0]` : reset ;
  - `btn[1]`, `btn[2]`, `btn[3]` : lancement des trois programmes ;
  - LED rouges : resultat ;
  - une LED verte : signal `DONE` ;
  - deux LED bleues : `SROUTL` et `SROUTR`.
- Partie 2 et Partie 3 :
  - `btn[0]` : lancement / reset du jeu ;
  - `btn[1]` : bleu ;
  - `btn[2]` : vert ;
  - `btn[3]` : rouge ;
  - `sw[3:2]` : difficulte ;
  - `led[3:0]` : score ;
  - `led3_r/g/b` : stimulus couleur ;
  - `led0_r/g/b` : resultat final.

## Partie 1 - Coeur de microcontroleur

### Objectif

Construire un coeur MCU simple comportant :

- une UAL 4 bits ;
- un datapath avec memoires intermediaires ;
- un controleur avec ROM d'instructions ;
- un top de test pour la carte ARTY.

### Fichiers principaux

#### `part1/ual.vhd`

Role :

- implementer les 16 operations arithmetiques et logiques demandees ;
- produire une sortie `S` sur 8 bits ;
- exposer `SROUTL` et `SROUTR` pour les decalages.

Operations codees :

- `0000` : NOP
- `0001` : `A`
- `0010` : `not A`
- `0011` : `B`
- `0100` : `not B`
- `0101` : `A and B`
- `0110` : `A or B`
- `0111` : `A xor B`
- `1000` : `A + B + Cin`
- `1001` : `A + B`
- `1010` : `A - B`
- `1011` : `A * B`
- `1100` : shift right de `A`
- `1101` : shift left de `A`
- `1110` : shift right de `B`
- `1111` : shift left de `B`

Points positifs :

- couverture fonctionnelle conforme au tableau du sujet ;
- multiplication 4 bits vers 8 bits bien prevue ;
- signaux serie exposes.

#### `part1/datapath.vhd`

Role :

- memoriser les operandes et resultats intermediaires ;
- interfacer l'UAL ;
- appliquer les codes `SELROUTE` et `SELOUT`.

Registres internes presents :

- `BufferA`
- `BufferB`
- `MEMCACHE1`
- `MEMCACHE2`
- `MEMSELFCT`
- `MEMSELOUT`
- `MEMSRINL`
- `MEMSRINR`

Remarque importante :

- la structure generale est bien alignée avec les pages 10 a 14 du PDF ;
- `SELFCT`, `SELOUT`, `SRINL`, `SRINR` sont memorises a chaque front montant, ce qui suit bien la logique temporelle du sujet ;
- `SELROUTE` reste combinatoire vers la logique de chargement, ce qui suit aussi les consignes.

#### `part1/mcu_controller.vhd`

Role :

- stocker en ROM les programmes de test ;
- piloter `SELFCT`, `SELROUTE`, `SELOUT` ;
- gerer un signal `DONE`.

Programmes cibles :

- programme 0 : `A * B`
- programme 1 : `(A + B) xnor A`
- programme 2 : `(A0 and B1) or (A1 and B0)`

Architecture :

- ROM 128 x 10 bits ;
- FSM `IDLE -> RUN -> DONE_ST` ;
- base d'adresse selon `SEL_PROG`.

#### `part1/mcu_top.vhd`

Role :

- instancier le `datapath` et le `mcu_controller` ;
- mapper les boutons, switches et LED de la carte.

Bon point :

- le mapping general suit correctement les slides d'integration ARTY de la partie 1.

### Bancs de test

- `tb_ual.vhd`
- `tb_datapath.vhd`
- `tb_mcu_controller.vhd`

Ils couvrent l'UAL, le datapath et l'ensemble controleur + datapath, mais il faut garder a l'esprit que certaines hypotheses de test ne couvrent pas tous les cas reels.

### Etat de completion de la partie 1

Sur le plan structurel, **la partie 1 est presente** :

- UAL : oui
- datapath : oui
- controleur MCU : oui
- top ARTY : oui
- testbenches : oui

Apres correction et validation locale sous GHDL, la partie 1 est maintenant exploitable sur les cas cibles du sujet :

- `tb_ual`, `tb_datapath` et `tb_mcu_controller` passent ;
- les trois programmes MCU demandes par le sujet produisent bien les resultats attendus ;
- la ROM du controleur a ete realignee avec la latence reelle d'un cycle du datapath ;
- les instructions finales maintiennent `RESOUT` sans ecraser `MEMCACHE1` en etat `DONE`.

Point a encore assumer clairement dans le rapport :

- la convention exacte de sequencement `SELFCT / SELROUTE / SELOUT` du datapath.

## Partie 2 - Jeu LogiGame avec LFSR VHDL

### Objectif

Construire le jeu interactif avec :

- un LFSR 4 bits ;
- un timer de difficulte ;
- un compteur de score ;
- un verificateur de reponse ;
- un controleur principal ;
- un top ARTY.

### Fichiers principaux

#### `part2/lfsr4.vhd`

Role :

- produire une valeur pseudo-aleatoire 4 bits ;
- repartir d'un seed non nul `1011` ;
- faire evoluer l'etat a `1 kHz`.

Ce que le sujet demande :

- polynome `X^4 + X^3 + 1`
- feedback : XOR des bits 3 et 2
- sequence de 15 etats

#### `part2/difficulty_timer.vhd`

Role :

- gerer le temps autorise selon `SW_LEVEL`.

Niveaux implementes :

- `00` : 4 s
- `01` : 2 s
- `10` : 1 s
- `11` : 0.5 s

Le module genere une impulsion `TIMEOUT` d'un seul cycle a la fin du delai.

#### `part2/score_counter.vhd`

Role :

- incrementer le score sur `VALID_HIT` ;
- figer le score en cas d'erreur ;
- lever `GAME_OVER` sur erreur ou a 15.

#### `part2/response_checker.vhd`

Role :

- verifier la coherence entre la couleur affichee et le bouton presse ;
- refuser les reponses multiples ;
- generer `VALID_HIT` ou `ERROR`.

Logique implemente :

- `100` -> bouton rouge
- `010` -> bouton vert
- `001` -> bouton bleu

#### `part2/game_controller.vhd`

Role :

- coordonner LFSR, timer, score et checker ;
- appliquer la FSM de jeu.

FSM :

- `IDLE`
- `NEW_ROUND`
- `WAIT_RESPONSE`
- `END_GAME`

#### `part2/logigame_top.vhd`

Role :

- connecter le controleur de jeu aux E/S de la carte.

### Bancs de test

- `tb_lfsr4.vhd`
- `tb_game_controller.vhd`
- `tb_difficulty_timer_and_score.vhd`
- `tb_response_checker.vhd`

Remarque :

- le fichier `tb_difficulty_timer_and_score.vhd` contient en realite **deux bancs de test** :
  - `tb_difficulty_timer`
  - `tb_score_counter`

Cela reste exploitable, mais ce n'est pas ideal pour l'organisation du projet.

### Etat de completion de la partie 2

Sur le plan structurel, **la partie 2 est presente** :

- LFSR : oui
- timer : oui
- score : oui
- checker : oui
- game controller : oui
- top ARTY : oui
- plusieurs testbenches : oui

Depuis la correction de ce depot :

- le lancement du jeu via `btn[0]` est maintenant gere par un **pulse de start au relachement** du bouton, tout en conservant `RESET` actif pendant l'appui ;
- le `LFSR` memorise une demande d'avance jusqu'au prochain tick `1 kHz`, ce qui garantit une nouvelle valeur par manche ;
- `response_checker.vhd` ignore maintenant un bouton maintenu entre deux manches, ce qui evite les doubles comptages ;
- `tb_lfsr4.vhd` verifie maintenant explicitement la sequence attendue sur 15 pas.
- `tb_response_checker.vhd` couvre maintenant bonnes reponses, erreurs, timeout, desactivation et bouton maintenu.

La partie 2 est donc **coherente fonctionnellement**, et ses bancs principaux passent sous GHDL.

## Partie 3 - Jeu avec LFSR remplace par le MCU

### Objectif

Remplacer le LFSR de la partie 2 par une generation pseudo-aleatoire effectuee par le coeur MCU.

### Fichiers principaux

#### `part3/mcu_lfsr_program.vhd`

Role :

- fournir une petite memoire d'instructions dediee a la generation pseudo-aleatoire ;
- piloter le `datapath` de la partie 1 ;
- sortir un `DONE` lorsque la nouvelle valeur pseudo-aleatoire est disponible ;
- executer la sequence **a la demande**, et non en boucle libre.

Principe :

- au premier lancement apres reset, le programme initialise `MEMCACHE1[3:0]` a `1011` ;
- ensuite, chaque demande `START` declenche une seule mise a jour pseudo-aleatoire ;
- le datapath realise decalages, XOR, OR et recomposition ;
- la nouvelle valeur pseudo-aleatoire est exposee via `RESOUT`.

#### `part3/logigame_mcu_top.vhd`

Role :

- remplacer le LFSR de la partie 2 par le duo `mcu_lfsr_program + datapath` ;
- reutiliser `difficulty_timer`, `score_counter` et `response_checker`.

### Bancs de test

- `tb_mcu_lfsr_program.vhd`
- `tb_logigame_mcu_top.vhd`

### Etat de completion de la partie 3

La structure generale est bien la :

- programme MCU dedie : oui
- top d'integration : oui
- contrainte XDC : oui
- testbench global : oui

Depuis la correction de ce depot :

- `START` et `RESET` ne sont plus relies brutalement de facon incompatible ;
- le sequenceur MCU ne tourne plus en continu pendant `WAIT_RESPONSE` ;
- `MEMCACHE1` est maintenant initialise explicitement a `1011` lors du premier lancement ;
- chaque nouvelle manche demande explicitement une seule nouvelle valeur pseudo-aleatoire ;
- `tb_mcu_lfsr_program.vhd` verifie maintenant la sequence pseudo-aleatoire complete sur 15 etats ;
- `tb_logigame_mcu_top.vhd` valide un scenario global avec demarrage, bonne reponse, erreur et redemarrage.

La partie 3 est donc **structurellement et fonctionnellement bien mieux cadree** qu'avant. Elle est maintenant validee localement sous GHDL par un test dedie du generateur MCU et par un test d'integration top-level avec assertions.

## Dependances entre fichiers

### Partie 1

Ordre logique de dependance :

1. `ual.vhd`
2. `datapath.vhd`
3. `mcu_controller.vhd`
4. `mcu_top.vhd`
5. bancs de test correspondants

### Partie 2

Ordre logique de dependance :

1. `lfsr4.vhd`
2. `difficulty_timer.vhd`
3. `score_counter.vhd`
4. `response_checker.vhd`
5. `game_controller.vhd`
6. `logigame_top.vhd`
7. bancs de test

### Partie 3

Ordre logique de dependance :

1. fichiers de la partie 1 :
   - `ual.vhd`
   - `datapath.vhd`
2. fichiers de la partie 2 :
   - `difficulty_timer.vhd`
   - `score_counter.vhd`
   - `response_checker.vhd`
3. `mcu_lfsr_program.vhd`
4. `logigame_mcu_top.vhd`
5. `tb_logigame_mcu_top.vhd`

Important :

- la partie 3 depend explicitement de sources de `part1` et `part2` ;
- si tu crees un projet Vivado pour la partie 3, il faut ajouter les sources partagees manuellement.

## Comment utiliser le depot dans Vivado

### Projet Vivado pour la partie 1

Ajouter uniquement :

- `part1/ual.vhd`
- `part1/datapath.vhd`
- `part1/mcu_controller.vhd`
- `part1/mcu_top.vhd`
- le fichier XDC du package etudiant ou celui de `part3`

Choisir top :

- `Arty_Digilent_TopLevel`

### Projet Vivado pour la partie 2

Ajouter uniquement :

- `part2/lfsr4.vhd`
- `part2/difficulty_timer.vhd`
- `part2/score_counter.vhd`
- `part2/response_checker.vhd`
- `part2/game_controller.vhd`
- `part2/logigame_top.vhd`
- le fichier XDC

Choisir top :

- `Arty_Digilent_TopLevel`

### Projet Vivado pour la partie 3

Ajouter :

- `part1/ual.vhd`
- `part1/datapath.vhd`
- `part2/difficulty_timer.vhd`
- `part2/score_counter.vhd`
- `part2/response_checker.vhd`
- `part3/mcu_lfsr_program.vhd`
- `part3/logigame_mcu_top.vhd`
- `part3/Arty_Digilent_TopLevel_Constraints.xdc`

Choisir top :

- `Arty_Digilent_TopLevel`

## Comment simuler

Le depot ne contient pas de script de simulation preconfigure, donc il faut charger les sources manuellement dans GHDL, Vivado Simulator, ModelSim ou un outil equivalent.

### Bancs de test disponibles

Partie 1 :

- `tb_ual`
- `tb_datapath`
- `tb_mcu_controller`

Partie 2 :

- `tb_lfsr4`
- `tb_difficulty_timer`
- `tb_score_counter`
- `tb_game_controller`
- `tb_response_checker`

Partie 3 :

- `tb_mcu_lfsr_program`
- `tb_logigame_mcu_top`

### Limites actuelles des testbenches

- certains bancs de test verifient surtout des cas "heureux" ;
- il reste peu de verification explicite de scenarios de timeout au niveau **top-level** ;
- les problemes de couplage top-level carte ne sont pas tous attrapes ;
- `part2/tb_difficulty_timer_and_score.vhd` contient toujours deux entites de testbench dans un seul fichier.

### Validation locale effectuee

Validation faite localement avec `GHDL 6.0.0` sur cette machine :

- analyse + elaboration reussies pour les trois parties ;
- simulations avec assertions passees :
  - `tb_ual`
  - `tb_datapath`
  - `tb_mcu_controller`
  - `tb_lfsr4`
  - `tb_difficulty_timer`
  - `tb_score_counter`
  - `tb_response_checker`
  - `tb_game_controller`
  - `tb_mcu_lfsr_program`
  - `tb_logigame_mcu_top`

En pratique, le depot dispose maintenant d'une regression GHDL qui couvre les trois parties de facon beaucoup plus convaincante qu'au debut de l'audit.

## Installer Vivado et GHDL sur cette machine

### Etat local observe

Sur cette machine, au moment de la mise a jour de ce README :

- OS detecte : `Windows 11 Professionnel`, 64 bits ;
- espace libre sur `C:` : environ `28.5 GB` ;
- `winget` est disponible ;
- `GHDL` a ete installe avec succes via `winget` ;
- l'executable a ete repere ici : `C:\Users\max\AppData\Local\Microsoft\WinGet\Packages\ghdl.ghdl.ucrt64.mcode_Microsoft.Winget.Source_8wekyb3d8bbwe\bin\ghdl.exe` ;
- `Vivado` n'est pas installe.

Conseil important :

- `GHDL` est deja installe et utilisable ici ;
- `Vivado` risque d'etre serre en espace disque avec seulement `28.5 GB` libres si tu prends une installation large ;
- pour `Vivado`, il faut absolument choisir une installation minimale ciblee sur `Artix-7` / `Arty A7-35T`.

### Installer GHDL

La methode la plus simple ici est `winget`.

Commande PowerShell recommandee :

```powershell
winget install --id ghdl.ghdl.ucrt64.mcode --accept-package-agreements --accept-source-agreements
```

Sur cette machine, cette installation a reussi.

Puis fermer et rouvrir le terminal, puis verifier :

```powershell
ghdl --version
```

Si `ghdl` n'est pas encore trouve dans le `PATH` apres installation, rouvrir PowerShell. En attendant, il peut etre lance par son chemin complet dans le dossier `WinGet\\Packages`.

Alternative :

- telecharger l'archive Windows standalone depuis les releases officielles GHDL ;
- decompresser dans un dossier sans espace, par exemple `C:\tools\ghdl` ;
- ajouter ce dossier au `PATH`.

### Installer Vivado

Vivado n'apparait pas dans `winget` ici. La methode propre passe par l'installateur officiel AMD.

Procedure conseillee :

1. creer ou utiliser un compte AMD ;
2. telecharger le `AMD Unified Installer for FPGAs & Adaptive SoCs` ;
3. lancer l'installateur ;
4. choisir `Download and Install Now` ;
5. selectionner `Vivado` ;
6. ne garder que les familles et outils necessaires au projet ;
7. choisir un chemin d'installation **sans espace** ;
8. verifier le resume d'installation et l'espace disque demande ;
9. lancer l'installation ;
10. installer les cable drivers si tu comptes programmer la carte ARTY depuis cette machine.

Selection minimale recommandee pour ce projet :

- `Vivado` ;
- support `Artix-7` ;
- eventuellement `Hardware Server` / cable drivers ;
- eviter les familles de FPGA non utilisees ;
- eviter les options lourdes inutiles.

Exemple de repertoire d'installation :

```text
C:\Xilinx\Vivado
```

### Verifier ensuite l'installation Vivado

Dans PowerShell :

```powershell
where.exe vivado
```

Ou bien lancer l'interface depuis le menu Demarrer.

### Exemple de commandes GHDL une fois installe

Partie 1 :

```powershell
ghdl -a --std=08 part1/ual.vhd part1/datapath.vhd part1/mcu_controller.vhd part1/tb_mcu_controller.vhd
ghdl -e --std=08 tb_mcu_controller
ghdl -r --std=08 tb_mcu_controller
```

Partie 2 :

```powershell
ghdl -a --std=08 part2/lfsr4.vhd part2\difficulty_timer.vhd part2\score_counter.vhd part2\response_checker.vhd part2\game_controller.vhd part2\tb_lfsr4.vhd part2\tb_response_checker.vhd part2\tb_game_controller.vhd part2\tb_difficulty_timer_and_score.vhd
ghdl -e --std=08 tb_response_checker
ghdl -r --std=08 tb_response_checker
```

Partie 3 :

```powershell
ghdl -a --std=08 part1/ual.vhd part1/datapath.vhd part2/difficulty_timer.vhd part2/score_counter.vhd part2/response_checker.vhd part3/mcu_lfsr_program.vhd part3/logigame_mcu_top.vhd part3/tb_mcu_lfsr_program.vhd part3/tb_logigame_mcu_top.vhd
ghdl -e --std=08 tb_mcu_lfsr_program
ghdl -r --std=08 tb_mcu_lfsr_program
```

## Audit technique du depot

Cette section est volontairement directe. L'idee n'est pas de devaloriser le travail, mais d'identifier ce qui est reellement pret et ce qui risque de casser en simulation ou sur FPGA.

### Correctifs critiques appliques

Les points suivants ont ete corriges dans cette mise a jour :

1. `btn[0]` ne sert plus de facon incompatible a `RESET` et `START` :
   - dans `part2/logigame_top.vhd` et `part3/logigame_mcu_top.vhd`, un **pulse de start au relachement** du bouton est genere ;
   - l'appui maintient toujours le reset actif, ce qui reste conforme a l'usage attendu sur la carte.
2. Le `LFSR` de la partie 2 ne depend plus d'une coincidence accidentelle entre un pulse a `100 MHz` et le tick `1 kHz` :
   - `part2/lfsr4.vhd` memorise maintenant une requete d'avance jusqu'au prochain tick ;
   - une seule nouvelle valeur est produite par demande.
3. Les programmes MCU de la partie 1 ont ete realignes avec le datapath reel :
   - `RES_OUT_1`, `RES_OUT_2` et `RES_OUT_3` tiennent maintenant compte de la latence d'un cycle entre `SELFCT` et le routage ;
   - le resultat final reste stable en etat `DONE` sans effacer `MEMCACHE1`.
4. Le programme `RES_OUT_2` de la partie 1 a ete rendu generique et `RES_OUT_3` a ete simplifie :
   - `RES_OUT_2` n'utilise plus l'hypothese implicite `A = B` ;
   - `RES_OUT_3` repose desormais sur des decalages a droite plus naturels pour extraire `A1`, `B1`, puis recombiner le resultat directement sur le `bit 0`.
5. Le pseudo-LFSR MCU de la partie 3 est maintenant initialise correctement :
   - `mcu_lfsr_program.vhd` charge explicitement `1011` dans `MEMCACHE1` au premier lancement ;
   - les tours suivants ne refont pas l'initialisation.
6. Le sequenceur MCU de la partie 3 ne tourne plus en boucle libre pendant la phase de reponse et son programme est aligne avec le datapath reel :
   - il fonctionne desormais **a la demande** ;
   - une nouvelle valeur pseudo-aleatoire est calculee uniquement au debut d'une nouvelle manche ;
   - la micro-sequence ROM tient maintenant compte de la latence d'un cycle du datapath, comme en partie 1.
7. La couverture de test a ete etendue :
   - il ne se contente plus d'afficher des valeurs ;
   - `tb_lfsr4.vhd` verifie explicitement la sequence attendue ;
   - `tb_response_checker.vhd` couvre les cas fonctionnels critiques du checker ;
   - `tb_mcu_lfsr_program.vhd` verifie la sequence pseudo-aleatoire MCU complete ;
   - `tb_logigame_mcu_top.vhd` valide un scenario global avec assertions.
8. `response_checker.vhd` a ete securise contre les appuis maintenus :
   - un front montant de bouton est necessaire pour valider une reponse ;
   - un bouton garde appuye entre deux manches n'ajoute plus un point par erreur.
9. Une incoherence mineure a ete supprimee dans `part1/mcu_top.vhd` :
   - la double affectation de `led2_r` a ete retiree.

### Points encore sensibles

Le depot est nettement plus propre qu'avant, mais il reste des limites importantes :

- `Vivado` n'a pas ete installe ici, donc la validation de synthese/place&route reste a faire ;
- le test top-level de la partie 3 ne couvre pas encore un vrai timeout complet avec le timer reel, car cela allonge fortement la simulation ;
- le choix du LFSR maximal (`feedback = bit3 xor bit0`) est **coherent avec la sequence a 15 etats**, mais il differe du texte brut de certaines slides qui mentionnent `bit3 xor bit2` ;
- `part2/tb_difficulty_timer_and_score.vhd` contient encore deux entites de testbench dans un seul fichier ;
- le depot contient toujours plusieurs tops `Arty_Digilent_TopLevel`, donc il faut continuer a separer les projets ou les source sets dans Vivado.

### Consequence pratique

Apres ces corrections, le depot n'est plus dans l'etat "structure presente mais comportement critique faux". Il est maintenant dans un etat beaucoup plus defendable :

- la logique de demarrage sur carte est credible ;
- les chemins critiques de generation pseudo-aleatoire sont corriges ;
- les programmes MCU principaux sont plus coherents avec le sujet ;
- la documentation du projet est exploitable pour un rapport.

## Synthese honnete : est-ce que "tout y est" ?

### Oui, sur le plan de la structure

Le depot contient bien les grands blocs attendus :

- Partie 1 complete en apparence ;
- Partie 2 complete en apparence ;
- Partie 3 presente ;
- tops ARTY presents ;
- fichier de contraintes present ;
- bancs de test presents en nombre raisonnable.

### Pas encore totalement sur le plan de la robustesse

Il manque encore des elements pour pouvoir dire "le projet est totalement verrouille" :

- la validation Vivado reste a faire ;
- le choix de convention LFSR devra etre assume clairement dans le rapport ;
- certains bancs de test restent trop legers ;
- l'organisation du depot reste manuelle cote Vivado.

## Recommandations prioritaires

Si tu veux remettre ce projet dans un etat vraiment defendable, l'ordre conseille est :

1. installer `Vivado` avec un profil minimal `Artix-7` ;
2. valider la synthese et l'implementation dans Vivado pour les trois parties ;
3. ajouter si besoin un scenario de timeout complet au niveau top-level ;
4. separer `tb_difficulty_timer` et `tb_score_counter` dans deux fichiers si tu veux un depot plus propre ;
5. expliquer explicitement dans le rapport le choix de la convention LFSR retenue.

## Livrables attendus par le sujet

Le PDF rappelle qu'en fin de projet il faut fournir :

- une archive ZIP du projet ;
- un fichier texte resumant les entites VHDL ;
- un rapport detaille.

Ce README peut servir de base solide pour le rapport technique ou au moins pour la partie "description de l'architecture" et "etat d'avancement".

## Conclusion

Le depot montre un travail important et la quasi-totalite des briques attendues sont la. L'architecture est comprehensible, les noms sont coherents, et l'intention globale suit bien le sujet. Les principaux problemes critiques releves lors de l'audit initial ont ete corriges dans cette mise a jour.

En l'etat, je qualifierais le projet ainsi :

- **structurellement complet**
- **valide localement sous GHDL sur les parties 1 et 2**
- **encore a verrouiller sous Vivado et par des tests plus forts sur la partie 3**

La suite logique est maintenant :

1. installer `Vivado` ici ;
2. ouvrir les trois parties dans des projets Vivado separes ;
3. valider la partie 3 sur carte ou avec un testbench plus strict ;
4. figer dans le rapport la convention exacte du LFSR choisie.
