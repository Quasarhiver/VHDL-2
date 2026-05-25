

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity trng is
    Port (
        CLK   : in  STD_LOGIC;                    -- 100 MHz : horloge d'echantillonnage
        RESET : in  STD_LOGIC;                    -- reset asynchrone actif haut
        EN    : in  STD_LOGIC;                    -- '1' = oscillateurs actifs
        RND   : out STD_LOGIC_VECTOR(3 downto 0)  -- entropie 4 bits de-biaisee
    );
end trng;

architecture Behavioral of trng is

    component ring_oscillator is
        Generic ( N_STAGES : integer := 5 );
        Port (
            EN  : in  STD_LOGIC;
            OSC : out STD_LOGIC
        );
    end component;


    constant DECIM : integer := 31;

    signal osc0, osc1, osc2 : STD_LOGIC;
    signal raw_noise        : STD_LOGIC;

    signal meta_ff : STD_LOGIC := '0';   
    signal sync_ff : STD_LOGIC := '0';  

    signal bit_acc : STD_LOGIC := '0';                      
    signal dec_cnt : integer range 0 to DECIM-1 := 0;       
    signal rnd_reg : STD_LOGIC_VECTOR(3 downto 0) := "1011";

   
    attribute ASYNC_REG : string;
    attribute ASYNC_REG of meta_ff : signal is "TRUE";
    attribute ASYNC_REG of sync_ff : signal is "TRUE";

begin

   
    RO0 : ring_oscillator generic map (N_STAGES => 7)
                          port map (EN => EN, OSC => osc0);
    RO1 : ring_oscillator generic map (N_STAGES => 9)
                          port map (EN => EN, OSC => osc1);
    RO2 : ring_oscillator generic map (N_STAGES => 11)
                          port map (EN => EN, OSC => osc2);

    
    raw_noise <= osc0 xor osc1 xor osc2;

    
    process(CLK, RESET)
    begin
        if RESET = '1' then
            meta_ff <= '0';
            sync_ff <= '0';
            bit_acc <= '0';
            dec_cnt <= 0;
            rnd_reg <= "1011";
        elsif rising_edge(CLK) then
           
            meta_ff <= raw_noise;
            sync_ff <= meta_ff;

            
            if dec_cnt = DECIM-1 then
                rnd_reg <= rnd_reg(2 downto 0) & (bit_acc xor sync_ff);
                bit_acc <= '0';
                dec_cnt <= 0;
            else
                bit_acc <= bit_acc xor sync_ff;
                dec_cnt <= dec_cnt + 1;
            end if;
        end if;
    end process;

    RND <= rnd_reg;

end Behavioral;
