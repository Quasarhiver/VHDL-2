-- =============================================================================
-- Module      : score_counter.vhd
-- Description : Compteur de score 4 bits pour le jeu LogiGame.
--               - Incrémente sur VALID_HIT='1' (bonne réponse)
--               - GAME_OVER='1' si mauvaise réponse (signal ERROR) ou score=15
--               - Score figé après GAME_OVER
--               NOTE : VALID_HIT et ERROR sont des impulsions d'un cycle.
-- Auteur      : Projet LogiGame – TE608 EFREI 2025-2026
-- Cible       : Xilinx Artix-35T – Vivado / GHDL
-- Révision    : 1.0 – Avril 2026
-- =============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity score_counter is
    Port (
        CLK       : in  STD_LOGIC;
        RESET     : in  STD_LOGIC;
        VALID_HIT : in  STD_LOGIC;   -- Bonne réponse (impulsion)
        ERROR     : in  STD_LOGIC;   -- Mauvaise réponse ou timeout (impulsion)
        SCORE     : out STD_LOGIC_VECTOR(3 downto 0);
        GAME_OVER : out STD_LOGIC
    );
end score_counter;

architecture Behavioral of score_counter is

    signal score_reg   : unsigned(3 downto 0) := (others => '0');
    signal gameover_reg: STD_LOGIC := '0';

begin

    process(CLK, RESET)
    begin
        if RESET = '1' then
            score_reg    <= (others => '0');
            gameover_reg <= '0';

        elsif rising_edge(CLK) then
            if gameover_reg = '0' then
                if ERROR = '1' then
                    -- Fin de jeu sur erreur
                    gameover_reg <= '1';
                elsif VALID_HIT = '1' then
                    if score_reg = 14 then
                        -- Score maximal atteint (15ème réponse correcte)
                        score_reg    <= score_reg + 1;
                        gameover_reg <= '1';
                    else
                        score_reg <= score_reg + 1;
                    end if;
                end if;
            end if;
            -- Si gameover, score est figé (aucune modification)
        end if;
    end process;

    SCORE     <= std_logic_vector(score_reg);
    GAME_OVER <= gameover_reg;

end Behavioral;
