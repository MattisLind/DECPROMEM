library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;

entity CY62167 is
port(
  signal address : in std_logic_vector (19 downto 0);
  signal data: inout std_logic_vector (15 downto 0);
  signal ce2: in std_logic;
  signal nce1: in std_logic;
  signal nbhe: in std_logic;
  signal nble: in std_logic;
  signal nwe: in std_logic;
  signal noe: in std_logic
);
end CY62167;

architecture rtl of CY62167 is

type RAM is array (0 to 1024) of std_logic_vector(7 downto 0);
--type RAM is array (0 to 1048576) of std_logic_vector(7 downto 0);
signal memUpper : RAM := (others => "00000000");
signal memLower : RAM := (others => "00000000");
signal data_out : std_logic_vector (15 downto 0);
begin 


data(7 downto 0)   <= data_out (7 downto 0)  when ce2 = '1' and nce1 = '0' and noe = '0' and nwe = '1' and nble = '0' else "ZZZZZZZZ"; 
data(15 downto 8)  <= data_out (15 downto 8) when ce2 = '1' and nce1 = '0' and noe = '0' and nwe = '1' and nbhe = '0' else "ZZZZZZZZ"; 

MEM_WRITE: process (address, data, nce1, ce2, nwe) begin
  if (nce1 = '0' and ce2 = '1' and nwe = '0') then
    if (nble = '0') then
      memLower(to_integer(unsigned(address))) <= data(7 downto 0);
    end if;
    if (nbhe = '0') then
      memUpper(to_integer(unsigned(address))) <= data(15 downto 8);
    end if;
  end if;
end process;


MEM_READ: process (address, nce1, ce2, memUpper, memLower) begin
  if (nce1 = '0' and ce2 = '1')   then
    data_out <= memUpper(to_integer(unsigned(address))) & memLower(to_integer(unsigned(address)));
  end if;
end process;  
  

end rtl;