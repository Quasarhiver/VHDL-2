-- =============================================================================
-- Module      : game_controller.vhd
-- Description : Contrôleur principal du jeu LogiGame.
--               FSM : IDLE → NEW_ROUND → WAIT_COLOR → WAIT_RESPONSE → END_GAME
--
--               IDLE         : Attente du bouton START (btn0)
--               NEW_ROUND    : Avance le LFSR d'un pas
--               WAIT_COLOR   : Attend >1 période 1kHz (100 001 cycles) pour que
--                              le LFSR ait effectivement avancé et que la couleur
--                              affichée sur LD3 soit stable avant de lancer le timer
--               WAIT_RESPONSE: Lance le timer, attente de la réponse joueur ou timeout
--               END_GAME     : Jeu terminé, affichage score final sur led0 RGB
--
--               LED_COLOR (3 bits) : R=100 / G=010 / B=001
--               La couleur est dérivée du LFSR : rnd[1:0] modulo 3
--                 00 ou 11 → Rouge
--                 01       → Vert
--                 10       → Bleu
--
--               Led0 résultat final :
--                 Vert   : score = 15
--                 Orange : score ∈ [7,14]  (R+G)
--                 Rouge  : score ∈ [0,6]
--

-- Auteur      : Projet LogiGame – TE608 EFREI 2025-2026
-- Cible       : Xilinx Artix-35T – Vivado / GHDL
-- Révision    : 2.0 – Avril 2026
-- =============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity game_controller is
    Port (
        CLK        : in  STD_LOGIC;
        RESET      : in  STD_LOGIC;
        -- Entrées joueur
        START      : in  STD_LOGIC;                    -- btn0 = démarrer
        BTN_R      : in  STD_LOGIC;                    -- btn3 = rouge
        BTN_G      : in  STD_LOGIC;                    -- btn2 = vert
        BTN_B      : in  STD_LOGIC;                    -- btn1 = bleu
        SW_LEVEL   : in  STD_LOGIC_VECTOR(1 downto 0); -- sw[3:2] difficulté
        -- Sorties LED stimulus LD3
        LED3_R     : out STD_LOGIC;
        LED3_G     : out STD_LOGIC;
        LED3_B     : out STD_LOGIC;
        -- Sortie LED résultat LED0
        LED0_R     : out STD_LOGIC;
        LED0_G     : out STD_LOGIC;
        LED0_B     : out STD_LOGIC;
        -- Score sur led[3:0]
        SCORE_OUT  : out STD_LOGIC_VECTOR(3 downto 0)
    );
end game_controller;

architecture Behavioral of game_controller is

    -- =========================================================================
    -- Composants
    -- =========================================================================
    component lfsr4 is
        Port (
            CLK    : in  STD_LOGIC;
            RESET  : in  STD_LOGIC;
            ENABLE : in  STD_LOGIC;
            RND    : out STD_LOGIC_VECTOR(3 downto 0)
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

    -- =========================================================================
    -- FSM : ajout de l'état WAIT_COLOR (fix bug 4)
    -- =========================================================================
    type fsm_state is (IDLE, NEW_ROUND, WAIT_COLOR, WAIT_RESPONSE, END_GAME);
    signal state : fsm_state := IDLE;

    -- =========================================================================
    -- Signaux internes
    -- =========================================================================
    signal rnd_s          : STD_LOGIC_VECTOR(3 downto 0);
    signal lfsr_en        : STD_LOGIC := '0';
    signal timer_start    : STD_LOGIC := '0';
    signal timeout_s      : STD_LOGIC;
    signal valid_hit_s    : STD_LOGIC;
    signal error_s        : STD_LOGIC;
    signal score_s        : STD_LOGIC_VECTOR(3 downto 0);
    signal gameover_s     : STD_LOGIC;
    signal checker_en     : STD_LOGIC := '0';
    signal led_color_r    : STD_LOGIC_VECTOR(2 downto 0) := "100";
    signal score_reset    : STD_LOGIC := '0';
    signal start_d        : STD_LOGIC := '0';

    -- Compteur pour WAIT_COLOR : attend 100 001 cycles (> 1 période 1kHz)
    -- pour garantir que le LFSR a avancé avant de lancer le timer (fix bug 4)
    signal color_wait_cnt : integer range 0 to 100_001 := 0;

    -- =========================================================================
    -- Conversion LFSR → couleur (rnd[1:0] mod 3)
    -- =========================================================================
    signal color_sel : STD_LOGIC_VECTOR(1 downto 0);

begin

    -- =========================================================================
    -- Instanciations
    -- =========================================================================
    U_LFSR : lfsr4
        port map (CLK => CLK, RESET => RESET, ENABLE => lfsr_en, RND => rnd_s);

    U_TIMER : difficulty_timer
        port map (CLK => CLK, RESET => RESET, START => timer_start,
                  SW_LEVEL => SW_LEVEL, TIMEOUT => timeout_s);

    U_SCORE : score_counter
        port map (CLK => CLK, RESET => score_reset,
                  VALID_HIT => valid_hit_s, ERROR => error_s,
                  SCORE => score_s, GAME_OVER => gameover_s);

    U_CHECK : response_checker
        port map (CLK => CLK, RESET => RESET, ENABLE => checker_en,
                  TIMEOUT => timeout_s, LED_COLOR => led_color_r,
                  BTN_R => BTN_R, BTN_G => BTN_G, BTN_B => BTN_B,
                  VALID_HIT => valid_hit_s, ERROR => error_s);

    -- =========================================================================
    -- Dérivation couleur depuis LFSR (rnd[1:0] mod 3)
    --   "00" ou "11" → Rouge (100)
    --   "01"         → Vert  (010)
    --   "10"         → Bleu  (001)
    -- =========================================================================
    color_sel <= rnd_s(1 downto 0);
    process(color_sel)
    begin
        case color_sel is
            when "01"   => led_color_r <= "010";   -- Vert
            when "10"   => led_color_r <= "001";   -- Bleu
            when others => led_color_r <= "100";   -- Rouge
        end case;
    end process;

    -- =========================================================================
    -- FSM principale
    -- =========================================================================
    process(CLK, RESET)
    begin
        if RESET = '1' then
            state          <= IDLE;
            lfsr_en        <= '0';
            timer_start    <= '0';
            checker_en     <= '0';
            score_reset    <= '1';
            start_d        <= '0';
            color_wait_cnt <= 0;

        elsif rising_edge(CLK) then
            -- Signaux pulsés par défaut
            lfsr_en     <= '0';
            timer_start <= '0';
            score_reset <= '0';
            start_d     <= START;

            case state is

                -- --------------------------------------------------------------
                when IDLE =>
                    checker_en <= '0';
                    -- Attente front montant sur START
                    if START = '1' and start_d = '0' then
                        score_reset <= '1';
                        state       <= NEW_ROUND;
                    end if;

                -- --------------------------------------------------------------
                when NEW_ROUND =>
                    -- Pulse LFSR enable : demande une avance au prochain tick 1kHz
                    lfsr_en        <= '1';
                    checker_en     <= '0';
                    color_wait_cnt <= 0;
                    -- Ne pas lancer le timer ici : attendre que le LFSR ait avancé
                    state          <= WAIT_COLOR;


                when WAIT_COLOR =>
                    checker_en <= '0';
                    if color_wait_cnt = 100_001 then
                        timer_start <= '1';   -- couleur stable, on lance le timer
                        state       <= WAIT_RESPONSE;
                    else
                        color_wait_cnt <= color_wait_cnt + 1;
                    end if;

                -- --------------------------------------------------------------
                when WAIT_RESPONSE =>
                    checker_en <= '1';
                    if gameover_s = '1' then
                        checker_en <= '0';
                        state      <= END_GAME;
                    elsif valid_hit_s = '1' then
                        checker_en <= '0';
                        if unsigned(score_s) = 14 then
                            state <= END_GAME;
                        else
                            state <= NEW_ROUND;
                        end if;
                    end if;

                -- --------------------------------------------------------------
                when END_GAME =>
                    checker_en <= '0';
                    -- Attente restart
                    if START = '1' and start_d = '0' then
                        score_reset <= '1';
                        state       <= NEW_ROUND;
                    end if;

                when others =>
                    state <= IDLE;

            end case;
        end if;
    end process;

    -- =========================================================================
    -- Sorties LED stimulus LD3
    -- =========================================================================
    LED3_R <= led_color_r(2);
    LED3_G <= led_color_r(1);
    LED3_B <= led_color_r(0);

    -- =========================================================================
    -- Sortie LED résultat LED0 (actif seulement en END_GAME)
    -- =========================================================================
    process(state, score_s)
        variable sc : unsigned(3 downto 0);
    begin
        sc := unsigned(score_s);
        if state = END_GAME then
            if sc = 15 then
                LED0_R <= '0'; LED0_G <= '1'; LED0_B <= '0';  -- Vert
            elsif sc >= 7 then
                LED0_R <= '1'; LED0_G <= '1'; LED0_B <= '0';  -- Orange (R+G)
            else
                LED0_R <= '1'; LED0_G <= '0'; LED0_B <= '0';  -- Rouge
            end if;
        else
            LED0_R <= '0'; LED0_G <= '0'; LED0_B <= '0';
        end if;
    end process;

    -- Score sur les LEDs standard
    SCORE_OUT <= score_s;

end Behavioral;