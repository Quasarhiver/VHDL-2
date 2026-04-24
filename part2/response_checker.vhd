-- =============================================================================
-- Module      : response_checker.vhd
-- Description : Valide la reponse du joueur pendant une manche.
--               Le bloc :
--               - compare le bouton appuye avec la couleur affichee sur LD3
--               - emet VALID_HIT pour une bonne reponse
--               - emet ERROR pour un mauvais bouton, un appui multiple ou un timeout
--               - n'accepte qu'un seul evenement par manche
--               - ignore un bouton deja maintenu au moment ou ENABLE passe a '1'
--
--               Mapping retenu :
--                 LED_COLOR = "100" -> BTN_R
--                 LED_COLOR = "010" -> BTN_G
--                 LED_COLOR = "001" -> BTN_B
-- Auteur      : Projet LogiGame - TE608 EFREI 2025-2026
-- Cible       : Xilinx Artix-35T - Vivado / GHDL
-- Revision    : 1.0 - Avril 2026
-- =============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity response_checker is
    Port (
        CLK       : in  STD_LOGIC;
        RESET     : in  STD_LOGIC;
        ENABLE    : in  STD_LOGIC;   -- Actif pendant WAIT_RESPONSE
        TIMEOUT   : in  STD_LOGIC;   -- Pulse timeout du minuteur
        LED_COLOR : in  STD_LOGIC_VECTOR(2 downto 0);
        BTN_R     : in  STD_LOGIC;
        BTN_G     : in  STD_LOGIC;
        BTN_B     : in  STD_LOGIC;
        VALID_HIT : out STD_LOGIC;
        ERROR     : out STD_LOGIC
    );
end response_checker;

architecture Behavioral of response_checker is

    signal user_pressed : STD_LOGIC := '0';  -- Verrou : un seul appui par manche
    signal prev_any_btn : STD_LOGIC := '0';  -- Filtre un bouton deja maintenu
    signal valid_hit_r  : STD_LOGIC := '0';
    signal error_r      : STD_LOGIC := '0';

begin

    process(CLK, RESET)
        variable correct_btn : STD_LOGIC;
        variable any_btn     : STD_LOGIC;
        variable onehot_btn  : STD_LOGIC;
    begin
        if RESET = '1' then
            user_pressed <= '0';
            prev_any_btn <= '0';
            valid_hit_r  <= '0';
            error_r      <= '0';

        elsif rising_edge(CLK) then
            valid_hit_r <= '0';
            error_r     <= '0';

            -- Selection du bouton attendu pour la couleur courante.
            case LED_COLOR is
                when "100"  => correct_btn := BTN_R;
                when "010"  => correct_btn := BTN_G;
                when "001"  => correct_btn := BTN_B;
                when others => correct_btn := '0';
            end case;

            -- any_btn detecte un appui quelconque.
            -- onehot_btn impose qu'un seul bouton soit actif.
            any_btn := BTN_R or BTN_G or BTN_B;
            if (BTN_R = '1' and BTN_G = '0' and BTN_B = '0') or
               (BTN_R = '0' and BTN_G = '1' and BTN_B = '0') or
               (BTN_R = '0' and BTN_G = '0' and BTN_B = '1') then
                onehot_btn := '1';
            else
                onehot_btn := '0';
            end if;

            if ENABLE = '1' and user_pressed = '0' then
                if any_btn = '1' and prev_any_btn = '0' then
                    user_pressed <= '1';
                    if onehot_btn = '1' and correct_btn = '1' then
                        valid_hit_r <= '1';
                    else
                        error_r <= '1';
                    end if;
                elsif TIMEOUT = '1' then
                    -- Timeout sans appui : la manche est perdue.
                    user_pressed <= '1';
                    error_r <= '1';
                end if;
            end if;

            -- Le verrou est relache des qu'on quitte WAIT_RESPONSE.
            if ENABLE = '0' then
                user_pressed <= '0';
            end if;

            prev_any_btn <= any_btn;
        end if;
    end process;

    VALID_HIT <= valid_hit_r;
    ERROR     <= error_r;

end Behavioral;
