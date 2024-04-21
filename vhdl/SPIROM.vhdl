library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;

entity SPIROM is
    port(
        signal nCS: in std_logic;
        signal nHOLD: in std_logic;
        signal MOSI: in std_logic;
        signal MISO: out std_logic;
        signal CLK: in std_logic 
      );
end SPIROM; 


architecture rtl of SPIROM is

component DiagROM is 
port (
    address : in integer range 0 to 1023;
    data:  out std_logic;
    bitAddress: in integer range 0 to 7
);
end component;

type stateType is (STORECOMMAND, STOREADDRESS, OUTPUTDATA);
signal state: stateType;
signal commandCount: integer range 0 to 7;
signal addressCount: integer range 0 to 16;
signal commandRegister: std_logic_vector (7 downto 0);
signal addressRegister: std_logic_vector (15 downto 0);
signal address: integer range 0 to 1023;
signal dataCount: integer range 0 to 7;
signal dataOut: std_logic;
begin 
    with nHOLD select
        MISO <= dataOut when '1',
                'Z' when others;
    ROM: DiagROM port map(
        address => address,
        data => dataOut,
        bitAddress => dataCount
        );            
    EEPROM: process(CLK, nCS)
    begin
    if nCS = '1' then
        state <= STORECOMMAND;
        addressCount <= 0;
        commandCount <= 0;
        dataCount <= 0;
        commandRegister <= "00000000";
        addressRegister <= "0000000000000000";
    elsif (nHOLD = '1' and rising_edge(CLK)) then
        case state is
        when STORECOMMAND =>
            commandRegister <= commandRegister(commandRegister'high - 1 downto commandRegister'low) & MOSI; 
            if commandCount = 7 then
            state <= STOREADDRESS;
            else 
            commandCount <= commandCount + 1;
            end if;
        when STOREADDRESS =>
            addressRegister <= addressRegister(addressRegister'high - 1 downto addressRegister'low) & MOSI; 
            if addressCount = 15 then
            state <= OUTPUTDATA;
            else
            addressCount <= addressCount + 1;
            end if;
        when OUTPUTDATA =>
        end case;
    elsif (nHOLD = '1' and falling_edge(CLK)) then
        case state is
        when OUTPUTDATA =>            
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
end rtl;





