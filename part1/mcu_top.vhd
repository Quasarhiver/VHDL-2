-- =============================================================================
-- Module      : mcu_top.vhd  (Arty_Digilent_TopLevel – Partie 1)
-- Description : Top-level de la Partie 1 : cœur microcontrôleur sur Arty A7-35T.
--               Instancie le datapath + le contrôleur MCU.
--               Mapping des ports de la carte ARTY :
--                 CLK100MHZ       → horloge 100 MHz
--                 btn[0]          → RESET global (actif haut)
--                 sw[3:0]         → A_IN = B_IN (les 4 switches = opérande)
--                 btn[1]          → START programme 0 (A×B)
--                 btn[2]          → START programme 1 ((A+B) xnor A)
--                 btn[3]          → START programme 2 (A0B1 or A1B0)
--                 led[3:0]        → RESOUT[3:0]  (rouge, 4 LSBs)
--                 led1_r..led0_r  → RESOUT[7:4]  (rouge, 4 MSBs via led0_r)
--                 led0_g          → DONE   (vert LSB)
--                 led0_b          → SROUTL (bleu)
--                 led1_b          → SROUTR (bleu)
--               Note : led[3:0] = bits [3:0] de RESOUT en rouge
--                      led0_r    = RESOUT[4]
--                      led1_r    = RESOUT[5]
--                      led2_r    = RESOUT[6]
--                      led3_r    = RESOUT[7]
-- Auteur      : Projet LogiGame – TE608 EFREI 2025-2026
-- Cible       : Xilinx Artix-35T – Vivado
-- Révision    : 1.0 – Avril 2026
-- =============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Arty_Digilent_TopLevel is
    Port (
        CLK100MHZ : in  STD_LOGIC;
        sw        : in  STD_LOGIC_VECTOR(3 downto 0);
        btn       : in  STD_LOGIC_VECTOR(3 downto 0);
        led       : out STD_LOGIC_VECTOR(3 downto 0);
        led0_r    : out STD_LOGIC; led0_g : out STD_LOGIC; led0_b : out STD_LOGIC;
        led1_r    : out STD_LOGIC; led1_g : out STD_LOGIC; led1_b : out STD_LOGIC;
        led2_r    : out STD_LOGIC; led2_g : out STD_LOGIC; led2_b : out STD_LOGIC;
        led3_r    : out STD_LOGIC; led3_g : out STD_LOGIC; led3_b : out STD_LOGIC
    );
end Arty_Digilent_TopLevel;

architecture Behavioral of Arty_Digilent_TopLevel is

    -- =========================================================================
    -- Composant Datapath
    -- =========================================================================
    component datapath is
        Port (
            CLK      : in  STD_LOGIC;
            RESET    : in  STD_LOGIC;
            A_IN     : in  STD_LOGIC_VECTOR(3 downto 0);
            B_IN     : in  STD_LOGIC_VECTOR(3 downto 0);
            SRINL    : in  STD_LOGIC;
            SRINR    : in  STD_LOGIC;
            SELFCT   : in  STD_LOGIC_VECTOR(3 downto 0);
            SELROUTE : in  STD_LOGIC_VECTOR(3 downto 0);
            SELOUT   : in  STD_LOGIC_VECTOR(1 downto 0);
            RESOUT   : out STD_LOGIC_VECTOR(7 downto 0);
            SROUTL   : out STD_LOGIC;
            SROUTR   : out STD_LOGIC
        );
    end component;

    -- =========================================================================
    -- Composant MCU Controller
    -- =========================================================================
    component mcu_controller is
        Port (
            CLK      : in  STD_LOGIC;
            RESET    : in  STD_LOGIC;
            START    : in  STD_LOGIC;
            SEL_PROG : in  STD_LOGIC_VECTOR(1 downto 0);
            SELFCT   : out STD_LOGIC_VECTOR(3 downto 0);
            SELROUTE : out STD_LOGIC_VECTOR(3 downto 0);
            SELOUT   : out STD_LOGIC_VECTOR(1 downto 0);
            DONE     : out STD_LOGIC
        );
    end component;

    -- =========================================================================
    -- Signaux internes
    -- =========================================================================
    signal clk_i     : STD_LOGIC;
    signal reset_i   : STD_LOGIC;
    signal start_i   : STD_LOGIC;
    signal sel_prog_i: STD_LOGIC_VECTOR(1 downto 0);

    signal selfct_i  : STD_LOGIC_VECTOR(3 downto 0);
    signal selroute_i: STD_LOGIC_VECTOR(3 downto 0);
    signal selout_i  : STD_LOGIC_VECTOR(1 downto 0);

    signal resout_i  : STD_LOGIC_VECTOR(7 downto 0);
    signal sroutl_i  : STD_LOGIC;
    signal sroutr_i  : STD_LOGIC;
    signal done_i    : STD_LOGIC;

begin

    -- =========================================================================
    -- Mapping des entrées physiques
    -- =========================================================================
    clk_i      <= CLK100MHZ;
    reset_i    <= btn(0);             -- btn0 = RESET
    -- Encodage START / SEL_PROG à partir des boutons :
    -- btn1 → programme 0, btn2 → programme 1, btn3 → programme 2
    start_i    <= btn(1) or btn(2) or btn(3);
    sel_prog_i <= "00" when btn(1) = '1' else
                  "01" when btn(2) = '1' else
                  "10" when btn(3) = '1' else
                  "00";

    -- =========================================================================
    -- Instanciation du MCU Controller
    -- =========================================================================
    U_CTRL : mcu_controller
        port map (
            CLK      => clk_i,
            RESET    => reset_i,
            START    => start_i,
            SEL_PROG => sel_prog_i,
            SELFCT   => selfct_i,
            SELROUTE => selroute_i,
            SELOUT   => selout_i,
            DONE     => done_i
        );

    -- =========================================================================
    -- Instanciation du Datapath
    -- SRINL et SRINR forcés à 0 pour les tests carte
    -- =========================================================================
    U_DP : datapath
        port map (
            CLK      => clk_i,
            RESET    => reset_i,
            A_IN     => sw(3 downto 0),
            B_IN     => sw(3 downto 0),   -- A = B sur la carte (mêmes switches)
            SRINL    => '0',
            SRINR    => '0',
            SELFCT   => selfct_i,
            SELROUTE => selroute_i,
            SELOUT   => selout_i,
            RESOUT   => resout_i,
            SROUTL   => sroutl_i,
            SROUTR   => sroutr_i
        )
-- =========================================================================
    -- Mapping des sorties LEDs
    -- RESOUT[7:0] → rouge (8 leds)
    -- led[3:0]  = RESOUT[3:0]
    -- led0_r    = RESOUT[4]  (5ème LED rouge)
    -- led1_r    = RESOUT[5]
    -- led2_r    = RESOUT[6]
    -- led3_r    = RESOUT[7]  (8ème LED rouge)
    -- led3_g    = DONE  (vert 8ème LED = calcul terminé)
    -- led0_b    = SROUTL (5ème LED bleue)
    -- led1_b    = SROUTR (6ème LED bleue)
    -- =========================================================================
    led    <= resout_i(3 downto 0);
    led0_r <= resout_i(4);
    led1_r <= resout_i(5);
    led2_r <= resout_i(6);
    led3_r <= resout_i(7);

    led3_g <= done_i;     -- Vert : résultat disponible (8ème LED, même LED que RESOUT[7])
    led0_b <= sroutl_i;   -- Bleu : bit sortant gauche (5ème LED)
    led1_b <= sroutr_i;   -- Bleu : bit sortant droit  (6ème LED)

    -- LEDs non utilisées : éteintes
    led0_g <= '0';
    led1_g <= '0';
    led2_g <= '0';
    led2_b <= '0';
    led3_b <= '0';
    
end Behavioral;