-- =============================================================================
-- Module      : mcu_lfsr_program.vhd
-- Description : Sequenceur MCU dedie a la generation pseudo-aleatoire.
--               Le datapath reste cadence a 100 MHz, mais une nouvelle valeur
--               LFSR n'est demande qu'une fois par tick 1 kHz.
--
--               Le registre pseudo-aleatoire est stocke dans MEMCACHE1[3:0].
--               Au premier lancement apres reset, le sequenceur initialise
--               MEMCACHE1 a "1011" via A_IN, puis calcule l'etat suivant.
--               Aux lancements suivants, seule l'etape de mise a jour LFSR est
--               executee.
--
--               Convention retenue :
--               feedback = bit3 XOR bit0
--               next     = {feedback, bit3, bit2, bit1}
-- =============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity mcu_lfsr_program is
    Port (
        CLK      : in  STD_LOGIC;
        RESET    : in  STD_LOGIC;
        START    : in  STD_LOGIC;
        SELFCT   : out STD_LOGIC_VECTOR(3 downto 0);
        SELROUTE : out STD_LOGIC_VECTOR(3 downto 0);
        SELOUT   : out STD_LOGIC_VECTOR(1 downto 0);
        DONE     : out STD_LOGIC
    );
end mcu_lfsr_program;

architecture Behavioral of mcu_lfsr_program is

    type rom_t is array (0 to 31) of STD_LOGIC_VECTOR(9 downto 0);
    type state_t is (IDLE, RUN, DONE_ST);

    -- =========================================================================
    -- Programme :
    -- Le datapath consomme SELFCT avec une latence d'un cycle. La ROM ci-dessous
    -- alterne donc les cycles de preparation UAL et les cycles de capture.
    --
    --   [0]  BufA <- A_IN = 1011, preparer A
    --   [1]  MC1  <- A
    --
    -- Boucle LFSR :
    --   [2]  BufA <- MC1, preparer SLA
    --   [3]  BufA <- A<<1, preparer SLA
    --   [4]  BufA <- A<<2, preparer SLA
    --   [5]  MC2  <- A<<3            = {b0,0,0,0}
    --   [6]  BufA <- MC2, preparer SRA
    --   [7]  BufA <- ..., preparer SRA
    --   [8]  BufA <- ..., preparer SRA
    --   [9]  MC2  <- ...             = {0,0,0,b0}
    --   [10] BufA <- MC1, preparer SRA
    --   [11] BufA <- ..., preparer SRA
    --   [12] BufA <- ..., preparer SRA
    --   [13] BufB <- ...             = {0,0,0,b3}
    --   [14] BufA <- MC2, preparer XOR
    --   [15] BufB <- feedback, preparer SLB
    --   [16] BufB <- ..., preparer SLB
    --   [17] BufB <- ..., preparer SLB
    --   [18] MC2  <- ...             = {feedback,0,0,0}
    --   [19] BufA <- MC1, preparer SRA
    --   [20] BufA <- state>>1
    --   [21] BufB <- MC2, preparer OR
    --   [22] MC1  <- next_state
    --   [23] RESOUT <- MC1
    -- =========================================================================
    constant ROM : rom_t := (
        0  => "0001" & "0000" & "00",  -- BufA<-A_IN, preparer A
        1  => "0000" & "0110" & "00",  -- MC1<-A
        2  => "1101" & "1000" & "00",  -- BufA<-MC1, preparer SLA
        3  => "1101" & "0010" & "00",  -- BufA<-S,  preparer SLA
        4  => "1101" & "0010" & "00",  -- BufA<-S,  preparer SLA
        5  => "0000" & "0111" & "00",  -- MC2<-S
        6  => "1100" & "1100" & "00",  -- BufA<-MC2, preparer SRA
        7  => "1100" & "0010" & "00",  -- BufA<-S,  preparer SRA
        8  => "1100" & "0010" & "00",  -- BufA<-S,  preparer SRA
        9  => "0000" & "0111" & "00",  -- MC2<-S
        10 => "1100" & "1000" & "00",  -- BufA<-MC1, preparer SRA
        11 => "1100" & "0010" & "00",  -- BufA<-S,  preparer SRA
        12 => "1100" & "0010" & "00",  -- BufA<-S,  preparer SRA
        13 => "0000" & "0100" & "00",  -- BufB<-S
        14 => "0111" & "1100" & "00",  -- BufA<-MC2, preparer XOR
        15 => "1111" & "0100" & "00",  -- BufB<-S,  preparer SLB
        16 => "1111" & "0100" & "00",  -- BufB<-S,  preparer SLB
        17 => "1111" & "0100" & "00",  -- BufB<-S,  preparer SLB
        18 => "0000" & "0111" & "00",  -- MC2<-S
        19 => "1100" & "1000" & "00",  -- BufA<-MC1, preparer SRA
        20 => "0000" & "0010" & "00",  -- BufA<-S
        21 => "0110" & "1110" & "00",  -- BufB<-MC2, preparer OR
        22 => "0000" & "0110" & "00",  -- MC1<-S
        23 => "0000" & "0000" & "01",  -- RESOUT=MC1
        others => "0000" & "0000" & "01"
    );

    constant DIV_MAX    : integer := 99999;
    constant LOOP_START : unsigned(4 downto 0) := to_unsigned(2, 5);
    constant PC_DONE    : unsigned(4 downto 0) := to_unsigned(23, 5);

    signal div_cnt      : integer range 0 to DIV_MAX := 0;
    signal tick_1khz    : STD_LOGIC := '0';

    signal state        : state_t := IDLE;
    signal pc           : unsigned(4 downto 0) := (others => '0');
    signal instr        : STD_LOGIC_VECTOR(9 downto 0);
    signal done_r       : STD_LOGIC := '0';
    signal run_req      : STD_LOGIC := '0';
    signal initialized  : STD_LOGIC := '0';

begin

    instr    <= ROM(to_integer(pc));
    SELFCT   <= instr(9 downto 6);
    SELROUTE <= instr(5 downto 2);
    SELOUT   <= instr(1 downto 0);
    DONE     <= done_r;

    -- =========================================================================
    -- Diviseur 100 MHz -> 1 kHz
    -- =========================================================================
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

    -- =========================================================================
    -- Sequenceur :
    -- - START demande une nouvelle valeur pseudo-aleatoire
    -- - la demande est servie au prochain tick 1 kHz
    -- - ensuite les instructions s'enchainent a 100 MHz, une seule fois chacune
    -- =========================================================================
    process(CLK, RESET)
    begin
        if RESET = '1' then
            state       <= IDLE;
            pc          <= (others => '0');
            done_r      <= '0';
            run_req     <= '0';
            initialized <= '0';

        elsif rising_edge(CLK) then
            done_r <= '0';

            if START = '1' then
                run_req <= '1';
            end if;

            case state is
                when IDLE =>
                    if tick_1khz = '1' and (run_req = '1' or START = '1') then
                        if initialized = '1' then
                            pc <= LOOP_START;
                        else
                            pc <= (others => '0');
                        end if;
                        run_req <= '0';
                        state   <= RUN;
                    end if;

                when RUN =>
                    if pc = PC_DONE then
                        done_r      <= '1';
                        initialized <= '1';
                        state       <= DONE_ST;
                    else
                        pc <= pc + 1;
                    end if;

                when DONE_ST =>
                    state <= IDLE;

                when others =>
                    state <= IDLE;
            end case;
        end if;
    end process;

end Behavioral;
