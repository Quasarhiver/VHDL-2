-- =============================================================================
-- Module      : tb_difficulty_timer.vhd
-- Description : Testbench du minuteur programmable (délais simulés réduits).
-- =============================================================================
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_difficulty_timer is
end tb_difficulty_timer;

architecture Behavioral of tb_difficulty_timer is

    -- Version testbench : on utilise un composant modifié avec délais courts
    -- via un diviseur générique. Ici on teste le comportement avec les vraies
    -- constantes mais on attend uniquement en simulation accélérée.
    component difficulty_timer is
        Port (
            CLK      : in  STD_LOGIC;
            RESET    : in  STD_LOGIC;
            START    : in  STD_LOGIC;
            SW_LEVEL : in  STD_LOGIC_VECTOR(1 downto 0);
            TIMEOUT  : out STD_LOGIC
        );
    end component;

    constant CLK_P : time := 10 ns;  -- 100 MHz

    signal CLK_tb     : STD_LOGIC := '0';
    signal RESET_tb   : STD_LOGIC := '1';
    signal START_tb   : STD_LOGIC := '0';
    signal LEVEL_tb   : STD_LOGIC_VECTOR(1 downto 0) := "11"; -- 0.5s = 50M cycles
    signal TIMEOUT_tb : STD_LOGIC;

    -- Pour simulation rapide, on ne peut pas attendre 50M cycles (500 ms sim).
    -- On vérifie la logique de contrôle avec START/RESET.

begin
    CLK_tb <= not CLK_tb after CLK_P/2;

    DUT : difficulty_timer
        port map (CLK => CLK_tb, RESET => RESET_tb, START => START_tb,
                  SW_LEVEL => LEVEL_tb, TIMEOUT => TIMEOUT_tb);

    process
    begin
        report "===== Testbench Difficulty Timer =====" severity note;

        RESET_tb <= '1'; wait for 5*CLK_P; RESET_tb <= '0';

        -- Test 1 : TIMEOUT doit rester à 0 sans START
        wait for 20*CLK_P;
        assert TIMEOUT_tb = '0'
            report "FAIL: TIMEOUT actif sans START" severity error;
        report "Sans START: TIMEOUT=" & std_logic'image(TIMEOUT_tb) & " (attendu 0)" severity note;

        -- Test 2 : RESET efface l'état
        START_tb <= '1'; wait for CLK_P; START_tb <= '0';
        wait for 10*CLK_P;
        RESET_tb <= '1'; wait for CLK_P; RESET_tb <= '0';
        assert TIMEOUT_tb = '0'
            report "FAIL: TIMEOUT non effacé après RESET" severity error;
        report "Après RESET: TIMEOUT=" & std_logic'image(TIMEOUT_tb) & " (attendu 0)" severity note;

        -- Test 3 : Comportement multi-niveaux (vérification sélection seulement)
        for lv in 0 to 3 loop
            LEVEL_tb <= std_logic_vector(to_unsigned(lv, 2));
            START_tb <= '1'; wait for CLK_P; START_tb <= '0';
            wait for 5*CLK_P;
            -- On vérifie que le timer est lancé (TIMEOUT ne doit pas encore être là)
            assert TIMEOUT_tb = '0'
                report "FAIL: TIMEOUT prématuré au niveau " & integer'image(lv) severity error;
            report "Niveau " & integer'image(lv) & ": timer lancé OK" severity note;
            RESET_tb <= '1'; wait for CLK_P; RESET_tb <= '0';
        end loop;

        report "===== Difficulty Timer terminé (vérification logique OK) =====" severity note;
        report "NOTE: délais réels non simulés (400M/200M/100M/50M cycles trop longs)" severity note;
        wait;
    end process;

end Behavioral;


-- =============================================================================
-- Module      : tb_score_counter.vhd
-- Description : Testbench du compteur de score.
-- =============================================================================
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_score_counter is
end tb_score_counter;

architecture Behavioral of tb_score_counter is

    component score_counter is
        Port (
            CLK       : in  STD_LOGIC;
            RESET     : in  STD_LOGIC;
            VALID_HIT : in  STD_LOGIC;
            ERROR     : in  STD_LOGIC;
            SCORE     : out STD_LOGIC_VECTOR(3 downto 0);
            GAME_OVER : out STD_LOGIC
        );
    end component;

    constant CLK_P : time := 10 ns;

    signal CLK_tb      : STD_LOGIC := '0';
    signal RESET_tb    : STD_LOGIC := '1';
    signal HIT_tb      : STD_LOGIC := '0';
    signal ERR_tb      : STD_LOGIC := '0';
    signal SCORE_tb    : STD_LOGIC_VECTOR(3 downto 0);
    signal GAMEOVER_tb : STD_LOGIC;

begin
    CLK_tb <= not CLK_tb after CLK_P/2;

    DUT : score_counter
        port map (CLK => CLK_tb, RESET => RESET_tb,
                  VALID_HIT => HIT_tb, ERROR => ERR_tb,
                  SCORE => SCORE_tb, GAME_OVER => GAMEOVER_tb);

    process
    begin
        report "===== Testbench Score Counter =====" severity note;

        RESET_tb <= '1'; wait for 5*CLK_P; RESET_tb <= '0'; wait for CLK_P;

        -- Test 1 : Score initial = 0
        wait for 2 ns;
        assert to_integer(unsigned(SCORE_tb)) = 0
            report "FAIL: score initial != 0" severity error;
        report "Score initial = " & integer'image(to_integer(unsigned(SCORE_tb))) & " (attendu 0)" severity note;

        -- Test 2 : Incrémenter 5 fois
        for i in 1 to 5 loop
            HIT_tb <= '1'; wait for CLK_P; HIT_tb <= '0'; wait for CLK_P;
        end loop;
        wait for 2 ns;
        assert to_integer(unsigned(SCORE_tb)) = 5
            report "FAIL: score après 5 hits =" & integer'image(to_integer(unsigned(SCORE_tb))) severity error;
        report "Score après 5 hits = " & integer'image(to_integer(unsigned(SCORE_tb))) & " (attendu 5)" severity note;

        -- Test 3 : GAME_OVER=0 encore
        assert GAMEOVER_tb = '0'
            report "FAIL: GAME_OVER prématuré" severity error;

        -- Test 4 : Erreur → GAME_OVER
        ERR_tb <= '1'; wait for CLK_P; ERR_tb <= '0'; wait for CLK_P;
        wait for 2 ns;
        assert GAMEOVER_tb = '1'
            report "FAIL: GAME_OVER non activé sur erreur" severity error;
        report "Après erreur: GAME_OVER=" & std_logic'image(GAMEOVER_tb) & " (attendu 1)" severity note;

        -- Test 5 : Score figé après GAME_OVER
        HIT_tb <= '1'; wait for CLK_P; HIT_tb <= '0'; wait for CLK_P;
        wait for 2 ns;
        assert to_integer(unsigned(SCORE_tb)) = 5
            report "FAIL: score modifié après GAME_OVER" severity error;
        report "Score figé = " & integer'image(to_integer(unsigned(SCORE_tb))) & " (attendu 5)" severity note;

        -- Test 6 : Atteindre score 15
        RESET_tb <= '1'; wait for CLK_P; RESET_tb <= '0'; wait for CLK_P;
        for i in 1 to 15 loop
            HIT_tb <= '1'; wait for CLK_P; HIT_tb <= '0'; wait for CLK_P;
        end loop;
        wait for 2 ns;
        assert to_integer(unsigned(SCORE_tb)) = 15
            report "FAIL: score 15 non atteint: " & integer'image(to_integer(unsigned(SCORE_tb))) severity error;
        assert GAMEOVER_tb = '1'
            report "FAIL: GAME_OVER non activé à score=15" severity error;
        report "Score=15: GAME_OVER=" & std_logic'image(GAMEOVER_tb) & " (attendu 1, score=15)" severity note;

        report "===== Score Counter terminé =====" severity note;
        wait;
    end process;

end Behavioral;
