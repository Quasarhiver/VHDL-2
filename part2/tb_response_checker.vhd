-- =============================================================================
-- Module      : tb_response_checker.vhd
-- Description : Testbench dedie au verificateur de reponse.
--               Verifie :
--               - bonne reponse
--               - mauvaise reponse
--               - timeout
--               - ignore les evenements si ENABLE='0'
--               - n'accepte pas un bouton maintenu entre deux manches
-- =============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_response_checker is
end tb_response_checker;

architecture Behavioral of tb_response_checker is

    component response_checker is
        Port (
            CLK       : in  STD_LOGIC;
            RESET     : in  STD_LOGIC;
            ENABLE    : in  STD_LOGIC;
            TIMEOUT   : in  STD_LOGIC;
            LED_COLOR : in  STD_LOGIC_VECTOR(2 downto 0);
            BTN_R     : in  STD_LOGIC;
            BTN_G     : in  STD_LOGIC;
            BTN_B     : in  STD_LOGIC;
            VALID_HIT : out STD_LOGIC;
            ERROR     : out STD_LOGIC
        );
    end component;

    constant CLK_P : time := 10 ns;

    signal CLK_tb       : STD_LOGIC := '0';
    signal RESET_tb     : STD_LOGIC := '1';
    signal ENABLE_tb    : STD_LOGIC := '0';
    signal TIMEOUT_tb   : STD_LOGIC := '0';
    signal LED_COLOR_tb : STD_LOGIC_VECTOR(2 downto 0) := "100";
    signal BTN_R_tb     : STD_LOGIC := '0';
    signal BTN_G_tb     : STD_LOGIC := '0';
    signal BTN_B_tb     : STD_LOGIC := '0';
    signal VALID_HIT_tb : STD_LOGIC;
    signal ERROR_tb     : STD_LOGIC;

begin

    CLK_tb <= not CLK_tb after CLK_P / 2;

    DUT : response_checker
        port map (
            CLK       => CLK_tb,
            RESET     => RESET_tb,
            ENABLE    => ENABLE_tb,
            TIMEOUT   => TIMEOUT_tb,
            LED_COLOR => LED_COLOR_tb,
            BTN_R     => BTN_R_tb,
            BTN_G     => BTN_G_tb,
            BTN_B     => BTN_B_tb,
            VALID_HIT => VALID_HIT_tb,
            ERROR     => ERROR_tb
        );

    process
    begin
        report "===== Testbench Response Checker =====" severity note;

        RESET_tb   <= '1';
        ENABLE_tb  <= '0';
        TIMEOUT_tb <= '0';
        BTN_R_tb   <= '0';
        BTN_G_tb   <= '0';
        BTN_B_tb   <= '0';
        wait for 5 * CLK_P;
        RESET_tb <= '0';
        wait until rising_edge(CLK_tb);
        wait for 1 ns;

        -- =====================================================================
        -- Test 1 : bonne reponse rouge
        -- =====================================================================
        report "--- Test 1 : bonne reponse rouge ---" severity note;
        LED_COLOR_tb <= "100";
        ENABLE_tb    <= '1';
        wait until rising_edge(CLK_tb);
        BTN_R_tb <= '1';
        wait until rising_edge(CLK_tb);
        wait for 1 ns;
        assert VALID_HIT_tb = '1' and ERROR_tb = '0'
            report "FAIL T1: bonne reponse rouge non detectee" severity error;
        BTN_R_tb <= '0';
        wait until rising_edge(CLK_tb);
        wait for 1 ns;
        assert VALID_HIT_tb = '0' and ERROR_tb = '0'
            report "FAIL T1: les sorties doivent revenir a 0 apres l'impulsion" severity error;

        -- Meme manche : un second appui doit etre ignore.
        BTN_R_tb <= '1';
        wait until rising_edge(CLK_tb);
        wait for 1 ns;
        assert VALID_HIT_tb = '0' and ERROR_tb = '0'
            report "FAIL T1b: un second appui dans la meme manche devrait etre ignore" severity error;
        BTN_R_tb <= '0';
        ENABLE_tb <= '0';
        wait until rising_edge(CLK_tb);
        wait for 1 ns;

        -- =====================================================================
        -- Test 2 : mauvaise reponse
        -- =====================================================================
        report "--- Test 2 : mauvaise reponse ---" severity note;
        LED_COLOR_tb <= "010";
        ENABLE_tb    <= '1';
        wait until rising_edge(CLK_tb);
        BTN_B_tb <= '1';
        wait until rising_edge(CLK_tb);
        wait for 1 ns;
        assert VALID_HIT_tb = '0' and ERROR_tb = '1'
            report "FAIL T2: mauvaise reponse non detectee" severity error;
        BTN_B_tb <= '0';
        wait until rising_edge(CLK_tb);
        wait for 1 ns;
        assert VALID_HIT_tb = '0' and ERROR_tb = '0'
            report "FAIL T2: l'impulsion ERROR devrait durer un seul cycle" severity error;
        ENABLE_tb <= '0';
        wait until rising_edge(CLK_tb);

        -- =====================================================================
        -- Test 3 : timeout
        -- =====================================================================
        report "--- Test 3 : timeout ---" severity note;
        LED_COLOR_tb <= "001";
        ENABLE_tb    <= '1';
        TIMEOUT_tb   <= '1';
        wait until rising_edge(CLK_tb);
        wait for 1 ns;
        assert VALID_HIT_tb = '0' and ERROR_tb = '1'
            report "FAIL T3: timeout non detecte" severity error;
        TIMEOUT_tb <= '0';
        wait until rising_edge(CLK_tb);
        wait for 1 ns;
        assert VALID_HIT_tb = '0' and ERROR_tb = '0'
            report "FAIL T3: l'impulsion ERROR sur timeout devrait durer un seul cycle" severity error;
        ENABLE_tb <= '0';
        wait until rising_edge(CLK_tb);

        -- =====================================================================
        -- Test 4 : si ENABLE='0', aucun evenement ne doit etre pris en compte
        -- =====================================================================
        report "--- Test 4 : ignore quand ENABLE=0 ---" severity note;
        LED_COLOR_tb <= "100";
        TIMEOUT_tb   <= '1';
        BTN_R_tb     <= '1';
        wait until rising_edge(CLK_tb);
        wait for 1 ns;
        assert VALID_HIT_tb = '0' and ERROR_tb = '0'
            report "FAIL T4: un evenement a ete pris en compte alors que ENABLE=0" severity error;
        TIMEOUT_tb <= '0';
        BTN_R_tb   <= '0';
        wait until rising_edge(CLK_tb);

        -- =====================================================================
        -- Test 5 : bouton maintenu entre deux manches
        -- =====================================================================
        report "--- Test 5 : bouton maintenu entre deux manches ---" severity note;
        BTN_R_tb  <= '1';
        ENABLE_tb <= '0';
        wait until rising_edge(CLK_tb);
        wait for 1 ns;
        assert VALID_HIT_tb = '0' and ERROR_tb = '0'
            report "FAIL T5a: aucun evenement ne doit etre declenche manche inactive" severity error;

        LED_COLOR_tb <= "100";
        ENABLE_tb    <= '1';
        wait until rising_edge(CLK_tb);
        wait for 1 ns;
        assert VALID_HIT_tb = '0' and ERROR_tb = '0'
            report "FAIL T5b: un bouton deja maintenu ne doit pas compter a l'activation" severity error;

        wait until rising_edge(CLK_tb);
        wait for 1 ns;
        assert VALID_HIT_tb = '0' and ERROR_tb = '0'
            report "FAIL T5c: le maintien ne doit toujours pas compter" severity error;

        BTN_R_tb <= '0';
        wait until rising_edge(CLK_tb);
        wait for 1 ns;
        assert VALID_HIT_tb = '0' and ERROR_tb = '0'
            report "FAIL T5d: le relachement seul ne doit rien produire" severity error;

        BTN_R_tb <= '1';
        wait until rising_edge(CLK_tb);
        wait for 1 ns;
        assert VALID_HIT_tb = '1' and ERROR_tb = '0'
            report "FAIL T5e: le nouvel appui apres relachement devrait etre accepte" severity error;

        BTN_R_tb <= '0';
        ENABLE_tb <= '0';
        wait until rising_edge(CLK_tb);
        wait for 1 ns;

        report "===== Response Checker termine =====" severity note;
        wait;
    end process;

end Behavioral;
