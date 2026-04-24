-- =============================================================================
-- Module      : mcu_lfsr_program.vhd
-- Description : Sequenceur MCU dedie a la generation pseudo-aleatoire.
--               Conforme au PDF : feedback = bit3 XOR bit2 (X^4 + X^3 + 1)
--               Decalage gauche : next = {b2, b1, b0, feedback}
--               Sequence identique au lfsr4.vhd corrige (15 etats).
--
--               Premiere execution (initialized=0) : init seed "1011" + boucle.
--               Executions suivantes (initialized=1) : boucle seule (addr 2-21).
--
-- Corrections v2.0 :
--   - feedback corrige (bit3 XOR bit2 au lieu de bit3 XOR bit0)
--   - decalage gauche (next = {b2,b1,b0,feedback})
--   - ROM entierement reecrite (20 etapes de boucle, adresses 2-21)
--   - PC_DONE mis a jour de 23 a 21
-- Auteur      : Projet LogiGame - TE608 EFREI 2025-2026
-- Cible       : Xilinx Artix-35T - Vivado / GHDL
-- Revision    : 2.0 - Avril 2026
-- =============================================================================
-- Programme ROM (SELFCT[9:6] | SELROUTE[5:2] | SELOUT[1:0]) :
--
-- Init (addr 0-1) :
--   [0] BufA <- A_IN="1011"  ; SELFCT=A,   SELROUTE=BufA<-A_IN
--   [1] MC1  <- A (seed)     ; SELFCT=NOP, SELROUTE=MC1<-S
--
-- Boucle (addr 2-21), etat courant MC1[3:0]={b3,b2,b1,b0} :
--
--   Phase A - {0,0,0,b3} dans MC2 (SRA x3) :
--   [2]  SELFCT=SRA, BufA <- MC1[3:0]
--   [3]  SELFCT=SRA, BufA <- S={0,b3,b2,b1}
--   [4]  SELFCT=SRA, BufA <- S={0,0,b3,b2}
--   [5]  SELFCT=NOP, MC2  <- S={0,0,0,b3}
--
--   Phase B - {0,0,b3,b2} dans BufB (SRA x2) :
--   [6]  SELFCT=SRA, BufA <- MC1[3:0]
--   [7]  SELFCT=SRA, BufA <- S={0,b3,b2,b1}
--   [8]  SELFCT=NOP, BufB <- S={0,0,b3,b2}
--
--   Phase C - XOR(MC2,BufB) -> {0,0,b3,feedback} dans BufA :
--   [9]  SELFCT=XOR, BufA <- MC2[3:0]={0,0,0,b3}
--   [10] SELFCT=SLA, BufA <- S=XOR={0,0,b3,feedback}
--
--   Phase D - SLA x3 -> {feedback,0,0,0} dans MC2 :
--   [11] SELFCT=SLA, BufA <- S={0,b3,feedback,0}
--   [12] SELFCT=SLA, BufA <- S={b3,feedback,0,0}
--   [13] SELFCT=NOP, MC2  <- S={feedback,0,0,0}
--
--   Phase E - SLA(MC1) -> {b2,b1,b0,0} dans BufA :
--   [14] SELFCT=SLA, BufA <- MC1[3:0]
--   [15] SELFCT=NOP, BufA <- S={b2,b1,b0,0}
--
--   Phase F - SRB x3 -> {0,0,0,feedback} dans BufB :
--   [16] SELFCT=SRB, BufB <- MC2[3:0]={feedback,0,0,0}
--   [17] SELFCT=SRB, BufB <- S={0,feedback,0,0}
--   [18] SELFCT=SRB, BufB <- S={0,0,feedback,0}
--   [19] SELFCT=OR,  BufB <- S={0,0,0,feedback}
--
--   Phase G - OR(BufA,BufB) -> {b2,b1,b0,feedback} dans MC1 :
--   [20] SELFCT=NOP, MC1  <- S={b2,b1,b0,feedback}
--
--   Phase H - affichage :
--   [21] SELFCT=NOP, SELOUT=01 -> RESOUT=MC1
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

    type rom_t   is array (0 to 31) of STD_LOGIC_VECTOR(9 downto 0);
    type state_t is (IDLE, RUN, DONE_ST);

    -- =========================================================================
    -- ROM 32 x 10 bits
    -- =========================================================================
    constant ROM : rom_t := (
        -- Initialisation
        0  => "0001" & "0000" & "00",  -- SELFCT=A,   BufA <- A_IN="1011"
        1  => "0000" & "0110" & "00",  -- SELFCT=NOP, MC1  <- A (seed "1011")

        -- Phase A : {0,0,0,b3} -> MC2
        2  => "1100" & "1000" & "00",  -- SELFCT=SRA, BufA <- MC1[3:0]
        3  => "1100" & "0010" & "00",  -- SELFCT=SRA, BufA <- S={0,b3,b2,b1}
        4  => "1100" & "0010" & "00",  -- SELFCT=SRA, BufA <- S={0,0,b3,b2}
        5  => "0000" & "0111" & "00",  -- SELFCT=NOP, MC2  <- S={0,0,0,b3}

        -- Phase B : {0,0,b3,b2} -> BufB
        6  => "1100" & "1000" & "00",  -- SELFCT=SRA, BufA <- MC1[3:0]
        7  => "1100" & "0010" & "00",  -- SELFCT=SRA, BufA <- S={0,b3,b2,b1}
        8  => "0000" & "0100" & "00",  -- SELFCT=NOP, BufB <- S={0,0,b3,b2}

        -- Phase C : XOR -> {0,0,b3,feedback} dans BufA
        9  => "0111" & "1100" & "00",  -- SELFCT=XOR, BufA <- MC2[3:0]={0,0,0,b3}
        10 => "1101" & "0010" & "00",  -- SELFCT=SLA, BufA <- S=XOR={0,0,b3,feedback}

        -- Phase D : SLA x3 -> {feedback,0,0,0} dans MC2
        11 => "1101" & "0010" & "00",  -- SELFCT=SLA, BufA <- S={0,b3,feedback,0}
        12 => "1101" & "0010" & "00",  -- SELFCT=SLA, BufA <- S={b3,feedback,0,0}
        13 => "0000" & "0111" & "00",  -- SELFCT=NOP, MC2  <- S={feedback,0,0,0}

        -- Phase E : SLA(MC1) -> {b2,b1,b0,0} dans BufA
        14 => "1101" & "1000" & "00",  -- SELFCT=SLA, BufA <- MC1[3:0]
        15 => "0000" & "0010" & "00",  -- SELFCT=NOP, BufA <- S={b2,b1,b0,0}

        -- Phase F : SRB x3 -> {0,0,0,feedback} dans BufB
        16 => "1110" & "1110" & "00",  -- SELFCT=SRB, BufB <- MC2[3:0]={feedback,0,0,0}
        17 => "1110" & "0100" & "00",  -- SELFCT=SRB, BufB <- S={0,feedback,0,0}
        18 => "1110" & "0100" & "00",  -- SELFCT=SRB, BufB <- S={0,0,feedback,0}
        19 => "0110" & "0100" & "00",  -- SELFCT=OR,  BufB <- S={0,0,0,feedback}

        -- Phase G : OR -> next_state dans MC1
        20 => "0000" & "0110" & "00",  -- SELFCT=NOP, MC1  <- S={b2,b1,b0,feedback}

        -- Phase H : affichage
        21 => "0000" & "0000" & "01",  -- SELFCT=NOP, SELOUT=01 -> RESOUT=MC1

        others => "0000" & "0000" & "01"
    );

    constant LOOP_START : unsigned(4 downto 0) := to_unsigned(2,  5);
    constant PC_DONE    : unsigned(4 downto 0) := to_unsigned(21, 5);

    signal state        : state_t   := IDLE;
    signal pc           : unsigned(4 downto 0) := (others => '0');
    signal instr        : STD_LOGIC_VECTOR(9 downto 0);
    signal done_r       : STD_LOGIC := '0';
    signal initialized  : STD_LOGIC := '0';
    signal start_d      : STD_LOGIC := '0';

begin

    instr    <= ROM(to_integer(pc));
    SELFCT   <= instr(9 downto 6);
    SELROUTE <= instr(5 downto 2);
    SELOUT   <= instr(1 downto 0);
    DONE     <= done_r;

    -- =========================================================================
    -- Sequenceur
    -- =========================================================================
    process(CLK, RESET)
    begin
        if RESET = '1' then
            state       <= IDLE;
            pc          <= (others => '0');
            done_r      <= '0';
            initialized <= '0';
            start_d     <= '0';

        elsif rising_edge(CLK) then
            done_r <= '0';
            start_d <= START;

            case state is

                when IDLE =>
                    if START = '1' and start_d = '0' then
                        if initialized = '1' then
                            pc <= LOOP_START;
                        else
                            pc <= (others => '0');
                        end if;
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
