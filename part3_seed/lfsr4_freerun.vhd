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
