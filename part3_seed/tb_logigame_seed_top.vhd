-- =============================================================================
-- Module      : tb_logigame_seed_top.vhd
-- Description : Banc de test d integration pour la Partie 3 variante SEED
--               (LFSR libre 100 MHz + MCU/datapath pour le calcul de couleur).
--
--               DEBOUNCE_CYCLES est reduit a 5 pour la simulation.
--
--               SETTLE = 2 ms : necessite que le MCU ait le temps d attendre
--               le tick 1 kHz (jusqu a 1 ms) et d executer ses instructions.
--
--               Le testbench lit la couleur affichee sur LD3 apres stabilisation
--               et appuie sur le bon bouton (joueur parfait simule).
--               La couleur exacte depend du moment d appui (LFSR libre) :
--               seul le code one-hot valide et la stabilite sont verifies.
--
--               Scenario :
--                 demarrage -> manche 1 bonne reponse -> manche 2 bonne reponse
--                 -> manche 3 mauvaise reponse -> END_GAME -> redemarrage.
-- =============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_logigame_seed_top is
end tb_logigame_seed_top;

architecture Behavioral of tb_logigame_seed_top is

    component Arty_Digilent_TopLevel
        Generic ( DEBOUNCE_CYCLES : integer := 200000 );
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

    constant CLK_PERIOD : time    := 10 ns;
    constant DEB_SIM    : integer := 5;
    -- SETTLE = 2 ms : couvre le tick 1 kHz du MCU (jusqu a 1 ms) + execution
    constant SETTLE     : time    := 2 ms;

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
        generic map (DEBOUNCE_CYCLES => DEB_SIM)
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

    CLK100MHZ <= not CLK100MHZ after CLK_PERIOD / 2;

    process
        -- Appui sur btn[0] : maintenu le temps du debounce puis relache.
        -- Le relachement genere le pulse start qui capture le LFSR et lance le MCU.
        procedure start_press is
        begin
            btn(0) <= '1';
            wait for (DEB_SIM + 5) * CLK_PERIOD;
            btn(0) <= '0';
            wait for (DEB_SIM + 5) * CLK_PERIOD;
        end procedure;

        procedure pulse_btn(constant idx : in integer) is
        begin
            btn(idx) <= '1';
            wait for 3 * CLK_PERIOD;
            btn(idx) <= '0';
            wait for 3 * CLK_PERIOD;
        end procedure;

        -- Lit la couleur courante de LD3 et appuie sur le bouton correspondant
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

        -- Appuie deliberement sur le mauvais bouton
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

        -- Verifie que LD3 affiche un code one-hot valide et qu il reste stable
        procedure check_color_valid_stable is
            variable r0, g0, b0 : STD_LOGIC;
        begin
            r0 := led3_r; g0 := led3_g; b0 := led3_b;
            assert (r0 = '1' and g0 = '0' and b0 = '0')
                or (r0 = '0' and g0 = '1' and b0 = '0')
                or (r0 = '0' and g0 = '0' and b0 = '1')
                report "FAIL: code couleur LD3 invalide (pas one-hot)" severity error;
            wait for 30 * CLK_PERIOD;
            assert (led3_r = r0 and led3_g = g0 and led3_b = b0)
                report "FAIL: la couleur LD3 a change pendant la manche" severity error;
        end procedure;

    begin
        report "===== Testbench LogiGame SEED (LFSR libre + MCU) =====" severity note;

        sw  <= "0000";
        btn <= "0000";
        wait for 10 * CLK_PERIOD;

        -- =====================================================================
        -- Demarrage
        -- =====================================================================
        report "--- Demarrage de la partie ---" severity note;
        start_press;
        wait for SETTLE;

        assert led = "0000"
            report "FAIL: score initial devrait etre nul" severity error;
        check_color_valid_stable;

        -- =====================================================================
        -- Manche 1 : bonne reponse
        -- =====================================================================
        report "--- Manche 1 : bonne reponse ---" severity note;
        press_correct_btn;
        wait for SETTLE;

        assert led = "0001"
            report "FAIL: score devrait valoir 1 apres manche 1" severity error;
        check_color_valid_stable;

        -- =====================================================================
        -- Manche 2 : bonne reponse
        -- =====================================================================
        report "--- Manche 2 : bonne reponse ---" severity note;
        press_correct_btn;
        wait for SETTLE;

        assert led = "0010"
            report "FAIL: score devrait valoir 2 apres manche 2" severity error;
        assert led0_r = '0' and led0_g = '0' and led0_b = '0'
            report "FAIL: LED0 doit rester eteinte avant le game over" severity error;

        -- =====================================================================
        -- Manche 3 : mauvaise reponse -> END_GAME
        -- =====================================================================
        report "--- Manche 3 : mauvaise reponse -> game over ---" severity note;
        press_wrong_btn;
        wait for SETTLE;

        assert led = "0010"
            report "FAIL: score final devrait rester a 2 apres une erreur" severity error;
        assert led0_r = '1' and led0_g = '0' and led0_b = '0'
            report "FAIL: LED0 devrait etre rouge (score < 7)" severity error;

        -- =====================================================================
        -- Redemarrage
        -- =====================================================================
        report "--- Redemarrage ---" severity note;
        start_press;
        wait for SETTLE;

        assert led = "0000"
            report "FAIL: score devrait etre remis a 0 apres redemarrage" severity error;
        check_color_valid_stable;

        report "===== LogiGame SEED : tous les tests passes =====" severity note;
        wait;
    end process;

end Behavioral;
