-- Testbench 
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
    -- PRO bus interface
    bdcokh: in std_logic;
    binitl: in std_logic;
    bdal: inout std_logic_vector (21 downto 0);
    brplyl: out std_logic;
    bmdenl: in std_logic;
    bwritel: in std_logic;
    bwlbl: in std_logic;
    bwhbl: in std_logic;
    bsdenl: in std_logic;
    bssxl: in std_logic;
    bdsl: in std_logic;
    basl: in std_logic;
    biosel: in std_logic
);
end component;

procedure slotActive(variable a: in integer range 0 to 4194303;
                     variable slot: in integer range 0 to 7;
                     signal bssxl: out std_logic) is
begin
  -- slot 0 is  17774000 - 17774177
  -- slot 1 is  17774200 - 17774377
  -- slot 2 is  17774400 - 17774577
  -- slot 3 is  17774600 - 17774777
  -- slot 4 is  17775000 - 17775177
  -- slot 5 is  17775200 - 17775377  
    if a >= 8#17774000# and a <= 8#17774177# and slot = 0 then
      bssxl <= '0';
    elsif a >= 8#17774200# and a <= 8#17774377# and slot = 1  then
      bssxl <= '0';
    elsif a >= 8#17774400# and a <= 8#17774577# and slot = 2  then
      bssxl <= '0';
    elsif a >= 8#17774600# and a <= 8#17774777# and slot = 3  then
      bssxl <= '0';
    elsif a >= 8#17775000# and a <= 8#17775177# and slot = 4  then
      bssxl <= '0';
    elsif a >= 8#17775200# and a <= 8#17775377# and slot = 5  then
      bssxl <= '0';
    else 
      bssxl <= '1';
    end if;
end slotActive;               

procedure readAccess (variable a: in integer range 0 to 4194303;
                      variable byteAccess: in boolean;
                      variable slot: in integer range 0 to 7;
                      signal basl: out std_logic;
                      signal bdsl: out std_logic;
                      signal bmdenl: out std_logic;
                      signal bsdenl: out std_logic;
                      signal bssxl: out std_logic;
                      signal biosel: out std_logic;
                      signal bwritel: out std_logic;
                      signal bwlbl: out std_logic;
                      signal bwhbl: out std_logic;
                      signal bdal: inout std_logic_vector(21 downto 0);
                      signal brplyl: in std_logic;
                      variable accessFault: out boolean;
                      variable dataRead: out integer range 0 to 65535;
                      variable numWaitStates: out integer range 0 to 30) is
variable address : std_logic_vector (21 downto 0);
variable data : std_logic_vector (15 downto 0);
variable loopCounter : integer range 0 to 30;
begin
  -- biosel is activated in the range 17760000-17777777

  loopCounter := 30;
  accessFault := false;
  bssxl <= '1';
  biosel <= '1';
  bwritel <= '1';
  bwlbl <= '1';
  bwhbl <= '1';
  bmdenl <= '1';
  bsdenl <= '1';
  basl <= '1';
  bdsl <= '1';
  bdal <= "ZZZZZZZZZZZZZZZZZZZZZZ";
  wait for 100 ns;
  bmdenl <= '0';
  wait for 100 ns;
  if a >= 8#17760000# and a <= 8#17777777# then -- active biosel in IO range. Also activate bssxl if right slot.
    slotActive(a, slot, bssxl);
    biosel <= '0';
  end if;
  bdal <= not std_logic_vector(to_unsigned(a, 22));
  wait for 100 ns;
  basl <= '0'; -- strobe in the address.
  wait for 300 ns;
  basl <= '1';
  wait for 200 ns;
  bdal <= "ZZZZZZZZZZZZZZZZZZZZZZ";
  bssxl <= '1';
  biosel <= '1';
  wait for 100 ns;
  bmdenl <= '1';
  wait for 200 ns;
  bsdenl <= '0'; 
  wait for 200 ns;
  bdsl <= '0';
  while (brplyl = '1' or brplyl = 'H') loop
    wait for 100 ns;
    loopCounter := loopCounter - 1;
    if loopCounter = 0 then
      accessFault := true;
      bdsl <= '1';
      bsdenl <= '1';
      return;
    end if;
  end loop;
  numWaitStates := 29 - loopCounter;
  
  if byteAccess and a MOD 1 = 0 then
    dataRead := to_integer(unsigned(not bdal(7 downto 0)));
  end if;
  if byteAccess and a MOD 1 = 1 then
    dataRead := to_integer(unsigned(not bdal(15 downto 8)));
  end if; 
  if not byteAccess then
    dataRead := to_integer(unsigned(not bdal(15 downto 0)));
  end if;   
  wait for 400 ns;
  bdsl <= '1';
  wait for 100 ns;
  bsdenl <= '1';
  wait for 100 ns;
  basl <= '1';
  loopCounter := 30;
  while (brplyl = '0') loop
    wait for 100 ns;
    loopCounter := loopCounter - 1;
    if loopCounter = 0 then
      accessFault := true;
      return;
    end if;  
  end loop; 
end readAccess;




-- signal ioa: std_logic_vector (6 downto 1);
signal bdal: std_logic_vector (21 downto 0);
signal brplyl: std_logic;
signal bmdenl: std_logic;
signal bwritel: std_logic;
signal bwlbl: std_logic;
signal bwhbl: std_logic;
signal bsdenl: std_logic;
signal bssxl: std_logic;
signal bdsl: std_logic;
signal basl: std_logic;
signal biosel: std_logic;
signal binitl: std_logic;
signal bdcokh: std_logic;

begin
  brplyl <= 'H';

  -- Connect DUT
  DUT: decpromem port map(
-- Clk is to be generated externally    
    -- PRO bus interface
    bdcokh => bdcokh,
    bdal => bdal,
    brplyl => brplyl,
    bmdenl => bmdenl,
    bwritel => bwritel,
    bwlbl => bwlbl,
    bwhbl => bwhbl,
    bsdenl => bsdenl,
    bssxl => bssxl,
    bdsl => bdsl,
    basl => basl,
    biosel => biosel,
    binitl => binitl  
  );


  MEMORYACCESS: process
  variable address: integer range 0 to 4194303;
  variable data: integer range 0 to 65535;
  variable slot: integer range 0 to 7;
  variable byteAccess: boolean;
  variable accessFault: boolean;
  variable numWaitStates : integer range 0 to 30;
  begin

    -- RESET

    bdcokh <= '0';
    binitl <= '0';
    bssxl <= '1';
    biosel <= '1';
    bwritel <= '1';
    bwlbl <= '1';
    bwhbl <= '1';
    bmdenl <= '1';
    bsdenl <= '1';
    basl <= '1';
    bdsl <= '1';
    bdal <= "ZZZZZZZZZZZZZZZZZZZZZZ";
    wait for 100 ns;
    bdcokh <= '1';
    wait for 100 ns;
    binitl <= '1';
    wait for 5000 ns;
    address:=8#17774000#;
    byteAccess := true;
    slot := 0;
    readAccess (address, byteAccess, slot, basl, bdsl, bmdenl, bsdenl, bssxl, biosel, bwritel, bwlbl, bwhbl,bdal, brplyl, accessFault, data, numWaitStates);   
    report "data:" & to_ostring(std_logic_vector(to_unsigned(data, 22))); 
    report "num wait states:" & integer'image(numWaitStates);
    assert data = 8#34# report "Got wrong data: " & to_ostring(std_logic_vector(to_unsigned(data, 22))); 
    readAccess (address, byteAccess, slot, basl, bdsl, bmdenl, bsdenl, bssxl, biosel, bwritel, bwlbl, bwhbl,bdal, brplyl, accessFault, data, numWaitStates); 
    report "data:" & to_ostring(std_logic_vector(to_unsigned(data, 22))); 
    report "num wait states:" & integer'image(numWaitStates);
    assert data = 8#0# report "Got wrong data: " & to_ostring(std_logic_vector(to_unsigned(data, 22)));   
    
    readAccess (address, byteAccess, slot, basl, bdsl, bmdenl, bsdenl, bssxl, biosel, bwritel, bwlbl, bwhbl,bdal, brplyl, accessFault, data, numWaitStates); 
    report "data:" & to_ostring(std_logic_vector(to_unsigned(data, 22))); 
    report "num wait states:" & integer'image(numWaitStates);
    assert data = 8#0# report "Got wrong data: " & to_ostring(std_logic_vector(to_unsigned(data, 22)));    

    assert false report "Test done." severity note;
    wait;
  end process;


end tb;
