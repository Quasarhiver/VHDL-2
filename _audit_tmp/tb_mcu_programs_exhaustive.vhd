library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_mcu_programs_exhaustive is end;

architecture Behavioral of tb_mcu_programs_exhaustive is
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

    constant CLK_P : time := 10 ns;
    signal clk      : std_logic := '0';
    signal reset    : std_logic := '1';
    signal start    : std_logic := '0';
    signal sel_prog : std_logic_vector(1 downto 0) := (others => '0');
    signal a_in     : std_logic_vector(3 downto 0) := (others => '0');
    signal b_in     : std_logic_vector(3 downto 0) := (others => '0');
    signal selfct   : std_logic_vector(3 downto 0);
    signal selroute : std_logic_vector(3 downto 0);
    signal selout   : std_logic_vector(1 downto 0);
    signal resout   : std_logic_vector(7 downto 0);
    signal done     : std_logic;

    function xnor4(a,b: std_logic_vector(3 downto 0)) return std_logic_vector is
    begin
        return not (a xor b);
    end function;

begin
    clk <= not clk after CLK_P/2;

    u_ctrl: mcu_controller port map(clk, reset, start, sel_prog, selfct, selroute, selout, done);
    u_dp  : datapath port map(clk, reset, a_in, b_in, '0', '0', selfct, selroute, selout, resout, open, open);

    process
        variable expected_mul  : signed(7 downto 0);
        variable sum4          : signed(4 downto 0);
        variable expected_xnor : std_logic_vector(3 downto 0);
        variable expected_bit  : std_logic;
    begin
        wait for 5*CLK_P;
        reset <= '0';
        wait for 2*CLK_P;

        for ai in 0 to 15 loop
            for bi in 0 to 15 loop
                a_in <= std_logic_vector(to_unsigned(ai,4));
                b_in <= std_logic_vector(to_unsigned(bi,4));

                sel_prog <= "00";
                start <= '1'; wait for CLK_P; start <= '0';
                wait until done = '1'; wait for 1 ns;
                expected_mul := signed(a_in) * signed(b_in);
                assert resout = std_logic_vector(expected_mul)
                    report "PROG0 mismatch ai=" & integer'image(ai) & " bi=" & integer'image(bi)
                    severity error;
                wait until rising_edge(clk); wait for 1 ns;

                sel_prog <= "01";
                start <= '1'; wait for CLK_P; start <= '0';
                wait until done = '1'; wait for 1 ns;
                sum4 := resize(signed(a_in),5) + resize(signed(b_in),5);
                expected_xnor := xnor4(std_logic_vector(sum4(3 downto 0)), a_in);
                assert resout(3 downto 0) = expected_xnor
                    report "PROG1 low nibble mismatch ai=" & integer'image(ai) & " bi=" & integer'image(bi)
                    severity error;
                wait until rising_edge(clk); wait for 1 ns;

                sel_prog <= "10";
                start <= '1'; wait for CLK_P; start <= '0';
                wait until done = '1'; wait for 1 ns;
                expected_bit := (a_in(0) and b_in(1)) or (a_in(1) and b_in(0));
                assert resout(0) = expected_bit
                    report "PROG2 bit0 mismatch ai=" & integer'image(ai) & " bi=" & integer'image(bi) &
                           " got=" & std_logic'image(resout(0)) & " exp=" & std_logic'image(expected_bit)
                    severity error;
                wait until rising_edge(clk); wait for 1 ns;
            end loop;
        end loop;

        report "EXHAUSTIVE MCU PROGRAMS PASS" severity note;
        wait;
    end process;
end Behavioral;
