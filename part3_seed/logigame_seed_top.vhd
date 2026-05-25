library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Arty_Digilent_TopLevel is
    Generic (
        DEBOUNCE_CYCLES : integer := 200000
    );
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

    component button_debouncer is
        Generic ( DEBOUNCE_CYCLES : integer := 200000 );
        Port (
            CLK       : in  STD_LOGIC;
            BTN_RAW   : in  STD_LOGIC;
            BTN_CLEAN : out STD_LOGIC
        );
    end component;

    component lfsr4_freerun is
        Port (
            CLK : in  STD_LOGIC;
            RND : out STD_LOGIC_VECTOR(3 downto 0)
        );
    end component;

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

    
    signal clk_i      : STD_LOGIC;
    signal reset_i    : STD_LOGIC;

    signal btn0_clean : STD_LOGIC;
    signal btn0_d     : STD_LOGIC := '0';
    signal start_pulse: STD_LOGIC := '0';

    signal lfsr_rnd   : STD_LOGIC_VECTOR(3 downto 0);

   
    signal seed_s     : STD_LOGIC_VECTOR(3 downto 0) := "1011";

  
    signal mcu_rst_s  : STD_LOGIC := '0';


    signal selfct_s   : STD_LOGIC_VECTOR(3 downto 0);
    signal selroute_s : STD_LOGIC_VECTOR(3 downto 0);
    signal selout_s   : STD_LOGIC_VECTOR(1 downto 0);
    signal mcu_done   : STD_LOGIC;
    signal mcu_start  : STD_LOGIC;

 
    signal resout_s   : STD_LOGIC_VECTOR(7 downto 0);
    signal led_color_s: STD_LOGIC_VECTOR(2 downto 0);


    signal timer_start: STD_LOGIC;
    signal timeout_s  : STD_LOGIC;


    signal valid_hit_s: STD_LOGIC;
    signal error_s    : STD_LOGIC;
    signal score_s    : STD_LOGIC_VECTOR(3 downto 0);
    signal gameover_s : STD_LOGIC;
    signal score_rst  : STD_LOGIC;

   
    signal checker_en : STD_LOGIC;

 
    type fsm_t is (IDLE, WAIT_MCU, WAIT_RESPONSE, NEW_SEED, END_GAME);
    signal state      : fsm_t := IDLE;


    signal led0_r_s, led0_g_s, led0_b_s : STD_LOGIC;

begin

    clk_i <= CLK100MHZ;


    U_DEB : button_debouncer
        generic map (DEBOUNCE_CYCLES => DEBOUNCE_CYCLES)
        port map (CLK => clk_i, BTN_RAW => btn(0), BTN_CLEAN => btn0_clean);

    reset_i <= btn0_clean;


    process(clk_i)
    begin
        if rising_edge(clk_i) then
            start_pulse <= '0';
            if btn0_d = '1' and btn0_clean = '0' then
                start_pulse <= '1';
            end if;
            btn0_d <= btn0_clean;
        end if;
    end process;


    U_LFSR : lfsr4_freerun
        port map (CLK => clk_i, RND => lfsr_rnd);

   
    U_MCU : mcu_lfsr_program
        port map (CLK => clk_i, RESET => reset_i or mcu_rst_s, START => mcu_start,
                  SELFCT => selfct_s, SELROUTE => selroute_s,
                  SELOUT => selout_s, DONE => mcu_done);

    U_DP : datapath
        port map (CLK => clk_i, RESET => reset_i or mcu_rst_s,
                  A_IN => seed_s, B_IN => "1011",
                  SRINL => '0', SRINR => '0',
                  SELFCT => selfct_s, SELROUTE => selroute_s, SELOUT => selout_s,
                  RESOUT => resout_s, SROUTL => open, SROUTR => open);

    
    process(resout_s)
    begin
        case to_integer(unsigned(resout_s(3 downto 0))) mod 3 is
            when 0      => led_color_s <= "100";
            when 1      => led_color_s <= "010";
            when others => led_color_s <= "001";
        end case;
    end process;

    
    U_TIMER : difficulty_timer
        port map (CLK => clk_i, RESET => reset_i, START => timer_start,
                  SW_LEVEL => sw(3 downto 2), TIMEOUT => timeout_s);

   
    U_SCORE : score_counter
        port map (CLK => clk_i, RESET => score_rst,
                  VALID_HIT => valid_hit_s, ERROR => error_s,
                  SCORE => score_s, GAME_OVER => gameover_s);

   
    U_CHECK : response_checker
        port map (CLK => clk_i, RESET => reset_i, ENABLE => checker_en,
                  TIMEOUT => timeout_s, LED_COLOR => led_color_s,
                  BTN_R => btn(3), BTN_G => btn(2), BTN_B => btn(1),
                  VALID_HIT => valid_hit_s, ERROR => error_s);

    process(clk_i, reset_i)
    begin
        if reset_i = '1' then
            state       <= IDLE;
            timer_start <= '0';
            mcu_start   <= '0';
            mcu_rst_s   <= '0';
            checker_en  <= '0';
            score_rst   <= '1';
            seed_s      <= "1011";

        elsif rising_edge(clk_i) then
            timer_start <= '0';
            mcu_start   <= '0';
            mcu_rst_s   <= '0';
            score_rst   <= '0';

            case state is
                when IDLE =>
                    checker_en <= '0';
                    if start_pulse = '1' then
                        -- reset_i vient de retomber : initialized=0 deja dans MCU
                        seed_s    <= lfsr_rnd;
                        score_rst <= '1';
                        mcu_start <= '1';
                        state     <= WAIT_MCU;
                    end if;

                when WAIT_MCU =>
                    if mcu_done = '1' then
                        timer_start <= '1';
                        state       <= WAIT_RESPONSE;
                    end if;

                when WAIT_RESPONSE =>
                    checker_en <= '1';
                    if gameover_s = '1' then
                        checker_en <= '0';
                        state      <= END_GAME;
                    elsif valid_hit_s = '1' then
                        checker_en <= '0';
                        seed_s     <= lfsr_rnd;  -- capture le LFSR courant
                        mcu_rst_s  <= '1';       -- efface initialized du MCU
                        state      <= NEW_SEED;
                    end if;

                when NEW_SEED =>
                    -- mcu_rst_s etait '1' le cycle precedent : initialized=0 dans MCU
                    -- Ce cycle : lance le MCU avec le nouveau seed
                    mcu_start <= '1';
                    state     <= WAIT_MCU;

                when END_GAME =>
                    checker_en <= '0';

                when others => state <= IDLE;
            end case;
        end if;
    end process;

  
    process(state, score_s)
    begin
        if state = END_GAME then
            if unsigned(score_s) = 15 then
                led0_r_s <= '0'; led0_g_s <= '1'; led0_b_s <= '0';
            elsif unsigned(score_s) >= 7 then
                led0_r_s <= '1'; led0_g_s <= '1'; led0_b_s <= '0';
            else
                led0_r_s <= '1'; led0_g_s <= '0'; led0_b_s <= '0';
            end if;
        else
            led0_r_s <= '0'; led0_g_s <= '0'; led0_b_s <= '0';
        end if;
    end process;

  
    led    <= score_s;
    led3_r <= led_color_s(2);
    led3_g <= led_color_s(1);
    led3_b <= led_color_s(0);
    led0_r <= led0_r_s; led0_g <= led0_g_s; led0_b <= led0_b_s;
    led1_r <= '0'; led1_g <= '0'; led1_b <= '0';
    led2_r <= '0'; led2_g <= '0'; led2_b <= '0';

end Behavioral;
