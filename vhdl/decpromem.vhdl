library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity decpromem is
port (
    clk : in std_logic;
    mosi: out std_logic;
    reset : in std_logic
);
end entity decpromem;
architecture rtl of decpromem is
    signal state : unsigned(5 downto 0);
begin
    process(clk)
    begin
        if(rising_edge(clk)) then
            state <= state + 1;
            if reset = '1' then
                state <= (others => '0');
            end if;
            if (state = 6 or state = 7) then
              mosi <= '1';
            else 
              mosi <= '0';
            end if;
        end if;
    end process;
end architecture rtl;