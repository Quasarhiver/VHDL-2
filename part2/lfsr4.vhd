
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity lfsr4 is
    Port (
        CLK    : in  STD_LOGIC;
        RESET  : in  STD_LOGIC;
        ENABLE : in  STD_LOGIC;
        RND    : out STD_LOGIC_VECTOR(3 downto 0)
    );
end lfsr4;

architecture Behavioral of lfsr4 is

   
    constant DIV_MAX : integer := 99999;

    signal lfsr_reg  : STD_LOGIC_VECTOR(3 downto 0) := "1011";
    signal div_cnt   : integer range 0 to DIV_MAX := 0;
    signal tick_1khz : STD_LOGIC := '0';
    signal feedback  : STD_LOGIC;
    signal step_req  : STD_LOGIC := '0';

begin

   
    feedback <= lfsr_reg(3) xor lfsr_reg(2);

   
    process(CLK, RESET)
    begin
        if RESET = '1' then
            div_cnt   <= 0;
            tick_1khz <= '0';
        elsif rising_edge(CLK) then
            if div_cnt = DIV_MAX then
                div_cnt   <= 0;
                tick_1khz <= '1';
            else
                div_cnt   <= div_cnt + 1;
                tick_1khz <= '0';
            end if;
        end if;
    end process;


    process(CLK, RESET)
    begin
        if RESET = '1' then
            lfsr_reg <= "1011";  -- Seed non-nul
            step_req <= '0';
        elsif rising_edge(CLK) then
            if ENABLE = '1' then
                step_req <= '1';
            end if;

            if tick_1khz = '1' and step_req = '1' then
                lfsr_reg <= lfsr_reg(2 downto 0) & feedback;
                step_req <= '0';
            end if;
        end if;
    end process;

    RND <= lfsr_reg;

end Behavioral;
