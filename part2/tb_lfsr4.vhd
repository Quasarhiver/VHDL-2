-- =============================================================================
-- Module      : tb_lfsr4.vhd
-- Description : Testbench du LFSR4. Vérifie la séquence de 15 états.
-- =============================================================================
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_lfsr4 is
end tb_lfsr4;

architecture Behavioral of tb_lfsr4 is

    component lfsr4 is
        Port (
            CLK    : in  STD_LOGIC;
            RESET  : in  STD_LOGIC;
            ENABLE : in  STD_LOGIC;
            RND    : out STD_LOGIC_VECTOR(3 downto 0)
        );
    end component;

    constant CLK_P : time := 10 ns;

    signal CLK_tb    : STD_LOGIC := '0';
    signal RESET_tb  : STD_LOGIC := '1';
    signal ENABLE_tb : STD_LOGIC := '0';
    signal RND_tb    : STD_LOGIC_VECTOR(3 downto 0);

    type seq_t is array (0 to 14) of STD_LOGIC_VECTOR(3 downto 0);
    constant EXPECTED_SEQ : seq_t := (
        "0101", "1010", "1101", "0110", "0011",
        "1001", "0100", "0010", "0001", "1000",
        "1100", "1110", "1111", "0111", "1011"
    );

begin
    CLK_tb <= not CLK_tb after CLK_P/2;

    DUT : lfsr4
        port map (CLK => CLK_tb, RESET => RESET_tb, ENABLE => ENABLE_tb, RND => RND_tb);

    process
        -- Pour tester sans attendre 100k cycles, on envoie des pulses ENABLE
        -- directement sur l'horloge (simulation fonctionnelle)
    begin
        report "===== Testbench LFSR4 =====" severity note;

        RESET_tb  <= '1';
        ENABLE_tb <= '0';
        wait for 5 * CLK_P;
        RESET_tb <= '0';
        wait for CLK_P;

        -- Vérification seed initial
        wait for 2 ns;
        assert RND_tb = "1011"
            report "FAIL: seed initial attendu 1011, obtenu " &
                   integer'image(to_integer(unsigned(RND_tb))) severity error;
        report "Seed initial : " & integer'image(to_integer(unsigned(RND_tb))) &
               " (attendu 11=1011)" severity note;

        -- Vérification de la séquence maximale de 15 états non nuls.
        report "--- Séquence LFSR (15 pas) ---" severity note;
        ENABLE_tb <= '1';
        for i in 0 to 14 loop
            wait for 100000 * CLK_P;
            assert RND_tb = EXPECTED_SEQ(i)
                report "FAIL: etat LFSR[" & integer'image(i) & "] inattendu"
                severity error;
            report "RND[" & integer'image(i) & "] = " &
                   integer'image(to_integer(unsigned(RND_tb))) severity note;
        end loop;
        ENABLE_tb <= '0';

        report "===== LFSR4 terminé =====" severity note;
        wait;
    end process;

end Behavioral;
