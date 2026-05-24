library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Arty_Digilent_TopLevel is
    Port (
        CLK100MHZ : in STD_LOGIC;
        sw        : in STD_LOGIC_VECTOR(3 downto 0);
        btn       : in STD_LOGIC_VECTOR(3 downto 0);
        led       : out STD_LOGIC_VECTOR(3 downto 0);
        led0_r : out STD_LOGIC; led0_g : out STD_LOGIC; led0_b : out STD_LOGIC;                
        led1_r : out STD_LOGIC; led1_g : out STD_LOGIC; led1_b : out STD_LOGIC;
        led2_r : out STD_LOGIC; led2_g : out STD_LOGIC; led2_b : out STD_LOGIC;                
        led3_r : out STD_LOGIC; led3_g : out STD_LOGIC; led3_b : out STD_LOGIC
    );
end Arty_Digilent_TopLevel;

architecture Behavioral of Arty_Digilent_TopLevel is

    -- Déclarer ci-dessous votre component synthcomb01
    
    -- Fin de déclaration du component synthcomb01

    
    -- déclaration des constantes et signaux internes 
    constant N : integer := 2;
    
    signal my_e1 : std_logic_vector (N-1 downto 0);
    signal my_e2 : std_logic_vector (N-1 downto 0);
    signal my_c_in : std_logic;
    signal my_sel : std_logic;
    signal my_s1 : std_logic_vector (2*N-1 downto 0);

begin

    -- Instancier ci-dessous votre component synthcomb01 (penser aux generic map et port map)
    
    -- Fin d'instanciation du component synthcomb01
    

    -- Connexions des signaux internes aux entrées et aux sorties

    -- Fin de connexion des signaux internes aux entrées et aux sorties
    

    -- Mise à 0 des leds de couleurs RGB
    led0_r <= '0'; led0_g <= '0'; led0_b <= '0';
    led1_r <= '0'; led1_g <= '0'; led1_b <= '0';
    led2_r <= '0'; led2_g <= '0'; led2_b <= '0';
    led3_r <= '0'; led3_g <= '0'; led3_b <= '0';
    
end Behavioral;
