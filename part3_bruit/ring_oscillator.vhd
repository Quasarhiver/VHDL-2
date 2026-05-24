-- =============================================================================
-- Module      : ring_oscillator.vhd
-- Description : Oscillateur en anneau (ring oscillator) - brique de base du
--               vrai generateur d'aleatoire materiel (TRNG) de la Partie 3
--               variante BRUIT.
--
--               Un oscillateur en anneau = un nombre IMPAIR d'inverseurs
--               reboucles sur eux-memes. Comme le nombre d'etages est impair,
--               la boucle ne peut pas se stabiliser : elle oscille en
--               permanence. La frequence depend uniquement des delais de
--               propagation des portes, qui :
--                 - ne sont pas controlables par le concepteur ;
--                 - derivent avec la temperature et la tension ;
--                 - tremblent en permanence a cause du BRUIT THERMIQUE (jitter).
--
--               C'est ce jitter imprevisible qui, une fois echantillonne par
--               une horloge fixe, fournit de l'entropie physique reelle.
--
--               SIMULATION vs SYNTHESE :
--                 - le delai 'after' (2 ns par etage ci-dessous) donne a la
--                   boucle une periode finie en SIMULATION (sinon la boucle
--                   combinatoire bouclerait sans fin en delta-cycles). Cette
--                   valeur est ARBITRAIRE et n'a aucun sens physique : elle
--                   n'existe que pour la simulation. En simulation l'oscillateur
--                   est donc DETERMINISTE : le vrai aleatoire n'existe que sur
--                   silicium (jitter thermique reel).
--                 - en SYNTHESE, 'after' est ignore ; les attributs KEEP /
--                   DONT_TOUCH empechent Vivado de supprimer la boucle (il la
--                   considererait sinon comme une erreur a optimiser).
--                 - la boucle combinatoire est autorisee directement en RTL
--                   via l'attribut ALLOW_COMBINATORIAL_LOOPS pose ci-dessous
--                   (aucune intervention dans le .xdc n'est necessaire).
-- Auteur      : Projet LogiGame - TE608 EFREI 2025-2026
-- Cible       : Xilinx Artix-35T - Vivado / GHDL
-- =============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity ring_oscillator is
    Generic (
        N_STAGES : integer := 5    -- nombre d'inverseurs, DOIT etre impair
    );
    Port (
        EN  : in  STD_LOGIC;       -- '1' = anneau actif (oscille)
        OSC : out STD_LOGIC        -- sortie oscillante
    );
end ring_oscillator;

architecture rtl of ring_oscillator is

    -- Chaine d'inverseurs. chain(i) = sortie du i-eme inverseur.
    signal chain : STD_LOGIC_VECTOR(N_STAGES-1 downto 0) := (others => '0');

    -- Attributs de synthese :
    --  - KEEP / DONT_TOUCH : interdisent a Vivado de supprimer ou de fusionner
    --    la chaine (sans cela, l'oscillateur disparaitrait a la synthese) ;
    --  - ALLOW_COMBINATORIAL_LOOPS : autorise explicitement la boucle
    --    combinatoire volontaire de l'anneau (sinon Vivado la traite en erreur).
    --    Pose directement en RTL : pas besoin de connaitre le nom de net ni de
    --    modifier le fichier .xdc.
    attribute KEEP                      : string;
    attribute DONT_TOUCH                : string;
    attribute ALLOW_COMBINATORIAL_LOOPS : string;
    attribute KEEP                      of chain : signal is "true";
    attribute DONT_TOUCH                of chain : signal is "true";
    attribute ALLOW_COMBINATORIAL_LOOPS of chain : signal is "true";

begin

    -- Garde de conception : un anneau a nombre PAIR d'inverseurs se stabilise
    -- au lieu d'osciller. On interdit donc cette configuration des l'elaboration.
    assert (N_STAGES mod 2) = 1
        report "ring_oscillator: N_STAGES doit etre impair (sinon pas d'oscillation)"
        severity failure;

    -- Premier etage : inverseur + porte d'activation EN.
    -- Quand EN = '0' la sortie est forcee a '0' : l'anneau s'arrete (utile pour
    -- ne pas faire osciller inutilement, et pour stopper la simulation).
    chain(0) <= (EN and (not chain(N_STAGES-1))) after 2 ns;

    -- Etages suivants : simples inverseurs en cascade.
    gen_inv : for i in 1 to N_STAGES-1 generate
        chain(i) <= (not chain(i-1)) after 2 ns;
    end generate;

    OSC <= chain(N_STAGES-1);

end rtl;
