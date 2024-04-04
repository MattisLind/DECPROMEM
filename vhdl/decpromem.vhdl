library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity decpromem is
port (
    clk : in std_logic;
    mosi: out std_logic;
    miso: in std_logic;
    reset : in std_logic;
    ncs: out std_logic;
    nhold: out std_logic
);
end entity decpromem;
architecture rtl of decpromem is
    signal state : integer range 0 to 33;
    signal inputShiftReg: std_logic_vector(7 downto 0);
begin
    process(clk,reset)
    begin
        if reset = '1' then
            state <= 0;
            ncs <= '1';
            nhold <= '1';
        elsif (falling_edge(clk)) then
            if (state < 33) then
                state <= state + 1; 
            end if;
            if (state = 7 or state = 8) then
                mosi <= '1';
            else 
                mosi <= '0';
            end if;
            if (state = 1) then 
                ncs <= '0';
            end if;
            if (state > 16 and state < 24) then
                inputShiftReg <= inputShiftReg(inputShiftReg'high - 1 downto inputShiftReg'low) & miso;           
            end if;
        end if;
    end process;
end architecture rtl;