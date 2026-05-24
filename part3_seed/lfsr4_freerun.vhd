-- =============================================================================
-- Module      : lfsr4_freerun.vhd
-- Description : LFSR 4 bits libre (free-running) a 100 MHz.
--               Avance d un etat a chaque front montant, sans ENABLE, sans
--               reset, sans diviseur de frequence.
--
--               Polynome X^4+X^3+1 (feedback = bit3 XOR bit2, decalage gauche)
--               Sequence de 15 etats non nuls depuis la valeur initiale "1011" :
--               1011->0111->1111->1110->1100->1000->0001->0010->
--               0100->1001->0011->0110->1101->1010->0101->(1011)
--
--               Pas de reset : le registre tourne en permanence depuis la mise
--               sous tension (valeur initiale garantie par le bitstream Xilinx).
--               La valeur lue au moment d un appui bouton est impredictible
--               car le joueur ne peut pas controler son appui a la nanoseconde.
-- Auteur      : Projet LogiGame - TE608 EFREI 2025-2026
-- Cible       : Xilinx Artix-35T - Vivado / GHDL
-- =============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity lfsr4_freerun is
    Port (
        CLK : in  STD_LOGIC;
        RND : out STD_LOGIC_VECTOR(3 downto 0)
    );
end lfsr4_freerun;

architecture Behavioral of lfsr4_freerun is

    signal lfsr_reg : STD_LOGIC_VECTOR(3 downto 0) := "1011";
    signal feedback : STD_LOGIC;

begin

    feedback <= lfsr_reg(3) xor lfsr_reg(2);

    process(CLK)
    begin
        if rising_edge(CLK) then
            lfsr_reg <= lfsr_reg(2 downto 0) & feedback;
        end if;
    end process;

    RND <= lfsr_reg;

end Behavioral;
