-- =============================================================================
-- Module      : seed_generator.vhd
-- Description : Generateur de seed "vrai aleatoire" pour la Partie 3 (variante
--               SEED). Au lieu d'utiliser une seed figee ("1011"), on derive la
--               seed du LFSR du COMPORTEMENT HUMAIN : la duree pendant laquelle
--               le joueur maintient le bouton de lancement appuye.
--
--               Cette duree est mesuree A LA MILLISECONDE PRES. Les bits de
--               poids faible de cette duree sont imprevisibles : un humain ne
--               peut pas controler son appui a la milliseconde. C'est donc une
--               vraie source d'entropie physique, contrairement a une seed
--               constante.
--
--               Fonctionnement :
--                 - un diviseur 100 MHz -> 1 kHz genere un tick "1 ms" ;
--                 - tant que le bouton est appuye, un compteur de ms avance ;
--                 - au relachement du bouton (= lancement du jeu), la duree
--                   mesuree est repliee (XOR-folding) sur 4 bits et latchee ;
--                 - une seed nulle est interdite (etat verrouille du LFSR),
--                   donc une duree donnant 0000 est remplacee par "1011".
--
--               IMPORTANT - l'entree BTN_CLEAN DOIT etre un signal deja
--               synchronise et anti-rebondi (voir button_debouncer.vhd). Sans
--               anti-rebond, les rebonds mecaniques du poussoir au relachement
--               creeraient de faux fronts montants qui remettraient le compteur
--               a zero : la duree mesuree serait fausse et la seed degenererait
--               (bug M-4). Ce module suppose donc une entree propre.
--
--               Ce module n'a PAS d'entree RESET : btn[0] sert aussi de reset
--               global, donc le compteur doit tourner PENDANT l'appui. L'etat
--               initial repose sur les valeurs ':=' (garanties par le bitstream
--               sur cible Xilinx).
-- Auteur      : Projet LogiGame - TE608 EFREI 2025-2026
-- Cible       : Xilinx Artix-35T - Vivado / GHDL
-- =============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity seed_generator is
    Port (
        CLK       : in  STD_LOGIC;                     -- horloge 100 MHz
        BTN_CLEAN : in  STD_LOGIC;                     -- btn[0] deja anti-rebondi
        SEED      : out STD_LOGIC_VECTOR(3 downto 0)   -- seed 4 bits, jamais nulle
    );
end seed_generator;

architecture Behavioral of seed_generator is

    -- Diviseur 100 MHz -> 1 kHz : 100 000 cycles = 1 ms
    constant DIV_MAX : integer := 99999;

    signal div_cnt  : integer range 0 to DIV_MAX := 0;
    signal ms_tick  : STD_LOGIC := '0';

    -- Compteur de duree d'appui, en millisecondes (16 bits = jusqu'a 65 s)
    signal ms_cnt   : unsigned(15 downto 0) := (others => '0');

    signal btn_d    : STD_LOGIC := '0';                 -- btn retarde (front)
    signal seed_reg : STD_LOGIC_VECTOR(3 downto 0) := "1011";

begin

    SEED <= seed_reg;

    process(CLK)
        variable fold : STD_LOGIC_VECTOR(3 downto 0);
    begin
        if rising_edge(CLK) then

            -- -----------------------------------------------------------------
            -- Diviseur de frequence : genere un tick toutes les 1 ms
            -- -----------------------------------------------------------------
            if div_cnt = DIV_MAX then
                div_cnt <= 0;
                ms_tick <= '1';
            else
                div_cnt <= div_cnt + 1;
                ms_tick <= '0';
            end if;

            -- -----------------------------------------------------------------
            -- Mesure de la duree d'appui (sur le signal deja anti-rebondi)
            -- -----------------------------------------------------------------
            btn_d <= BTN_CLEAN;

            if BTN_CLEAN = '1' and btn_d = '0' then
                -- Front montant : debut de l'appui -> on repart de zero
                ms_cnt <= (others => '0');

            elsif BTN_CLEAN = '1' then
                -- Appui maintenu : on compte les millisecondes
                if ms_tick = '1' then
                    ms_cnt <= ms_cnt + 1;
                end if;

            elsif BTN_CLEAN = '0' and btn_d = '1' then
                -- Front descendant : relachement = lancement du jeu
                -- On replie la duree (16 bits) sur 4 bits par XOR-folding,
                -- ce qui melange tous les bits de poids de la mesure.
                fold := std_logic_vector(ms_cnt(3 downto 0))
                    xor std_logic_vector(ms_cnt(7 downto 4))
                    xor std_logic_vector(ms_cnt(11 downto 8))
                    xor std_logic_vector(ms_cnt(15 downto 12));

                if fold = "0000" then
                    -- Seed nulle interdite : on force une valeur non nulle
                    seed_reg <= "1011";
                else
                    seed_reg <= fold;
                end if;
            end if;

        end if;
    end process;

end Behavioral;
