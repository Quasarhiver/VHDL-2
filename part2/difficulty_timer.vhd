-- =============================================================================
-- Module      : difficulty_timer.vhd
-- Description : Minuteur programmable pour la gestion de la difficulté du jeu.
--               4 niveaux sélectionnés par SW_LEVEL (2 bits) :
--                 "00" → 4s    (400 000 000 cycles à 100 MHz)
--                 "01" → 2s    (200 000 000 cycles)
--                 "10" → 1s    (100 000 000 cycles)
--                 "11" → 0.5s  ( 50 000 000 cycles)
--               Le signal TIMEOUT passe à '1' UNE SEULE FOIS à la fin du délai,
--               puis reste à '0' jusqu'à un nouveau START.
-- Auteur      : Projet LogiGame – TE608 EFREI 2025-2026
-- Cible       : Xilinx Artix-35T – Vivado / GHDL
-- Révision    : 1.0 – Avril 2026
-- =============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity difficulty_timer is
    Port (
        CLK      : in  STD_LOGIC;
        RESET    : in  STD_LOGIC;
        START    : in  STD_LOGIC;                    -- Lance le décompte (niveau haut actif)
        SW_LEVEL : in  STD_LOGIC_VECTOR(1 downto 0); -- Niveau de difficulté
        TIMEOUT  : out STD_LOGIC                     -- Passe à '1' à la fin du délai
    );
end difficulty_timer;

architecture Behavioral of difficulty_timer is

    -- =========================================================================
    -- Constantes de délai (cycles à 100 MHz)
    -- =========================================================================
    constant CYCLES_4S   : unsigned(28 downto 0) := to_unsigned(399_999_999, 29); -- 4s
    constant CYCLES_2S   : unsigned(28 downto 0) := to_unsigned(199_999_999, 29); -- 2s
    constant CYCLES_1S   : unsigned(28 downto 0) := to_unsigned( 99_999_999, 29); -- 1s
    constant CYCLES_500MS: unsigned(28 downto 0) := to_unsigned( 49_999_999, 29); -- 0.5s

    signal cnt       : unsigned(28 downto 0) := (others => '0');
    signal limit     : unsigned(28 downto 0) := CYCLES_4S;
    signal running   : STD_LOGIC := '0';
    signal timeout_r : STD_LOGIC := '0';

begin

    -- =========================================================================
    -- Sélection de la limite en fonction du niveau de difficulté
    -- =========================================================================
    process(SW_LEVEL)
    begin
        case SW_LEVEL is
            when "00"   => limit <= CYCLES_4S;
            when "01"   => limit <= CYCLES_2S;
            when "10"   => limit <= CYCLES_1S;
            when "11"   => limit <= CYCLES_500MS;
            when others => limit <= CYCLES_4S;
        end case;
    end process;

    -- =========================================================================
    -- Process principal du minuteur
    -- =========================================================================
    process(CLK, RESET)
    begin
        if RESET = '1' then
            cnt       <= (others => '0');
            running   <= '0';
            timeout_r <= '0';

        elsif rising_edge(CLK) then
            timeout_r <= '0';  -- Pulse d'un seul cycle par défaut

            if START = '1' then
                -- Lancement : reset compteur et activation
                cnt     <= (others => '0');
                running <= '1';
            elsif running = '1' then
                if cnt = limit then
                    -- Fin du délai
                    running   <= '0';
                    timeout_r <= '1';
                    cnt       <= (others => '0');
                else
                    cnt <= cnt + 1;
                end if;
            end if;
        end if;
    end process;

    TIMEOUT <= timeout_r;

end Behavioral;
