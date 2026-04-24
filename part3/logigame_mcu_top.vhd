-- =============================================================================
-- Module      : logigame_mcu_top.vhd  (Arty_Digilent_TopLevel - Partie 3)
-- Description : Top-level final du projet LogiGame.
--               La partie 3 remplace le LFSR de la partie 2 par un coeur MCU
--               pilote par microprogramme.
--
--               Architecture :
--                 - un diviseur cree une horloge MCU a 1 kHz depuis CLK100MHZ
--                 - mcu_lfsr_program fournit les micro-instructions
--                 - datapath execute ces micro-instructions et livre l'etat LFSR
--                 - la FSM de jeu reutilise timer, score et response_checker
--                 - la couleur de LD3 est derivee via un vrai modulo 3
-- Auteur      : Projet LogiGame - TE608 EFREI 2025-2026
-- Cible       : Xilinx Artix-35T - Vivado
-- Revision    : 2.0 - Avril 2026
-- =============================================================================

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

    component mcu_lfsr_program is
        Port (
            CLK      : in  STD_LOGIC;
            RESET    : in  STD_LOGIC;
            START    : in  STD_LOGIC;
            SELFCT   : out STD_LOGIC_VECTOR(3 downto 0);
            SELROUTE : out STD_LOGIC_VECTOR(3 downto 0);
            SELOUT   : out STD_LOGIC_VECTOR(1 downto 0);
            DONE     : out STD_LOGIC
        );
    end component;

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

    component difficulty_timer is
        Port (
            CLK      : in  STD_LOGIC;
            RESET    : in  STD_LOGIC;
            START    : in  STD_LOGIC;
            SW_LEVEL : in  STD_LOGIC_VECTOR(1 downto 0);
            TIMEOUT  : out STD_LOGIC
        );
    end component;

    component score_counter is
        Port (
            CLK       : in  STD_LOGIC;
            RESET     : in  STD_LOGIC;
            VALID_HIT : in  STD_LOGIC;
            ERROR     : in  STD_LOGIC;
            SCORE     : out STD_LOGIC_VECTOR(3 downto 0);
            GAME_OVER : out STD_LOGIC
        );
    end component;

    component response_checker is
        Port (
            CLK       : in  STD_LOGIC;
            RESET     : in  STD_LOGIC;
            ENABLE    : in  STD_LOGIC;
            TIMEOUT   : in  STD_LOGIC;
            LED_COLOR : in  STD_LOGIC_VECTOR(2 downto 0);
            BTN_R     : in  STD_LOGIC;
            BTN_G     : in  STD_LOGIC;
            BTN_B     : in  STD_LOGIC;
            VALID_HIT : out STD_LOGIC;
            ERROR     : out STD_LOGIC
        );
    end component;

    signal clk_i         : STD_LOGIC;
    signal clk_mcu       : STD_LOGIC := '0';
    signal reset_i       : STD_LOGIC;
    signal mcu_divcnt    : integer range 0 to 49_999 := 0;

    signal selfct_s      : STD_LOGIC_VECTOR(3 downto 0);
    signal selroute_s    : STD_LOGIC_VECTOR(3 downto 0);
    signal selout_s      : STD_LOGIC_VECTOR(1 downto 0);
    signal mcu_done      : STD_LOGIC;
    signal mcu_done_meta : STD_LOGIC := '0';
    signal mcu_done_sync : STD_LOGIC := '0';
    signal mcu_start     : STD_LOGIC := '0';

    signal resout_s      : STD_LOGIC_VECTOR(7 downto 0);
    signal led_color_s   : STD_LOGIC_VECTOR(2 downto 0);

    signal timer_start   : STD_LOGIC;
    signal timeout_s     : STD_LOGIC;

    signal valid_hit_s   : STD_LOGIC;
    signal error_s       : STD_LOGIC;
    signal score_s       : STD_LOGIC_VECTOR(3 downto 0);
    signal gameover_s    : STD_LOGIC;
    signal score_rst     : STD_LOGIC;

    signal checker_en    : STD_LOGIC;

    type fsm_t is (IDLE, WAIT_MCU, WAIT_RESPONSE, END_GAME);
    signal state         : fsm_t  := IDLE;
    signal btn0_d        : STD_LOGIC := '0';
    signal start_pulse   : STD_LOGIC := '0';

    signal led3_r_s, led3_g_s, led3_b_s : STD_LOGIC;
    signal led0_r_s, led0_g_s, led0_b_s : STD_LOGIC;

    function is_binary4(v : STD_LOGIC_VECTOR(3 downto 0)) return boolean is
    begin
        return ((v(3) = '0') or (v(3) = '1')) and
               ((v(2) = '0') or (v(2) = '1')) and
               ((v(1) = '0') or (v(1) = '1')) and
               ((v(0) = '0') or (v(0) = '1'));
    end function;

begin

    clk_i   <= CLK100MHZ;
    reset_i <= btn(0);

    -- BTN0 sert a la fois de reset materiel et de bouton start :
    --   appui   -> reset actif
    --   relache -> impulsion start_pulse d'un cycle a 100 MHz
    process(clk_i)
    begin
        if rising_edge(clk_i) then
            start_pulse <= '0';
            if btn0_d = '1' and btn(0) = '0' then
                start_pulse <= '1';
            end if;
            btn0_d <= btn(0);
        end if;
    end process;

    -- Horloge MCU 1 kHz. Le sequenceur MCU et le datapath vivent dans ce
    -- domaine lent afin de respecter explicitement la contrainte FMCU = 1 kHz.
    process(clk_i, reset_i)
    begin
        if reset_i = '1' then
            mcu_divcnt <= 0;
            clk_mcu    <= '0';
        elsif rising_edge(clk_i) then
            if mcu_divcnt = 49_999 then
                mcu_divcnt <= 0;
                clk_mcu    <= not clk_mcu;
            else
                mcu_divcnt <= mcu_divcnt + 1;
            end if;
        end if;
    end process;

    -- DONE est produit dans le domaine 1 kHz puis resynchronise en 100 MHz
    -- avant d'etre consomme par la FSM de jeu.
    process(clk_i, reset_i)
    begin
        if reset_i = '1' then
            mcu_done_meta <= '0';
            mcu_done_sync <= '0';
        elsif rising_edge(clk_i) then
            mcu_done_meta <= mcu_done;
            mcu_done_sync <= mcu_done_meta;
        end if;
    end process;

    U_MCU : mcu_lfsr_program
        port map (CLK => clk_mcu, RESET => reset_i,
                  START    => mcu_start,
                  SELFCT   => selfct_s,
                  SELROUTE => selroute_s,
                  SELOUT   => selout_s,
                  DONE     => mcu_done);

    -- A_IN = "1011" fournit la seed de reference pour la premiere execution.
    U_DP : datapath
        port map (CLK => clk_mcu, RESET => reset_i,
                  A_IN     => "1011", B_IN => "1011",
                  SRINL    => '0',    SRINR => '0',
                  SELFCT   => selfct_s,
                  SELROUTE => selroute_s,
                  SELOUT   => selout_s,
                  RESOUT   => resout_s,
                  SROUTL   => open,
                  SROUTR   => open);

    process(resout_s)
        variable color_idx : integer range 0 to 2;
    begin
        if is_binary4(resout_s(3 downto 0)) then
            color_idx := to_integer(unsigned(resout_s(3 downto 0))) mod 3;
            case color_idx is
                when 1      => led_color_s <= "010";
                when 2      => led_color_s <= "001";
                when others => led_color_s <= "100";
            end case;
        else
            led_color_s <= "100";
        end if;
    end process;

    U_TIMER : difficulty_timer
        port map (CLK => clk_i, RESET => reset_i,
                  START    => timer_start,
                  SW_LEVEL => sw(3 downto 2),
                  TIMEOUT  => timeout_s);

    U_SCORE : score_counter
        port map (CLK => clk_i, RESET => score_rst,
                  VALID_HIT => valid_hit_s,
                  ERROR     => error_s,
                  SCORE     => score_s,
                  GAME_OVER => gameover_s);

    U_CHECK : response_checker
        port map (CLK => clk_i, RESET => reset_i,
                  ENABLE    => checker_en,
                  TIMEOUT   => timeout_s,
                  LED_COLOR => led_color_s,
                  BTN_R     => btn(3),
                  BTN_G     => btn(2),
                  BTN_B     => btn(1),
                  VALID_HIT => valid_hit_s,
                  ERROR     => error_s);

    process(clk_i, reset_i)
    begin
        if reset_i = '1' then
            state       <= IDLE;
            timer_start <= '0';
            mcu_start   <= '0';
            checker_en  <= '0';
            score_rst   <= '1';

        elsif rising_edge(clk_i) then
            timer_start <= '0';
            mcu_start   <= '0';
            score_rst   <= '0';

            case state is

                when IDLE =>
                    checker_en <= '0';
                    mcu_start  <= '0';
                    if start_pulse = '1' then
                        score_rst <= '1';
                        mcu_start <= '1';
                        state     <= WAIT_MCU;
                    end if;

                when WAIT_MCU =>
                    checker_en <= '0';
                    -- mcu_start reste a '1' le temps que le domaine 1 kHz voie
                    -- la demande de nouvelle valeur.
                    mcu_start <= '1';
                    if mcu_done_sync = '1' then
                        timer_start <= '1';
                        mcu_start   <= '0';
                        state       <= WAIT_RESPONSE;
                    end if;

                when WAIT_RESPONSE =>
                    checker_en <= '1';
                    mcu_start  <= '0';
                    if gameover_s = '1' then
                        checker_en <= '0';
                        state      <= END_GAME;
                    elsif valid_hit_s = '1' then
                        checker_en <= '0';
                        if unsigned(score_s) = 14 then
                            state <= END_GAME;
                        else
                            mcu_start <= '1';
                            state     <= WAIT_MCU;
                        end if;
                    end if;

                when END_GAME =>
                    checker_en <= '0';
                    mcu_start  <= '0';
                    if start_pulse = '1' then
                        score_rst <= '1';
                        mcu_start <= '1';
                        state     <= WAIT_MCU;
                    end if;

                when others =>
                    state <= IDLE;

            end case;
        end if;
    end process;

    led3_r_s <= led_color_s(2);
    led3_g_s <= led_color_s(1);
    led3_b_s <= led_color_s(0);

    process(state, score_s)
    begin
        if state = END_GAME then
            if unsigned(score_s) = 15 then
                led0_r_s <= '0'; led0_g_s <= '1'; led0_b_s <= '0';  -- Vert
            elsif unsigned(score_s) >= 7 then
                led0_r_s <= '1'; led0_g_s <= '1'; led0_b_s <= '0';  -- Orange
            else
                led0_r_s <= '1'; led0_g_s <= '0'; led0_b_s <= '0';  -- Rouge
            end if;
        else
            led0_r_s <= '0'; led0_g_s <= '0'; led0_b_s <= '0';
        end if;
    end process;

    led    <= score_s;
    led3_r <= led3_r_s; led3_g <= led3_g_s; led3_b <= led3_b_s;
    led0_r <= led0_r_s; led0_g <= led0_g_s; led0_b <= led0_b_s;
    led1_r <= '0'; led1_g <= '0'; led1_b <= '0';
    led2_r <= '0'; led2_g <= '0'; led2_b <= '0';

end Behavioral;
