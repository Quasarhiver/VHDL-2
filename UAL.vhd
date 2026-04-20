library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity UAL is
    Port (
        A         : in  STD_LOGIC_VECTOR(3 downto 0);
        B         : in  STD_LOGIC_VECTOR(3 downto 0);
        SEL_FCT   : in  STD_LOGIC_VECTOR(3 downto 0);
        SR_IN_L   : in  STD_LOGIC;
        SR_IN_R   : in  STD_LOGIC;

        S         : out STD_LOGIC_VECTOR(7 downto 0);
        SR_OUT_L  : out STD_LOGIC;
        SR_OUT_R  : out STD_LOGIC
    );
end UAL;

architecture Behavioral of UAL is
begin
    process(A, B, SEL_FCT, SR_IN_L, SR_IN_R)
        variable a_u    : unsigned(3 downto 0);
        variable b_u    : unsigned(3 downto 0);
        variable res4   : unsigned(3 downto 0);
        variable res5   : unsigned(4 downto 0);
        variable res8   : unsigned(7 downto 0);
    begin
        a_u := unsigned(A);
        b_u := unsigned(B);

        res4 := (others => '0');
        res5 := (others => '0');
        res8 := (others => '0');

        SR_OUT_L <= '0';
        SR_OUT_R <= '0';

        case SEL_FCT is
            when "0000" => -- nop
                res8 := (others => '0');

            when "0001" => -- A
                res8(3 downto 0) := a_u;

            when "0010" => -- not A
                res8(3 downto 0) := not a_u;

            when "0011" => -- B
                res8(3 downto 0) := b_u;

            when "0100" => -- not B
                res8(3 downto 0) := not b_u;

            when "0101" => -- A and B
                res8(3 downto 0) := a_u and b_u;

            when "0110" => -- A or B
                res8(3 downto 0) := a_u or b_u;

            when "0111" => -- A xor B
                res8(3 downto 0) := a_u xor b_u;

            when "1000" => -- A + B + 1
                res5 := ('0' & a_u) + ('0' & b_u) + 1;
                res8(4 downto 0) := res5;

            when "1001" => -- A + B
                res5 := ('0' & a_u) + ('0' & b_u);
                res8(4 downto 0) := res5;

            when "1010" => -- A - B
                res8(3 downto 0) := a_u - b_u;

            when "1011" => -- A * B
                res8 := a_u * b_u;

            when "1100" => -- décalage droite A
                res8(3 downto 0) := unsigned(SR_IN_L & A(3 downto 1));
                SR_OUT_R <= A(0);

            when "1101" => -- décalage gauche A
                res8(3 downto 0) := unsigned(A(2 downto 0) & SR_IN_R);
                SR_OUT_L <= A(3);

            when "1110" => -- décalage droite B
                res8(3 downto 0) := unsigned(SR_IN_L & B(3 downto 1));
                SR_OUT_R <= B(0);

            when "1111" => -- décalage gauche B
                res8(3 downto 0) := unsigned(B(2 downto 0) & SR_IN_R);
                SR_OUT_L <= B(3);

            when others =>
                res8 := (others => '0');
        end case;

        S <= std_logic_vector(res8);
    end process;
end Behavioral;
