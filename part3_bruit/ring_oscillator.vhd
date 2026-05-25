

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity ring_oscillator is
    Generic (
        N_STAGES : integer := 5   
    );
    Port (
        EN  : in  STD_LOGIC;      
        OSC : out STD_LOGIC        
    );
end ring_oscillator;

architecture rtl of ring_oscillator is


    signal chain : STD_LOGIC_VECTOR(N_STAGES-1 downto 0) := (others => '0');


    attribute KEEP                      : string;
    attribute DONT_TOUCH                : string;
    attribute ALLOW_COMBINATORIAL_LOOPS : string;
    attribute KEEP                      of chain : signal is "true";
    attribute DONT_TOUCH                of chain : signal is "true";
    attribute ALLOW_COMBINATORIAL_LOOPS of chain : signal is "true";

begin

    assert (N_STAGES mod 2) = 1
        report "ring_oscillator: N_STAGES doit etre impair (sinon pas d'oscillation)"
        severity failure;

   
    chain(0) <= (EN and (not chain(N_STAGES-1))) after 2 ns;

    
    gen_inv : for i in 1 to N_STAGES-1 generate
        chain(i) <= (not chain(i-1)) after 2 ns;
    end generate;

    OSC <= chain(N_STAGES-1);

end rtl;
