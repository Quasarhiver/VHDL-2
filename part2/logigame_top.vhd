

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Arty_Digilent_TopLevel is
    Port (
        CLK100MHZ : in  STD_LOGIC;
        sw        : in  STD_LOGIC_VECTOR(3 downto 0);
        btn       : in  STD_LOGIC_VECTOR(3 downto 0);
        led       : out STD_LOGIC_VECTOR(3 downto 0);
        led0_r    : out STD_LOGIC; led0_g : out STD_LOGIC; led0_b : out STD_LOGIC;
        led1_r    : out STD_LOGIC; led1_g : out STD_LOGIC; led1_b : out STD_LOGIC;
        led2_r    : out STD_LOGIC; led2_g : out STD_LOGIC; led2_b : out STD_LOGIC;
        led3_r    : out STD_LOGIC; led3_g : out STD_LOGIC; led3_b : out STD_LOGIC
    );
end Arty_Digilent_TopLevel;

architecture Behavioral of Arty_Digilent_TopLevel is

    component game_controller is
        Port (
            CLK        : in  STD_LOGIC;
            RESET      : in  STD_LOGIC;
            START      : in  STD_LOGIC;
            BTN_R      : in  STD_LOGIC;
            BTN_G      : in  STD_LOGIC;
            BTN_B      : in  STD_LOGIC;
            SW_LEVEL   : in  STD_LOGIC_VECTOR(1 downto 0);
            LED3_R     : out STD_LOGIC;
            LED3_G     : out STD_LOGIC;
            LED3_B     : out STD_LOGIC;
            LED0_R     : out STD_LOGIC;
            LED0_G     : out STD_LOGIC;
            LED0_B     : out STD_LOGIC;
            SCORE_OUT  : out STD_LOGIC_VECTOR(3 downto 0)
        );
    end component;

    signal score_s    : STD_LOGIC_VECTOR(3 downto 0);
    signal btn0_d     : STD_LOGIC := '0';
    signal start_pulse: STD_LOGIC := '0';

begin


    process(CLK100MHZ)
    begin
        if rising_edge(CLK100MHZ) then
            start_pulse <= '0';
            if btn0_d = '1' and btn(0) = '0' then
                start_pulse <= '1';
            end if;
            btn0_d <= btn(0);
        end if;
    end process;

    U_GAME : game_controller
        port map (
            CLK       => CLK100MHZ,
            RESET     => btn(0),
            START     => start_pulse,
            BTN_R     => btn(3),
            BTN_G     => btn(2),
            BTN_B     => btn(1),
            SW_LEVEL  => sw(3 downto 2),
            LED3_R    => led3_r,
            LED3_G    => led3_g,
            LED3_B    => led3_b,
            LED0_R    => led0_r,
            LED0_G    => led0_g,
            LED0_B    => led0_b,
            SCORE_OUT => score_s
        );

  
    led <= score_s;

    
    led1_r <= '0'; led1_g <= '0'; led1_b <= '0';
    led2_r <= '0'; led2_g <= '0'; led2_b <= '0';

end Behavioral;
