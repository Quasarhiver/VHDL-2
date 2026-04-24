# Projet LogiGame - TE608

## Resume

Ce depot contient une implementation VHDL du mini-projet `LogiGame` du module `TE608 - Conception de systemes numeriques 2`.

Le projet est organise en trois parties :

1. un coeur MCU simple base sur une UAL, un datapath et une ROM d'instructions
2. un jeu LogiGame sur carte ARTY avec LFSR, timer, score et controleur de jeu
3. une version finale ou le LFSR materiel est remplace par une generation pseudo-aleatoire via le coeur MCU

Etat actuel du depot apres audit :

- les sources VHDL principales sont presentes et compilent
- les `10` testbenches du depot passent avec `GHDL`
- les trois tops compilent separement
- la partie 3 execute maintenant le coeur MCU a `1 kHz` au sens strict
- la conversion couleur utilise maintenant un vrai `mod 3`

## Fichier de reference

Le sujet analyse pour ce depot est :

- `TE608 - 25_26 - Conception de systemes numeriques 2 - v1.1.pdf`

## Arborescence

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
|   |-- tb_response_checker.vhd
|   |-- tb_game_controller.vhd
|   `-- tb_difficulty_timer_and_score.vhd
|
|-- part3/
|   |-- mcu_lfsr_program.vhd
|   |-- logigame_mcu_top.vhd
|   |-- tb_mcu_lfsr_program.vhd
|   |-- tb_logigame_mcu_top.vhd
|   `-- Arty_Digilent_TopLevel_Constraints.xdc
|
|-- scripts/
|   |-- get_ghdl.ps1
|   `-- run_sims.ps1
|
`-- student_package_vivado_comb_01/
    `-- student_package_vivado_comb_01/
        |-- Arty_Digilent_TopLevel_Empty.vhd
        `-- Arty_Digilent_TopLevel_Constraints.xdc
```

## Verification effectuee

Validation locale realisee dans ce depot :

- execution de `powershell -ExecutionPolicy Bypass -File scripts\run_sims.ps1`
- compilation separee des tops des parties 1, 2 et 3 avec `GHDL`
- verification exhaustive des trois programmes MCU de la partie 1 sur toutes les combinaisons 4 bits

Resultat :

- `tb_ual` : OK
- `tb_datapath` : OK
- `tb_mcu_controller` : OK
- `tb_lfsr4` : OK
- `tb_response_checker` : OK
- `tb_difficulty_timer` : OK
- `tb_score_counter` : OK
- `tb_game_controller` : OK
- `tb_mcu_lfsr_program` : OK
- `tb_logigame_mcu_top` : OK

## Partie 1

### Contenu

La partie 1 implemente le coeur MCU de base :

- [part1/ual.vhd](/c:/Users/max/VHDL-2/part1/ual.vhd) : UAL 16 operations
- [part1/datapath.vhd](/c:/Users/max/VHDL-2/part1/datapath.vhd) : registres internes, routage, sortie `RESOUT`
- [part1/mcu_controller.vhd](/c:/Users/max/VHDL-2/part1/mcu_controller.vhd) : ROM d'instructions et FSM `IDLE -> RUN -> DONE_ST`
- [part1/mcu_top.vhd](/c:/Users/max/VHDL-2/part1/mcu_top.vhd) : integration carte ARTY

### Programmes implementes

- `RES_OUT_1 = A * B`
- `RES_OUT_2 = (A + B) xnor A`
- `RES_OUT_3 = (A0 and B1) or (A1 and B0)`

### Etat

La partie 1 est fonctionnelle en simulation :

- le top compile
- les trois programmes produisent les bons resultats
- `RES_OUT_2` est maintenant propre sur `8 bits`, avec le nibble haut remis a zero

## Partie 2

### Contenu

La partie 2 implemente le jeu LogiGame avec LFSR materiel :

- [part2/lfsr4.vhd](/c:/Users/max/VHDL-2/part2/lfsr4.vhd) : LFSR 4 bits, seed `1011`, feedback `bit3 xor bit2`, cadence `1 kHz`
- [part2/difficulty_timer.vhd](/c:/Users/max/VHDL-2/part2/difficulty_timer.vhd) : timer `4 s / 2 s / 1 s / 0.5 s`
- [part2/score_counter.vhd](/c:/Users/max/VHDL-2/part2/score_counter.vhd) : score 4 bits et `GAME_OVER`
- [part2/response_checker.vhd](/c:/Users/max/VHDL-2/part2/response_checker.vhd) : validation des boutons et du timeout
- [part2/game_controller.vhd](/c:/Users/max/VHDL-2/part2/game_controller.vhd) : FSM du jeu
- [part2/logigame_top.vhd](/c:/Users/max/VHDL-2/part2/logigame_top.vhd) : top ARTY

### Comportement notable

- le LFSR ne perd plus une demande d'avance si `ENABLE` est pulse a `100 MHz`
- le `response_checker` refuse maintenant les appuis multiples
- la couleur est derivee d'un vrai `mod 3` sur la valeur pseudo-aleatoire 4 bits
- un etat technique `WAIT_COLOR` existe pour laisser la couleur se stabiliser avant le lancement du timer

### Etat

La partie 2 est fonctionnelle en simulation et ses testbenches passent.

## Partie 3

### Contenu

La partie 3 remplace le LFSR materiel par le coeur MCU :

- [part3/mcu_lfsr_program.vhd](/c:/Users/max/VHDL-2/part3/mcu_lfsr_program.vhd) : microprogramme de generation pseudo-aleatoire
- [part3/logigame_mcu_top.vhd](/c:/Users/max/VHDL-2/part3/logigame_mcu_top.vhd) : integration finale
- [part3/tb_mcu_lfsr_program.vhd](/c:/Users/max/VHDL-2/part3/tb_mcu_lfsr_program.vhd) : verification de la sequence MCU
- [part3/tb_logigame_mcu_top.vhd](/c:/Users/max/VHDL-2/part3/tb_logigame_mcu_top.vhd) : scenario global de jeu

### Comportement notable

- le coeur MCU de la partie 3 tourne maintenant sur une horloge derivee a `1 kHz`
- le datapath de la partie 3 est cadence avec cette meme horloge MCU
- le signal `DONE` du MCU est resynchronise vers le domaine `100 MHz` du jeu
- la sequence pseudo-aleatoire obtenue est identique a celle du LFSR de la partie 2
- la couleur est derivee d'un vrai `mod 3` sur `RESOUT(3 downto 0)`

### Etat

La partie 3 est fonctionnelle en simulation et respecte maintenant l'exigence `FMCU = 1 kHz` du PDF de facon stricte.

## Simulation avec GHDL

### Installation

Telecharger GHDL localement :

```powershell
powershell -ExecutionPolicy Bypass -File scripts\get_ghdl.ps1
```

### Regression complete

Lancer tous les testbenches :

```powershell
powershell -ExecutionPolicy Bypass -File scripts\run_sims.ps1
```

Le script utilise le binaire local :

- [tools/ghdl/bin/ghdl.exe](/c:/Users/max/VHDL-2/tools/ghdl/bin/ghdl.exe)

## Utilisation dans Vivado

### Important

Les trois parties definissent toutes la meme entite top-level :

- [part1/mcu_top.vhd](/c:/Users/max/VHDL-2/part1/mcu_top.vhd:31)
- [part2/logigame_top.vhd](/c:/Users/max/VHDL-2/part2/logigame_top.vhd:25)
- [part3/logigame_mcu_top.vhd](/c:/Users/max/VHDL-2/part3/logigame_mcu_top.vhd:22)
- [student_package_vivado_comb_01/student_package_vivado_comb_01/Arty_Digilent_TopLevel_Empty.vhd](/c:/Users/max/VHDL-2/student_package_vivado_comb_01/student_package_vivado_comb_01/Arty_Digilent_TopLevel_Empty.vhd:5)

Toutes s'appellent `Arty_Digilent_TopLevel`.

Consequence :

- ne pas mettre tous les tops dans le meme source set
- creer un projet Vivado par partie, ou au minimum un jeu de sources distinct par partie

### Sources a charger

Pour la partie 1 :

- `part1/ual.vhd`
- `part1/datapath.vhd`
- `part1/mcu_controller.vhd`
- `part1/mcu_top.vhd`

Pour la partie 2 :

- `part2/lfsr4.vhd`
- `part2/difficulty_timer.vhd`
- `part2/score_counter.vhd`
- `part2/response_checker.vhd`
- `part2/game_controller.vhd`
- `part2/logigame_top.vhd`

Pour la partie 3 :

- `part1/ual.vhd`
- `part1/datapath.vhd`
- `part2/difficulty_timer.vhd`
- `part2/score_counter.vhd`
- `part2/response_checker.vhd`
- `part3/mcu_lfsr_program.vhd`
- `part3/logigame_mcu_top.vhd`

### Contraintes

Le modele fourni par le package etudiant est ici :

- [student_package_vivado_comb_01/student_package_vivado_comb_01/Arty_Digilent_TopLevel_Constraints.xdc](/c:/Users/max/VHDL-2/student_package_vivado_comb_01/student_package_vivado_comb_01/Arty_Digilent_TopLevel_Constraints.xdc)

Une copie de travail est aussi presente ici :

- [part3/Arty_Digilent_TopLevel_Constraints.xdc](/c:/Users/max/VHDL-2/part3/Arty_Digilent_TopLevel_Constraints.xdc)

## Limitations connues

Le depot est propre en simulation, mais il reste quelques limites connues :

- la validation `Vivado` complete n'est pas faite dans ce depot
- les boutons physiques sont encore utilises sans vrai debounce
- le test du timer ne simule pas les delais reels complets sur `4 s / 2 s / 1 s / 0.5 s`
- [part2/tb_difficulty_timer_and_score.vhd](/c:/Users/max/VHDL-2/part2/tb_difficulty_timer_and_score.vhd) contient toujours deux entites de testbench dans un seul fichier

## Conclusion

Apres audit et corrections, le depot est dans un etat coherent et defendable :

- les trois parties sont implementees
- les principaux bugs logiques identifies ont ete corriges
- la partie 3 respecte maintenant l'exigence `MCU a 1 kHz`
- la couleur est calculee par vrai `mod 3`
- la regression `GHDL` passe integralement

Le point principal a garder en tete pour la suite est methodologique :

- un projet Vivado par partie
- puis validation synthese / implementation / carte si tu veux verrouiller le projet jusqu'au bout
