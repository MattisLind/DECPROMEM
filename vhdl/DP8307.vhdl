library IEEE;
use IEEE.std_logic_1164.all;

entity DP8307 is
port(
  signal A : inout std_logic_vector (7 downto 0);
  signal B: inout std_logic_vector (7 downto 0);
  signal nT: in std_logic;
  signal nR: in std_logic
);
end DP8307;

architecture rtl of DP8307 is

begin 
    A <= not B when  nR = '0' else "ZZZZZZZZ";
    B <= not A when nT = '0' else "ZZZZZZZZ";
end rtl;