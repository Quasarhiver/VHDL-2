

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_ual is
end tb_ual;

architecture Behavioral of tb_ual is

    component ual is
        Port (
            A       : in  STD_LOGIC_VECTOR(3 downto 0);
            B       : in  STD_LOGIC_VECTOR(3 downto 0);
            SEL_FCT : in  STD_LOGIC_VECTOR(3 downto 0);
            SRINL   : in  STD_LOGIC;
            SRINR   : in  STD_LOGIC;
            S       : out STD_LOGIC_VECTOR(7 downto 0);
            SROUTL  : out STD_LOGIC;
            SROUTR  : out STD_LOGIC
        );
    end component;

    signal A_tb      : STD_LOGIC_VECTOR(3 downto 0) := (others => '0');
    signal B_tb      : STD_LOGIC_VECTOR(3 downto 0) := (others => '0');
    signal SEL_tb    : STD_LOGIC_VECTOR(3 downto 0) := (others => '0');
    signal SRINL_tb  : STD_LOGIC := '0';
    signal SRINR_tb  : STD_LOGIC := '0';
    signal S_tb      : STD_LOGIC_VECTOR(7 downto 0);
    signal SROUTL_tb : STD_LOGIC;
    signal SROUTR_tb : STD_LOGIC;

    constant T_PROP : time := 20 ns;

    
    function to_hstr(v : STD_LOGIC_VECTOR) return string is
    begin
        return integer'image(to_integer(signed(v)));
    end function;

begin

    DUT : ual
        port map (
            A       => A_tb,
            B       => B_tb,
            SEL_FCT => SEL_tb,
            SRINL   => SRINL_tb,
            SRINR   => SRINR_tb,
            S       => S_tb,
            SROUTL  => SROUTL_tb,
            SROUTR  => SROUTR_tb
        );

    process
     
        variable exp_s    : signed(7 downto 0);
        variable a_s      : signed(3 downto 0);
        variable b_s      : signed(3 downto 0);
        variable mul_res  : signed(7 downto 0);
    begin
        report "===== Début testbench UAL =====" severity note;

      
        A_tb   <= "0011";  -- +3
        B_tb   <= "0010";  -- +2
        a_s    := to_signed(3, 4);
        b_s    := to_signed(2, 4);
        mul_res:= a_s * b_s;

      
        SEL_tb <= "0000"; wait for T_PROP;
        assert S_tb = "00000000"
            report "FAIL NOP: S=" & integer'image(to_integer(unsigned(S_tb))) severity error;
        report "NOP     : S=" & integer'image(to_integer(unsigned(S_tb))) & " (attendu 0)" severity note;

       
        SEL_tb <= "0001"; wait for T_PROP;
        assert S_tb = "00000011"
            report "FAIL A: S=" & integer'image(to_integer(unsigned(S_tb))) severity error;
        report "A       : S=" & integer'image(to_integer(unsigned(S_tb))) & " (attendu 3)" severity note;

      
        SEL_tb <= "0010"; wait for T_PROP;
        assert S_tb = "11111100"
            report "FAIL notA: S=" & integer'image(to_integer(unsigned(S_tb))) severity error;
        report "notA    : S=0x" & integer'image(to_integer(unsigned(S_tb))) & " (attendu 252)" severity note;

    
        SEL_tb <= "0011"; wait for T_PROP;
        assert S_tb = "00000010"
            report "FAIL B: S=" & integer'image(to_integer(unsigned(S_tb))) severity error;
        report "B       : S=" & integer'image(to_integer(unsigned(S_tb))) & " (attendu 2)" severity note;

       
        SEL_tb <= "0100"; wait for T_PROP;
        assert S_tb = "11111101"
            report "FAIL notB: S=" & integer'image(to_integer(unsigned(S_tb))) severity error;
        report "notB    : S=0x" & integer'image(to_integer(unsigned(S_tb))) & " (attendu 253)" severity note;


        SEL_tb <= "0101"; wait for T_PROP;
        assert S_tb = "00000010"
            report "FAIL AND: S=" & integer'image(to_integer(unsigned(S_tb))) severity error;
        report "A AND B : S=" & integer'image(to_integer(unsigned(S_tb))) & " (attendu 2)" severity note;

      
        SEL_tb <= "0110"; wait for T_PROP;
        assert S_tb = "00000011"
            report "FAIL OR: S=" & integer'image(to_integer(unsigned(S_tb))) severity error;
        report "A OR B  : S=" & integer'image(to_integer(unsigned(S_tb))) & " (attendu 3)" severity note;

       
        SEL_tb <= "0111"; wait for T_PROP;
        assert S_tb = "00000001"
            report "FAIL XOR: S=" & integer'image(to_integer(unsigned(S_tb))) severity error;
        report "A XOR B : S=" & integer'image(to_integer(unsigned(S_tb))) & " (attendu 1)" severity note;

        
        SEL_tb  <= "1000"; SRINR_tb <= '0'; wait for T_PROP;
        assert S_tb = "00000101"
            report "FAIL ADD+Cin0: S=" & integer'image(to_integer(unsigned(S_tb))) severity error;
        report "ADD+0   : S=" & integer'image(to_integer(unsigned(S_tb))) & " (attendu 5)" severity note;

       
        SEL_tb  <= "1000"; SRINR_tb <= '1'; wait for T_PROP;
        assert S_tb = "00000110"
            report "FAIL ADD+Cin1: S=" & integer'image(to_integer(unsigned(S_tb))) severity error;
        report "ADD+1   : S=" & integer'image(to_integer(unsigned(S_tb))) & " (attendu 6)" severity note;
        SRINR_tb <= '0';

     
        SEL_tb <= "1001"; wait for T_PROP;
        assert S_tb = "00000101"
            report "FAIL ADD: S=" & integer'image(to_integer(unsigned(S_tb))) severity error;
        report "ADD     : S=" & integer'image(to_integer(unsigned(S_tb))) & " (attendu 5)" severity note;

    
        SEL_tb <= "1010"; wait for T_PROP;
        assert S_tb = "00000001"
            report "FAIL SUB: S=" & integer'image(to_integer(unsigned(S_tb))) severity error;
        report "SUB     : S=" & integer'image(to_integer(unsigned(S_tb))) & " (attendu 1)" severity note;

       
        SEL_tb <= "1011"; wait for T_PROP;
        assert S_tb = "00000110"
            report "FAIL MUL: S=" & integer'image(to_integer(unsigned(S_tb))) severity error;
        report "MUL     : S=" & integer'image(to_integer(unsigned(S_tb))) & " (attendu 6)" severity note;

        
        SEL_tb  <= "1100"; SRINL_tb <= '0'; wait for T_PROP;
        assert S_tb(3 downto 0) = "0001"
            report "FAIL SRA: S(3:0)=" & integer'image(to_integer(unsigned(S_tb(3 downto 0)))) severity error;
        assert SROUTR_tb = '1'
            report "FAIL SRA SROUTR" severity error;
        report "SRA     : S[3:0]=" & integer'image(to_integer(unsigned(S_tb(3 downto 0)))) & " SROUTR=" & std_logic'image(SROUTR_tb) & " (attendu 1, SROUTR=1)" severity note;

  
        SEL_tb  <= "1101"; SRINR_tb <= '0'; wait for T_PROP;
        assert S_tb(3 downto 0) = "0110"
            report "FAIL SLA: S(3:0)=" & integer'image(to_integer(unsigned(S_tb(3 downto 0)))) severity error;
        assert SROUTL_tb = '0'
            report "FAIL SLA SROUTL" severity error;
        report "SLA     : S[3:0]=" & integer'image(to_integer(unsigned(S_tb(3 downto 0)))) & " SROUTL=" & std_logic'image(SROUTL_tb) & " (attendu 6, SROUTL=0)" severity note;

       
        SEL_tb  <= "1110"; SRINL_tb <= '0'; wait for T_PROP;
        assert S_tb(3 downto 0) = "0001"
            report "FAIL SRB: S(3:0)=" & integer'image(to_integer(unsigned(S_tb(3 downto 0)))) severity error;
        report "SRB     : S[3:0]=" & integer'image(to_integer(unsigned(S_tb(3 downto 0)))) & " (attendu 1)" severity note;

        SEL_tb  <= "1111"; SRINR_tb <= '0'; wait for T_PROP;
        assert S_tb(3 downto 0) = "0100"
            report "FAIL SLB: S(3:0)=" & integer'image(to_integer(unsigned(S_tb(3 downto 0)))) severity error;
        report "SLB     : S[3:0]=" & integer'image(to_integer(unsigned(S_tb(3 downto 0)))) & " (attendu 4)" severity note;

  
        report "--- Test valeurs négatives ---" severity note;
        A_tb <= "1111";  -- -1
        B_tb <= "1110";  -- -2

        
        SEL_tb <= "1011"; wait for T_PROP;
        assert to_integer(signed(S_tb)) = 2
            report "FAIL MUL négatifs: S=" & integer'image(to_integer(signed(S_tb))) severity error;
        report "(-1)*(-2): S=" & integer'image(to_integer(signed(S_tb))) & " (attendu 2)" severity note;

       
        SEL_tb <= "1010"; wait for T_PROP;
        assert to_integer(signed(S_tb(4 downto 0))) = 1
            report "FAIL SUB négatifs" severity error;
        report "(-1)-(-2): S=" & integer'image(to_integer(signed(S_tb(4 downto 0)))) & " (attendu 1)" severity note;

      
        report "--- Validation programmes MCU (A=3, B=2) ---" severity note;
        A_tb <= "0011"; B_tb <= "0010";
        SEL_tb <= "1011"; wait for T_PROP;
        report "PROG0 A*B = " & integer'image(to_integer(unsigned(S_tb))) & " (attendu 6)" severity note;

        report "===== Testbench UAL terminé =====" severity note;
        wait;
    end process;

end Behavioral;
