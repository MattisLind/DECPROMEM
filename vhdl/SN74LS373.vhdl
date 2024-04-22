library IEEE;
use IEEE.std_logic_1164.all;

entity SN74LS373 is
port(
    signal pin_1_nOC : in std_logic;
    signal pin_2_1Q : out std_logic;
    signal pin_3_1D : in std_logic;
    signal pin_4_2D : in std_logic;
    signal pin_5_2Q : out std_logic;
    signal pin_6_3Q : out std_logic;
    signal pin_7_3D : in std_logic;
    signal pin_8_4D : in std_logic;
    signal pin_9_4Q : out std_logic;
    signal pin_11_C : in std_logic;
    signal pin_12_5Q : out std_logic;
    signal pin_13_5D : in std_logic;
    signal pin_14_6D : in std_logic;
    signal pin_15_6Q : out std_logic;
    signal pin_16_7Q : out std_logic;
    signal pin_17_7D : in std_logic;
    signal pin_18_8D : in std_logic;
    signal pin_19_8Q : out std_logic
);
end SN74LS373;

architecture rtl of SN74LS373 is
signal l1, l2, l3, l4, l5, l6, l7, l8 : std_logic;
begin 
    process (pin_3_1D, pin_11_C)
    begin
        if (pin_11_C = '0') then
            l1 <= pin_3_1D;
        end if;
    end process;
    pin_2_1Q <= l1 when pin_1_nOC = '0' else 'Z';
    process (pin_4_2D, pin_11_C)
    begin
        if (pin_11_C = '0') then
            l2 <= pin_4_2D;
        end if;
    end process;
    pin_5_2Q <= l2 when pin_1_nOC = '0' else 'Z';  
    process (pin_7_3D, pin_11_C)
    begin
        if (pin_11_C = '0') then
            l3 <= pin_7_3D;
        end if;
    end process;
    pin_6_3Q <= l3 when pin_1_nOC = '0' else 'Z';
    process (pin_8_4D, pin_11_C)
    begin
        if (pin_11_C = '0') then
            l4 <= pin_8_4D;
        end if;
    end process;
    pin_9_4Q <= l4 when pin_1_nOC = '0' else 'Z';    
    
    process (pin_13_5D, pin_11_C)
    begin
        if (pin_11_C = '0') then
            l5 <= pin_13_5D;
        end if;
    end process;
    pin_12_5Q <= l5 when pin_1_nOC = '0' else 'Z';
    process (pin_14_6D, pin_11_C)
    begin
        if (pin_11_C = '0') then
            l6 <= pin_14_6D;
        end if;
    end process;
    pin_15_6Q <= l6 when pin_1_nOC = '0' else 'Z';  
    process (pin_17_7D, pin_11_C)
    begin
        if (pin_11_C = '0') then
            l7 <= pin_17_7D;
        end if;
    end process;
    pin_16_7Q <= l7 when pin_1_nOC = '0' else 'Z';
    process (pin_18_8D, pin_11_C)
    begin
        if (pin_11_C = '0') then
            l8 <= pin_18_8D;
        end if;
    end process;
    pin_19_8Q <= l8 when pin_1_nOC = '0' else 'Z';     
end rtl;