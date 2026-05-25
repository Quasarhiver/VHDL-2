
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


    signal clk_i     : STD_LOGIC;
    signal reset_i   : STD_LOGIC;
    signal start_i   : STD_LOGIC;
    signal sel_prog_i: STD_LOGIC_VECTOR(1 downto 0);

    signal selfct_i  : STD_LOGIC_VECTOR(3 downto 0);
    signal selroute_i: STD_LOGIC_VECTOR(3 downto 0);
    signal selout_i  : STD_LOGIC_VECTOR(1 downto 0);

    signal resout_i  : STD_LOGIC_VECTOR(7 downto 0);
    signal sroutl_i  : STD_LOGIC;
    signal sroutr_i  : STD_LOGIC;
    signal done_i    : STD_LOGIC;

begin

    clk_i      <= CLK100MHZ;
    reset_i    <= btn(0);            
   
    start_i    <= btn(1) or btn(2) or btn(3);
    sel_prog_i <= "00" when btn(1) = '1' else
                  "01" when btn(2) = '1' else
                  "10" when btn(3) = '1' else
                  "00";

   
    U_CTRL : mcu_controller
        port map (
            CLK      => clk_i,
            RESET    => reset_i,
            START    => start_i,
            SEL_PROG => sel_prog_i,
            SELFCT   => selfct_i,
            SELROUTE => selroute_i,
            SELOUT   => selout_i,
            DONE     => done_i
        );


    U_DP : datapath
        port map (
            CLK      => clk_i,
            RESET    => reset_i,
            A_IN     => sw(3 downto 0),
            B_IN     => sw(3 downto 0),  
            SRINL    => '0',
            SRINR    => '0',
            SELFCT   => selfct_i,
            SELROUTE => selroute_i,
            SELOUT   => selout_i,
            RESOUT   => resout_i,
            SROUTL   => sroutl_i,
            SROUTR   => sroutr_i
        );

    led    <= resout_i(3 downto 0);
    led0_r <= resout_i(4);
    led1_r <= resout_i(5);
    led2_r <= resout_i(6);
    led3_r <= resout_i(7);

    led0_g <= done_i;   
    led0_b <= sroutl_i;  
    led1_b <= sroutr_i; 

   
    led1_g <= '0';
    led2_g <= '0';
    led2_b <= '0';
    led3_g <= '0';
    led3_b <= '0';

end Behavioral;
