-- =============================================================================
-- Module      : ual.vhd
-- Description : Unité Arithmétique et Logique (UAL) 4 bits signés, 16 opérations
--               Entrées A et B sur 4 bits signés, sortie S sur 8 bits.
--               Ports de décalage série : SRINL (gauche), SRINR (droite),
--               SROUTL (bit sortant gauche), SROUTR (bit sortant droite).

-- =============================================================================
-- Table SEL_FCT :
--  0000 NOP      S=0,  SROUTL=0, SROUTR=0
--  0001 A        S=A (sign-ext)
--  0010 notA     S=not A (sign-ext)
--  0011 B        S=B (sign-ext)
--  0100 notB     S=not B (sign-ext)
--  0101 A and B  S=A and B
--  0110 A or  B  S=A or  B
--  0111 A xor B  S=A xor B
--  1000 A+B+Cin  addition avec retenue SRINR
--  1001 A+B      addition sans retenue
--  1010 A-B      soustraction
--  1011 A*B      multiplication (résultat 8 bits)
--  1100 SRA      décalage droite A  (SRINL→MSB, LSB→SROUTR)
--  1101 SLA      décalage gauche A  (SRINR→LSB, MSB→SROUTL)
--  1110 SRB      décalage droite B  (SRINL→MSB, LSB→SROUTR)
--  1111 SLB      décalage gauche B  (SRINR→LSB, MSB→SROUTL)
-- =============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ual is
    Port (
        -- Opérandes 4 bits signés
        A       : in  STD_LOGIC_VECTOR(3 downto 0);  -- Opérande A
        B       : in  STD_LOGIC_VECTOR(3 downto 0);  -- Opérande B
        -- Sélection de l'opération
        SEL_FCT : in  STD_LOGIC_VECTOR(3 downto 0);  -- Code opération (16 cas)
        -- Ports série de décalage
        SRINL   : in  STD_LOGIC;                      -- Bit entrant gauche (décalage droite)
        SRINR   : in  STD_LOGIC;                      -- Bit entrant droit  (décalage gauche)
        -- Résultat 8 bits
        S       : out STD_LOGIC_VECTOR(7 downto 0);   -- Résultat étendu 8 bits
        -- Bits sortants série
        SROUTL  : out STD_LOGIC;                      -- Bit sortant gauche (décalage gauche)
        SROUTR  : out STD_LOGIC                       -- Bit sortant droite  (décalage droite)
    );
end ual;

architecture Behavioral of ual is

begin

    -- Process purement combinatoire : calcul selon SEL_FCT
    process(A, B, SEL_FCT, SRINL, SRINR)
        variable vA       : signed(4 downto 0);
        variable vB       : signed(4 downto 0);
        variable vMul     : signed(7 downto 0);
        variable sum_s    : signed(4 downto 0);
        variable diff_s   : signed(4 downto 0);
        variable shifted  : std_logic_vector(3 downto 0);
    begin
        -- Valeurs par défaut (évite latch)
        S      <= (others => '0');
        SROUTL <= '0';
        SROUTR <= '0';

        vA       := resize(signed(A), 5);
        vB       := resize(signed(B), 5);
        vMul     := signed(A) * signed(B);  -- multiplication 4b × 4b → 8b
        sum_s    := (others => '0');
        diff_s   := (others => '0');
        shifted  := (others => '0');

        case SEL_FCT is

            -- ----------------------------------------------------------------
            -- 0000 : NOP – S=0
            -- ----------------------------------------------------------------
            when "0000" =>
                S      <= (others => '0');
                SROUTL <= '0';
                SROUTR <= '0';

            -- ----------------------------------------------------------------
            -- 0001 : S = A (extension de signe)
            -- ----------------------------------------------------------------
            when "0001" =>
                S      <= std_logic_vector(resize(signed(A), 8));
                SROUTL <= '0';
                SROUTR <= '0';

            -- ----------------------------------------------------------------
            -- 0010 : S = not A (extension de signe puis NOT)
            -- ----------------------------------------------------------------
            when "0010" =>
                S      <= std_logic_vector(not resize(signed(A), 8));
                SROUTL <= '0';
                SROUTR <= '0';

            -- ----------------------------------------------------------------
            -- 0011 : S = B
            -- ----------------------------------------------------------------
            when "0011" =>
                S      <= std_logic_vector(resize(signed(B), 8));
                SROUTL <= '0';
                SROUTR <= '0';

            -- ----------------------------------------------------------------
            -- 0100 : S = not B
            -- ----------------------------------------------------------------
            when "0100" =>
                S      <= std_logic_vector(not resize(signed(B), 8));
                SROUTL <= '0';
                SROUTR <= '0';

            -- ----------------------------------------------------------------
            -- 0101 : S = A and B (bit à bit, 4 bits, zero-étendu)
            -- ----------------------------------------------------------------
            when "0101" =>
                S      <= "0000" & (A and B);
                SROUTL <= '0';
                SROUTR <= '0';

            -- ----------------------------------------------------------------
            -- 0110 : S = A or B
            -- ----------------------------------------------------------------
            when "0110" =>
                S      <= "0000" & (A or B);
                SROUTL <= '0';
                SROUTR <= '0';

            -- ----------------------------------------------------------------
            -- 0111 : S = A xor B
            -- ----------------------------------------------------------------
            when "0111" =>
                S      <= "0000" & (A xor B);
                SROUTL <= '0';
                SROUTR <= '0';

            -- ----------------------------------------------------------------
            -- 1000 : S = A + B + SRINR (addition avec retenue d'entrée)
            -- ----------------------------------------------------------------
            when "1000" =>
                sum_s := vA + vB;
                if SRINR = '1' then
                    sum_s := sum_s + to_signed(1, 5);
                end if;
                S      <= std_logic_vector(resize(sum_s, 8));
                SROUTL <= '0';
                SROUTR <= '0';

            -- ----------------------------------------------------------------
            -- 1001 : S = A + B (sans retenue)
            -- ----------------------------------------------------------------
            when "1001" =>
                sum_s := vA + vB;
                S      <= std_logic_vector(resize(sum_s, 8));
                SROUTL <= '0';
                SROUTR <= '0';

            -- ----------------------------------------------------------------
            -- 1010 : S = A - B
            -- ----------------------------------------------------------------
            when "1010" =>
                diff_s := vA - vB;
                S      <= std_logic_vector(resize(diff_s, 8));
                SROUTL <= '0';
                SROUTR <= '0';

            -- ----------------------------------------------------------------
            -- 1011 : S = A * B (résultat complet 8 bits)
            -- ----------------------------------------------------------------
            when "1011" =>
                S      <= std_logic_vector(vMul);
                SROUTL <= '0';
                SROUTR <= '0';

            -- ----------------------------------------------------------------
            -- 1100 : SRA – Décalage droite de A sur 4 bits
            --         SRINL → A[3], A[0] → SROUTR
            -- ----------------------------------------------------------------
            when "1100" =>
                shifted := SRINL & A(3 downto 1);
                S       <= "0000" & shifted;
                SROUTL  <= '0';
                SROUTR  <= A(0);

            -- ----------------------------------------------------------------
            -- 1101 : SLA – Décalage gauche de A sur 4 bits
            --         SRINR → A[0], A[3] → SROUTL
            -- ----------------------------------------------------------------
            when "1101" =>
                shifted := A(2 downto 0) & SRINR;
                S       <= "0000" & shifted;
                SROUTL  <= A(3);
                SROUTR  <= '0';

            -- ----------------------------------------------------------------
            -- 1110 : SRB – Décalage droite de B
            -- ----------------------------------------------------------------
            when "1110" =>
                shifted := SRINL & B(3 downto 1);
                S       <= "0000" & shifted;
                SROUTL  <= '0';
                SROUTR  <= B(0);

            -- ----------------------------------------------------------------
            -- 1111 : SLB – Décalage gauche de B
            -- ----------------------------------------------------------------
            when "1111" =>
                shifted := B(2 downto 0) & SRINR;
                S       <= "0000" & shifted;
                SROUTL  <= B(3);
                SROUTR  <= '0';

            when others =>
                S      <= (others => '0');
                SROUTL <= '0';
                SROUTR <= '0';

        end case;
    end process;

end Behavioral;
