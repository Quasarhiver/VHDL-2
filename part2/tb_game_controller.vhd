-- =============================================================================
-- Module      : tb_game_controller.vhd
-- Description : Testbench du contrôleur de jeu LogiGame.
--               Simule : démarrage, réponse correcte, réponse incorrecte,
--               timeout et vérification du score final.
--               NOTE : Les délais du timer sont attendus (niveau 11 = 50M cycles).
--               Pour une simulation rapide, utiliser un fichier de stimuli
--               GTKWave et examiner les transitions d'états.
-- Auteur      : Projet LogiGame – TE608 EFREI 2025-2026
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

    constant CLK_P : time := 10 ns;
    -- Période 1 kHz simulée (diviseur 100 000)
    constant TICK_1KHZ : time := 1_000_000 ns;

    signal CLK_tb   : STD_LOGIC := '0';
    signal RESET_tb : STD_LOGIC := '1';
    signal START_tb : STD_LOGIC := '0';
    signal BTNR_tb  : STD_LOGIC := '0';
    signal BTNG_tb  : STD_LOGIC := '0';
    signal BTNB_tb  : STD_LOGIC := '0';
    signal SW_tb    : STD_LOGIC_VECTOR(1 downto 0) := "11"; -- Difficile = 0.5s

    signal LED3_R_tb, LED3_G_tb, LED3_B_tb : STD_LOGIC;
    signal LED0_R_tb, LED0_G_tb, LED0_B_tb : STD_LOGIC;
    signal SCORE_tb : STD_LOGIC_VECTOR(3 downto 0);

begin
    CLK_tb <= not CLK_tb after CLK_P/2;

    DUT : game_controller
        port map (
            CLK => CLK_tb, RESET => RESET_tb, START => START_tb,
            BTN_R => BTNR_tb, BTN_G => BTNG_tb, BTN_B => BTNB_tb,
            SW_LEVEL => SW_tb,
            LED3_R => LED3_R_tb, LED3_G => LED3_G_tb, LED3_B => LED3_B_tb,
            LED0_R => LED0_R_tb, LED0_G => LED0_G_tb, LED0_B => LED0_B_tb,
            SCORE_OUT => SCORE_tb
        );

    -- =========================================================================
    -- Processus : lecture du stimulus et injection de la bonne réponse
    -- =========================================================================
    process
        procedure press_correct_btn is
        begin
            -- Lire la couleur et appuyer sur le bouton correspondant
            if LED3_R_tb = '1' then
                report "Stimulus: ROUGE -> appui BTN_R" severity note;
                BTNR_tb <= '1'; wait for 5*CLK_P; BTNR_tb <= '0';
            elsif LED3_G_tb = '1' then
                report "Stimulus: VERT -> appui BTN_G" severity note;
                BTNG_tb <= '1'; wait for 5*CLK_P; BTNG_tb <= '0';
            else
                report "Stimulus: BLEU -> appui BTN_B" severity note;
                BTNB_tb <= '1'; wait for 5*CLK_P; BTNB_tb <= '0';
            end if;
        end procedure;

        procedure press_wrong_btn is
        begin
            -- Appuyer sur le mauvais bouton
            if LED3_R_tb = '1' then
                report "Stimulus: ROUGE -> MAUVAIS appui BTN_G" severity note;
                BTNG_tb <= '1'; wait for 5*CLK_P; BTNG_tb <= '0';
            else
                report "Stimulus: non-ROUGE -> MAUVAIS appui BTN_R" severity note;
                BTNR_tb <= '1'; wait for 5*CLK_P; BTNR_tb <= '0';
            end if;
        end procedure;

    begin
        report "===== Testbench Game Controller =====" severity note;

        -- Reset initial
        RESET_tb <= '1'; wait for 5*CLK_P; RESET_tb <= '0'; wait for 5*CLK_P;

        -- Démarrage du jeu
        report "--- Démarrage du jeu ---" severity note;
        START_tb <= '1'; wait for CLK_P; START_tb <= '0';

        -- Attendre que le LFSR avance (1 tick 1kHz)
        wait for TICK_1KHZ + 10*CLK_P;
        wait for 2 ns;

        -- Score doit être 0 au départ
        assert to_integer(unsigned(SCORE_tb)) = 0
            report "FAIL: score initial != 0" severity error;
        report "Score initial = " & integer'image(to_integer(unsigned(SCORE_tb))) severity note;
        report "Stimulus LED3: R=" & std_logic'image(LED3_R_tb) &
               " G=" & std_logic'image(LED3_G_tb) &
               " B=" & std_logic'image(LED3_B_tb) severity note;

        -- Round 1 : Bonne réponse
        press_correct_btn;
        wait for 2*TICK_1KHZ + 20*CLK_P;
        wait for 2 ns;
        report "Score après round 1 = " & integer'image(to_integer(unsigned(SCORE_tb))) &
               " (attendu 1)" severity note;
        assert to_integer(unsigned(SCORE_tb)) = 1
            report "FAIL: score attendu 1" severity error;

        -- Round 2 : Bonne réponse
        press_correct_btn;
        wait for 2*TICK_1KHZ + 20*CLK_P;
        wait for 2 ns;
        report "Score après round 2 = " & integer'image(to_integer(unsigned(SCORE_tb))) &
               " (attendu 2)" severity note;

        -- Round 3 : Mauvaise réponse -> GAME_OVER
        report "--- Mauvaise réponse (fin de partie attendue) ---" severity note;
        press_wrong_btn;
        wait for 3*CLK_P;
        wait for 2 ns;

        -- Vérification affichage LED0 (score 2 -> rouge)
        report "LED0 résultat: R=" & std_logic'image(LED0_R_tb) &
               " G=" & std_logic'image(LED0_G_tb) &
               " B=" & std_logic'image(LED0_B_tb) & " (score=2, attendu rouge)" severity note;

        -- Redémarrage
        report "--- Redémarrage ---" severity note;
        wait for 5*CLK_P;
        START_tb <= '1'; wait for CLK_P; START_tb <= '0';
        wait for TICK_1KHZ;

        report "Score après restart = " & integer'image(to_integer(unsigned(SCORE_tb))) &
               " (attendu 0)" severity note;

        report "===== Game Controller terminé =====" severity note;
        wait;
    end process;

end Behavioral;
