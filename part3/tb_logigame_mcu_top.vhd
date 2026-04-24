-- =============================================================================
-- Module      : tb_logigame_mcu_top.vhd
-- Description : Banc de test d'integration globale pour la partie 3.
--               Le scenario couvre :
--               - le demarrage via btn0 (reset pendant l'appui, START au relachement)
--               - deux manches reussies
--               - une troisieme manche ratee
--               - l'affichage du score final
--               - un redemarrage propre
--
--               Couleurs attendues avec le vrai modulo 3 :
--               - manche 1 : etat "0111" -> 7 mod 3 = 1 -> vert
--               - manche 2 : etat "1111" -> 15 mod 3 = 0 -> rouge
--               - manche 3 : etat "1110" -> 14 mod 3 = 2 -> bleu
-- =============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_logigame_mcu_top is
end tb_logigame_mcu_top;

architecture Behavioral of tb_logigame_mcu_top is

    component Arty_Digilent_TopLevel
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
    end component;

    constant CLK100MHZ_PERIOD : time := 10 ns;
    constant WAIT_ROUND       : time := 25 ms;

    signal CLK100MHZ : STD_LOGIC := '0';
    signal sw        : STD_LOGIC_VECTOR(3 downto 0) := (others => '0');
    signal btn       : STD_LOGIC_VECTOR(3 downto 0) := (others => '0');

    signal led       : STD_LOGIC_VECTOR(3 downto 0);
    signal led0_r, led0_g, led0_b : STD_LOGIC;
    signal led1_r, led1_g, led1_b : STD_LOGIC;
    signal led2_r, led2_g, led2_b : STD_LOGIC;
    signal led3_r, led3_g, led3_b : STD_LOGIC;

begin

    UUT : Arty_Digilent_TopLevel
        port map (
            CLK100MHZ => CLK100MHZ,
            sw        => sw,
            btn       => btn,
            led       => led,
            led0_r    => led0_r, led0_g => led0_g, led0_b => led0_b,
            led1_r    => led1_r, led1_g => led1_g, led1_b => led1_b,
            led2_r    => led2_r, led2_g => led2_g, led2_b => led2_b,
            led3_r    => led3_r, led3_g => led3_g, led3_b => led3_b
        );

    CLK100MHZ <= not CLK100MHZ after CLK100MHZ_PERIOD / 2;

    process
        procedure pulse_btn(constant idx : in integer) is
        begin
            btn(idx) <= '1';
            wait for 3 * CLK100MHZ_PERIOD;
            btn(idx) <= '0';
            wait for 3 * CLK100MHZ_PERIOD;
        end procedure;

        procedure press_correct_btn is
        begin
            if led3_r = '1' then
                report "Stimulus: ROUGE -> appui BTN_R (btn3)" severity note;
                pulse_btn(3);
            elsif led3_g = '1' then
                report "Stimulus: VERT -> appui BTN_G (btn2)" severity note;
                pulse_btn(2);
            else
                report "Stimulus: BLEU -> appui BTN_B (btn1)" severity note;
                pulse_btn(1);
            end if;
        end procedure;

        procedure press_wrong_btn is
        begin
            if led3_r = '1' then
                report "Stimulus: ROUGE -> MAUVAIS appui BTN_G (btn2)" severity note;
                pulse_btn(2);
            elsif led3_g = '1' then
                report "Stimulus: VERT -> MAUVAIS appui BTN_B (btn1)" severity note;
                pulse_btn(1);
            else
                report "Stimulus: BLEU -> MAUVAIS appui BTN_R (btn3)" severity note;
                pulse_btn(3);
            end if;
        end procedure;

    begin
        report "===== Testbench LogiGame MCU Top =====" severity note;

        sw  <= "1100";
        btn <= "0000";
        wait for 10 * CLK100MHZ_PERIOD;

        report "--- Demarrage de la partie ---" severity note;
        pulse_btn(0);
        wait for WAIT_ROUND;

        assert led = "0000"
            report "FAIL: le score initial devrait etre nul" severity error;
        assert led0_r = '0' and led0_g = '0' and led0_b = '0'
            report "FAIL: LED0 devrait etre eteinte pendant le jeu" severity error;

        -- Seed 1011 -> premiere valeur 0111 -> 7 mod 3 = 1 -> vert.
        assert led3_r = '0' and led3_g = '1' and led3_b = '0'
            report "FAIL: premiere couleur attendue = verte (etat LFSR 0111, 7 mod 3 = 1)"
            severity error;

        report "--- Manche 1 : bonne reponse ---" severity note;
        press_correct_btn;
        wait for WAIT_ROUND;

        assert led = "0001"
            report "FAIL: le score devrait valoir 1 apres la premiere bonne reponse"
            severity error;
        assert led0_r = '0' and led0_g = '0' and led0_b = '0'
            report "FAIL: LED0 devrait rester eteinte avant le game over" severity error;
        -- Deuxieme etat 1111 -> 15 mod 3 = 0 -> rouge.
        assert led3_r = '1' and led3_g = '0' and led3_b = '0'
            report "FAIL: deuxieme couleur attendue = rouge (etat LFSR 1111, 15 mod 3 = 0)"
            severity error;

        report "--- Manche 2 : bonne reponse ---" severity note;
        press_correct_btn;
        wait for WAIT_ROUND;

        assert led = "0010"
            report "FAIL: le score devrait valoir 2 apres la deuxieme bonne reponse"
            severity error;
        assert led0_r = '0' and led0_g = '0' and led0_b = '0'
            report "FAIL: LED0 devrait rester eteinte tant que la partie continue"
            severity error;
        -- Troisieme etat 1110 -> 14 mod 3 = 2 -> bleu.
        assert led3_r = '0' and led3_g = '0' and led3_b = '1'
            report "FAIL: troisieme couleur attendue = bleue (etat LFSR 1110, 14 mod 3 = 2)"
            severity error;

        report "--- Manche 3 : mauvaise reponse (fin de partie attendue) ---" severity note;
        press_wrong_btn;
        wait for WAIT_ROUND;

        assert led = "0010"
            report "FAIL: le score final devrait rester a 2 apres une erreur"
            severity error;
        assert led0_r = '1' and led0_g = '0' and led0_b = '0'
            report "FAIL: LED0 devrait etre rouge pour un score final de 2"
            severity error;

        report "--- Redemarrage ---" severity note;
        wait for 5 * CLK100MHZ_PERIOD;
        pulse_btn(0);
        wait for 10 * CLK100MHZ_PERIOD;

        assert led = "0000"
            report "FAIL: le score devrait etre remis a 0 apres restart" severity error;
        assert led0_r = '0' and led0_g = '0' and led0_b = '0'
            report "FAIL: LED0 devrait s'eteindre apres restart" severity error;

        wait for WAIT_ROUND;
        assert led = "0000"
            report "FAIL: le score doit rester a 0 au debut de la nouvelle partie"
            severity error;
        assert led3_r = '0' and led3_g = '1' and led3_b = '0'
            report "FAIL: premiere couleur apres restart attendue = verte"
            severity error;

        report "===== LogiGame MCU Top termine =====" severity note;
        wait;
    end process;

end Behavioral;
