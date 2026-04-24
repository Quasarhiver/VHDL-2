-- =============================================================================
-- Module      : tb_datapath.vhd
-- Description : Testbench pour le chemin de données.
--               Vérifie le chargement des registres, le routage et les sorties.
-- Auteur      : Projet LogiGame – TE608 EFREI 2025-2026
-- Simulation  : GHDL / Vivado Simulator
-- =============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_datapath is
end tb_datapath;

architecture Behavioral of tb_datapath is

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

    constant CLK_PERIOD : time := 10 ns;  -- 100 MHz

    signal CLK_tb      : STD_LOGIC := '0';
    signal RESET_tb    : STD_LOGIC := '1';
    signal A_IN_tb     : STD_LOGIC_VECTOR(3 downto 0) := "0011";  -- A=3
    signal B_IN_tb     : STD_LOGIC_VECTOR(3 downto 0) := "0010";  -- B=2
    signal SRINL_tb    : STD_LOGIC := '0';
    signal SRINR_tb    : STD_LOGIC := '0';
    signal SELFCT_tb   : STD_LOGIC_VECTOR(3 downto 0) := "0000";
    signal SELROUTE_tb : STD_LOGIC_VECTOR(3 downto 0) := "0000";
    signal SELOUT_tb   : STD_LOGIC_VECTOR(1 downto 0) := "00";
    signal RESOUT_tb   : STD_LOGIC_VECTOR(7 downto 0);
    signal SROUTL_tb   : STD_LOGIC;
    signal SROUTR_tb   : STD_LOGIC;

begin

    CLK_tb <= not CLK_tb after CLK_PERIOD / 2;

    DUT : datapath
        port map (
            CLK      => CLK_tb,
            RESET    => RESET_tb,
            A_IN     => A_IN_tb,
            B_IN     => B_IN_tb,
            SRINL    => SRINL_tb,
            SRINR    => SRINR_tb,
            SELFCT   => SELFCT_tb,
            SELROUTE => SELROUTE_tb,
            SELOUT   => SELOUT_tb,
            RESOUT   => RESOUT_tb,
            SROUTL   => SROUTL_tb,
            SROUTR   => SROUTR_tb
        );

    process
    begin
        report "===== Début testbench Datapath =====" severity note;

        -- Reset
        RESET_tb <= '1';
        wait for 3 * CLK_PERIOD;
        RESET_tb <= '0';
        wait for CLK_PERIOD;

        -- =====================================================================
        -- TEST 1 : A×B = 3×2 = 6
        -- =====================================================================
        report "--- Test RESOUT1 = A*B (A=3, B=2) ---" severity note;

        -- Cycle 0 : BufferA <- A_IN=3
        SELFCT_tb   <= "0000"; SELROUTE_tb <= "0000"; SELOUT_tb <= "00";
        wait for CLK_PERIOD;

        -- Cycle 1 : BufferB <- B_IN=2 ; préparer MUL
        SELFCT_tb   <= "1011"; SELROUTE_tb <= "0001"; SELOUT_tb <= "00";
        wait for CLK_PERIOD;

        -- Cycle 2 : MC1 <- A*B ; RESOUT = MC1
        SELFCT_tb   <= "0000"; SELROUTE_tb <= "0110"; SELOUT_tb <= "01";
        wait for CLK_PERIOD;

        -- Lecture résultat
        wait for 2 ns;
        assert RESOUT_tb = "00000110"
            report "FAIL TEST1 A*B: RESOUT=" & integer'image(to_integer(unsigned(RESOUT_tb))) & " (attendu 6)" severity error;
        report "TEST1 A*B = " & integer'image(to_integer(unsigned(RESOUT_tb))) & " (attendu 6)" severity note;

        -- =====================================================================
        -- TEST 2 : (A+B) XNOR A sur 4 LSBs (A=3, B=2)
        --   A+B = 5 = 0101, XNOR A(0011) = NOT XOR(0101,0011) = NOT(0110) = 1001
        -- =====================================================================
        report "--- Test RESOUT2 = (A+B) xnor A ---" severity note;

        -- Reset datapath
        RESET_tb <= '1'; wait for CLK_PERIOD; RESET_tb <= '0'; wait for CLK_PERIOD;

        -- Cycle 0 : BufferA <- A_IN
        SELFCT_tb <= "0000"; SELROUTE_tb <= "0000"; SELOUT_tb <= "00";
        wait for CLK_PERIOD;
        -- Cycle 1 : BufferB <- B_IN ; préparer ADD
        SELFCT_tb <= "1001"; SELROUTE_tb <= "0001"; SELOUT_tb <= "00";
        wait for CLK_PERIOD;
        -- Cycle 2 : MC1 <- A+B = 5
        SELFCT_tb <= "0000"; SELROUTE_tb <= "0110"; SELOUT_tb <= "00";
        wait for CLK_PERIOD;
        -- Cycle 3 : BufferB <- MC1[3:0] ; préparer XOR avec A conservé
        SELFCT_tb <= "0111"; SELROUTE_tb <= "1010"; SELOUT_tb <= "00";
        wait for CLK_PERIOD;
        -- Cycle 4 : BufferB <- A xor (A+B) ; préparer notB
        SELFCT_tb <= "0100"; SELROUTE_tb <= "0100"; SELOUT_tb <= "00";
        wait for CLK_PERIOD;
        -- Cycle 5 : BufferA <- XNOR[3:0] ; préparer NOP
        SELFCT_tb <= "0000"; SELROUTE_tb <= "0010"; SELOUT_tb <= "00";
        wait for CLK_PERIOD;
        -- Cycle 6 : BufferB <- 0 ; préparer OR
        SELFCT_tb <= "0110"; SELROUTE_tb <= "0100"; SELOUT_tb <= "00";
        wait for CLK_PERIOD;
        -- Cycle 7 : MC1 <- "0000" & XNOR
        SELFCT_tb <= "0000"; SELROUTE_tb <= "0110"; SELOUT_tb <= "00";
        wait for CLK_PERIOD;
        -- Cycle 8 : sortie MC1
        SELFCT_tb <= "0000"; SELROUTE_tb <= "0111"; SELOUT_tb <= "01";
        wait for CLK_PERIOD;

        wait for 2 ns;
        report "TEST2 (A+B) XNOR A = " & integer'image(to_integer(unsigned(RESOUT_tb))) &
               " RESOUT[3:0]=" & integer'image(to_integer(unsigned(RESOUT_tb(3 downto 0)))) severity note;
        -- Pour A=3, B=2 : A+B=5=0101, XOR A(0011)=0110, NOT=1001=9
        assert RESOUT_tb = "00001001"
            report "FAIL TEST2: RESOUT=" & integer'image(to_integer(unsigned(RESOUT_tb))) &
                   " (attendu 9=00001001)" severity error;

        -- =====================================================================
        -- TEST 3 : (A0 AND B1) OR (A1 AND B0)  avec A=3 (0011), B=2 (0010)
        --   A0=1, A1=1, B0=0, B1=1 -> (1 AND 1) OR (1 AND 0) = 1
        -- =====================================================================
        report "--- Test RESOUT3 = (A0 AND B1) OR (A1 AND B0) ---" severity note;
        RESET_tb <= '1'; wait for CLK_PERIOD; RESET_tb <= '0'; wait for CLK_PERIOD;

        -- Cycle 0 : BufferA <- A
        SELFCT_tb <= "0000"; SELROUTE_tb <= "0000"; SELOUT_tb <= "00"; wait for CLK_PERIOD;
        -- Cycle 1 : BufferB <- B ; préparer SRA(A)
        SELFCT_tb <= "1100"; SELROUTE_tb <= "0001"; SELOUT_tb <= "00"; wait for CLK_PERIOD;
        -- Cycle 2 : MC1 <- A>>1
        SELFCT_tb <= "0000"; SELROUTE_tb <= "0110"; SELOUT_tb <= "00"; wait for CLK_PERIOD;
        -- Cycle 3 : BufferA <- MC1[3:0] ; préparer AND
        SELFCT_tb <= "0101"; SELROUTE_tb <= "1000"; SELOUT_tb <= "00"; wait for CLK_PERIOD;
        -- Cycle 4 : MC2 <- (A>>1) AND B ; préparer SRB(B)
        SELFCT_tb <= "1110"; SELROUTE_tb <= "0111"; SELOUT_tb <= "00"; wait for CLK_PERIOD;
        -- Cycle 5 : MC1 <- B>>1
        SELFCT_tb <= "0000"; SELROUTE_tb <= "0110"; SELOUT_tb <= "00"; wait for CLK_PERIOD;
        -- Cycle 6 : BufferB <- MC1[3:0]
        SELFCT_tb <= "0000"; SELROUTE_tb <= "1010"; SELOUT_tb <= "00"; wait for CLK_PERIOD;
        -- Cycle 7 : BufferA <- A ; préparer AND
        SELFCT_tb <= "0101"; SELROUTE_tb <= "0000"; SELOUT_tb <= "00"; wait for CLK_PERIOD;
        -- Cycle 8 : MC1 <- A AND (B>>1)
        SELFCT_tb <= "0000"; SELROUTE_tb <= "0110"; SELOUT_tb <= "00"; wait for CLK_PERIOD;
        -- Cycle 9 : BufferA <- MC2[3:0]
        SELFCT_tb <= "0000"; SELROUTE_tb <= "1100"; SELOUT_tb <= "00"; wait for CLK_PERIOD;
        -- Cycle 10: BufferB <- MC1[3:0] ; préparer OR
        SELFCT_tb <= "0110"; SELROUTE_tb <= "1010"; SELOUT_tb <= "00"; wait for CLK_PERIOD;
        -- Cycle 11: MC1 <- terme1 OR terme2
        SELFCT_tb <= "0000"; SELROUTE_tb <= "0110"; SELOUT_tb <= "00"; wait for CLK_PERIOD;
        -- Cycle 12: sortie MC1
        SELFCT_tb <= "0000"; SELROUTE_tb <= "0000"; SELOUT_tb <= "01"; wait for CLK_PERIOD;

        wait for 2 ns;
        report "TEST3 (A0 and B1) or (A1 and B0) bit0 = " & std_logic'image(RESOUT_tb(0)) &
               " (attendu 1 pour A=3, B=2)" severity note;
        assert RESOUT_tb(0) = '1'
            report "FAIL TEST3: bit0=" & std_logic'image(RESOUT_tb(0)) & " (attendu 1)" severity error;

        report "===== Testbench Datapath terminé =====" severity note;
        wait;
    end process;

end Behavioral;
