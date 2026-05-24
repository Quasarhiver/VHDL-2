-- =============================================================================
-- Module      : button_debouncer.vhd
-- Description : Synchroniseur + anti-rebond pour un bouton-poussoir mecanique.
--
--               Deux roles :
--                 1. SYNCHRONISATION (corrige M-5) : un poussoir est un signal
--                    asynchrone vis-a-vis de CLK. Une chaine de 2 bascules
--                    (ASYNC_REG) recale le signal sur l'horloge et evite la
--                    metastabilite des registres en aval (FSM, reset, ...).
--                 2. ANTI-REBOND (corrige M-4) : un contact mecanique "rebondit"
--                    pendant quelques millisecondes a chaque appui/relachement.
--                    Sans filtrage, ces rebonds generent de faux fronts. La
--                    sortie BTN_CLEAN ne change donc que si l'entree reste
--                    stable pendant DEBOUNCE_CYCLES cycles consecutifs.
--
--               IMPORTANT : ce module n'a pas d'entree RESET. Sur la carte, sa
--               sortie sert justement a fabriquer le reset global ; il doit donc
--               tourner librement. L'etat initial est fixe par la configuration
--               du bitstream (valeurs ':=' ci-dessous), garantie sur FPGA
--               Xilinx (et seulement sur ce type de cible).
-- Auteur      : Projet LogiGame - TE608 EFREI 2025-2026
-- Cible       : Xilinx Artix-35T - Vivado / GHDL
-- =============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity button_debouncer is
    Generic (
        -- Duree de stabilite exigee. 200 000 cycles a 100 MHz = 2 ms, largement
        -- au-dessus des rebonds (< 1 ms) des poussoirs tactiles de la carte Arty.
        DEBOUNCE_CYCLES : integer := 200000
    );
    Port (
        CLK       : in  STD_LOGIC;   -- horloge 100 MHz
        BTN_RAW   : in  STD_LOGIC;   -- entree bouton brute (asynchrone)
        BTN_CLEAN : out STD_LOGIC    -- sortie synchronisee et anti-rebondie
    );
end button_debouncer;

architecture Behavioral of button_debouncer is

    signal sync_0  : STD_LOGIC := '0';   -- 1er etage de synchronisation
    signal sync_1  : STD_LOGIC := '0';   -- 2e etage de synchronisation
    signal clean_r : STD_LOGIC := '0';   -- sortie filtree
    signal cnt     : integer range 0 to DEBOUNCE_CYCLES := 0;

    -- ASYNC_REG : indique a Vivado que ces bascules recoivent un signal
    -- asynchrone et doivent etre placees au plus pres pour maximiser le temps
    -- de resolution de metastabilite (corrige m-5).
    attribute ASYNC_REG : string;
    attribute ASYNC_REG of sync_0 : signal is "TRUE";
    attribute ASYNC_REG of sync_1 : signal is "TRUE";

begin

    BTN_CLEAN <= clean_r;

    process(CLK)
    begin
        if rising_edge(CLK) then
            -- Synchroniseur 2 bascules : recale BTN_RAW sur le domaine CLK.
            sync_0 <= BTN_RAW;
            sync_1 <= sync_0;

            -- Anti-rebond : BTN_CLEAN ne suit sync_1 que si celui-ci est reste
            -- stable (different de la sortie actuelle) pendant DEBOUNCE_CYCLES.
            if sync_1 = clean_r then
                cnt <= 0;
            elsif cnt = DEBOUNCE_CYCLES - 1 then
                clean_r <= sync_1;
                cnt     <= 0;
            else
                cnt <= cnt + 1;
            end if;
        end if;
    end process;

end Behavioral;
