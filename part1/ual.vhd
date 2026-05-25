
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ual is
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
end ual;

architecture Behavioral of ual is

begin

  
    process(A, B, SEL_FCT, SRINL, SRINR)
        variable vA       : signed(4 downto 0);
        variable vB       : signed(4 downto 0);
        variable vMul     : signed(7 downto 0);
        variable sum_s    : signed(4 downto 0);
        variable diff_s   : signed(4 downto 0);
        variable shifted  : std_logic_vector(3 downto 0);
    begin
    
        S      <= (others => '0');
        SROUTL <= '0';
        SROUTR <= '0';

        vA       := resize(signed(A), 5);
        vB       := resize(signed(B), 5);
        vMul     := signed(A) * signed(B);  -- multiplication 4b × 4b → 8b
        sum_s    := (others => '0');
        diff_s   := (others => '0');
        shifted  := (others => '0');

        case SEL_FCT is


            when "0000" =>
                S      <= (others => '0');
                SROUTL <= '0';
                SROUTR <= '0';

         
            when "0001" =>
                S      <= std_logic_vector(resize(signed(A), 8));
                SROUTL <= '0';
                SROUTR <= '0';

       
            when "0010" =>
                S      <= std_logic_vector(not resize(signed(A), 8));
                SROUTL <= '0';
                SROUTR <= '0';

         
            when "0011" =>
                S      <= std_logic_vector(resize(signed(B), 8));
                SROUTL <= '0';
                SROUTR <= '0';

      
            when "0100" =>
                S      <= std_logic_vector(not resize(signed(B), 8));
                SROUTL <= '0';
                SROUTR <= '0';

         
            when "0101" =>
                S      <= "0000" & (A and B);
                SROUTL <= '0';
                SROUTR <= '0';

         
            when "0110" =>
                S      <= "0000" & (A or B);
                SROUTL <= '0';
                SROUTR <= '0';

            when "0111" =>
                S      <= "0000" & (A xor B);
                SROUTL <= '0';
                SROUTR <= '0';

            when "1000" =>
                sum_s := vA + vB;
                if SRINR = '1' then
                    sum_s := sum_s + to_signed(1, 5);
                end if;
                S      <= std_logic_vector(resize(sum_s, 8));
                SROUTL <= '0';
                SROUTR <= '0';

            when "1001" =>
                sum_s := vA + vB;
                S      <= std_logic_vector(resize(sum_s, 8));
                SROUTL <= '0';
                SROUTR <= '0';

           
            when "1010" =>
                diff_s := vA - vB;
                S      <= std_logic_vector(resize(diff_s, 8));
                SROUTL <= '0';
                SROUTR <= '0';

         
            when "1011" =>
                S      <= std_logic_vector(vMul);
                SROUTL <= '0';
                SROUTR <= '0';

          
            when "1100" =>
                shifted := SRINL & A(3 downto 1);
                S       <= "0000" & shifted;
                SROUTL  <= '0';
                SROUTR  <= A(0);

            
            when "1101" =>
                shifted := A(2 downto 0) & SRINR;
                S       <= "0000" & shifted;
                SROUTL  <= A(3);
                SROUTR  <= '0';

            when "1110" =>
                shifted := SRINL & B(3 downto 1);
                S       <= "0000" & shifted;
                SROUTL  <= '0';
                SROUTR  <= B(0);

     
            when "1111" =>
                shifted := B(2 downto 0) & SRINR;
                S       <= "0000" & shifted;
                SROUTL  <= B(3);
                SROUTR  <= '0';

            when others =>
                S      <= (others => '0');
                SROUTL <= '0';
                SROUTR <= '0';

        end case;
    end process;

end Behavioral;
