library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity decpromem is
port (
    clk : in std_logic;
    mosi: out std_logic;
    miso: in std_logic;
    reset : in std_logic;
    ncs: out std_logic;
    nhold: out std_logic
);
end entity decpromem;
architecture rtl of decpromem is
    type stateType is (INITIAL, SEND_COMMAND, SEND_HIGH_ADDRESS, SEND_LOW_ADDRESS, RECEIVE_DATA);
    signal state: stateType; 
    signal counter: integer range 0 to 7;   
    signal inputShiftReg: std_logic_vector(7 downto 0);
    signal inputReg: std_logic_vector(7 downto 0);
    signal loadNext: std_logic;
begin
    process(clk,reset)
    begin
        if reset = '1' then
            state <= INITIAL;
            ncs <= '1';
            nhold <= '1';
            counter <= 0;
            inputShiftReg <= "00000000";
            mosi <= '0';
        elsif (falling_edge(clk)) then
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
                    else 
                        counter <= counter + 1;
                    end if;                
                when RECEIVE_DATA =>
                    if counter = 7 then
                        counter <= 0;
                        inputReg <= inputShiftReg;
                        -- state <= HOLD;
                    else 
                        counter <= counter + 1;
                    end if;    
                    inputShiftReg <= inputShiftReg(inputShiftReg'high - 1 downto inputShiftReg'low) & miso;                         
                -- when HOLD =>
            end case;

            
        end if;
    end process;
end architecture rtl;