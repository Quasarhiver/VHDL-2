library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_response_checker_multibtn is end;
architecture Behavioral of tb_response_checker_multibtn is
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
    signal clk : std_logic := '0';
    signal reset, enable, timeout, btn_r, btn_g, btn_b, valid_hit, error : std_logic := '0';
    signal led_color : std_logic_vector(2 downto 0) := "100";
begin
    clk <= not clk after CLK_P/2;
    dut: response_checker port map(clk, reset, enable, timeout, led_color, btn_r, btn_g, btn_b, valid_hit, error);
    process begin
        reset <= '1'; wait for 30 ns; reset <= '0'; enable <= '1';
        wait until rising_edge(clk);
        btn_r <= '1'; btn_g <= '1';
        wait until rising_edge(clk); wait for 1 ns;
        report "valid_hit=" & std_logic'image(valid_hit) & " error=" & std_logic'image(error) severity note;
        wait;
    end process;
end;
