
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity button_debouncer is
    Generic (
        
        DEBOUNCE_CYCLES : integer := 200000
    );
    Port (
        CLK       : in  STD_LOGIC;   
        BTN_RAW   : in  STD_LOGIC;  
        BTN_CLEAN : out STD_LOGIC    
    );
end button_debouncer;

architecture Behavioral of button_debouncer is

    signal sync_0  : STD_LOGIC := '0';  
    signal sync_1  : STD_LOGIC := '0';  
    signal clean_r : STD_LOGIC := '0';  
    signal cnt     : integer range 0 to DEBOUNCE_CYCLES := 0;

   
    attribute ASYNC_REG : string;
    attribute ASYNC_REG of sync_0 : signal is "TRUE";
    attribute ASYNC_REG of sync_1 : signal is "TRUE";

begin

    BTN_CLEAN <= clean_r;

    process(CLK)
    begin
        if rising_edge(CLK) then
         
            sync_0 <= BTN_RAW;
            sync_1 <= sync_0;

          
            if sync_1 = clean_r then
                cnt <= 0;
            elsif cnt = DEBOUNCE_CYCLES - 1 then
                clean_r <= sync_1;
                cnt     <= 0;
            else
                cnt <= cnt + 1;
            end if;
        end if;
    end process;

end Behavioral;
