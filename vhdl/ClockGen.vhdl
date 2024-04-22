library IEEE;
use IEEE.std_logic_1164.all;
use std.textio.all;

entity ClockGen is
port(
  signal CLK : out std_logic
);
end ClockGen;

architecture rtl of ClockGen is
signal latch: std_logic_vector (7 downto 0);
begin 
    process
    begin
        for i in 1 to 10000 loop  -- 40 MHz clock
            CLK <= '0'; 
            wait for 50 ns;
            CLK <= '1';
            wait for 50 ns;  
            end loop;
        assert false report "Clock generator done." severity note;
        wait;
    end process;
end rtl;