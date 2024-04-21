library IEEE;
use IEEE.std_logic_1164.all;

entity SN74LS373 is
port(
  signal D : in std_logic_vector (7 downto 0);
  signal Q: out std_logic_vector (7 downto 0);
  signal C: in std_logic;
  signal nOC: in std_logic
);
end SN74LS373;

architecture rtl of SN74LS373 is
signal latch: std_logic_vector (7 downto 0);
begin 
    process (D, C)
    begin
        if (C = '0') then
            latch <= D;
        end if;
    end process;
    Q <= latch when nOC = '0' else "ZZZZZZZZ";
end rtl;