-- =============================================================================
-- Module      : response_checker.vhd
-- Description : Valide la réponse du joueur dans le jeu LogiGame.
--               Compare le bouton pressé avec la couleur de la LED LD3.
--               Génère VALID_HIT='1' si bonne réponse avant timeout.
--               Génère ERROR='1' si mauvaise réponse ou timeout sans appui.
--               Un seul appui comptabilisé par round (registre user_pressed).
--
--               Mapping des couleurs :
--                 LED_COLOR = "100" (Rouge)  → BTN_R correct
--                 LED_COLOR = "010" (Vert)   → BTN_G correct
--                 LED_COLOR = "001" (Bleu)   → BTN_B correct
--
--               BTN_R = btn[3], BTN_G = btn[2], BTN_B = btn[1]  (spec cours)
-- Auteur      : Projet LogiGame – TE608 EFREI 2025-2026
-- Cible       : Xilinx Artix-35T – Vivado / GHDL
-- Révision    : 1.0 – Avril 2026
-- =============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity response_checker is
    Port (
        CLK       : in  STD_LOGIC;
        RESET     : in  STD_LOGIC;
        ENABLE    : in  STD_LOGIC;   -- Actif pendant la phase WAIT_RESPONSE
        TIMEOUT   : in  STD_LOGIC;   -- Signal timeout du minuteur
        LED_COLOR : in  STD_LOGIC_VECTOR(2 downto 0); -- Couleur actuelle (R=100/G=010/B=001)
        BTN_R     : in  STD_LOGIC;   -- Bouton rouge  (btn3)
        BTN_G     : in  STD_LOGIC;   -- Bouton vert   (btn2)
        BTN_B     : in  STD_LOGIC;   -- Bouton bleu   (btn1)
        VALID_HIT : out STD_LOGIC;   -- Bonne réponse
        ERROR     : out STD_LOGIC    -- Mauvaise réponse ou timeout
    );
end response_checker;

architecture Behavioral of response_checker is

    signal user_pressed : STD_LOGIC := '0';  -- Verrou : un seul appui par round
    signal prev_any_btn : STD_LOGIC := '0';  -- Evite qu'un bouton maintenu soit recompte
    signal valid_hit_r  : STD_LOGIC := '0';
    signal error_r      : STD_LOGIC := '0';

begin

    process(CLK, RESET)
        variable correct_btn : STD_LOGIC;
        variable any_btn     : STD_LOGIC;
    begin
        if RESET = '1' then
            user_pressed <= '0';
            prev_any_btn <= '0';
            valid_hit_r  <= '0';
            error_r      <= '0';

        elsif rising_edge(CLK) then
            valid_hit_r <= '0';  -- Impulsions d'un seul cycle
            error_r     <= '0';

            -- Détermination du bouton correct selon la couleur
            case LED_COLOR is
                when "100"  => correct_btn := BTN_R;
                when "010"  => correct_btn := BTN_G;
                when "001"  => correct_btn := BTN_B;
                when others => correct_btn := '0';
            end case;

            -- Un bouton quelconque appuyé
            any_btn := BTN_R or BTN_G or BTN_B;

            if ENABLE = '1' and user_pressed = '0' then
                if any_btn = '1' and prev_any_btn = '0' then
                    user_pressed <= '1';  -- Verrouiller après premier appui
                    if correct_btn = '1' then
                        valid_hit_r <= '1';
                    else
                        error_r <= '1';
                    end if;
                elsif TIMEOUT = '1' then
                    -- Timeout sans appui = erreur
                    user_pressed <= '1';
                    error_r <= '1';
                end if;
            end if;

            -- Reset du verrou en fin de round (sur ENABLE désactivé)
            if ENABLE = '0' then
                user_pressed <= '0';
            end if;

            prev_any_btn <= any_btn;
        end if;
    end process;

    VALID_HIT <= valid_hit_r;
    ERROR     <= error_r;

end Behavioral;
