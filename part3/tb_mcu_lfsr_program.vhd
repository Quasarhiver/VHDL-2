-- =============================================================================
-- Module      : tb_mcu_lfsr_program.vhd
-- Description : Testbench dedie au generateur pseudo-aleatoire MCU.
--               Verifie :
--               - qu'aucune execution n'a lieu sans START
--               - que DONE est emis apres chaque demande
--               - que la sequence de 15 etats attendue est produite
--               - que l'etat interne est preserve entre les demandes
-- =============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_mcu_lfsr_program is
end tb_mcu_lfsr_program;

architecture Behavioral of tb_mcu_lfsr_program is

    component mcu_lfsr_program is
        Port (
            CLK      : in  STD_LOGIC;
            RESET    : in  STD_LOGIC;
            START    : in  STD_LOGIC;
            SELFCT   : out STD_LOGIC_VECTOR(3 downto 0);
            SELROUTE : out STD_LOGIC_VECTOR(3 downto 0);
            SELOUT   : out STD_LOGIC_VECTOR(1 downto 0);
            DONE     : out STD_LOGIC
        );
    end component;

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

    constant CLK_P : time := 1 ms;

    signal CLK_tb      : STD_LOGIC := '0';
    signal RESET_tb    : STD_LOGIC := '1';
    signal START_tb    : STD_LOGIC := '0';
    signal SELFCT_tb   : STD_LOGIC_VECTOR(3 downto 0);
    signal SELROUTE_tb : STD_LOGIC_VECTOR(3 downto 0);
    signal SELOUT_tb   : STD_LOGIC_VECTOR(1 downto 0);
    signal DONE_tb     : STD_LOGIC;
    signal RESOUT_tb   : STD_LOGIC_VECTOR(7 downto 0);

    type seq_t is array (0 to 15) of STD_LOGIC_VECTOR(3 downto 0);
    constant EXPECTED_SEQ : seq_t := (
        "0111", "1111", "1110", "1100",
        "1000", "0001", "0010", "0100",
        "1001", "0011", "0110", "1101",
        "1010", "0101", "1011", "0111"
    );

begin

    CLK_tb <= not CLK_tb after CLK_P / 2;

    U_MCU : mcu_lfsr_program
        port map (
            CLK      => CLK_tb,
            RESET    => RESET_tb,
            START    => START_tb,
            SELFCT   => SELFCT_tb,
            SELROUTE => SELROUTE_tb,
            SELOUT   => SELOUT_tb,
            DONE     => DONE_tb
        );

    U_DP : datapath
        port map (
            CLK      => CLK_tb,
            RESET    => RESET_tb,
            A_IN     => "1011",
            B_IN     => "1011",
            SRINL    => '0',
            SRINR    => '0',
            SELFCT   => SELFCT_tb,
            SELROUTE => SELROUTE_tb,
            SELOUT   => SELOUT_tb,
            RESOUT   => RESOUT_tb,
            SROUTL   => open,
            SROUTR   => open
        );

    process
    begin
        report "===== Testbench MCU LFSR Program =====" severity note;

        RESET_tb <= '1';
        START_tb <= '0';
        wait for 5 * CLK_P;
        RESET_tb <= '0';

        -- Sans START, aucune execution ne doit se produire.
        wait for 1200 us;
        assert DONE_tb = '0'
            report "FAIL: DONE actif sans demande START" severity error;
        assert RESOUT_tb = "00000000"
            report "FAIL: RESOUT devrait rester nul avant la premiere execution" severity error;

        -- Verification de la sequence complete.
        for i in 0 to 15 loop
            START_tb <= '1';
            wait for CLK_P;
            START_tb <= '0';

            wait until DONE_tb = '1' for 25 ms;
            assert DONE_tb = '1'
                report "FAIL: DONE non recu pour l'etape " & integer'image(i) severity error;

            wait for 1 ns;
            assert RESOUT_tb(3 downto 0) = EXPECTED_SEQ(i)
                report "FAIL: etat pseudo-aleatoire inattendu a l'etape " &
                       integer'image(i) & ", obtenu " &
                       integer'image(to_integer(unsigned(RESOUT_tb(3 downto 0))))
                severity error;
            report "Etat[" & integer'image(i) & "] = " &
                   integer'image(to_integer(unsigned(RESOUT_tb(3 downto 0)))) severity note;

            wait until rising_edge(CLK_tb);
            wait for 1 ns;
            assert DONE_tb = '0'
                report "FAIL: DONE devrait etre un pulse d'un seul cycle" severity error;
        end loop;

        report "===== MCU LFSR Program termine =====" severity note;
        wait;
    end process;

end Behavioral;
