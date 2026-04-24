-- =============================================================================
-- Module      : tb_mcu_controller.vhd
-- Description : Testbench du couple mcu_controller + datapath.
--               Les trois programmes sont valides avec A = B = 3, ce qui
--               correspond au cablage de la carte pour la partie 1 :
--                 PROG0 : A * B = 9
--                 PROG1 : (A + B) XNOR A = 10 -> 0000_1010
--                 PROG2 : (A0 AND B1) OR (A1 AND B0) = 1 sur le bit 0
-- Auteur      : Projet LogiGame - TE608 EFREI 2025-2026
-- Simulation  : GHDL / Vivado Simulator
-- =============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_mcu_controller is
end tb_mcu_controller;

architecture Behavioral of tb_mcu_controller is

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

    constant CLK_PERIOD : time := 10 ns;
    constant MAX_CYCLES : integer := 100;

    signal CLK_tb      : STD_LOGIC := '0';
    signal RESET_tb    : STD_LOGIC := '1';
    signal START_tb    : STD_LOGIC := '0';
    signal SEL_PROG_tb : STD_LOGIC_VECTOR(1 downto 0) := "00";

    signal selfct_s    : STD_LOGIC_VECTOR(3 downto 0);
    signal selroute_s  : STD_LOGIC_VECTOR(3 downto 0);
    signal selout_s    : STD_LOGIC_VECTOR(1 downto 0);
    signal done_s      : STD_LOGIC;

    signal resout_s    : STD_LOGIC_VECTOR(7 downto 0);
    signal sroutl_s    : STD_LOGIC;
    signal sroutr_s    : STD_LOGIC;

begin

    CLK_tb <= not CLK_tb after CLK_PERIOD / 2;

    U_CTRL : mcu_controller
        port map (
            CLK      => CLK_tb,
            RESET    => RESET_tb,
            START    => START_tb,
            SEL_PROG => SEL_PROG_tb,
            SELFCT   => selfct_s,
            SELROUTE => selroute_s,
            SELOUT   => selout_s,
            DONE     => done_s
        );

    U_DP : datapath
        port map (
            CLK      => CLK_tb,
            RESET    => RESET_tb,
            A_IN     => "0011",
            B_IN     => "0011",
            SRINL    => '0',
            SRINR    => '0',
            SELFCT   => selfct_s,
            SELROUTE => selroute_s,
            SELOUT   => selout_s,
            RESOUT   => resout_s,
            SROUTL   => sroutl_s,
            SROUTR   => sroutr_s
        );

    process
        variable cycle_count : integer;
    begin
        report "===== Debut testbench MCU Controller =====" severity note;
        report "Test avec A=3 et B=3 (cablage carte : A=B)" severity note;

        RESET_tb <= '1';
        START_tb <= '0';
        wait for 5 * CLK_PERIOD;
        RESET_tb <= '0';
        wait for 2 * CLK_PERIOD;

        report "--- Programme 0 : A * B ---" severity note;
        SEL_PROG_tb <= "00";
        wait for CLK_PERIOD;
        START_tb <= '1';
        wait for CLK_PERIOD;
        START_tb <= '0';

        cycle_count := 0;
        while done_s = '0' and cycle_count < MAX_CYCLES loop
            wait for CLK_PERIOD;
            cycle_count := cycle_count + 1;
        end loop;

        wait for 2 ns;
        assert done_s = '1'
            report "FAIL PROG0 : DONE non recu" severity error;
        assert resout_s = "00001001"
            report "FAIL PROG0 : RESOUT=" & integer'image(to_integer(unsigned(resout_s))) &
                   " (attendu 9 pour A=B=3)" severity error;

        wait for 2 * CLK_PERIOD;

        report "--- Programme 1 : (A+B) XNOR A ---" severity note;
        RESET_tb <= '1';
        wait for 3 * CLK_PERIOD;
        RESET_tb <= '0';
        wait for 2 * CLK_PERIOD;
        SEL_PROG_tb <= "01";
        wait for CLK_PERIOD;
        START_tb <= '1';
        wait for CLK_PERIOD;
        START_tb <= '0';

        cycle_count := 0;
        while done_s = '0' and cycle_count < MAX_CYCLES loop
            wait for CLK_PERIOD;
            cycle_count := cycle_count + 1;
        end loop;

        wait for 2 ns;
        assert done_s = '1'
            report "FAIL PROG1 : DONE non recu" severity error;
        assert resout_s = "00001010"
            report "FAIL PROG1 : RESOUT=" & integer'image(to_integer(unsigned(resout_s))) &
                   " (attendu 10=00001010 pour A=B=3)" severity error;

        wait for 2 * CLK_PERIOD;

        report "--- Programme 2 : (A0 AND B1) OR (A1 AND B0) ---" severity note;
        RESET_tb <= '1';
        wait for 3 * CLK_PERIOD;
        RESET_tb <= '0';
        wait for 2 * CLK_PERIOD;
        SEL_PROG_tb <= "10";
        wait for CLK_PERIOD;
        START_tb <= '1';
        wait for CLK_PERIOD;
        START_tb <= '0';

        cycle_count := 0;
        while done_s = '0' and cycle_count < MAX_CYCLES loop
            wait for CLK_PERIOD;
            cycle_count := cycle_count + 1;
        end loop;

        wait for 2 ns;
        assert done_s = '1'
            report "FAIL PROG2 : DONE non recu" severity error;
        assert resout_s(0) = '1'
            report "FAIL PROG2 : bit0=" & std_logic'image(resout_s(0)) &
                   " (attendu 1)" severity error;

        report "===== Testbench MCU Controller termine =====" severity note;
        wait;
    end process;

end Behavioral;
