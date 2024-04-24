-- Testbench 
library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.math_real.uniform;
use ieee.math_real.floor; 
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
    biosel: in std_logic;
    msiz: in std_logic
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
                      variable numWaitStates: out integer range 0 to 100) is
variable address : std_logic_vector (21 downto 0);
variable data : std_logic_vector (15 downto 0);
variable loopCounter : integer range 0 to 100;
begin
  -- biosel is activated in the range 17760000-17777777

  loopCounter := 100;
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
  numWaitStates := 99 - loopCounter;
  
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
  loopCounter := 100;
  while (brplyl = '0') loop
    wait for 100 ns;
    loopCounter := loopCounter - 1;
    if loopCounter = 0 then
      accessFault := true;
      return;
    end if;  
  end loop; 
end readAccess;


procedure writeAccess (variable a: in integer range 0 to 4194303;
                      variable byteAccess: in boolean;
                      variable slot: in integer range 0 to 7;
                      variable d: in integer range 0 to 65535;
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
                      variable numWaitStates: out integer range 0 to 100) is
variable address : std_logic_vector (21 downto 0);
variable data : std_logic_vector (15 downto 0);
variable loopCounter : integer range 0 to 100;
begin
  -- biosel is activated in the range 17760000-17777777

  loopCounter := 100;
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
  bwritel <= '0';
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
  bmdenl <= '0'; 
  if byteAccess and a MOD 1 = 0 then
    bwlbl <= '0';
  end if;
  if byteAccess and a MOD 1 = 1 then
    bwhbl <= '0';
  end if; 
  if not byteAccess then
    bwlbl <= '0';
    bwhbl <= '0';
  end if;   
  wait for 100 ns;
  bdal <= not ("000000" & std_logic_vector(to_unsigned(d,16)));
  wait for 100 ns;
  bdsl <= '0';
  while (brplyl = '1' or brplyl = 'H') loop
    wait for 100 ns;
    loopCounter := loopCounter - 1;
    if loopCounter = 0 then
      accessFault := true;
      bdsl <= '1';
      bmdenl <= '1';
      return;
    end if;
  end loop;
  numWaitStates := 99 - loopCounter;   
  wait for 400 ns;
  bdsl <= '1';
  bwlbl <= '1';
  bwhbl <= '1';
  wait for 100 ns;
  bmdenl <= '1';
  wait for 100 ns;
  basl <= '1';
  bwritel <= '1';
  loopCounter := 30;
  while (brplyl = '0') loop
    wait for 100 ns;
    loopCounter := loopCounter - 1;
    if loopCounter = 0 then
      accessFault := true;
      return;
    end if;  
  end loop; 
end writeAccess;


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
signal msiz: std_logic;
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
    binitl => binitl,
    msiz => msiz  
  );


  MEMORYACCESS: process
  variable address: integer range 0 to 4194303;
  variable data, readData: integer range 0 to 65535;
  variable slot: integer range 0 to 7;
  variable byteAccess: boolean;
  variable accessFault: boolean;
  variable numWaitStates : integer range 0 to 100;
  variable seed1 : positive;
  variable seed2 : positive;
  variable x : real;
  begin
    seed1 := 999;
    seed2 := 999;
    -- RESET
    msiz <= '1';
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
    assert accessFault = false report "Read caused accessFault";

    readAccess (address, byteAccess, slot, basl, bdsl, bmdenl, bsdenl, bssxl, biosel, bwritel, bwlbl, bwhbl,bdal, brplyl, accessFault, data, numWaitStates); 
    report "data:" & to_ostring(std_logic_vector(to_unsigned(data, 22))); 
    report "num wait states:" & integer'image(numWaitStates);
    assert data = 8#0# report "Got wrong data: " & to_ostring(std_logic_vector(to_unsigned(data, 22)));   
    assert accessFault = false report "Read caused accessFault";

    readAccess (address, byteAccess, slot, basl, bdsl, bmdenl, bsdenl, bssxl, biosel, bwritel, bwlbl, bwhbl,bdal, brplyl, accessFault, data, numWaitStates); 
    report "data:" & to_ostring(std_logic_vector(to_unsigned(data, 22))); 
    report "num wait states:" & integer'image(numWaitStates);
    assert data = 8#377# report "Got wrong data: " & to_ostring(std_logic_vector(to_unsigned(data, 22)));    
    assert accessFault = false report "Read caused accessFault";

    address:=8#17774176#;
    readAccess (address, byteAccess, slot, basl, bdsl, bmdenl, bsdenl, bssxl, biosel, bwritel, bwlbl, bwhbl,bdal, brplyl, accessFault, data, numWaitStates);     
    assert accessFault = false report "Read caused accessFault";

    address:=8#17774200#;
    readAccess (address, byteAccess, slot, basl, bdsl, bmdenl, bsdenl, bssxl, biosel, bwritel, bwlbl, bwhbl,bdal, brplyl, accessFault, data, numWaitStates);     
    assert accessFault = true report "Read didn't cause accessFault";

    -- Reset Diag ROM counter

    address:=8#17774002#;
    data:= 8#0#;
    writeAccess (address, byteAccess, slot, data, basl, bdsl, bmdenl, bsdenl, bssxl, biosel, bwritel, bwlbl, bwhbl,bdal, brplyl, accessFault, numWaitStates);     
    assert accessFault = false report "write caused accessFault";

    -- Read from beginning again!

    address:=8#17774000#;
    byteAccess := true;
    slot := 0;
    readAccess (address, byteAccess, slot, basl, bdsl, bmdenl, bsdenl, bssxl, biosel, bwritel, bwlbl, bwhbl,bdal, brplyl, accessFault, data, numWaitStates);   
    report "data:" & to_ostring(std_logic_vector(to_unsigned(data, 22))); 
    report "num wait states:" & integer'image(numWaitStates);
    assert data = 8#34# report "Got wrong data: " & to_ostring(std_logic_vector(to_unsigned(data, 22))); 
    assert accessFault = false report "Read caused accessFault";

    readAccess (address, byteAccess, slot, basl, bdsl, bmdenl, bsdenl, bssxl, biosel, bwritel, bwlbl, bwhbl,bdal, brplyl, accessFault, data, numWaitStates); 
    report "data:" & to_ostring(std_logic_vector(to_unsigned(data, 22))); 
    report "num wait states:" & integer'image(numWaitStates);
    assert data = 8#0# report "Got wrong data: " & to_ostring(std_logic_vector(to_unsigned(data, 22)));   
    assert accessFault = false report "Read caused accessFault";

    readAccess (address, byteAccess, slot, basl, bdsl, bmdenl, bsdenl, bssxl, biosel, bwritel, bwlbl, bwhbl,bdal, brplyl, accessFault, data, numWaitStates); 
    report "data:" & to_ostring(std_logic_vector(to_unsigned(data, 22))); 
    report "num wait states:" & integer'image(numWaitStates);
    assert data = 8#377# report "Got wrong data: " & to_ostring(std_logic_vector(to_unsigned(data, 22)));    
    assert accessFault = false report "Read caused accessFault";

    -- Read fpop bit
    address:=8#17774006#;
    readAccess (address, byteAccess, slot, basl, bdsl, bmdenl, bsdenl, bssxl, biosel, bwritel, bwlbl, bwhbl,bdal, brplyl, accessFault, data, numWaitStates); 
    report "data:" & to_ostring(std_logic_vector(to_unsigned(data, 22))); 
    report "num wait states:" & integer'image(numWaitStates);
    assert data = 8#40# report "Got wrong data: " & to_ostring(std_logic_vector(to_unsigned(data, 22)));    
    assert accessFault = false report "Read caused accessFault";

    -- Read fpop bit
    msiz <= '0';
    address:=8#17774006#;
    readAccess (address, byteAccess, slot, basl, bdsl, bmdenl, bsdenl, bssxl, biosel, bwritel, bwlbl, bwhbl,bdal, brplyl, accessFault, data, numWaitStates); 
    report "data:" & to_ostring(std_logic_vector(to_unsigned(data, 22))); 
    report "num wait states:" & integer'image(numWaitStates);
    assert data = 8#00# report "Got wrong data: " & to_ostring(std_logic_vector(to_unsigned(data, 22)));    
    assert accessFault = false report "Read caused accessFault";

    -- Write base register
    report "Write 010 to base register and read back";
    address:=8#17774004#;
    data:= 8#10#;
    writeAccess (address, byteAccess, slot, data, basl, bdsl, bmdenl, bsdenl, bssxl, biosel, bwritel, bwlbl, bwhbl,bdal, brplyl, accessFault, numWaitStates);     
    assert accessFault = false report "write caused accessFault";

    readAccess (address, byteAccess, slot, basl, bdsl, bmdenl, bsdenl, bssxl, biosel, bwritel, bwlbl, bwhbl,bdal, brplyl, accessFault, data, numWaitStates); 
    report "data:" & to_ostring(std_logic_vector(to_unsigned(data, 22))); 
    report "num wait states:" & integer'image(numWaitStates);
    assert data = 8#40# report "Got wrong data: " & to_ostring(std_logic_vector(to_unsigned(data, 22)));    
    assert accessFault = false report "Read caused accessFault";

    report "Enable memory and read back to check bit.";
    -- Enable memory 
    address:=8#17774006#;
    data:= 8#1#;
    writeAccess (address, byteAccess, slot, data, basl, bdsl, bmdenl, bsdenl, bssxl, biosel, bwritel, bwlbl, bwhbl,bdal, brplyl, accessFault, numWaitStates);     
    assert accessFault = false report "write caused accessFault";

    -- Read back memory enable bit.

    readAccess (address, byteAccess, slot, basl, bdsl, bmdenl, bsdenl, bssxl, biosel, bwritel, bwlbl, bwhbl,bdal, brplyl, accessFault, data, numWaitStates); 
    report "data:" & to_ostring(std_logic_vector(to_unsigned(data, 22))); 
    report "num wait states:" & integer'image(numWaitStates);
    assert data = 8#01# report "Got wrong data: " & to_ostring(std_logic_vector(to_unsigned(data, 22)));    
    assert accessFault = false report "Read caused accessFault";
    address:=8#01000000#;
    -- Write to lowest address in memory
    while (address  < 8#11000000#) loop
      uniform(seed1, seed2, x);
      data := integer(floor(x * 65536.0));
      report "Write " & to_ostring(std_logic_vector(to_unsigned(data, 16))) & " to address " & to_ostring(std_logic_vector(to_unsigned(address, 22)));
      
      --data:= 8#152525#;
      byteAccess := false;
      writeAccess (address, byteAccess, slot, data, basl, bdsl, bmdenl, bsdenl, bssxl, biosel, bwritel, bwlbl, bwhbl,bdal, brplyl, accessFault, numWaitStates);     
      assert accessFault = false report "write caused accessFault";
  
      readAccess (address, byteAccess, slot, basl, bdsl, bmdenl, bsdenl, bssxl, biosel, bwritel, bwlbl, bwhbl,bdal, brplyl, accessFault, readData, numWaitStates); 
      report "data:" & to_ostring(std_logic_vector(to_unsigned(data, 22))); 
      report "num wait states:" & integer'image(numWaitStates);
      assert readData = data report "Got wrong data: " & to_ostring(std_logic_vector(to_unsigned(data, 22)));    
      assert accessFault = false report "Read caused accessFault";      
      address := address + 8#100000#;
    end loop; 

    -- Write outside memory
    --report "Trying to write to 00777776 which is outside memory should trigger access fault.";
    address:=8#00777776#;
    data:= 8#152525#;
    byteAccess := false;
    writeAccess (address, byteAccess, slot, data, basl, bdsl, bmdenl, bsdenl, bssxl, biosel, bwritel, bwlbl, bwhbl,bdal, brplyl, accessFault, numWaitStates);     
    assert accessFault = true report "write outside memory didn't cause accessFault"; 

    --report "Trying to write to 014000000 which is outside memory should trigger access fault.";
    address:=8#11000000#;
    data:= 8#152525#;
    byteAccess := false;
    writeAccess (address, byteAccess, slot, data, basl, bdsl, bmdenl, bsdenl, bssxl, biosel, bwritel, bwlbl, bwhbl,bdal, brplyl, accessFault, numWaitStates);     
    assert accessFault = true report "write outside memory didn't cause accessFault";

    msiz <= '1';

    address:=8#01000000#;
    -- Write to lowest address in memory
    while (address  < 8#14000000#) loop
      uniform(seed1, seed2, x);
      data := integer(floor(x * 65536.0));
      report "Write " & to_ostring(std_logic_vector(to_unsigned(data, 16))) & " to address " & to_ostring(std_logic_vector(to_unsigned(address, 22)));
      
      --data:= 8#152525#;
      byteAccess := false;
      writeAccess (address, byteAccess, slot, data, basl, bdsl, bmdenl, bsdenl, bssxl, biosel, bwritel, bwlbl, bwhbl,bdal, brplyl, accessFault, numWaitStates);     
      assert accessFault = false report "write caused accessFault";
  
      readAccess (address, byteAccess, slot, basl, bdsl, bmdenl, bsdenl, bssxl, biosel, bwritel, bwlbl, bwhbl,bdal, brplyl, accessFault, readData, numWaitStates); 
      report "data:" & to_ostring(std_logic_vector(to_unsigned(data, 22))); 
      report "num wait states:" & integer'image(numWaitStates);
      assert readData = data report "Got wrong data: " & to_ostring(std_logic_vector(to_unsigned(data, 22)));    
      assert accessFault = false report "Read caused accessFault";      
      address := address + 8#100000#;
    end loop; 
    
    -- Write outside memory
    --report "Trying to write to 00777776 which is outside memory should trigger access fault.";
    address:=8#00777776#;
    data:= 8#152525#;
    byteAccess := false;
    writeAccess (address, byteAccess, slot, data, basl, bdsl, bmdenl, bsdenl, bssxl, biosel, bwritel, bwlbl, bwhbl,bdal, brplyl, accessFault, numWaitStates);     
    assert accessFault = true report "write outside memory didn't cause accessFault"; 

    -- Write outside memory
    --report "Trying to write to 014000000 which is outside memory should trigger access fault.";
    address:=8#14000000#;
    data:= 8#152525#;
    byteAccess := false;
    writeAccess (address, byteAccess, slot, data, basl, bdsl, bmdenl, bsdenl, bssxl, biosel, bwritel, bwlbl, bwhbl,bdal, brplyl, accessFault, numWaitStates);     
    assert accessFault = true report "write outside memory didn't cause accessFault";

    msiz <= '0';
    -- Write base register
    report "Write 040 to base register and read back";
    address:=8#17774004#;
    data:= 8#40#;
    writeAccess (address, byteAccess, slot, data, basl, bdsl, bmdenl, bsdenl, bssxl, biosel, bwritel, bwlbl, bwhbl,bdal, brplyl, accessFault, numWaitStates);     
    assert accessFault = false report "write caused accessFault";

    address:=8#04000000#;
    -- Write to lowest address in memory
    while (address  < 8#14000000#) loop
      uniform(seed1, seed2, x);
      data := integer(floor(x * 65536.0));
      report "Write " & to_ostring(std_logic_vector(to_unsigned(data, 16))) & " to address " & to_ostring(std_logic_vector(to_unsigned(address, 22)));
      
      --data:= 8#152525#;
      byteAccess := false;
      writeAccess (address, byteAccess, slot, data, basl, bdsl, bmdenl, bsdenl, bssxl, biosel, bwritel, bwlbl, bwhbl,bdal, brplyl, accessFault, numWaitStates);     
      assert accessFault = false report "write caused accessFault";
  
      readAccess (address, byteAccess, slot, basl, bdsl, bmdenl, bsdenl, bssxl, biosel, bwritel, bwlbl, bwhbl,bdal, brplyl, accessFault, readData, numWaitStates); 
      report "data:" & to_ostring(std_logic_vector(to_unsigned(data, 22))); 
      report "num wait states:" & integer'image(numWaitStates);
      assert readData = data report "Got wrong data: " & to_ostring(std_logic_vector(to_unsigned(data, 22)));    
      assert accessFault = false report "Read caused accessFault";      
      address := address + 8#100000#;
    end loop; 

    -- Write outside memory
    --report "Trying to write to 014000000 which is outside memory should trigger access fault.";
    address:=8#14000000#;
    data:= 8#152525#;
    byteAccess := false;
    writeAccess (address, byteAccess, slot, data, basl, bdsl, bmdenl, bsdenl, bssxl, biosel, bwritel, bwlbl, bwhbl,bdal, brplyl, accessFault, numWaitStates);     
    assert accessFault = true report "write outside memory didn't cause accessFault";
    
    -- Write outside memory
    --report "Trying to write to 03777776 which is outside memory should trigger access fault.";
    address:=8#03777776#;
    data:= 8#152525#;
    byteAccess := false;
    writeAccess (address, byteAccess, slot, data, basl, bdsl, bmdenl, bsdenl, bssxl, biosel, bwritel, bwlbl, bwhbl,bdal, brplyl, accessFault, numWaitStates);     
    assert accessFault = true report "write outside memory didn't cause accessFault";    


    assert false report "Test done." severity note;
    wait;
  end process;


end tb;
