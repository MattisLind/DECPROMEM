library IEEE;
use IEEE.std_logic_1164.all;

entity SN74ALS640 is
port(
  signal pin_1_DIR: in std_logic;
  signal pin_2_A1: inout std_logic;
  signal pin_3_A2: inout std_logic;
  signal pin_4_A3: inout std_logic;
  signal pin_5_A4: inout std_logic;
  signal pin_6_A5: inout std_logic;
  signal pin_7_A6: inout std_logic;
  signal pin_8_A7: inout std_logic; 
  signal pin_9_A8: inout std_logic;     
  signal pin_11_B8: inout std_logic;
  signal pin_12_B7: inout std_logic;
  signal pin_13_B6: inout std_logic;
  signal pin_14_B5: inout std_logic;
  signal pin_15_B4: inout std_logic;
  signal pin_16_B3: inout std_logic;
  signal pin_17_B2: inout std_logic;
  signal pin_18_B1: inout std_logic; 
  signal pin_19_nOE: in std_logic    
);
end SN74ALS640;

architecture rtl of SN74ALS640 is

begin 

    pin_2_A1 <= not pin_18_B1 when pin_1_DIR = '0' and pin_19_nOE = '0' else 'Z';
    pin_18_B1 <= not pin_2_A1 when pin_1_DIR = '1' and pin_19_nOE = '0' else 'Z'; 
    pin_3_A2 <= not pin_17_B2 when pin_1_DIR = '0' and pin_19_nOE = '0' else 'Z';
    pin_17_B2 <= not pin_3_A2 when pin_1_DIR = '1' and pin_19_nOE = '0' else 'Z';
    pin_4_A3 <= not pin_16_B3 when pin_1_DIR = '0' and pin_19_nOE = '0' else 'Z';
    pin_16_B3 <= not pin_4_A3 when pin_1_DIR = '1' and pin_19_nOE = '0' else 'Z';  
    pin_5_A4 <= not pin_15_B4 when pin_1_DIR = '0' and pin_19_nOE = '0' else 'Z';
    pin_15_B4 <= not pin_5_A4 when pin_1_DIR = '1' and pin_19_nOE = '0' else 'Z';
    pin_6_A5 <= not pin_14_B5 when pin_1_DIR = '0' and pin_19_nOE = '0' else 'Z';
    pin_14_B5 <= not pin_6_A5 when pin_1_DIR = '1' and pin_19_nOE = '0' else 'Z'; 
    pin_7_A6 <= not pin_13_B6 when pin_1_DIR = '0' and pin_19_nOE = '0' else 'Z';
    pin_13_B6 <= not pin_7_A6 when pin_1_DIR = '1' and pin_19_nOE = '0' else 'Z';
    pin_8_A7 <= not pin_12_B7 when pin_1_DIR = '0' and pin_19_nOE = '0' else 'Z';
    pin_12_B7 <= not pin_8_A7 when pin_1_DIR = '1' and pin_19_nOE = '0' else 'Z'; 
    pin_9_A8 <= not pin_11_B8 when pin_1_DIR = '0' and pin_19_nOE = '0' else 'Z';
    pin_11_B8 <= not pin_9_A8 when pin_1_DIR = '1' and pin_19_nOE = '0' else 'Z';              
end rtl;