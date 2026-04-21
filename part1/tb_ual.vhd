-- =============================================================================
-- Module      : tb_ual.vhd
-- Description : Testbench exhaustif pour l'UAL 4 bits.
--               Teste les 16 opérations avec plusieurs combinaisons (A,B).
--               Utilise assert/report pour valider chaque résultat.
-- Auteur      : Projet LogiGame – TE608 EFREI 2025-2026
-- Simulation  : GHDL / Vivado Simulator
-- =============================================================================

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

    -- Délai de propagation combinatoire
    constant T_PROP : time := 20 ns;

    -- Helper : convertit signed 4-bit en string
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
        -- Variables pour calcul des résultats attendus
        variable exp_s    : signed(7 downto 0);
        variable a_s      : signed(3 downto 0);
        variable b_s      : signed(3 downto 0);
        variable mul_res  : signed(7 downto 0);
    begin
        report "===== Début testbench UAL =====" severity note;

        -- =====================================================================
        -- Jeu de tests : A=3 (0011), B=2 (0010)
        -- =====================================================================
        A_tb   <= "0011";  -- +3
        B_tb   <= "0010";  -- +2
        a_s    := to_signed(3, 4);
        b_s    := to_signed(2, 4);
        mul_res:= a_s * b_s;

        -- 0000 : NOP → S = 0
        SEL_tb <= "0000"; wait for T_PROP;
        assert S_tb = "00000000"
            report "FAIL NOP: S=" & integer'image(to_integer(unsigned(S_tb))) severity error;
        report "NOP     : S=" & integer'image(to_integer(unsigned(S_tb))) & " (attendu 0)" severity note;

        -- 0001 : A → S = sign_ext(3) = 00000011
        SEL_tb <= "0001"; wait for T_PROP;
        assert S_tb = "00000011"
            report "FAIL A: S=" & integer'image(to_integer(unsigned(S_tb))) severity error;
        report "A       : S=" & integer'image(to_integer(unsigned(S_tb))) & " (attendu 3)" severity note;

        -- 0010 : notA → S = not(00000011) = 11111100
        SEL_tb <= "0010"; wait for T_PROP;
        assert S_tb = "11111100"
            report "FAIL notA: S=" & integer'image(to_integer(unsigned(S_tb))) severity error;
        report "notA    : S=0x" & integer'image(to_integer(unsigned(S_tb))) & " (attendu 252)" severity note;

        -- 0011 : B → S = 00000010
        SEL_tb <= "0011"; wait for T_PROP;
        assert S_tb = "00000010"
            report "FAIL B: S=" & integer'image(to_integer(unsigned(S_tb))) severity error;
        report "B       : S=" & integer'image(to_integer(unsigned(S_tb))) & " (attendu 2)" severity note;

        -- 0100 : notB → S = not(00000010) = 11111101
        SEL_tb <= "0100"; wait for T_PROP;
        assert S_tb = "11111101"
            report "FAIL notB: S=" & integer'image(to_integer(unsigned(S_tb))) severity error;
        report "notB    : S=0x" & integer'image(to_integer(unsigned(S_tb))) & " (attendu 253)" severity note;

        -- 0101 : A AND B → 0011 AND 0010 = 0010 → S=00000010
        SEL_tb <= "0101"; wait for T_PROP;
        assert S_tb = "00000010"
            report "FAIL AND: S=" & integer'image(to_integer(unsigned(S_tb))) severity error;
        report "A AND B : S=" & integer'image(to_integer(unsigned(S_tb))) & " (attendu 2)" severity note;

        -- 0110 : A OR B → 0011 OR 0010 = 0011 → S=00000011
        SEL_tb <= "0110"; wait for T_PROP;
        assert S_tb = "00000011"
            report "FAIL OR: S=" & integer'image(to_integer(unsigned(S_tb))) severity error;
        report "A OR B  : S=" & integer'image(to_integer(unsigned(S_tb))) & " (attendu 3)" severity note;

        -- 0111 : A XOR B → 0011 XOR 0010 = 0001 → S=00000001
        SEL_tb <= "0111"; wait for T_PROP;
        assert S_tb = "00000001"
            report "FAIL XOR: S=" & integer'image(to_integer(unsigned(S_tb))) severity error;
        report "A XOR B : S=" & integer'image(to_integer(unsigned(S_tb))) & " (attendu 1)" severity note;

        -- 1000 : A+B+SRINR (SRINR=0) → 3+2=5 → S=00000101
        SEL_tb  <= "1000"; SRINR_tb <= '0'; wait for T_PROP;
        assert S_tb = "00000101"
            report "FAIL ADD+Cin0: S=" & integer'image(to_integer(unsigned(S_tb))) severity error;
        report "ADD+0   : S=" & integer'image(to_integer(unsigned(S_tb))) & " (attendu 5)" severity note;

        -- 1000 : A+B+SRINR (SRINR=1) → 3+2+1=6 → S=00000110
        SEL_tb  <= "1000"; SRINR_tb <= '1'; wait for T_PROP;
        assert S_tb = "00000110"
            report "FAIL ADD+Cin1: S=" & integer'image(to_integer(unsigned(S_tb))) severity error;
        report "ADD+1   : S=" & integer'image(to_integer(unsigned(S_tb))) & " (attendu 6)" severity note;
        SRINR_tb <= '0';

        -- 1001 : A+B → 5 → S=00000101
        SEL_tb <= "1001"; wait for T_PROP;
        assert S_tb = "00000101"
            report "FAIL ADD: S=" & integer'image(to_integer(unsigned(S_tb))) severity error;
        report "ADD     : S=" & integer'image(to_integer(unsigned(S_tb))) & " (attendu 5)" severity note;

        -- 1010 : A-B → 3-2=1 → S=00000001
        SEL_tb <= "1010"; wait for T_PROP;
        assert S_tb = "00000001"
            report "FAIL SUB: S=" & integer'image(to_integer(unsigned(S_tb))) severity error;
        report "SUB     : S=" & integer'image(to_integer(unsigned(S_tb))) & " (attendu 1)" severity note;

        -- 1011 : A*B → 3*2=6 → S=00000110
        SEL_tb <= "1011"; wait for T_PROP;
        assert S_tb = "00000110"
            report "FAIL MUL: S=" & integer'image(to_integer(unsigned(S_tb))) severity error;
        report "MUL     : S=" & integer'image(to_integer(unsigned(S_tb))) & " (attendu 6)" severity note;

        -- 1100 : SRA (A=0011, SRINL=0) → 0001, SROUTR=1
        SEL_tb  <= "1100"; SRINL_tb <= '0'; wait for T_PROP;
        assert S_tb(3 downto 0) = "0001"
            report "FAIL SRA: S(3:0)=" & integer'image(to_integer(unsigned(S_tb(3 downto 0)))) severity error;
        assert SROUTR_tb = '1'
            report "FAIL SRA SROUTR" severity error;
        report "SRA     : S[3:0]=" & integer'image(to_integer(unsigned(S_tb(3 downto 0)))) & " SROUTR=" & std_logic'image(SROUTR_tb) & " (attendu 1, SROUTR=1)" severity note;

        -- 1101 : SLA (A=0011, SRINR=0) → 0110, SROUTL=0
        SEL_tb  <= "1101"; SRINR_tb <= '0'; wait for T_PROP;
        assert S_tb(3 downto 0) = "0110"
            report "FAIL SLA: S(3:0)=" & integer'image(to_integer(unsigned(S_tb(3 downto 0)))) severity error;
        assert SROUTL_tb = '0'
            report "FAIL SLA SROUTL" severity error;
        report "SLA     : S[3:0]=" & integer'image(to_integer(unsigned(S_tb(3 downto 0)))) & " SROUTL=" & std_logic'image(SROUTL_tb) & " (attendu 6, SROUTL=0)" severity note;

        -- 1110 : SRB (B=0010, SRINL=0) → 0001, SROUTR=0
        SEL_tb  <= "1110"; SRINL_tb <= '0'; wait for T_PROP;
        assert S_tb(3 downto 0) = "0001"
            report "FAIL SRB: S(3:0)=" & integer'image(to_integer(unsigned(S_tb(3 downto 0)))) severity error;
        report "SRB     : S[3:0]=" & integer'image(to_integer(unsigned(S_tb(3 downto 0)))) & " (attendu 1)" severity note;

        -- 1111 : SLB (B=0010, SRINR=0) → 0100, SROUTL=0
        SEL_tb  <= "1111"; SRINR_tb <= '0'; wait for T_PROP;
        assert S_tb(3 downto 0) = "0100"
            report "FAIL SLB: S(3:0)=" & integer'image(to_integer(unsigned(S_tb(3 downto 0)))) severity error;
        report "SLB     : S[3:0]=" & integer'image(to_integer(unsigned(S_tb(3 downto 0)))) & " (attendu 4)" severity note;

        -- =====================================================================
        -- Test valeurs négatives : A=-1 (1111), B=-2 (1110)
        -- =====================================================================
        report "--- Test valeurs négatives ---" severity note;
        A_tb <= "1111";  -- -1
        B_tb <= "1110";  -- -2

        -- MUL : -1 * -2 = +2
        SEL_tb <= "1011"; wait for T_PROP;
        assert to_integer(signed(S_tb)) = 2
            report "FAIL MUL négatifs: S=" & integer'image(to_integer(signed(S_tb))) severity error;
        report "(-1)*(-2): S=" & integer'image(to_integer(signed(S_tb))) & " (attendu 2)" severity note;

        -- SUB : -1 - (-2) = +1
        SEL_tb <= "1010"; wait for T_PROP;
        assert to_integer(signed(S_tb(4 downto 0))) = 1
            report "FAIL SUB négatifs" severity error;
        report "(-1)-(-2): S=" & integer'image(to_integer(signed(S_tb(4 downto 0)))) & " (attendu 1)" severity note;

        -- =====================================================================
        -- Test A=3, B=2 pour validation des programmes MCU
        -- =====================================================================
        report "--- Validation programmes MCU (A=3, B=2) ---" severity note;
        A_tb <= "0011"; B_tb <= "0010";
        SEL_tb <= "1011"; wait for T_PROP;
        report "PROG0 A*B = " & integer'image(to_integer(unsigned(S_tb))) & " (attendu 6)" severity note;

        report "===== Testbench UAL terminé =====" severity note;
        wait;
    end process;

end Behavioral;
