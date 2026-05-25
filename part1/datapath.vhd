

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity datapath is
    Port (
        CLK      : in  STD_LOGIC;
        RESET    : in  STD_LOGIC;
        -- Entrées opérandes
        A_IN     : in  STD_LOGIC_VECTOR(3 downto 0);
        B_IN     : in  STD_LOGIC_VECTOR(3 downto 0);
        -- Ports série
        SRINL    : in  STD_LOGIC;
        SRINR    : in  STD_LOGIC;
        -- Contrôle
        SELFCT   : in  STD_LOGIC_VECTOR(3 downto 0);
        SELROUTE : in  STD_LOGIC_VECTOR(3 downto 0);
        SELOUT   : in  STD_LOGIC_VECTOR(1 downto 0);
        -- Sorties
        RESOUT   : out STD_LOGIC_VECTOR(7 downto 0);
        SROUTL   : out STD_LOGIC;
        SROUTR   : out STD_LOGIC
    );
end datapath;

architecture Behavioral of datapath is

   
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


    signal BufferA    : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    signal BufferB    : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    signal MEMCACHE1  : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    signal MEMCACHE2  : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    signal MEMSELFCT  : STD_LOGIC_VECTOR(3 downto 0) := (others => '0');
    signal MEMSELOUT  : STD_LOGIC_VECTOR(1 downto 0) := (others => '0');
    signal MEMSRINL   : STD_LOGIC := '0';
    signal MEMSRINR   : STD_LOGIC := '0';


    signal ual_A      : STD_LOGIC_VECTOR(3 downto 0);
    signal ual_B      : STD_LOGIC_VECTOR(3 downto 0);
    signal ual_S      : STD_LOGIC_VECTOR(7 downto 0);
    signal ual_SROUTL : STD_LOGIC;
    signal ual_SROUTR : STD_LOGIC;

begin

   
    UAL_INST : ual
        port map (
            A       => ual_A,
            B       => ual_B,
            SEL_FCT => MEMSELFCT,
            SRINL   => MEMSRINL,
            SRINR   => MEMSRINR,
            S       => ual_S,
            SROUTL  => ual_SROUTL,
            SROUTR  => ual_SROUTR
        );


    ual_A <= BufferA(3 downto 0);
    ual_B <= BufferB(3 downto 0);

  
    SROUTL <= ual_SROUTL;
    SROUTR <= ual_SROUTR;

 
    process(CLK, RESET)
    begin
        if RESET = '1' then
           
            BufferA   <= (others => '0');
            BufferB   <= (others => '0');
            MEMCACHE1 <= (others => '0');
            MEMCACHE2 <= (others => '0');
            MEMSELFCT <= (others => '0');
            MEMSELOUT <= (others => '0');
            MEMSRINL  <= '0';
            MEMSRINR  <= '0';

        elsif rising_edge(CLK) then

          
            MEMSELFCT <= SELFCT;
            MEMSELOUT <= SELOUT;
            MEMSRINL  <= SRINL;
            MEMSRINR  <= SRINR;

            case SELROUTE is

               
                when "0000" =>
                    BufferA <= "0000" & A_IN;

               
                when "0001" =>
                    BufferB <= "0000" & B_IN;

               
                when "0010" =>
                    BufferA(3 downto 0) <= ual_S(3 downto 0);
                    BufferA(7 downto 4) <= BufferA(7 downto 4);  -- inchangé

               
                when "0011" =>
                    BufferA(7 downto 4) <= ual_S(3 downto 0);
                    BufferA(3 downto 0) <= BufferA(3 downto 0);  -- inchangé

              
                when "0100" =>
                    BufferB(3 downto 0) <= ual_S(3 downto 0);
                    BufferB(7 downto 4) <= BufferB(7 downto 4);

               
                when "0101" =>
                    BufferB(7 downto 4) <= ual_S(3 downto 0);
                    BufferB(3 downto 0) <= BufferB(3 downto 0);


                when "0110" =>
                    MEMCACHE1 <= ual_S;

                
                when "0111" =>
                    MEMCACHE2 <= ual_S;

              
                when "1000" =>
                    BufferA(3 downto 0) <= MEMCACHE1(3 downto 0);
                    BufferA(7 downto 4) <= BufferA(7 downto 4);

               
                when "1001" =>
                    BufferA(3 downto 0) <= MEMCACHE1(7 downto 4);
                    BufferA(7 downto 4) <= BufferA(7 downto 4);

                
                when "1010" =>
                    BufferB(3 downto 0) <= MEMCACHE1(3 downto 0);
                    BufferB(7 downto 4) <= BufferB(7 downto 4);

                when "1011" =>
                    BufferB(3 downto 0) <= MEMCACHE1(7 downto 4);
                    BufferB(7 downto 4) <= BufferB(7 downto 4);

         
                when "1100" =>
                    BufferA(3 downto 0) <= MEMCACHE2(3 downto 0);
                    BufferA(7 downto 4) <= BufferA(7 downto 4);

                
                when "1101" =>
                    BufferA(3 downto 0) <= MEMCACHE2(7 downto 4);
                    BufferA(7 downto 4) <= BufferA(7 downto 4);

              
                when "1110" =>
                    BufferB(3 downto 0) <= MEMCACHE2(3 downto 0);
                    BufferB(7 downto 4) <= BufferB(7 downto 4);

              
                when "1111" =>
                    BufferB(3 downto 0) <= MEMCACHE2(7 downto 4);
                    BufferB(7 downto 4) <= BufferB(7 downto 4);

                when others =>
                    null;  -- aucune opération de routage

            end case;
        end if;
    end process;

    process(MEMSELOUT, MEMCACHE1, MEMCACHE2, ual_S)
    begin
        case MEMSELOUT is
            when "00"   => RESOUT <= (others => '0');  -- Aucune sortie
            when "01"   => RESOUT <= MEMCACHE1;
            when "10"   => RESOUT <= MEMCACHE2;
            when "11"   => RESOUT <= ual_S;
            when others => RESOUT <= (others => '0');
        end case;
    end process;

end Behavioral;
