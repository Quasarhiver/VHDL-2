-- =============================================================================
-- Module      : mcu_controller.vhd
-- Description : Contrôleur MCU avec mémoire d'instructions ROM 128 × 10 bits.
--               Format mot instruction : SELFCT[3:0] | SELROUTE[3:0] | SELOUT[1:0]
--               3 programmes encodés :
--                 PROG 0 (btn1) : RESOUT1 = A × B  (8 bits)
--                 PROG 1 (btn2) : RESOUT2 = (A+B) XNOR A  (4 LSBs)
--                 PROG 2 (btn3) : RESOUT3 = (A0 AND B1) OR (A1 AND B0)  (bit 0)
--               FSM : IDLE → RUN → DONE
--               DONE passe à '1' quand le résultat est disponible sur RESOUT.
-- Auteur      : Projet LogiGame – TE608 EFREI 2025-2026
-- Cible       : Xilinx Artix-35T – Vivado / GHDL
-- Révision    : 1.0 – Avril 2026
-- =============================================================================
-- Encodage instruction (10 bits) :
--   [9:6]  SELFCT  (4 bits) – code opération UAL
--   [5:2]  SELROUTE(4 bits) – routage des données
--   [1:0]  SELOUT  (2 bits) – sélection sortie RESOUT
--
-- Adresses ROM :
--   Programme 0 (A×B)           : adresses 0  à 15
--   Programme 1 ((A+B) xnor A)  : adresses 16 à 31
--   Programme 2 (A0B1 or A1B0)  : adresses 32 à 47
-- =============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity mcu_controller is
    Port (
        CLK      : in  STD_LOGIC;
        RESET    : in  STD_LOGIC;
        START    : in  STD_LOGIC;                    -- Lance le calcul (front montant)
        SEL_PROG : in  STD_LOGIC_VECTOR(1 downto 0); -- Sélection du programme
        -- Sorties vers le datapath
        SELFCT   : out STD_LOGIC_VECTOR(3 downto 0);
        SELROUTE : out STD_LOGIC_VECTOR(3 downto 0);
        SELOUT   : out STD_LOGIC_VECTOR(1 downto 0);
        -- Indicateur fin de calcul
        DONE     : out STD_LOGIC
    );
end mcu_controller;

architecture Behavioral of mcu_controller is

    -- =========================================================================
    -- Types et constantes
    -- =========================================================================
    type rom_type  is array (0 to 127) of STD_LOGIC_VECTOR(9 downto 0);
    type fsm_state is (IDLE, RUN, DONE_ST);

    -- =========================================================================
    -- Fonction helper : construit un mot instruction
    -- =========================================================================
    -- NOP instruction (no operation, no route, no output)
    constant NOP_INSTR : STD_LOGIC_VECTOR(9 downto 0) := "0000000000";

    -- =========================================================================
    -- ROM d'instructions 128 × 10 bits
    -- =========================================================================
    -- Format : SELFCT(3:0) & SELROUTE(3:0) & SELOUT(1:0)
    --
    -- SEL_FCT codes :
    --   0000=NOP  0001=A    0010=notA  0011=B    0100=notB
    --   0101=AND  0110=OR   0111=XOR   1000=ADD+ 1001=ADD
    --   1010=SUB  1011=MUL  1100=SRA   1101=SLA  1110=SRB  1111=SLB
    --
    -- SEL_ROUTE codes :
    --   0000=A→BufA  0001=B→BufB  0010=S[3:0]→BufA[3:0]  0011=S[3:0]→BufA[7:4]
    --   0100=S[3:0]→BufB[3:0]  0101=S[3:0]→BufB[7:4]
    --   0110=S→MC1   0111=S→MC2
    --   1000=MC1[3:0]→BufA[3:0]  1001=MC1[7:4]→BufA[3:0]
    --   1010=MC1[3:0]→BufB[3:0]  1011=MC1[7:4]→BufB[3:0]
    --   1100=MC2[3:0]→BufA[3:0]  1101=MC2[7:4]→BufA[3:0]
    --   1110=MC2[3:0]→BufB[3:0]  1111=MC2[7:4]→BufB[3:0]
    --
    -- SEL_OUT codes :
    --   00=zéro  01=MC1  10=MC2  11=S
    --
    -- -------------------------------------------------------------------------
    -- PROGRAMME 0 : RESOUT1 = A × B  (8 bits)
    -- -------------------------------------------------------------------------
    -- Le datapath mémorise SELFCT/SELOUT sur le front d'horloge. Le routage
    -- consomme donc le résultat UAL du cycle précédent.
    --
    -- Cycle 0 : Charger A dans BufferA
    -- Cycle 1 : Charger B dans BufferB et préparer MUL
    -- Cycle 2 : Routage S -> MC1 et affichage MC1
    --
    -- PROGRAMME 1 : RESOUT2 = (A+B) XNOR A  (4 LSBs)
    -- -------------------------------------------------------------------------
    -- Implémentation générique :
    -- Cycle 0 : Charger A dans BufferA
    -- Cycle 1 : Charger B dans BufferB et préparer ADD
    -- Cycle 2 : Routage S -> MC1  (MC1 = A + B)
    -- Cycle 3 : Charger MC1[3:0] dans BufferB et préparer XOR
    -- Cycle 4 : Routage S[3:0] -> BufferB[3:0] et préparer notB
    -- Cycle 5 : Routage S -> MC1 et affichage MC1
    --
    -- PROGRAMME 2 : RESOUT3 = (A0 AND B1) OR (A1 AND B0)  sur bit 0
    -- -------------------------------------------------------------------------
    -- On a A=sw[3:0] et B=sw[3:0] pour le test, donc:
    -- A0=sw[0], A1=sw[1], B0=sw[0], B1=sw[1]
    -- (A0 AND B1) = A[0] AND B[1]
    -- (A1 AND B0) = A[1] AND B[0]
    -- Pour extraire bits individuels, on utilise des masques via AND et décalages.
    -- Cycle 0 : BufferA ← A_IN (SELROUTE=0000)
    -- Cycle 1 : BufferB ← B_IN (SELROUTE=0001)
    -- Cycle 2 : SRA(A) : décalage droit de A → A[0]→SROUTR, [3:1]→[2:0]
    --           On a besoin de A0. Masque : AND(A, "0001") puis SRA pour isoler A[0].
    --           Approche directe : A AND "0001" = A0 dans BufferA, B AND "0010" → isoler B1
    --           On masque A avec "0001" via XOR tricks... mais plus simple:
    --           Utiliser SRA (1100) pour décaler A à droite → S[3:0] = SRINL & A[3:1]
    --           avec SRINL=0 → S[0]=A[1], S[3:1]=0
    --           Mais l'UAL fait SRA sur 4 bits: S = {SRINL, A[3:1]} → A[0] sort sur SROUTR
    --           On ne peut pas capturer SROUTR dans les registres directement...
    --           Approche alternative: AND puis masquage combiné
    -- Simplification : Pour le test A=B, (A0 AND B1) OR (A1 AND B0) = A0*A1 OR A1*A0 = A0 AND A1
    -- Mais il faut rester général. On utilise :
    -- Step : masquer A avec 0001 (SLA A deux fois pour isoler A[0] puis revenir)
    --        En fait, on peut faire:
    --        BufferA = A_IN, BufferB = B_IN
    --        SLA(A) → S = {A[2:0], SRINR=0} = A décalé gauche, A[3] sort en SROUTL
    --        puis SLA(A) à nouveau → {A[1:0],0,0}, A[2] sort
    --        Mais on ne peut stocker que S (pas SROUTL).
    --        Solution plus simple: on utilise AND direct pour masquer les bits.
    --        A AND B → donne les bits communs. Pour (A0 AND B1) OR (A1 AND B0) :
    --        = bit 0 du résultat de ((A SHL 0) AND (B SHL 1)) OR ((A SHL 1) AND (B SHL 0))
    --        On manipule : SLA(A) donne A<<1. Puis AND(A<<1, B) = A[i]*B[i-1].
    --        Trop complexe pour 10 cycles. Simplifons :
    --        RESOUT3 = bit[0] de (A XOR B) revient à (A0≠B0). Mais la spec est précise.
    --        On implémente directement : charger A, SLA, stocker MC1 (A<<1)
    --        puis AND(MC1[3:0], B_IN) → MC2, puis SRB pour extraire bit 0 de MC2
    --        Autre nibble : SLA B, AND avec A → MC2 (cumul)
    -- Voir ci-dessous pour l'implémentation finale choisie.
    --
    -- Implémentation choisie pour PROG2:
    -- BUT : calculer (A[0] AND B[1]) OR (A[1] AND B[0]) sur bit[0] de RESOUT
    --
    -- Etape 1  : BufferA ← A_IN                (SELROUTE=0000)
    -- Etape 2  : BufferB ← B_IN                (SELROUTE=0001)
    -- Etape 3  : SLA(A): S={A[2:0],0}, MC1←S   (SEL_FCT=1101, SELROUTE=0110)
    --            MC1 = A << 1
    -- Etape 4  : MC1[3:0]→BufA                 (SELROUTE=1000) BufA = A<<1
    -- Etape 5  : AND(BufA,BufB)→MC2            (SEL_FCT=0101, SELROUTE=0111)
    --            MC2[0] = A[1] AND B[0]  (bit 0 du résultat)
    -- Etape 6  : SLA(B): S={B[2:0],0}, MC1←S   (SEL_FCT=1111, SELROUTE=0110)
    --            MC1 = B << 1
    -- Etape 7  : MC1[3:0]→BufB                 (SELROUTE=1010)
    -- Etape 8  : BufferA ← A_IN à nouveau       (SELROUTE=0000) -- recharge A dans BufA
    -- Etape 9  : AND(BufA,BufB)→MC1            (SEL_FCT=0101, SELROUTE=0110)
    --            MC1[0] = A[0] AND B[1]
    -- Etape 10 : MC2[3:0]→BufA                 (SELROUTE=1100)  BufA[3:0]=MC2[3:0]
    -- Etape 11 : MC1[3:0]→BufB                 (SELROUTE=1010)  BufB[3:0]=MC1[3:0]
    -- Etape 12 : OR(BufA, BufB)→MC1            (SEL_FCT=0110, SELROUTE=0110)
    --            Le résultat intermédiaire utile est en bit1.
    -- Etape 13 : MC1[3:0]→BufA                 (SELROUTE=1000)
    -- Etape 14 : SRA(BufA)→MC1                 (SEL_FCT=1100, SELROUTE=0110)
    --            Décalage droit pour ramener le résultat final sur bit0.
    -- Etape 15 : SELOUT=01 → RESOUT = MC1

    constant ROM : rom_type := (
        -- ==============================================================
        -- PROGRAMME 0 : RESOUT1 = A × B  (adresses 0-3)
        -- ==============================================================
        -- [9:6]=SELFCT  [5:2]=SELROUTE  [1:0]=SELOUT
        0  => "0000" & "0000" & "00",  -- BufferA <- A_IN
        1  => "1011" & "0001" & "00",  -- BufferB <- B_IN ; préparer MUL
        2  => "0000" & "0110" & "00",  -- MC1 <- A*B
        3  => "0000" & "0000" & "01",  -- Affichage MC1, maintien sûr en DONE
        4  => "0000" & "0000" & "01",
        5  => "0000" & "0000" & "01",
        6  => "0000" & "0000" & "01",
        7  => "0000" & "0000" & "01",
        -- ==============================================================
        -- PROGRAMME 1 : RESOUT2 = (A+B) XNOR A  4LSBs (adresses 8-14)
        -- ==============================================================
        8  => "0000" & "0000" & "00",  -- BufferA <- A_IN
        9  => "1001" & "0001" & "00",  -- BufferB <- B_IN ; préparer ADD
        10 => "0000" & "0110" & "00",  -- MC1 <- A + B
        11 => "0111" & "1010" & "00",  -- BufferB <- MC1[3:0] ; préparer XOR
        12 => "0100" & "0100" & "00",  -- BufferB <- A xor (A+B) ; préparer notB
        13 => "0000" & "0110" & "00",  -- MC1 <- not(BufferB)
        14 => "0000" & "0000" & "01",  -- Affichage MC1, maintien sûr en DONE
        15 => "0000" & "0000" & "01",
        -- ==============================================================
        -- PROGRAMME 2 : RESOUT3 = (A0∧B1) ∨ (A1∧B0) sur bit[0] (adresses 20-32)
        -- ==============================================================
        20 => "0000" & "0000" & "00",  -- BufferA <- A_IN
        21 => "1100" & "0001" & "00",  -- BufferB <- B_IN ; préparer SRA(A)
        22 => "0000" & "0110" & "00",  -- MC1 <- A>>1
        23 => "0101" & "1000" & "00",  -- BufferA <- MC1[3:0] ; préparer AND
        24 => "1110" & "0111" & "00",  -- MC2 <- (A>>1) AND B ; préparer SRB(B)
        25 => "0000" & "0110" & "00",  -- MC1 <- B>>1
        26 => "0000" & "1010" & "00",  -- BufferB <- MC1[3:0]
        27 => "0101" & "0000" & "00",  -- BufferA <- A_IN ; préparer AND
        28 => "0000" & "0110" & "00",  -- MC1 <- A AND (B>>1)
        29 => "0000" & "1100" & "00",  -- BufferA <- MC2[3:0]
        30 => "0110" & "1010" & "00",  -- BufferB <- MC1[3:0] ; préparer OR
        31 => "0000" & "0110" & "00",  -- MC1 <- terme1 OR terme2
        32 => "0000" & "0000" & "01",  -- Affichage MC1, maintien sûr en DONE
        35 => "0000" & "0000" & "01",
        -- Reste de la ROM : NOP
        others => NOP_INSTR
    );

    -- =========================================================================
    -- Signaux FSM et compteur PC
    -- =========================================================================
    signal state    : fsm_state := IDLE;
    signal pc       : unsigned(6 downto 0) := (others => '0');  -- Program Counter 7 bits
    signal prog_base: unsigned(6 downto 0) := (others => '0');  -- Adresse de base du programme
    signal prog_end : unsigned(6 downto 0) := (others => '0');  -- Adresse de fin (DONE instr)
    signal instr    : STD_LOGIC_VECTOR(9 downto 0);
    signal start_d  : STD_LOGIC := '0';  -- Mémorisation front START

begin

    -- =========================================================================
    -- Décodage de l'instruction courante
    -- =========================================================================
    instr    <= ROM(to_integer(pc));
    SELFCT   <= instr(9 downto 6);
    SELROUTE <= instr(5 downto 2);
    SELOUT   <= instr(1 downto 0);

    -- =========================================================================
    -- Calcul adresse de base et fin selon SEL_PROG
    -- =========================================================================
    process(SEL_PROG)
    begin
        case SEL_PROG is
            when "00"   => prog_base <= to_unsigned(0,  7); prog_end <= to_unsigned(3,  7);
            when "01"   => prog_base <= to_unsigned(8,  7); prog_end <= to_unsigned(14, 7);
            when "10"   => prog_base <= to_unsigned(20, 7); prog_end <= to_unsigned(32, 7);
            when others => prog_base <= to_unsigned(0,  7); prog_end <= to_unsigned(3,  7);
        end case;
    end process;

    -- =========================================================================
    -- FSM séquenceur principal
    -- =========================================================================
    process(CLK, RESET)
    begin
        if RESET = '1' then
            state   <= IDLE;
            pc      <= (others => '0');
            DONE    <= '0';
            start_d <= '0';

        elsif rising_edge(CLK) then
            start_d <= START;

            case state is

                -- Attente d'un start
                when IDLE =>
                    DONE <= '0';
                    if START = '1' and start_d = '0' then  -- front montant
                        pc    <= prog_base;
                        state <= RUN;
                    end if;

                -- Exécution : incrémente PC jusqu'à atteindre prog_end
                when RUN =>
                    DONE <= '0';
                    if pc = prog_end then
                        state <= DONE_ST;
                    else
                        pc <= pc + 1;
                    end if;

                -- Résultat disponible
                when DONE_ST =>
                    DONE <= '1';
                    -- Reste dans DONE jusqu'au prochain start
                    if START = '1' and start_d = '0' then
                        pc    <= prog_base;
                        DONE  <= '0';
                        state <= RUN;
                    end if;

                when others =>
                    state <= IDLE;

            end case;
        end if;
    end process;

end Behavioral;
