

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity seed_generator is
    Port (
        CLK       : in  STD_LOGIC;                   
        BTN_CLEAN : in  STD_LOGIC;                     
        SEED      : out STD_LOGIC_VECTOR(3 downto 0)   
    );
end seed_generator;

architecture Behavioral of seed_generator is

  
    constant DIV_MAX : integer := 99999;

    signal div_cnt  : integer range 0 to DIV_MAX := 0;
    signal ms_tick  : STD_LOGIC := '0';

 
    signal ms_cnt   : unsigned(15 downto 0) := (others => '0');

    signal btn_d    : STD_LOGIC := '0';                 -- btn retarde (front)
    signal seed_reg : STD_LOGIC_VECTOR(3 downto 0) := "1011";

begin

    SEED <= seed_reg;

    process(CLK)
        variable fold : STD_LOGIC_VECTOR(3 downto 0);
    begin
        if rising_edge(CLK) then

           
            if div_cnt = DIV_MAX then
                div_cnt <= 0;
                ms_tick <= '1';
            else
                div_cnt <= div_cnt + 1;
                ms_tick <= '0';
            end if;

           
            btn_d <= BTN_CLEAN;

            if BTN_CLEAN = '1' and btn_d = '0' then
                
                ms_cnt <= (others => '0');

            elsif BTN_CLEAN = '1' then
                
                if ms_tick = '1' then
                    ms_cnt <= ms_cnt + 1;
                end if;

            elsif BTN_CLEAN = '0' and btn_d = '1' then
             
                fold := std_logic_vector(ms_cnt(3 downto 0))
                    xor std_logic_vector(ms_cnt(7 downto 4))
                    xor std_logic_vector(ms_cnt(11 downto 8))
                    xor std_logic_vector(ms_cnt(15 downto 12));

                if fold = "0000" then
                    -- Seed nulle interdite : on force une valeur non nulle
                    seed_reg <= "1011";
                else
                    seed_reg <= fold;
                end if;
            end if;

        end if;
    end process;

end Behavioral;
