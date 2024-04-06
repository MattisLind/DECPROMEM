-- Testbench for the Alfaskop 3550 system
library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
 
entity testbench is
-- empty
end testbench; 

architecture tb of testbench is
-- DUT component

component decpromem is
port (
    clk : in std_logic;
    mosi: out std_logic;
    miso: in std_logic;
    reset : in std_logic;
    ncs: out std_logic;
    nhold: out std_logic
);
end component;



component DiagROM is 
port (
  address : in integer range 0 to 1023;
  data:  out std_logic;
  bitAddress: in integer range 0 to 7
);
end component;

type stateType is (STORECOMMAND, STOREADDRESS, OUTPUTDATA);
signal state: stateType;
signal clkInput, reset : std_logic;
signal cmd : std_logic_vector (7 downto 0);
signal ncs: std_logic;
signal mosi: std_logic;
signal miso: std_logic;
signal commandCount: integer range 0 to 7;
signal addressCount: integer range 0 to 16;
signal commandRegister: std_logic_vector (7 downto 0);
signal addressRegister: std_logic_vector (15 downto 0);
signal address: integer range 0 to 1023;
signal dataCount: integer range 0 to 7;
signal dataOut: std_logic;
begin
  address <= to_integer(unsigned(addressRegister));
  ROM: DiagROM port map(
    address => address,
    data => dataOut,
    bitAddress => dataCount
  );
  -- Connect DUT
  DUT: decpromem port map(
-- Clk is to be generated externally    
    clk => clkInput,
    reset => reset,
    ncs => ncs,
    mosi => mosi,
    miso => miso
    );
  CLK: process
  begin
    reset <= '0';
    wait for 200 ns;
    reset <= '1';
    wait for 200 ns;
    reset <= '0';
    wait for 200 ns;
    for i in 1 to 128 loop
      clkInput <= '0'; 
      wait for 200 ns;
      clkInput <= '1';
      wait for 200 ns;  
    end loop;
    assert false report "Test done." severity note;
    wait;
  end process;

  EEPROM: process(clkInput, ncs)
  begin
    if ncs = '1' then
      state <= STORECOMMAND;
      addressCount <= 0;
      commandCount <= 0;
      commandRegister <= "00000000";
      addressRegister <= "0000000000000000";
    elsif (rising_edge(clkInput)) then
      case state is
        when STORECOMMAND =>
          commandRegister <= commandRegister(commandRegister'high - 1 downto commandRegister'low) & mosi; 
          if commandCount = 7 then
            state <= STOREADDRESS;
          else 
            commandCount <= commandCount + 1;
          end if;
        when STOREADDRESS =>
          addressRegister <= addressRegister(addressRegister'high - 1 downto addressRegister'low) & mosi; 
          if addressCount = 15 then
            state <= OUTPUTDATA;
          else
            addressCount <= addressCount + 1;
          end if;
        when OUTPUTDATA =>
      end case;
    elsif (falling_edge(clkInput)) then
      case state is
        when OUTPUTDATA =>
          -- dataOut <= dataOut(6 downto 0) & "0"; 
          
          if dataCount = 7 then 
            dataCount <= 0;
            addressRegister <= std_logic_vector(unsigned(addressRegister) + 1);
          else 
            dataCount <= dataCount + 1;
          end if;
        when STOREADDRESS =>
        when STORECOMMAND =>
      end case;
    end if;
  end process;
  miso <= dataOut;
end tb;
