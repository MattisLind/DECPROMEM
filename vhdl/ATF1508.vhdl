library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity ATF1508 is
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
    bdcokh: in std_logic;
    binitl: in std_logic;
    ioa: in std_logic_vector (5 downto 0);
    a: in std_logic_vector (6 downto 0);
    data: inout std_logic_vector (7 downto 0);
    brplyl: out std_logic;
    bmdenl: in std_logic;
    bwritel: in std_logic;
    bwlbl: in std_logic;
    bwhbl: in std_logic;
    bsdenl: in std_logic;
    bssxl: in std_logic;
    bdsl: in std_logic;
    basl: in std_logic;
    -- memory inteface
    ma: out std_logic_vector(6 downto 0);
    mcelow: out std_logic;
    nmcehigh: out std_logic;
    moe: out std_logic;
    mhe: out std_logic;
    mle: out std_logic;
    mwe: out std_logic;
    -- size jumper
    msiz : in std_logic;
    -- dir and oe for 74ALS640-1
    busoe: out std_logic;
    busdir: out std_logic;
    -- buffered outputs
    asl: out std_logic;
    mdenl: out std_logic;
    sdenl: out std_logic
--PIN: CHIP "src/ATF1508" ASSIGNED TO AN PLCC84
--PIN: miso : 73
--PIN: spiclk : 76
--PIN: ncs : 74
--PIN: mosi : 75
--PIN: nhold : 77
--PIN: bdcokh : 84
--PIN: bdsl : 12
--PIN: bwritel : 11
--PIN: brplyl : 10
--PIN: moe : 8
--PIN: data_0 : 5
--PIN: data_5 : 4
--PIN: mle : 22
--PIN: data_7 : 21
--PIN: data_6 : 20
--PIN: data_3 : 18
--PIN: data_4 : 17
--PIN: data_2 : 16
--PIN: data_1 : 15
--PIN: TDI : 14
--PIN: ioa_3 : 31
--PIN: ioa_2 : 30
--PIN: ioa_0 : 29
--PIN: ioa_1 : 28
--PIN: ioa_4 : 27
--PIN: busdir : 25
--PIN: TMS : 23
--PIN: ioa_5 : 41
--PIN: msiz : 40
--PIN: bwlbl : 39
--PIN: A_6 : 37
--PIN: A_5 : 36
--PIN: nmcehigh : 44
--PIN: mcelow : 45
--PIN: ma_0 : 48
--PIN: ma_5 : 35
--PIN: ma_3 : 33
--PIN: ma_1 : 34
--PIN: ma_2 : 50
--PIN: ma_6 : 52
--PIN: ma_4 : 51
--PIN: A_4 : 63
--PIN: A_3 : 9
--PIN: bsdenl : 55
--PIN: A_2 : 54
--PIN: mwe : 46
--PIN: busoe : 24
--PIN: mhe : 49
--PIN: TCK : 62
--PIN: A_0 : 6
--PIN: A_1 : 57
--PIN: bwhbl : 64
--PIN: bmdenl : 56
--PIN: basl : 65
--PIN: TDO : 71
--PIN: bssxl : 68
--PIN: CLK : 83
--PIN: binitl : 1
--PIN: asl : 58
--PIN: mdenl : 60
--PIN: sdenl : 61    
);
end entity ATF1508;
architecture rtl of ATF1508 is
    type stateType is (INITIAL, SEND_COMMAND, SEND_HIGH_ADDRESS, SEND_LOW_ADDRESS, RECEIVE_DATA, HOLD, HOLD_WAIT_LOW);
    signal state: stateType; 
    signal counter: integer range 0 to 7;   
    signal inputShiftReg: std_logic_vector(7 downto 0);
    signal loadNext: std_logic;
    signal reset: std_logic;
    signal writePort2: std_logic;
    signal decodedAddress: std_logic_vector(3 downto 0);
    signal readPort0: std_logic;
    signal readPort4: std_logic;
    signal readPort6: std_logic;
    signal enableMemory: std_logic;
    signal writePort4: std_logic;
    signal writePort6: std_logic;
    signal writePort: std_logic;
    signal readPort: std_logic;
    signal portAccess: std_logic;
    signal baseAddress: std_logic_vector(7 downto 0);
    signal intspiclk: std_logic;
    signal dataOut: std_logic_vector(7 downto 0);
    signal spiReadReady: std_logic;
    signal memoryAccess: std_logic;
begin
    asl <= basl;
    mdenl <= bmdenl;
    sdenl <= '0' when ((bsdenl = '0') and (memoryAccess = '1' or portAccess = '1')) else '1';
    brplyl <= '0' when ((spiReadReady = '1' and readPort0 = '1') or (writePort = '1') or (readPort = '1' and readPort0 = '0') or memoryAccess = '1') else 'Z';  
    busoe <= '0' when (bmdenl = '0') or ((bsdenl = '0') and (memoryAccess = '1' or portAccess = '1')) else '1';
    busdir <= bsdenl;
    with ioa(5 downto 0) select
        decodedAddress <= "0001" when "000000",
                          "0010" when "000001",
                          "0100" when "000010",
                          "1000" when "000011",
                          "0000" when others; 


    spiclk <= intspiclk;
    portAccess <=  not bssxl and not bdsl;                        
    writePort <= portAccess and not bwlbl;
    readPort <= portAccess and bwritel;
    writePort2 <=  writePort and decodedAddress(1);
    reset <= (not binitl and bdcokh) or writePort2; -- A write to port 2 will reset counter

    writePort6 <= writePort and decodedAddress(3);
    writePort4 <= writePort and decodedAddress(2);

    readPort0 <= readPort and decodedAddress(0);
    readPort4 <= readPort and decodedAddress(2);
    readPort6 <= readPort and decodedAddress(3);

    dataOut <= inputShiftReg when readPort0 = '1' else
               "00" & msiz & "0000" & enableMemory when readPort6 = '1' else
               baseAddress when readPort4 = '1' else
               "00000000";
              
    data <= dataOut when readPort = '1' else
           "ZZZZZZZZ";           

    --data <= dataOut;
    -- data <= dataOut when bsdenl = '0' else "ZZZZZZZZ";

    process(binitl, clk)
    begin
        if (binitl = '0') then
            enableMemory <= '0';
        elsif (rising_edge(clk) and writePort6 = '1' ) then
            enableMemory <= data(0);
        end if;   
    end process;

    process (clk) 
    begin
        if (rising_edge(clk)) then
            if writePort4 = '1' then
                baseAddress <= data(7 downto 0);
            end if;
        end if;
    end process;


    nhold <= '0' when state = HOLD or state = HOLD_WAIT_LOW else
             '1';
       

    process(a, baseAddress, msiz, enableMemory, bdsl) 
    variable vAddress : integer range 0 to 127;
    variable vBaseAddress : integer range 0 to 127;
    variable vSize : integer range 0 to 255;
    variable vTop : integer range 0 to 255;
    variable vOutputAddress : integer range 0 to 127;
    variable ramSelected : std_logic;
    variable vOutputAddressVector : std_logic_vector (6 downto 0);
    begin
        vBaseAddress := to_integer(unsigned(baseAddress));
        vAddress := to_integer(unsigned(a(6 downto 0)));
        if msiz = '1' then
            vSize := 8#200#;  -- 4 meg
        else 
            vSize := 8#100#;  -- 2 meg
        end if;
        vTop := vBaseAddress + vSize;
        if vTop > 8#140# then
            vTop := 8#140#;   -- 3 meg
        end if;
        if vAddress >= vBaseAddress and vAddress < vTop then
            ramSelected := '1';
        else
            ramSelected := '0';
        end if;
        memoryAccess <= ramSelected and not bdsl;
        if ramSelected = '1' then
            vOutputAddress := vAddress - vBaseAddress;
            vOutputAddressVector := std_logic_vector(to_unsigned(vOutputAddress, 7));
        else 
            vOutputAddressVector := "0000000";
        end if;
        mcelow <= ramSelected and enableMemory;
        nmcehigh <= not (ramSelected and enableMemory);
        ma(6 downto 0) <= vOutputAddressVector(6 downto 0);

    end process;

    moe <= not bwritel and not bdsl;
    -- mhe <= bwhbl and not bwritel and bdsl;
    mhe <= '0' when bwhbl = '0' else 
           '0' when bwritel = '1' and bdsl = '0' else
           '1';
    mle <= '0' when bwlbl = '0' else 
           '0' when bwritel = '1' and bdsl = '0' else
           '1';
    mwe <= bwlbl and bwhbl; 
    process(clk,reset)
    begin
        
        if reset = '1' then
            state <= INITIAL;
            ncs <= '1';
            counter <= 0;
            inputShiftReg <= "00000000";
            mosi <= '0';
            intspiclk <= '0';
            spiReadReady <='0';
        elsif (rising_edge(clk)) then
            if intspiclk = '0' then
                intspiclk <= '1';
                -- rising edge spiclk
                case state is 
                    when INITIAL =>
                        ncs <= '0';
                        state <= SEND_COMMAND;
                    when RECEIVE_DATA =>
                        if counter = 7 then
                            counter <= 0;
                        else 
                            counter <= counter + 1;
                        end if;  
                        inputShiftReg <= inputShiftReg(inputShiftReg'high - 1 downto inputShiftReg'low) & miso;  
                    when OTHERS =>
                end case;
            else
                intspiclk <= '0';
                -- falling edge spiclk
                case state is

                    when SEND_COMMAND =>
                        if counter = 7 then
                            counter <= 0;
                            state <= SEND_HIGH_ADDRESS;
                        else 
                            counter <= counter + 1;
                        end if;
                        if (counter = 5 or counter = 6) then -- read comand!
                            mosi <= '1';
                        else 
                            mosi <= '0';
                        end if;
                    when SEND_HIGH_ADDRESS =>
                        mosi <= '0';
                        if counter = 7 then
                            counter <= 0;
                            state <= SEND_LOW_ADDRESS;
                        else 
                            counter <= counter + 1;
                        end if;
                    when SEND_LOW_ADDRESS =>
                        mosi <= '0';
                        if counter = 7 then
                            counter <= 0;
                            state <= RECEIVE_DATA;
                            inputShiftReg <= inputShiftReg(inputShiftReg'high - 1 downto inputShiftReg'low) & miso; 
                        else 
                            counter <= counter + 1;
                        end if;                
                    when RECEIVE_DATA =>
                        if counter = 7 then
                            state <= HOLD;
                            spiReadReady <= '1';
                        end if;    
                    when HOLD =>
                        if readPort0 = '1' then
                            state <= HOLD_WAIT_LOW;
                        end if;
                    when HOLD_WAIT_LOW =>
                        if readPort0 = '0' then
                            state <= RECEIVE_DATA;
                            spiReadReady <= '0';
                        end if;
                    when OTHERS =>    
                end case;
            end if;
        end if;
    end process;
end architecture rtl;