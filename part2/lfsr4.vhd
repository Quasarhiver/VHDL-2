-- =============================================================================
-- Module      : lfsr4.vhd
-- Description : Registre à décalage à rétroaction linéaire (LFSR) 4 bits.
--               Seed initial : "1011"
--               Fréquence de sortie : 1 kHz (diviseur 100 000 depuis CLK 100 MHz)
--               Un pulse ENABLE demande une seule avance du LFSR ; la demande
--               est mémorisée jusqu'au prochain tick 1 kHz.
--
--               Note :
--               Le sujet demande le polynôme X^4 + X^3 + 1 avec :
--                 - feedback = XOR(bits 3 et 2)
--                 - séquence maximale de 15 états non nuls
--               L'orientation retenue ici est un décalage gauche :
--                 next = {b2, b1, b0, feedback}
--               ce qui satisfait ces contraintes.
-- Auteur      : Projet LogiGame – TE608 EFREI 2025-2026
-- Cible       : Xilinx Artix-35T – Vivado / GHDL
-- Révision    : 1.0 – Avril 2026
-- =============================================================================
-- Ports :
--   CLK    : horloge 100 MHz
--   RESET  : reset asynchrone actif haut → lfsr ← "1011"
--   ENABLE : active l'évolution du LFSR à 1 kHz
--   RND    : sortie pseudo-aléatoire 4 bits
-- =============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity lfsr4 is
    Port (
        CLK    : in  STD_LOGIC;
        RESET  : in  STD_LOGIC;
        ENABLE : in  STD_LOGIC;
        RND    : out STD_LOGIC_VECTOR(3 downto 0)
    );
end lfsr4;

architecture Behavioral of lfsr4 is

    -- Diviseur de fréquence : 100 MHz / 1 kHz = 100 000
    constant DIV_MAX : integer := 99999;

    signal lfsr_reg  : STD_LOGIC_VECTOR(3 downto 0) := "1011";
    signal div_cnt   : integer range 0 to DIV_MAX := 0;
    signal tick_1khz : STD_LOGIC := '0';
    signal feedback  : STD_LOGIC;
    signal step_req  : STD_LOGIC := '0';

begin

    -- =========================================================================
    -- Feedback LFSR : taps bit3 et bit2 (X^4 + X^3 + 1).
    -- Décalage gauche : next = {b2, b1, b0, feedback}.
    -- =========================================================================
    feedback <= lfsr_reg(3) xor lfsr_reg(2);

    -- =========================================================================
    -- Process diviseur de fréquence : génère tick_1khz
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
    -- Process LFSR : un pulse ENABLE arme une avance, consommée au prochain tick
    -- 1 kHz. Cela garantit qu'une seule nouvelle valeur est produite par manche,
    -- même si ENABLE n'est présent qu'un seul cycle à 100 MHz.
    -- =========================================================================
    process(CLK, RESET)
    begin
        if RESET = '1' then
            lfsr_reg <= "1011";  -- Seed non-nul
            step_req <= '0';
        elsif rising_edge(CLK) then
            if ENABLE = '1' then
                step_req <= '1';
            end if;

            if tick_1khz = '1' and step_req = '1' then
                lfsr_reg <= lfsr_reg(2 downto 0) & feedback;
                step_req <= '0';
            end if;
        end if;
    end process;

    RND <= lfsr_reg;

end Behavioral;
