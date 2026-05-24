-- =============================================================================
-- Module      : trng.vhd
-- Description : Vrai generateur de nombres aleatoires materiel (True Random
--               Number Generator) pour la Partie 3 variante BRUIT.
--
--               Il REMPLACE COMPLETEMENT le LFSR / le sequenceur MCU : la
--               valeur produite n'est pas pseudo-aleatoire (pas de sequence
--               deterministe), elle vient directement du bruit thermique du
--               silicium.
--
--               Principe :
--                 1. Trois oscillateurs en anneau de longueurs differentes
--                    (7, 9, 11 etages) oscillent librement. Leurs frequences
--                    sont independantes et tremblent (jitter thermique). On
--                    evite volontairement les longueurs donnant, en simulation,
--                    une periode multiple de la periode d'echantillonnage.
--                 2. raw_noise = XOR des trois sorties -> combine les bruits.
--                 3. Un synchroniseur 2 bascules (ASYNC_REG) echantillonne
--                    raw_noise. La 1ere bascule peut devenir METASTABLE quand la
--                    capture tombe pendant une transition ; elle se resout dans
--                    un sens imprevisible (bruit thermique) -> source d'entropie.
--                 4. POST-TRAITEMENT / DE-BIAISAGE (corrige M-2) : un bit de RND
--                    n'est PAS un echantillon brut. Chaque bit publie est le XOR
--                    de DECIM echantillons consecutifs (decimation). Si la source
--                    brute a un biais (P(1) = 0.5 + e), le XOR de DECIM bits
--                    ramene le biais a ~ (2e)^DECIM / 2, donc quasi nul.
--                 5. Les bits de-biaises sont empiles dans un registre 4 bits.
--
--               Ce n'est pas un LFSR : aucun etat n'evolue tout seul, tout est
--               pilote par le bruit physique echantillonne.
-- Auteur      : Projet LogiGame - TE608 EFREI 2025-2026
-- Cible       : Xilinx Artix-35T - Vivado / GHDL
-- =============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity trng is
    Port (
        CLK   : in  STD_LOGIC;                    -- 100 MHz : horloge d'echantillonnage
        RESET : in  STD_LOGIC;                    -- reset asynchrone actif haut
        EN    : in  STD_LOGIC;                    -- '1' = oscillateurs actifs
        RND   : out STD_LOGIC_VECTOR(3 downto 0)  -- entropie 4 bits de-biaisee
    );
end trng;

architecture Behavioral of trng is

    component ring_oscillator is
        Generic ( N_STAGES : integer := 5 );
        Port (
            EN  : in  STD_LOGIC;
            OSC : out STD_LOGIC
        );
    end component;

    -- Nombre d'echantillons bruts XORes pour produire UN bit de-biaise.
    -- 31 est premier : il decorrele la decimation des periodes des anneaux.
    constant DECIM : integer := 31;

    signal osc0, osc1, osc2 : STD_LOGIC;
    signal raw_noise        : STD_LOGIC;

    signal meta_ff : STD_LOGIC := '0';   -- 1ere bascule : peut etre metastable
    signal sync_ff : STD_LOGIC := '0';   -- 2e bascule : resolution metastabilite

    signal bit_acc : STD_LOGIC := '0';                       -- XOR en cours
    signal dec_cnt : integer range 0 to DECIM-1 := 0;        -- compteur decimation
    signal rnd_reg : STD_LOGIC_VECTOR(3 downto 0) := "1011"; -- mot de sortie

    -- ASYNC_REG : place les bascules du synchroniseur au plus pres pour
    -- maximiser le temps de resolution de metastabilite (corrige m-5).
    attribute ASYNC_REG : string;
    attribute ASYNC_REG of meta_ff : signal is "TRUE";
    attribute ASYNC_REG of sync_ff : signal is "TRUE";

begin

    -- =========================================================================
    -- Trois oscillateurs en anneau de longueurs differentes : leurs frequences
    -- sont distinctes et independantes.
    -- =========================================================================
    RO0 : ring_oscillator generic map (N_STAGES => 7)
                          port map (EN => EN, OSC => osc0);
    RO1 : ring_oscillator generic map (N_STAGES => 9)
                          port map (EN => EN, OSC => osc1);
    RO2 : ring_oscillator generic map (N_STAGES => 11)
                          port map (EN => EN, OSC => osc2);

    -- Bruit brut = combinaison XOR des trois oscillateurs.
    raw_noise <= osc0 xor osc1 xor osc2;

    -- =========================================================================
    -- Echantillonnage + de-biaisage par decimation
    -- =========================================================================
    process(CLK, RESET)
    begin
        if RESET = '1' then
            meta_ff <= '0';
            sync_ff <= '0';
            bit_acc <= '0';
            dec_cnt <= 0;
            rnd_reg <= "1011";
        elsif rising_edge(CLK) then
            -- Synchroniseur 2 bascules. meta_ff peut etre metastable sur
            -- silicium : c'est precisement ce qui rend le bit imprevisible.
            meta_ff <= raw_noise;
            sync_ff <= meta_ff;

            -- Decimation : on accumule le XOR de DECIM echantillons consecutifs.
            if dec_cnt = DECIM-1 then
                -- Fin de fenetre : le bit de-biaise est pousse dans le mot RND.
                rnd_reg <= rnd_reg(2 downto 0) & (bit_acc xor sync_ff);
                bit_acc <= '0';
                dec_cnt <= 0;
            else
                bit_acc <= bit_acc xor sync_ff;
                dec_cnt <= dec_cnt + 1;
            end if;
        end if;
    end process;

    RND <= rnd_reg;

end Behavioral;
