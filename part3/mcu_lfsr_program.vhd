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
--               Convention retenue (X^4+X^3+1, decalage gauche) :
--               feedback = bit3 XOR bit2
--               next     = {bit2, bit1, bit0, feedback}
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
    -- Programme (15 instructions) :
    -- feedback = bit3 XOR bit2 ; next = {bit2,bit1,bit0,feedback}
    -- Algorithme : t1=state<<1 ; t2=state XOR t1 ; fb=t2>>3 ; next=t1 OR fb
    --
    --   [0]  BufA <- A_IN (seed)
    --   [1]  MC1  <- A_IN                         (etat initial)
    -- Boucle (LOOP_START=2) :
    --   [2]  BufA <- MC1 ; prep SLA
    --   [3]  MC2  <- SLA(MC1) = t1
    --   [4]  BufA <- MC1                          (re-charger etat courant)
    --   [5]  BufB <- MC2(t1)  ; prep XOR
    --   [6]  MC1  <- state XOR t1 = t2
    --   [7]  BufA <- MC1(t2)  ; prep SRA
    --   [8]  BufA <- t2>>1    ; prep SRA
    --   [9]  BufA <- t2>>2    ; prep SRA
    --   [10] MC1  <- t2>>3 = fb (bit0 = feedback)
    --   [11] BufA <- MC1(fb)
    --   [12] BufB <- MC2(t1)  ; prep OR
    --   [13] MC1  <- fb OR t1 = next
    --   [14] RESOUT <- MC1 ; DONE
    -- =========================================================================
    constant ROM : rom_t := (
        0  => "0001" & "0000" & "00",  -- BufA<-A_IN; prep S=A
        1  => "0000" & "0110" & "00",  -- MC1<-S (=seed)
        2  => "1101" & "1000" & "00",  -- BufA<-MC1(etat); prep SLA  [LOOP_START]
        3  => "0000" & "0111" & "00",  -- MC2<-S (=etat<<1=t1)
        4  => "0000" & "1000" & "00",  -- BufA<-MC1(etat)
        5  => "0111" & "1110" & "00",  -- BufB<-MC2(t1); prep XOR
        6  => "0000" & "0110" & "00",  -- MC1<-S (=etat XOR t1=t2)
        7  => "1100" & "1000" & "00",  -- BufA<-MC1(t2); prep SRA
        8  => "1100" & "0010" & "00",  -- BufA<-S (t2>>1); prep SRA
        9  => "1100" & "0010" & "00",  -- BufA<-S (t2>>2); prep SRA
        10 => "0000" & "0110" & "00",  -- MC1<-S (=t2>>3=fb)
        11 => "0000" & "1000" & "00",  -- BufA<-MC1(fb)
        12 => "0110" & "1110" & "00",  -- BufB<-MC2(t1); prep OR
        13 => "0000" & "0110" & "00",  -- MC1<-S (=fb OR t1=next)
        14 => "0000" & "0000" & "01",  -- RESOUT<-MC1; DONE
        others => "0000" & "0000" & "01"
    );

    constant DIV_MAX    : integer := 99999;
    constant LOOP_START : unsigned(4 downto 0) := to_unsigned(2, 5);
    constant PC_DONE    : unsigned(4 downto 0) := to_unsigned(14, 5);

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
