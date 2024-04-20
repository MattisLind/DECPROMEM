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
    -- 40 MHz clock
    clk : in std_logic;
    -- spi interface 
    spiclk: out std_logic;
    mosi: out std_logic;
    miso: in std_logic;
    ncs: out std_logic;
    nhold: out std_logic;
    -- PRO bus interface
    -- bdcokh: in std_logic;
    binitl: in std_logic;
    ioa: in std_logic_vector (6 downto 1);
    a: in std_logic_vector (21 downto 15);
    data: inout std_logic_vector (7 downto 0);
    brplyl: out std_logic;
    bmdenl: in std_logic;
    bwritel: in std_logic;
    bwlbl: in std_logic;
    bwhbl: in std_logic;
    bsdenl: in std_logic;
    ssxl: in std_logic;
    bdsl: in std_logic;
    -- basl: in std_logic;
    biosel: in std_logic;
    -- memory inteface
    ma: out std_logic_vector(19 downto 14);
    mce1: out std_logic;
    mce2: out std_logic;
    moe: out std_logic;
    mwh: out std_logic;
    mwl: out std_logic;
    -- size jumper
    msiz : in std_logic;
    -- dir and oe for 74ALS640-1
    busoe: out std_logic;
    busdir: out std_logic
);
end component;



component DiagROM is 
port (
  address : in integer range 0 to 1023;
  data:  out std_logic;
  bitAddress: in integer range 0 to 7
);
end component;

procedure readAccess (variable ad: in std_logic_vector(21 downto 0);
                      signal bdsl: out std_logic;
                      signal ssxl: out std_logic;
                      signal biosel: out std_logic;
                      signal bwritel: out std_logic;
                      signal bwlbl: out std_logic;
                      signal bwhbl: out std_logic;
                      signal ioa: out std_logic_vector(6 downto 1);
                      signal brplyl: in std_logic;
                      signal a: out std_logic_vector (21 downto 15)) is
begin
  ssxl <= '0';
  biosel <= '0';
  bwritel <= '1';
  bwlbl <= 'X';
  bwhbl <= 'X';
  wait for 200 ns;
  ioa <= a;
  wait for 200 ns;
  bdsl <= '0';
  while (brplyl = '1' or brplyl = 'H') loop
    wait for 100 ns;
  end loop;
  wait for 400 ns;
  bdsl <= '1';
  ssxl <= '1';
  biosel <= '1';
  bwritel <= '1';
  bwlbl <= 'X';
  bwhbl <= 'X';
end readAccess;


procedure writeAccess (variable address: in std_logic_vector(21 downto 0);
                      variable data: in std_logic_vector(15 downto 0);
                      variable byteAccess: in std_logic;
                      signal bdsl: out std_logic;
                      signal ssxl: out std_logic;
                      signal biosel: out std_logic;
                      signal bwritel: out std_logic;
                      signal bwlbl: out std_logic;
                      signal bwhbl: out std_logic;
                      signal ioa: out std_logic_vector(6 downto 1);
                      signal brplyl: in std_logic;
                      signal d: out std_logic_vector(7 downto 0);
                      signal a: out std_logic_vector (21 downto 15)) is
begin
  ssxl <= '0';
  biosel <= '0';
  bwritel <= '0';
  if byteAccess = '1' then
    if address(0) = '0' then
      bwlbl <= '0';
      bwhbl <= '1';
    else
      bwlbl <= '1';
      bwhbl <= '0';
    end if;
  else 
    bwlbl <= '0';
    bwhbl <= '0';
  end if;
  a <= address(21 downto 15);
  wait for 200 ns;
  ioa <= address (6 downto 1);
  wait for 200 ns;
  bdsl <= '0';
  data <= d;
  while (brplyl = '1' or brplyl = 'H') loop
    wait for 100 ns;
  end loop;
  wait for 400 ns;
  data <= "ZZZZZZZZ";
  bdsl <= '1';
  ssxl <= '1';
  biosel <= '1';
  bwritel <= '1';
  bwlbl <= 'X';
  bwhbl <= 'X';
end writeAccess;

type stateType is (STORECOMMAND, STOREADDRESS, OUTPUTDATA);
signal state: stateType;
signal clkInput, reset : std_logic;
signal cmd : std_logic_vector (7 downto 0);
signal ncs: std_logic;
signal mosi: std_logic;
signal miso: std_logic;
signal spiclk: std_logic;
signal commandCount: integer range 0 to 7;
signal addressCount: integer range 0 to 16;
signal commandRegister: std_logic_vector (7 downto 0);
signal addressRegister: std_logic_vector (15 downto 0);
signal address: integer range 0 to 1023;
signal dataCount: integer range 0 to 7;
signal dataOut: std_logic;
signal startRead: std_logic;
signal nhold: std_logic;
signal ioa: std_logic_vector (6 downto 1);
signal a: std_logic_vector (21 downto 15);
signal data: std_logic_vector (7 downto 0);
signal brplyl: std_logic;
signal bmdenl: std_logic;
signal bwritel: std_logic;
signal bwlbl: std_logic;
signal bwhbl: std_logic;
signal bsdenl: std_logic;
signal ssxl: std_logic;
signal bdsl: std_logic;
-- basl: in std_logic;
signal biosel: std_logic;
-- memory inteface
signal ma:  std_logic_vector(19 downto 14);
signal mce1:  std_logic;
signal mce2: std_logic;
signal moe:  std_logic;
signal mwh: std_logic;
signal mwl: std_logic;
-- size jumper
signal msiz : std_logic;
-- dir and oe for 74ALS640-1
signal busoe: std_logic;
signal busdir: std_logic;
begin
  address <= to_integer(unsigned(addressRegister));
  brplyl <= 'H';
  ROM: DiagROM port map(
    address => address,
    data => dataOut,
    bitAddress => dataCount
  );
  -- Connect DUT
  DUT: decpromem port map(
-- Clk is to be generated externally    
    clk => clkInput,
    spiclk => spiclk,
    binitl => reset,
    ncs => ncs,
    mosi => mosi,
    miso => miso,
    nhold => nhold,
    -- PRO bus interface
    -- bdcokh: in std_logic;
    ioa => ioa,
    a => a,
    data => data,
    brplyl => brplyl,
    bmdenl => bmdenl,
    bwritel => bwritel,
    bwlbl => bwlbl,
    bwhbl => bwhbl,
    bsdenl => bsdenl,
    ssxl => ssxl,
    bdsl => bdsl,
    -- basl: in std_logic;
    biosel => biosel,
    -- memory inteface
    ma => ma,
    mce1 => mce1,
    mce2 => mce2,
    moe => moe,
    mwh => mwh,
    mwl => mwl,
    -- size jumper
    msiz => msiz,
    -- dir and oe for 74ALS640-1
    busoe => busoe,
    busdir => busdir    
    );
  CLK: process
  begin
    reset <= '1';
    wait for 200 ns;
    reset <= '0';
    wait for 200 ns;
    reset <= '1';
    wait for 200 ns;
    for i in 1 to 1000 loop  -- 40 MHz clock
      clkInput <= '0'; 
      wait for 25 ns;
      clkInput <= '1';
      wait for 25 ns;  
    end loop;
    assert false report "Test done." severity note;
    wait;
  end process;

  MEMORYACCESS: process
  variable ad: std_logic_vector(6 downto 1);
  variable d: std_logic_vector(7 downto 0);
  begin
    wait for 5000 ns;
    ad:="000000";
    readAccess (ad, bdsl, ssxl, biosel, bwritel, bwlbl, bwhbl,ioa, brplyl);
    wait for 2000 ns;
    ad:="000000";
    readAccess (ad, bdsl, ssxl, biosel, bwritel, bwlbl, bwhbl,ioa, brplyl);   
    wait for 2000 ns;
    ad:="000000";
    readAccess (ad, bdsl, ssxl, biosel, bwritel, bwlbl, bwhbl,ioa, brplyl); 
    wait for 2000 ns;
    ad:="000000";
    readAccess (ad, bdsl, ssxl, biosel, bwritel, bwlbl, bwhbl,ioa, brplyl); 
    wait for 2000 ns;
    ad:="000000";
    readAccess (ad, bdsl, ssxl, biosel, bwritel, bwlbl, bwhbl,ioa, brplyl); 
    wait for 5 ns; -- Testing the BRPLYL logic to prolong the bus - cycle when not ready shifting in SPI data.
    ad:="000000";
    readAccess (ad, bdsl, ssxl, biosel, bwritel, bwlbl, bwhbl,ioa, brplyl);  
    wait for 2000 ns;
    ad:="000001"; -- Resetting to address 0 in diag ROM  again.
    d := "00000000";
    writeAccess (ad, bdsl, ssxl, biosel, bwritel, bwlbl, bwhbl,ioa, brplyl, d, data); 
    wait for 2000 ns;
    ad:="000000";
    readAccess (ad, bdsl, ssxl, biosel, bwritel, bwlbl, bwhbl,ioa, brplyl);   
    wait for 2000 ns;
    ad:="000000";
    readAccess (ad, bdsl, ssxl, biosel, bwritel, bwlbl, bwhbl,ioa, brplyl); 
    wait for 2000 ns;
    ad:="000000";
    readAccess (ad, bdsl, ssxl, biosel, bwritel, bwlbl, bwhbl,ioa, brplyl); 
    wait for 2000 ns;   
    ad:="000010"; -- Writing base address
    d := "00100000";  -- Set base address to 1 meg.
    writeAccess (ad, bdsl, ssxl, biosel, bwritel, bwlbl, bwhbl,ioa, brplyl, d, data); 
    wait for 2000 ns;    
    ad:="000011"; -- Writing CSR
    d := "00000001";  -- Enable memory
    writeAccess (ad, bdsl, ssxl, biosel, bwritel, bwlbl, bwhbl,ioa, brplyl, d, data); 
    wait for 2000 ns;       
    assert false report "Test done." severity note;
    wait;
  end process;

  EEPROM: process(spiclk, ncs)
  begin
    if ncs = '1' then
      state <= STORECOMMAND;
      addressCount <= 0;
      commandCount <= 0;
      dataCount <= 0;
      commandRegister <= "00000000";
      addressRegister <= "0000000000000000";
    elsif (nhold = '1' and rising_edge(spiclk)) then
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
    elsif (nhold = '1' and falling_edge(spiclk)) then
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
  with nhold select
    miso <= dataOut when '1',
            'Z' when others;
end tb;
