
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity mcu_controller is
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
end mcu_controller;

architecture Behavioral of mcu_controller is

   
    type rom_type  is array (0 to 127) of STD_LOGIC_VECTOR(9 downto 0);
    type fsm_state is (IDLE, RUN, DONE_ST);


    constant NOP_INSTR : STD_LOGIC_VECTOR(9 downto 0) := "0000000000";


 
 
   

    constant ROM : rom_type := (
       
        0  => "0000" & "0000" & "00",  -- BufferA <- A_IN
        1  => "1011" & "0001" & "00",  -- BufferB <- B_IN ; préparer MUL
        2  => "0000" & "0110" & "00",  -- MC1 <- A*B
        3  => "0000" & "0000" & "01",  -- Affichage MC1, maintien sûr en DONE
        4  => "0000" & "0000" & "01",
        5  => "0000" & "0000" & "01",
        6  => "0000" & "0000" & "01",
        7  => "0000" & "0000" & "01",
       
        8  => "0000" & "0000" & "00",  -- BufferA <- A_IN
        9  => "1001" & "0001" & "00",  -- BufferB <- B_IN ; préparer ADD
        10 => "0000" & "0110" & "00",  -- MC1 <- A + B
        11 => "0111" & "1010" & "00",  -- BufferB <- MC1[3:0] ; préparer XOR
        12 => "0100" & "0100" & "00",  -- BufferB <- A xor (A+B) ; préparer notB
        13 => "0000" & "0110" & "00",  -- MC1 <- not(BufferB)
        14 => "0000" & "0000" & "01",  -- Affichage MC1, maintien sûr en DONE
        15 => "0000" & "0000" & "01",
       
        20 => "0000" & "0000" & "00",  -- BufferA <- A_IN
        21 => "1100" & "0001" & "00",  -- BufferB <- B_IN ; préparer SRA(A)
        22 => "0000" & "0110" & "00",  -- MC1 <- A>>1
        23 => "0101" & "1000" & "00",  -- BufferA <- MC1[3:0] ; préparer AND
        24 => "1110" & "0111" & "00",  -- MC2 <- (A>>1) AND B ; préparer SRB(B)
        25 => "0000" & "0110" & "00",  -- MC1 <- B>>1
        26 => "0000" & "1010" & "00",  -- BufferB <- MC1[3:0]
        27 => "0101" & "0000" & "00",  -- BufferA <- A_IN ; préparer AND
        28 => "0000" & "0110" & "00",  -- MC1 <- A AND (B>>1)
        29 => "0000" & "1100" & "00",  -- BufferA <- MC2[3:0]
        30 => "0110" & "1010" & "00",  -- BufferB <- MC1[3:0] ; préparer OR
        31 => "0000" & "0110" & "00",  -- MC1 <- terme1 OR terme2
        32 => "0000" & "0000" & "01",  -- Affichage MC1, maintien sûr en DONE
        35 => "0000" & "0000" & "01",
        
        others => NOP_INSTR
    );

 
    signal state    : fsm_state := IDLE;
    signal pc       : unsigned(6 downto 0) := (others => '0');  -- Program Counter 7 bits
    signal prog_base: unsigned(6 downto 0) := (others => '0');  -- Adresse de base du programme
    signal prog_end : unsigned(6 downto 0) := (others => '0');  -- Adresse de fin (DONE instr)
    signal instr    : STD_LOGIC_VECTOR(9 downto 0);
    signal start_d  : STD_LOGIC := '0';  -- Mémorisation front START

begin


    instr    <= ROM(to_integer(pc));
    SELFCT   <= instr(9 downto 6);
    SELROUTE <= instr(5 downto 2);
    SELOUT   <= instr(1 downto 0);


    process(SEL_PROG)
    begin
        case SEL_PROG is
            when "00"   => prog_base <= to_unsigned(0,  7); prog_end <= to_unsigned(3,  7);
            when "01"   => prog_base <= to_unsigned(8,  7); prog_end <= to_unsigned(14, 7);
            when "10"   => prog_base <= to_unsigned(20, 7); prog_end <= to_unsigned(32, 7);
            when others => prog_base <= to_unsigned(0,  7); prog_end <= to_unsigned(3,  7);
        end case;
    end process;


    process(CLK, RESET)
    begin
        if RESET = '1' then
            state   <= IDLE;
            pc      <= (others => '0');
            DONE    <= '0';
            start_d <= '0';

        elsif rising_edge(CLK) then
            start_d <= START;

            case state is

             
                when IDLE =>
                    DONE <= '0';
                    if START = '1' and start_d = '0' then  -- front montant
                        pc    <= prog_base;
                        state <= RUN;
                    end if;

             
                when RUN =>
                    DONE <= '0';
                    if pc = prog_end then
                        state <= DONE_ST;
                    else
                        pc <= pc + 1;
                    end if;

             
                when DONE_ST =>
                    DONE <= '1';
                    
                    if START = '1' and start_d = '0' then
                        pc    <= prog_base;
                        DONE  <= '0';
                        state <= RUN;
                    end if;

                when others =>
                    state <= IDLE;

            end case;
        end if;
    end process;

end Behavioral;
