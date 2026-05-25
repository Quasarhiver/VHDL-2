

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

       
        RESET_tb <= '1';
        wait for 3 * CLK_PERIOD;
        RESET_tb <= '0';
        wait for CLK_PERIOD;

    
        report "--- Test RESOUT1 = A*B (A=3, B=2) ---" severity note;

    
        SELFCT_tb   <= "0000"; SELROUTE_tb <= "0000"; SELOUT_tb <= "00";
        wait for CLK_PERIOD;

      
        SELFCT_tb   <= "1011"; SELROUTE_tb <= "0001"; SELOUT_tb <= "00";
        wait for CLK_PERIOD;

      
        SELFCT_tb   <= "0000"; SELROUTE_tb <= "0110"; SELOUT_tb <= "01";
        wait for CLK_PERIOD;

        
        wait for 2 ns;
        assert RESOUT_tb = "00000110"
            report "FAIL TEST1 A*B: RESOUT=" & integer'image(to_integer(unsigned(RESOUT_tb))) & " (attendu 6)" severity error;
        report "TEST1 A*B = " & integer'image(to_integer(unsigned(RESOUT_tb))) & " (attendu 6)" severity note;

        report "--- Test RESOUT2 = (A+B) xnor A ---" severity note;

        RESET_tb <= '1'; wait for CLK_PERIOD; RESET_tb <= '0'; wait for CLK_PERIOD;

      
        SELFCT_tb <= "0000"; SELROUTE_tb <= "0000"; SELOUT_tb <= "00";
        wait for CLK_PERIOD;
       
        SELFCT_tb <= "1001"; SELROUTE_tb <= "0001"; SELOUT_tb <= "00";
        wait for CLK_PERIOD;
      
        SELFCT_tb <= "0000"; SELROUTE_tb <= "0110"; SELOUT_tb <= "00";
        wait for CLK_PERIOD;
        SELFCT_tb <= "0111"; SELROUTE_tb <= "1010"; SELOUT_tb <= "00";
        wait for CLK_PERIOD;
       
        SELFCT_tb <= "0100"; SELROUTE_tb <= "0100"; SELOUT_tb <= "00";
        wait for CLK_PERIOD;
       
        SELFCT_tb <= "0000"; SELROUTE_tb <= "0110"; SELOUT_tb <= "01";
        wait for CLK_PERIOD;

        wait for 2 ns;
        report "TEST2 (A+B) XNOR A = 0x" & integer'image(to_integer(unsigned(RESOUT_tb))) &
               " RESOUT[3:0]=" & integer'image(to_integer(unsigned(RESOUT_tb(3 downto 0)))) severity note;
       
        assert RESOUT_tb(3 downto 0) = "1001"
            report "FAIL TEST2: RESOUT[3:0]=" & integer'image(to_integer(unsigned(RESOUT_tb(3 downto 0)))) &
                   " (attendu 9=1001)" severity error;


        report "--- Test RESOUT3 = (A0 AND B1) OR (A1 AND B0) ---" severity note;
        RESET_tb <= '1'; wait for CLK_PERIOD; RESET_tb <= '0'; wait for CLK_PERIOD;

     
        SELFCT_tb <= "0000"; SELROUTE_tb <= "0000"; SELOUT_tb <= "00"; wait for CLK_PERIOD;
        
        SELFCT_tb <= "1100"; SELROUTE_tb <= "0001"; SELOUT_tb <= "00"; wait for CLK_PERIOD;
       
        SELFCT_tb <= "0000"; SELROUTE_tb <= "0110"; SELOUT_tb <= "00"; wait for CLK_PERIOD;

        SELFCT_tb <= "0101"; SELROUTE_tb <= "1000"; SELOUT_tb <= "00"; wait for CLK_PERIOD;
      
        SELFCT_tb <= "1110"; SELROUTE_tb <= "0111"; SELOUT_tb <= "00"; wait for CLK_PERIOD;
      
        SELFCT_tb <= "0000"; SELROUTE_tb <= "0110"; SELOUT_tb <= "00"; wait for CLK_PERIOD;
        
        SELFCT_tb <= "0000"; SELROUTE_tb <= "1010"; SELOUT_tb <= "00"; wait for CLK_PERIOD;
       
        SELFCT_tb <= "0101"; SELROUTE_tb <= "0000"; SELOUT_tb <= "00"; wait for CLK_PERIOD;
      
        SELFCT_tb <= "0000"; SELROUTE_tb <= "0110"; SELOUT_tb <= "00"; wait for CLK_PERIOD;
        
        SELFCT_tb <= "0000"; SELROUTE_tb <= "1100"; SELOUT_tb <= "00"; wait for CLK_PERIOD;
       
        SELFCT_tb <= "0110"; SELROUTE_tb <= "1010"; SELOUT_tb <= "00"; wait for CLK_PERIOD;
        
        SELFCT_tb <= "0000"; SELROUTE_tb <= "0110"; SELOUT_tb <= "00"; wait for CLK_PERIOD;
      
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
