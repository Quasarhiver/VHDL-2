-- =============================================================================
-- Module      : game_controller.vhd
-- Description : Controleur principal du jeu LogiGame pour la partie 2.
--
--               FSM :
--                 IDLE          -> attente de START
--                 NEW_ROUND     -> demande une nouvelle valeur au LFSR
--                 WAIT_COLOR    -> attend que la nouvelle couleur soit stable
--                 WAIT_RESPONSE -> accepte une reponse ou un timeout
--                 END_GAME      -> fige le score et affiche LED0
--
--               LD3 affiche la couleur de la manche courante.
--               Cette couleur est derivee de la valeur pseudo-aleatoire 4 bits
--               par un vrai modulo 3 :
--                 0 -> rouge
--                 1 -> vert
--                 2 -> bleu
--
--               LED0 affiche le resultat final :
--                 vert   si score = 15
--                 orange si score est entre 7 et 14
--                 rouge  sinon
-- Auteur      : Projet LogiGame - TE608 EFREI 2025-2026
-- Cible       : Xilinx Artix-35T - Vivado / GHDL
-- Revision    : 2.0 - Avril 2026
-- =============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity game_controller is
    Port (
        CLK        : in  STD_LOGIC;
        RESET      : in  STD_LOGIC;
        -- Entrees joueur
        START      : in  STD_LOGIC;                    -- btn0 = demarrer
        BTN_R      : in  STD_LOGIC;                    -- btn3 = rouge
        BTN_G      : in  STD_LOGIC;                    -- btn2 = vert
        BTN_B      : in  STD_LOGIC;                    -- btn1 = bleu
        SW_LEVEL   : in  STD_LOGIC_VECTOR(1 downto 0); -- sw[3:2] difficulte
        -- Sorties LED stimulus LD3
        LED3_R     : out STD_LOGIC;
        LED3_G     : out STD_LOGIC;
        LED3_B     : out STD_LOGIC;
        -- Sortie LED resultat LED0
        LED0_R     : out STD_LOGIC;
        LED0_G     : out STD_LOGIC;
        LED0_B     : out STD_LOGIC;
        -- Score sur led[3:0]
        SCORE_OUT  : out STD_LOGIC_VECTOR(3 downto 0)
    );
end game_controller;

architecture Behavioral of game_controller is

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

    -- WAIT_COLOR est un etat technique qui separe proprement :
    -- 1) la demande d'avance au LFSR
    -- 2) le lancement du timer une fois la nouvelle couleur stable
    type fsm_state is (IDLE, NEW_ROUND, WAIT_COLOR, WAIT_RESPONSE, END_GAME);
    signal state : fsm_state := IDLE;

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

    -- Un peu plus d'une periode 1 kHz pour garantir que le pulse lfsr_en
    -- d'un seul cycle a bien ete consomme par le LFSR.
    signal color_wait_cnt : integer range 0 to 100_001 := 0;

    function is_binary4(v : STD_LOGIC_VECTOR(3 downto 0)) return boolean is
    begin
        return ((v(3) = '0') or (v(3) = '1')) and
               ((v(2) = '0') or (v(2) = '1')) and
               ((v(1) = '0') or (v(1) = '1')) and
               ((v(0) = '0') or (v(0) = '1'));
    end function;

begin

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

    -- Derivation de la couleur a partir de la valeur pseudo-aleatoire.
    process(rnd_s)
        variable color_idx : integer range 0 to 2;
    begin
        if is_binary4(rnd_s) then
            color_idx := to_integer(unsigned(rnd_s)) mod 3;
            case color_idx is
                when 1      => led_color_r <= "010";   -- Vert
                when 2      => led_color_r <= "001";   -- Bleu
                when others => led_color_r <= "100";   -- Rouge
            end case;
        else
            led_color_r <= "100";
        end if;
    end process;

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
            -- Pulses d'un seul cycle par defaut.
            lfsr_en     <= '0';
            timer_start <= '0';
            score_reset <= '0';
            start_d     <= START;

            case state is

                when IDLE =>
                    checker_en <= '0';
                    if START = '1' and start_d = '0' then
                        score_reset <= '1';
                        state       <= NEW_ROUND;
                    end if;

                when NEW_ROUND =>
                    lfsr_en        <= '1';
                    checker_en     <= '0';
                    color_wait_cnt <= 0;
                    state          <= WAIT_COLOR;

                when WAIT_COLOR =>
                    checker_en <= '0';
                    if color_wait_cnt = 100_001 then
                        timer_start <= '1';
                        state       <= WAIT_RESPONSE;
                    else
                        color_wait_cnt <= color_wait_cnt + 1;
                    end if;

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

                when END_GAME =>
                    checker_en <= '0';
                    if START = '1' and start_d = '0' then
                        score_reset <= '1';
                        state       <= NEW_ROUND;
                    end if;

                when others =>
                    state <= IDLE;

            end case;
        end if;
    end process;

    LED3_R <= led_color_r(2);
    LED3_G <= led_color_r(1);
    LED3_B <= led_color_r(0);

    process(state, score_s)
        variable sc : unsigned(3 downto 0);
    begin
        sc := unsigned(score_s);
        if state = END_GAME then
            if sc = 15 then
                LED0_R <= '0'; LED0_G <= '1'; LED0_B <= '0';  -- Vert
            elsif sc >= 7 then
                LED0_R <= '1'; LED0_G <= '1'; LED0_B <= '0';  -- Orange
            else
                LED0_R <= '1'; LED0_G <= '0'; LED0_B <= '0';  -- Rouge
            end if;
        else
            LED0_R <= '0'; LED0_G <= '0'; LED0_B <= '0';
        end if;
    end process;

    SCORE_OUT <= score_s;

end Behavioral;
