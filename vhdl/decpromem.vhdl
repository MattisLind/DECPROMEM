library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity decpromem is
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
    ioaddress: in std_logic_vector (6 downto 1);
    address: in std_logic_vector (21 downto 15);
    data: inout std_logic_vector (7 downto 0);
    brplyl: out std_logic;
    bmdenl: in std_logic;
    bwritel: in std_logic;
    bwlb: in std_logic;
    bwhb: in std_logic;
    bsdenl: in std_logic;
    ssxl: in std_logic;
    bdsl: in std_logic;
    basl: in std_logic;
    biosel: in std_logic;
    -- memory inteface
    memoryaddress: out std_logic_vector(19 downto 14);
    memoryselect1: out std_logic;
    memoryselect2: out std_logic;
    memoryoe: out std_logic;
    memorywritehigh: out std_logic;
    memorywritelow: out std_logic;
    -- size jumper
    memorysize : in std_logic;
    -- dir and oe for 74ALS640-1
    busdriveroe: out std_logic;
    buddriverdir: out std_logic;
    newReadCycle: in std_logic
);
end entity decpromem;
architecture rtl of decpromem is
    type stateType is (INITIAL, SEND_COMMAND, SEND_HIGH_ADDRESS, SEND_LOW_ADDRESS, RECEIVE_DATA, HOLD);
    signal state: stateType; 
    signal counter: integer range 0 to 7;   
    signal inputShiftReg: std_logic_vector(7 downto 0);
    signal loadNext: std_logic;
    signal reset: std_logic;
    signal writePort0: std_logic;
    signal decodedAddress: std_logic_vector(3 downto 0);
    signal readPort0: std_logic;
    signal readPort6: std_logic;
    signal enableMemory: std_logic;
    signal writePort4: std_logic;
    signal writePort6: std_logic;
    signal writePort: std_logic;
    signal readPort: std_logic;
    signal portAccess: std_logic;
    signal baseAddress: std_logic_vector(7 downto 0);
    signal intspiclk: std_logic;
begin
    with ioaddress(6 downto 1) select
        decodedAddress <= "0001" when "000000",
                          "0010" when "000001",
                          "0100" when "000010",
                          "1000" when "000011",
                          "0000" when others; 


    spiclk <= intspiclk;
    portAccess <=  not biosel and not ssxl and not bdsl;                     
    writePort <= portAccess and not bwlb;
    readPort <= portAccess and bwritel;
    writePort0 <=  writePort and decodedAddress(0);
    reset <= not binitl or writePort0; -- A write to port 0 will reset counter

    writePort6 <= writePort and decodedAddress(3);
    writePort4 <= writePort and decodedAddress(2);

    readPort0 <= readPort and decodedAddress(0);
    readPort6 <= readPort and decodedAddress(3);

    data(7 downto 0) <= inputShiftReg when readPort0 = '1' else
                        "ZZZZZZZZ";

    data(5) <= memorysize when readPort6 = '1' else  -- enable memory size onto bus.
               'Z';

    process(binitl, clk) -- latch for CSR. Only one bit - enable the memory.
    begin
        if (binitl = '0') then
            enableMemory <= '0';
        elsif (rising_edge(clk) and writePort6 = '1' ) then
            enableMemory <= data(0);
        end if;
    end process;

    process (clk) -- latch for base register.
    begin
        if (rising_edge(clk)) then
            if writePort4 = '1' then
                baseAddress <= data(7 downto 0);
            end if;
        end if;
    end process;

    nhold <= '0' when state = HOLD else
             '1';
       

    process(address, baseAddress, memorysize, enableMemory) 
    variable vAddress : integer range 0 to 127;
    variable vBaseAddress : integer range 0 to 127;
    variable vSize : integer range 0 to 255;
    variable vTop : integer range 0 to 255;
    variable vOutputAddress : integer range 0 to 127;
    variable ramSelected : std_logic;
    variable vOutputAddressVector : std_logic_vector (6 downto 0);
    begin
        vBaseAddress := to_integer(unsigned(baseAddress));
        vAddress := to_integer(unsigned(address(21 downto 15)));
        if memorysize = '1' then
            vSize := 8#100#;  -- 2 meg
        else 
            vSize := 8#200#;  -- 4 meg
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
        vOutputAddress := vAddress - vBaseAddress;
        vOutputAddressVector := std_logic_vector(to_unsigned(vOutputAddress, 7));
        memoryselect1 <= vOutputAddressVector(6) and ramSelected and enableMemory;
        memoryselect2 <= not vOutputAddressVector(6) and ramSelected and enableMemory;
        memoryaddress <= vOutputAddressVector(5 downto 0);
    end process;

    process(clk,reset)
    begin
        if reset = '1' then
            state <= INITIAL;
            ncs <= '1';
            counter <= 0;
            inputShiftReg <= "00000000";
            mosi <= '0';
            intspiclk <= '0';
        elsif (rising_edge(clk)) then
            if intspiclk = '0' then
                intspiclk <= '1';
                -- rising edge spiclk
                case state is 
                    when RECEIVE_DATA =>
                        if counter = 7 then
                            counter <= 0;
                        else 
                            counter <= counter + 1;
                        end if;  
                        inputShiftReg <= inputShiftReg(inputShiftReg'high - 1 downto inputShiftReg'low) & miso;  
                    when HOLD => 
                        if newReadCycle = '1' then
                            state <= RECEIVE_DATA;
                        end if;
                    when OTHERS =>
                end case;
            else
                intspiclk <= '0';
                -- falling edge spiclk
                case state is
                    when INITIAL =>
                        ncs <= '0';
                        state <= SEND_COMMAND;
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
                        end if;    
                    when HOLD =>
                        if newReadCycle = '1' then
                            state <= RECEIVE_DATA;
                        end if;
                end case;
            end if;
        end if;
    end process;
end architecture rtl;