-- =============================================================================
-- Module      : datapath.vhd
-- Description : Chemin de données du cœur MCU.
--               Instancie l'UAL et gère tous les registres internes :
--               BufferA (8b), BufferB (8b), MEMCACHE1 (8b), MEMCACHE2 (8b),
--               MEMSELFCT (4b), MEMSELOUT (2b), MEMSRINL (1b), MEMSRINR (1b).
--               Le routage (SELROUTE 4 bits, 16 cas) et la sortie (SELOUT 2 bits)
--               sont entièrement implémentés.
-- Auteur      : Projet LogiGame – TE608 EFREI 2025-2026
-- Cible       : Xilinx Artix-35T – Vivado / GHDL
-- Révision    : 1.0 – Avril 2026
-- =============================================================================
-- Ports :
--   CLK      : horloge 100 MHz (front montant actif)
--   RESET    : reset asynchrone actif haut
--   A_IN     : entrée opérande A (4 bits)
--   B_IN     : entrée opérande B (4 bits)
--   SRINL    : bit série entrant gauche
--   SRINR    : bit série entrant droit
--   SELFCT   : code opération UAL (4 bits) – mémorisé dans MEMSELFCT
--   SELROUTE : sélection du transfert de données (4 bits)
--   SELOUT   : sélection de la sortie RESOUT (2 bits) – mémorisé dans MEMSELOUT
--   RESOUT   : résultat 8 bits
--   SROUTL   : bit sortant gauche (UAL)
--   SROUTR   : bit sortant droit  (UAL)
-- =============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity datapath is
    Port (
        CLK      : in  STD_LOGIC;
        RESET    : in  STD_LOGIC;
        -- Entrées opérandes
        A_IN     : in  STD_LOGIC_VECTOR(3 downto 0);
        B_IN     : in  STD_LOGIC_VECTOR(3 downto 0);
        -- Ports série
        SRINL    : in  STD_LOGIC;
        SRINR    : in  STD_LOGIC;
        -- Contrôle
        SELFCT   : in  STD_LOGIC_VECTOR(3 downto 0);
        SELROUTE : in  STD_LOGIC_VECTOR(3 downto 0);
        SELOUT   : in  STD_LOGIC_VECTOR(1 downto 0);
        -- Sorties
        RESOUT   : out STD_LOGIC_VECTOR(7 downto 0);
        SROUTL   : out STD_LOGIC;
        SROUTR   : out STD_LOGIC
    );
end datapath;

architecture Behavioral of datapath is

    -- =========================================================================
    -- Composant UAL
    -- =========================================================================
    component ual is
        Port (
            A       : in  STD_LOGIC_VECTOR(3 downto 0);
            B       : in  STD_LOGIC_VECTOR(3 downto 0);
            SEL_FCT : in  STD_LOGIC_VECTOR(3 downto 0);
            SRINL   : in  STD_LOGIC;
            SRINR   : in  STD_LOGIC;
            S       : out STD_LOGIC_VECTOR(7 downto 0);
            SROUTL  : out STD_LOGIC;
            SROUTR  : out STD_LOGIC
        );
    end component;

    -- =========================================================================
    -- Registres internes
    -- =========================================================================
    signal BufferA    : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    signal BufferB    : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    signal MEMCACHE1  : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    signal MEMCACHE2  : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    signal MEMSELFCT  : STD_LOGIC_VECTOR(3 downto 0) := (others => '0');
    signal MEMSELOUT  : STD_LOGIC_VECTOR(1 downto 0) := (others => '0');
    signal MEMSRINL   : STD_LOGIC := '0';
    signal MEMSRINR   : STD_LOGIC := '0';

    -- =========================================================================
    -- Signaux de connexion UAL
    -- =========================================================================
    signal ual_A      : STD_LOGIC_VECTOR(3 downto 0);
    signal ual_B      : STD_LOGIC_VECTOR(3 downto 0);
    signal ual_S      : STD_LOGIC_VECTOR(7 downto 0);
    signal ual_SROUTL : STD_LOGIC;
    signal ual_SROUTR : STD_LOGIC;

begin

    -- =========================================================================
    -- Instanciation de l'UAL
    -- Les opérandes de l'UAL sont les 4 LSB des buffers
    -- =========================================================================
    UAL_INST : ual
        port map (
            A       => ual_A,
            B       => ual_B,
            SEL_FCT => MEMSELFCT,
            SRINL   => MEMSRINL,
            SRINR   => MEMSRINR,
            S       => ual_S,
            SROUTL  => ual_SROUTL,
            SROUTR  => ual_SROUTR
        );

    -- Les 4 LSBs des buffers alimentent l'UAL
    ual_A <= BufferA(3 downto 0);
    ual_B <= BufferB(3 downto 0);

    -- Sorties série directement issues de l'UAL (combinatoires)
    SROUTL <= ual_SROUTL;
    SROUTR <= ual_SROUTR;

    -- =========================================================================
    -- Process séquentiel : front montant CLK, reset asynchrone actif haut
    -- =========================================================================
    process(CLK, RESET)
    begin
        if RESET = '1' then
            -- Reset asynchrone : tout à zéro
            BufferA   <= (others => '0');
            BufferB   <= (others => '0');
            MEMCACHE1 <= (others => '0');
            MEMCACHE2 <= (others => '0');
            MEMSELFCT <= (others => '0');
            MEMSELOUT <= (others => '0');
            MEMSRINL  <= '0';
            MEMSRINR  <= '0';

        elsif rising_edge(CLK) then

            -- -----------------------------------------------------------------
            -- Mémorisation systématique des signaux de contrôle
            -- (MEM_SEL_FCT, MEM_SEL_OUT, MEM_SRINL, MEM_SRINR chargés à chaque cycle)
            -- -----------------------------------------------------------------
            MEMSELFCT <= SELFCT;
            MEMSELOUT <= SELOUT;
            MEMSRINL  <= SRINL;
            MEMSRINR  <= SRINR;

            -- -----------------------------------------------------------------
            -- Routage des données selon SELROUTE
            -- (le routage définit le transfert qui s'effectue sur ce front montant)
            -- -----------------------------------------------------------------
-- -----------------------------------------------------------------
            -- Routage des données selon SELROUTE
            -- -----------------------------------------------------------------
            case SELROUTE is

                -- 0000 : BufferA ← A_IN (zero-étendu à 8 bits)
                when "0000" =>
                    BufferA <= "0000" & A_IN;

                -- 0001 : BufferB ← B_IN
                when "0001" =>
                    BufferB <= "0000" & B_IN;

                -- 0010 : BufferA[3:0] ← S[3:0]  (4 bits de poids faibles de S → nibble bas de A)
                when "0010" =>
                    BufferA(3 downto 0) <= ual_S(3 downto 0);
                    BufferA(7 downto 4) <= BufferA(7 downto 4);

                -- 0011 : BufferA[3:0] ← S[7:4]  (4 bits de poids forts de S → nibble bas de A)
                when "0011" =>
                    BufferA(3 downto 0) <= ual_S(7 downto 4);
                    BufferA(7 downto 4) <= BufferA(7 downto 4);

                -- 0100 : BufferB[3:0] ← S[3:0]
                when "0100" =>
                    BufferB(3 downto 0) <= ual_S(3 downto 0);
                    BufferB(7 downto 4) <= BufferB(7 downto 4);

                -- 0101 : BufferB[3:0] ← S[7:4]  (4 bits de poids forts de S → nibble bas de B)
                when "0101" =>
                    BufferB(3 downto 0) <= ual_S(7 downto 4);
                    BufferB(7 downto 4) <= BufferB(7 downto 4);

                -- 0110 : MEMCACHE1 ← S  (8 bits complets)
                when "0110" =>
                    MEMCACHE1 <= ual_S;

                -- 0111 : MEMCACHE2 ← S
                when "0111" =>
                    MEMCACHE2 <= ual_S;

                -- 1000 : BufferA[3:0] ← MEMCACHE1[3:0]
                when "1000" =>
                    BufferA(3 downto 0) <= MEMCACHE1(3 downto 0);
                    BufferA(7 downto 4) <= BufferA(7 downto 4);

                -- 1001 : BufferA[3:0] ← MEMCACHE1[7:4]  (nibble fort de MC1 → nibble bas de A)
                when "1001" =>
                    BufferA(3 downto 0) <= MEMCACHE1(7 downto 4);
                    BufferA(7 downto 4) <= BufferA(7 downto 4);

                -- 1010 : BufferB[3:0] ← MEMCACHE1[3:0]
                when "1010" =>
                    BufferB(3 downto 0) <= MEMCACHE1(3 downto 0);
                    BufferB(7 downto 4) <= BufferB(7 downto 4);

                -- 1011 : BufferB[3:0] ← MEMCACHE1[7:4]
                when "1011" =>
                    BufferB(3 downto 0) <= MEMCACHE1(7 downto 4);
                    BufferB(7 downto 4) <= BufferB(7 downto 4);

                -- 1100 : BufferA[3:0] ← MEMCACHE2[3:0]
                when "1100" =>
                    BufferA(3 downto 0) <= MEMCACHE2(3 downto 0);
                    BufferA(7 downto 4) <= BufferA(7 downto 4);

                -- 1101 : BufferA[3:0] ← MEMCACHE2[7:4]
                when "1101" =>
                    BufferA(3 downto 0) <= MEMCACHE2(7 downto 4);
                    BufferA(7 downto 4) <= BufferA(7 downto 4);

                -- 1110 : BufferB[3:0] ← MEMCACHE2[3:0]
                when "1110" =>
                    BufferB(3 downto 0) <= MEMCACHE2(3 downto 0);
                    BufferB(7 downto 4) <= BufferB(7 downto 4);

                -- 1111 : BufferB[3:0] ← MEMCACHE2[7:4]
                when "1111" =>
                    BufferB(3 downto 0) <= MEMCACHE2(7 downto 4);
                    BufferB(7 downto 4) <= BufferB(7 downto 4);

                when others =>
                    null;

            end case;
        end if;
    end process;

    -- =========================================================================
    -- Sortie RESOUT (combinatoire, basée sur MEMSELOUT mémorisé)
    -- =========================================================================
    process(MEMSELOUT, MEMCACHE1, MEMCACHE2, ual_S)
    begin
        case MEMSELOUT is
            when "00"   => RESOUT <= (others => '0');  -- Aucune sortie
            when "01"   => RESOUT <= MEMCACHE1;
            when "10"   => RESOUT <= MEMCACHE2;
            when "11"   => RESOUT <= ual_S;
            when others => RESOUT <= (others => '0');
        end case;
    end process;

end Behavioral;
