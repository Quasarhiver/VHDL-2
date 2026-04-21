-- =============================================================================
-- Module      : tb_logigame_mcu_top.vhd
-- Description : Banc de test d'integration globale pour la Partie 3.
--               Verifie un scenario joueur complet :
--               - demarrage via btn0 (reset puis start au relachement)
--               - premiere manche reussie
--               - deuxieme manche ratee
--               - affichage du score final
--               - redemarrage
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
    constant WAIT_ROUND       : time := 1200 us;

    signal CLK100MHZ : STD_LOGIC := '0';
    signal sw        : STD_LOGIC_VECTOR(3 downto 0) := (others => '0');
    signal btn       : STD_LOGIC_VECTOR(3 downto 0) := (others => '0');

    signal led       : STD_LOGIC_VECTOR(3 downto 0);
    signal led0_r    : STD_LOGIC;
    signal led0_g    : STD_LOGIC;
    signal led0_b    : STD_LOGIC;
    signal led1_r    : STD_LOGIC;
    signal led1_g    : STD_LOGIC;
    signal led1_b    : STD_LOGIC;
    signal led2_r    : STD_LOGIC;
    signal led2_g    : STD_LOGIC;
    signal led2_b    : STD_LOGIC;
    signal led3_r    : STD_LOGIC;
    signal led3_g    : STD_LOGIC;
    signal led3_b    : STD_LOGIC;

begin

    UUT : Arty_Digilent_TopLevel
        port map (
        CLK100MHZ => CLK100MHZ,
        sw        => sw,
        btn       => btn,
        led       => led,
        led0_r => led0_r, led0_g => led0_g, led0_b => led0_b,
        led1_r => led1_r, led1_g => led1_g, led1_b => led1_b,
        led2_r => led2_r, led2_g => led2_g, led2_b => led2_b,
        led3_r => led3_r, led3_g => led3_g, led3_b => led3_b
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
                pulse_btn(3);
            elsif led3_g = '1' then
                pulse_btn(2);
            else
                pulse_btn(1);
            end if;
        end procedure;

        procedure press_wrong_btn is
        begin
            if led3_r = '1' then
                pulse_btn(2);
            elsif led3_g = '1' then
                pulse_btn(1);
            else
                pulse_btn(3);
            end if;
        end procedure;
    begin
        report "===== Testbench LogiGame MCU Top =====" severity note;

        -- Difficulte maximale pour accelerer les essais manuels, meme si le
        -- timeout n'est pas utilise dans ce scenario.
        sw  <= "1100";
        btn <= "0000";
        wait for 10 * CLK100MHZ_PERIOD;

        -- =====================================================================
        -- Demarrage : btn0 appuye puis relache
        -- =====================================================================
        report "--- Demarrage de la partie ---" severity note;
        pulse_btn(0);
        wait for WAIT_ROUND;

        assert led = "0000"
            report "FAIL: le score initial devrait etre nul" severity error;
        assert led0_r = '0' and led0_g = '0' and led0_b = '0'
            report "FAIL: LED0 devrait etre eteinte pendant le jeu" severity error;
        assert led3_r = '0' and led3_g = '1' and led3_b = '0'
            report "FAIL: premiere couleur attendue = vert (etat LFSR 0101)" severity error;

        -- =====================================================================
        -- Manche 1 : bonne reponse
        -- =====================================================================
        report "--- Manche 1 : bonne reponse ---" severity note;
        press_correct_btn;
        wait for WAIT_ROUND;

        assert led = "0001"
            report "FAIL: le score devrait valoir 1 apres la premiere bonne reponse" severity error;
        assert led0_r = '0' and led0_g = '0' and led0_b = '0'
            report "FAIL: LED0 devrait rester eteinte avant le game over" severity error;
        assert led3_r = '0' and led3_g = '0' and led3_b = '1'
            report "FAIL: deuxieme couleur attendue = bleu (etat LFSR 1010)" severity error;

        -- =====================================================================
        -- Manche 2 : mauvaise reponse -> END_GAME
        -- =====================================================================
        report "--- Manche 2 : mauvaise reponse ---" severity note;
        press_wrong_btn;
        wait for 10 * CLK100MHZ_PERIOD;

        assert led = "0001"
            report "FAIL: le score final devrait rester a 1 apres une erreur" severity error;
        assert led0_r = '1' and led0_g = '0' and led0_b = '0'
            report "FAIL: LED0 devrait etre rouge pour un score final de 1" severity error;

        -- =====================================================================
        -- Redemarrage
        -- =====================================================================
        report "--- Redemarrage ---" severity note;
        pulse_btn(0);
        wait for 10 * CLK100MHZ_PERIOD;

        assert led = "0000"
            report "FAIL: le score devrait etre remis a 0 apres restart" severity error;
        assert led0_r = '0' and led0_g = '0' and led0_b = '0'
            report "FAIL: LED0 devrait s'eteindre apres restart" severity error;

        wait for WAIT_ROUND;
        assert led = "0000"
            report "FAIL: le score doit rester a 0 au debut de la nouvelle partie" severity error;
        assert (led3_r = '1') or (led3_g = '1') or (led3_b = '1')
            report "FAIL: aucune couleur de stimulus detectee apres restart" severity error;

        report "===== LogiGame MCU Top termine =====" severity note;
        wait;
    end process;

end Behavioral;
