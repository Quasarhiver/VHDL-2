-- =============================================================================
-- Module      : tb_game_controller.vhd
-- Description : Testbench du controleur de jeu de la partie 2.
--               Le scenario couvre :
--               - le demarrage d'une partie
--               - trois couleurs successives issues du vrai modulo 3
--               - deux bonnes reponses consecutives
--               - une mauvaise reponse qui termine la partie
--               - l'affichage du score final sur LED0
--               - un redemarrage propre
-- Auteur      : Projet LogiGame - TE608 EFREI 2025-2026
-- =============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_game_controller is
end tb_game_controller;

architecture Behavioral of tb_game_controller is

    component game_controller is
        Port (
            CLK        : in  STD_LOGIC;
            RESET      : in  STD_LOGIC;
            START      : in  STD_LOGIC;
            BTN_R      : in  STD_LOGIC;
            BTN_G      : in  STD_LOGIC;
            BTN_B      : in  STD_LOGIC;
            SW_LEVEL   : in  STD_LOGIC_VECTOR(1 downto 0);
            LED3_R     : out STD_LOGIC;
            LED3_G     : out STD_LOGIC;
            LED3_B     : out STD_LOGIC;
            LED0_R     : out STD_LOGIC;
            LED0_G     : out STD_LOGIC;
            LED0_B     : out STD_LOGIC;
            SCORE_OUT  : out STD_LOGIC_VECTOR(3 downto 0)
        );
    end component;

    constant CLK_P             : time := 10 ns;
    constant TICK_1KHZ         : time := 1_000_000 ns;
    constant WAIT_COLOR_STABLE : time := TICK_1KHZ + 20 * CLK_P;
    constant WAIT_NEXT_ROUND   : time := 2 * TICK_1KHZ + 20 * CLK_P;

    signal CLK_tb   : STD_LOGIC := '0';
    signal RESET_tb : STD_LOGIC := '1';
    signal START_tb : STD_LOGIC := '0';
    signal BTNR_tb  : STD_LOGIC := '0';
    signal BTNG_tb  : STD_LOGIC := '0';
    signal BTNB_tb  : STD_LOGIC := '0';
    signal SW_tb    : STD_LOGIC_VECTOR(1 downto 0) := "11";

    signal LED3_R_tb, LED3_G_tb, LED3_B_tb : STD_LOGIC;
    signal LED0_R_tb, LED0_G_tb, LED0_B_tb : STD_LOGIC;
    signal SCORE_tb : STD_LOGIC_VECTOR(3 downto 0);

begin
    CLK_tb <= not CLK_tb after CLK_P / 2;

    DUT : game_controller
        port map (
            CLK       => CLK_tb,
            RESET     => RESET_tb,
            START     => START_tb,
            BTN_R     => BTNR_tb,
            BTN_G     => BTNG_tb,
            BTN_B     => BTNB_tb,
            SW_LEVEL  => SW_tb,
            LED3_R    => LED3_R_tb,
            LED3_G    => LED3_G_tb,
            LED3_B    => LED3_B_tb,
            LED0_R    => LED0_R_tb,
            LED0_G    => LED0_G_tb,
            LED0_B    => LED0_B_tb,
            SCORE_OUT => SCORE_tb
        );

    process
        procedure assert_led3(
            constant exp_r : in STD_LOGIC;
            constant exp_g : in STD_LOGIC;
            constant exp_b : in STD_LOGIC;
            constant msg   : in string
        ) is
        begin
            assert LED3_R_tb = exp_r and LED3_G_tb = exp_g and LED3_B_tb = exp_b
                report msg &
                       " (R=" & std_logic'image(LED3_R_tb) &
                       " G=" & std_logic'image(LED3_G_tb) &
                       " B=" & std_logic'image(LED3_B_tb) & ")"
                severity error;
        end procedure;

        procedure assert_led0(
            constant exp_r : in STD_LOGIC;
            constant exp_g : in STD_LOGIC;
            constant exp_b : in STD_LOGIC;
            constant msg   : in string
        ) is
        begin
            assert LED0_R_tb = exp_r and LED0_G_tb = exp_g and LED0_B_tb = exp_b
                report msg &
                       " (R=" & std_logic'image(LED0_R_tb) &
                       " G=" & std_logic'image(LED0_G_tb) &
                       " B=" & std_logic'image(LED0_B_tb) & ")"
                severity error;
        end procedure;

        procedure press_correct_btn is
        begin
            if LED3_R_tb = '1' then
                report "Stimulus: ROUGE -> appui BTN_R" severity note;
                BTNR_tb <= '1';
                wait for 5 * CLK_P;
                BTNR_tb <= '0';
            elsif LED3_G_tb = '1' then
                report "Stimulus: VERT -> appui BTN_G" severity note;
                BTNG_tb <= '1';
                wait for 5 * CLK_P;
                BTNG_tb <= '0';
            else
                report "Stimulus: BLEU -> appui BTN_B" severity note;
                BTNB_tb <= '1';
                wait for 5 * CLK_P;
                BTNB_tb <= '0';
            end if;
        end procedure;

        procedure press_wrong_btn is
        begin
            if LED3_R_tb = '1' then
                report "Stimulus: ROUGE -> MAUVAIS appui BTN_G" severity note;
                BTNG_tb <= '1';
                wait for 5 * CLK_P;
                BTNG_tb <= '0';
            else
                report "Stimulus: non-ROUGE -> MAUVAIS appui BTN_R" severity note;
                BTNR_tb <= '1';
                wait for 5 * CLK_P;
                BTNR_tb <= '0';
            end if;
        end procedure;

    begin
        report "===== Testbench Game Controller =====" severity note;

        RESET_tb <= '1';
        wait for 5 * CLK_P;
        RESET_tb <= '0';
        wait for 5 * CLK_P;

        report "--- Demarrage du jeu ---" severity note;
        START_tb <= '1';
        wait for CLK_P;
        START_tb <= '0';

        -- Le LFSR avance au prochain tick 1 kHz puis la FSM attend que la
        -- couleur soit stable avant d'ouvrir la fenetre de reponse.
        wait for WAIT_COLOR_STABLE;
        wait for 2 ns;

        assert to_integer(unsigned(SCORE_tb)) = 0
            report "FAIL: le score initial devrait valoir 0" severity error;
        assert_led0('0', '0', '0', "FAIL: LED0 devrait etre eteinte pendant la partie");
        -- Seed 1011 -> premier etat 0111 -> 7 mod 3 = 1 -> vert.
        assert_led3('0', '1', '0', "FAIL: la premiere couleur attendue est verte");

        report "--- Manche 1 : bonne reponse ---" severity note;
        press_correct_btn;
        wait for WAIT_NEXT_ROUND;
        wait for 2 ns;

        assert to_integer(unsigned(SCORE_tb)) = 1
            report "FAIL: le score devrait valoir 1 apres la premiere bonne reponse"
            severity error;
        -- Deuxieme etat 1111 -> 15 mod 3 = 0 -> rouge.
        assert_led3('1', '0', '0', "FAIL: la deuxieme couleur attendue est rouge");
        assert_led0('0', '0', '0', "FAIL: LED0 doit rester eteinte apres un hit");

        report "--- Manche 2 : bonne reponse ---" severity note;
        press_correct_btn;
        wait for WAIT_NEXT_ROUND;
        wait for 2 ns;

        assert to_integer(unsigned(SCORE_tb)) = 2
            report "FAIL: le score devrait valoir 2 apres la deuxieme bonne reponse"
            severity error;
        -- Troisieme etat 1110 -> 14 mod 3 = 2 -> bleu.
        assert_led3('0', '0', '1', "FAIL: la troisieme couleur attendue est bleue");
        assert_led0('0', '0', '0', "FAIL: LED0 doit rester eteinte avant la fin");

        report "--- Manche 3 : mauvaise reponse ---" severity note;
        press_wrong_btn;
        wait for 3 * CLK_P;
        wait for 2 ns;

        assert to_integer(unsigned(SCORE_tb)) = 2
            report "FAIL: le score final devrait rester a 2 apres une erreur"
            severity error;
        assert_led0('1', '0', '0', "FAIL: LED0 devrait etre rouge pour un score final de 2");

        -- Dans la partie 2, le redemarrage remet le score a zero mais ne
        -- re-seed pas le LFSR. La sequence reprend donc depuis l'etat courant.
        report "--- Redemarrage ---" severity note;
        wait for 5 * CLK_P;
        START_tb <= '1';
        wait for CLK_P;
        START_tb <= '0';
        wait for WAIT_COLOR_STABLE;
        wait for 2 ns;

        assert to_integer(unsigned(SCORE_tb)) = 0
            report "FAIL: le score devrait revenir a 0 apres restart" severity error;
        assert_led0('0', '0', '0', "FAIL: LED0 devrait etre eteinte apres restart");
        -- La manche precedente a laisse l'etat 1110. Le round suivant produit
        -- donc 1100, soit 12 mod 3 = 0 -> rouge.
        assert_led3('1', '0', '0', "FAIL: la couleur attendue apres restart est rouge");

        report "===== Game Controller termine =====" severity note;
        wait;
    end process;

end Behavioral;
