library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity decpromem is
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
end entity decpromem;

architecture rtl of decpromem is
constant useSN74ALS640 : boolean := false;
signal clk: std_logic;
signal spiclk: std_logic;
signal miso: std_logic;
signal mosi: std_logic;
signal nhold: std_logic;
signal ncs: std_logic; 
signal ida: std_logic_vector (21 downto 0);
signal ia: std_logic_vector (21 downto 0);
signal ma: std_logic_vector (21 downto 0);
signal mcelow: std_logic;
signal nmcehigh: std_logic;
signal mhe: std_logic;
signal mle: std_logic;
signal moe: std_logic;
signal mwe: std_logic;
signal busoe: std_logic;
signal busdir: std_logic;
signal mbank: std_logic_vector (6 downto 0);
signal asl: std_logic;
signal mdenl: std_logic;
signal sdenl: std_logic;

component CY62167 is
    port(
      address : in std_logic_vector (19 downto 0);
      data: inout std_logic_vector (15 downto 0);
      ce2: in std_logic;
      nce1: in std_logic;
      nbhe: in std_logic;
      nble: in std_logic;
      nwe: in std_logic;
      noe: in std_logic
    );
end component;

component ClockGen is
    port(
      CLK : out std_logic
    );
end component;

component SPIROM is
    port(
        nCS: in std_logic;
        nHOLD: in std_logic;
        MOSI: in std_logic;
        MISO: out std_logic;
        CLK: in std_logic 
      );
end component; 

component DP8307 is
    port(
        pin_1_A0: inout std_logic;
        pin_2_A1: inout std_logic;
        pin_3_A2: inout std_logic;
        pin_4_A3: inout std_logic;
        pin_5_A4: inout std_logic;
        pin_6_A5: inout std_logic;
        pin_7_A6: inout std_logic;
        pin_8_A7: inout std_logic; 
        pin_9_nT: in std_logic; 
        pin_11_nR: in std_logic;
        pin_12_B7: inout std_logic;
        pin_13_B6: inout std_logic;
        pin_14_B5: inout std_logic;
        pin_15_B4: inout std_logic;
        pin_16_B3: inout std_logic;
        pin_17_B2: inout std_logic;
        pin_18_B1: inout std_logic; 
        pin_19_B0: inout std_logic 
    );
end component;

component SN74ALS640 is
    port(
        pin_1_DIR: in std_logic;
        pin_2_A1: inout std_logic;
        pin_3_A2: inout std_logic;
        pin_4_A3: inout std_logic;
        pin_5_A4: inout std_logic;
        pin_6_A5: inout std_logic;
        pin_7_A6: inout std_logic;
        pin_8_A7: inout std_logic; 
        pin_9_A8: inout std_logic;     
        pin_11_B8: inout std_logic;
        pin_12_B7: inout std_logic;
        pin_13_B6: inout std_logic;
        pin_14_B5: inout std_logic;
        pin_15_B4: inout std_logic;
        pin_16_B3: inout std_logic;
        pin_17_B2: inout std_logic;
        pin_18_B1: inout std_logic; 
        pin_19_nOE: in std_logic    
    );
end component;


component SN74LS373 is
    port(
        pin_1_nOC : in std_logic;
        pin_2_1Q : out std_logic;
        pin_3_1D : in std_logic;
        pin_4_2D : in std_logic;
        pin_5_2Q : out std_logic;
        pin_6_3Q : out std_logic;
        pin_7_3D : in std_logic;
        pin_8_4D : in std_logic;
        pin_9_4Q : out std_logic;
        pin_11_C : in std_logic;
        pin_12_5Q : out std_logic;
        pin_13_5D : in std_logic;
        pin_14_6D : in std_logic;
        pin_15_6Q : out std_logic;
        pin_16_7Q : out std_logic;
        pin_17_7D : in std_logic;
        pin_18_8D : in std_logic;
        pin_19_8Q : out std_logic
    );    
end component;

component ATF1508 is
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
        biosel: in std_logic;
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
        -- 
        asl : out std_logic;
        mdenl : out std_logic;
        sdenl : out std_logic
    );
end component;

begin
    ma(21 downto 15) <= mbank(6 downto 0);
    ma(14 downto 1) <= ia (14 downto 1);

    HighRAM: CY62167 port map(
        address => ma(20 downto 1),
        data => ida (15 downto 0),
        ce2 => ma(21),
        nce1 => nmcehigh,
        nbhe => mhe,
        nble => mle,
        nwe => mwe,
        noe => moe  
    );
    
    LowRAM: CY62167 port map(
        address => ma(20 downto 1),
        data => ida (15 downto 0),
        ce2 => mcelow,
        nce1 => ma(21),
        nbhe => mhe,
        nble => mle,
        nwe => mwe,
        noe => moe  
    ); 
      
    ClockGenerator: ClockGen port map (
        CLK => clk
    );


    SPI_ROM: SPIROM port map (
        nCS => ncs,
        nHOLD => nhold,
        MOSI => mosi,
        MISO => miso,
        CLK => spiclk
    );

CondDP8307: if not useSN74ALS640 generate 

    LOWXCEIVER: DP8307 port map (
        pin_1_A0 => bdal(0),
        pin_2_A1 => bdal(1),
        pin_3_A2 => bdal(2),
        pin_4_A3 => bdal(3),
        pin_5_A4 => bdal(4),
        pin_6_A5 => bdal(5),
        pin_7_A6 => bdal(6),
        pin_8_A7 => bdal(7), 
        pin_9_nT => mdenl,
        pin_11_nR => sdenl,
        pin_12_B7 => ida(7),
        pin_13_B6 => ida(6),
        pin_14_B5 => ida(5),
        pin_15_B4 => ida(4),
        pin_16_B3 => ida(3),
        pin_17_B2 => ida(2),
        pin_18_B1 => ida(1), 
        pin_19_B0 => ida(0)        
    );

    MIDXCEIVER: DP8307 port map (
        pin_1_A0 => bdal(8),
        pin_2_A1 => bdal(9),
        pin_3_A2 => bdal(10),
        pin_4_A3 => bdal(11),
        pin_5_A4 => bdal(12),
        pin_6_A5 => bdal(13),
        pin_7_A6 => bdal(14),
        pin_8_A7 => bdal(15), 
        pin_9_nT => mdenl,
        pin_11_nR => sdenl,
        pin_12_B7 => ida(15),
        pin_13_B6 => ida(14),
        pin_14_B5 => ida(13),
        pin_15_B4 => ida(12),
        pin_16_B3 => ida(11),
        pin_17_B2 => ida(10),
        pin_18_B1 => ida(9), 
        pin_19_B0 => ida(8)   
    );

    HIXCEIVER: DP8307 port map (
        pin_1_A0 => bdal(16),
        pin_2_A1 => bdal(17),
        pin_3_A2 => bdal(18),
        pin_4_A3 => bdal(19),
        pin_5_A4 => bdal(20),
        pin_6_A5 => bdal(21),
        pin_7_A6 => open,
        pin_8_A7 => open, 
        pin_9_nT => mdenl,
        pin_11_nR => sdenl,
        pin_12_B7 => open,
        pin_13_B6 => open,
        pin_14_B5 => ida(21),
        pin_15_B4 => ida(20),
        pin_16_B3 => ida(19),
        pin_17_B2 => ida(18),
        pin_18_B1 => ida(17), 
        pin_19_B0 => ida(16)   
    );  

end generate CondDP8307;
CondSN74ALS640: if useSN74ALS640 generate 
    LOWXCEIVER: SN74ALS640 port map (
            pin_1_DIR => busdir,
            pin_2_A1 => bdal(0),
            pin_3_A2 => bdal(1),
            pin_4_A3 => bdal(2),
            pin_5_A4 => bdal(3),
            pin_6_A5 => bdal(4),
            pin_7_A6 => bdal(5),
            pin_8_A7 => bdal(6), 
            pin_9_A8 => bdal(7),     
            pin_11_B8 => ida(7),
            pin_12_B7 => ida(6),
            pin_13_B6 => ida(5),
            pin_14_B5 => ida(4),
            pin_15_B4 => ida(3),
            pin_16_B3 => ida(2),
            pin_17_B2 => ida(1),
            pin_18_B1 => ida(0), 
            pin_19_nOE => busoe
    );

    MIDXCEIVER: SN74ALS640 port map (
        pin_1_DIR => busdir,
        pin_2_A1 => bdal(8),
        pin_3_A2 => bdal(9),
        pin_4_A3 => bdal(10),
        pin_5_A4 => bdal(11),
        pin_6_A5 => bdal(12),
        pin_7_A6 => bdal(13),
        pin_8_A7 => bdal(14), 
        pin_9_A8 => bdal(15),     
        pin_11_B8 => ida(15),
        pin_12_B7 => ida(14),
        pin_13_B6 => ida(13),
        pin_14_B5 => ida(12),
        pin_15_B4 => ida(11),
        pin_16_B3 => ida(10),
        pin_17_B2 => ida(9),
        pin_18_B1 => ida(8), 
        pin_19_nOE => busoe  
);

HIXCEIVER: SN74ALS640 port map (
    pin_1_DIR => busdir,
    pin_2_A1 => bdal(16),
    pin_3_A2 => bdal(17),
    pin_4_A3 => bdal(18),
    pin_5_A4 => bdal(19),
    pin_6_A5 => bdal(20),
    pin_7_A6 => bdal(21),
    pin_8_A7 => open, 
    pin_9_A8 => open,     
    pin_11_B8 => open,
    pin_12_B7 => open,
    pin_13_B6 => ida(21),
    pin_14_B5 => ida(20),
    pin_15_B4 => ida(19),
    pin_16_B3 => ida(18),
    pin_17_B2 => ida(17),
    pin_18_B1 => ida(16), 
    pin_19_nOE => busoe 
);

end generate CondSN74ALS640;

    LOWLATCH: SN74LS373 port map(
        pin_1_nOC => '0',
        pin_2_1Q => ia(0),
        pin_3_1D => ida(0),
        pin_4_2D => ida(1),
        pin_5_2Q => ia(1),
        pin_6_3Q => ia(2),
        pin_7_3D => ida(2),
        pin_8_4D => ida(3),
        pin_9_4Q => ia(3),
        pin_11_C => asl,
        pin_12_5Q => ia(4),
        pin_13_5D => ida(4),
        pin_14_6D => ida(5),
        pin_15_6Q => ia(5),
        pin_16_7Q => ia(6),
        pin_17_7D => ida(6),
        pin_18_8D => ida(7),
        pin_19_8Q => ia(7)
    );
    
    MIDLATCH: SN74LS373 port map( 
        pin_1_nOC => '0',
        pin_2_1Q => ia(8),
        pin_3_1D => ida(8),
        pin_4_2D => ida(9),
        pin_5_2Q => ia(9),
        pin_6_3Q => ia(10),
        pin_7_3D => ida(10),
        pin_8_4D => ida(11),
        pin_9_4Q => ia(11),
        pin_11_C => asl,
        pin_12_5Q => ia(12),
        pin_13_5D => ida(12),
        pin_14_6D => ida(13),
        pin_15_6Q => ia(13),
        pin_16_7Q => ia(14),
        pin_17_7D => ida(14),
        pin_18_8D => ida(15),
        pin_19_8Q => ia(15)        
    );

    HILATCH: SN74LS373 port map(
        pin_1_nOC => '0',
        pin_2_1Q => ia(16),
        pin_3_1D => ida(16),
        pin_4_2D => ida(17),
        pin_5_2Q => ia(17),
        pin_6_3Q => ia(18),
        pin_7_3D => ida(18),
        pin_8_4D => ida(19),
        pin_9_4Q => ia(19),
        pin_11_C => asl,
        pin_12_5Q => ia(20),
        pin_13_5D => ida(20),
        pin_14_6D => ida(21),
        pin_15_6Q => ia(21),
        pin_16_7Q => open,
        pin_17_7D => 'H',
        pin_18_8D => 'H',
        pin_19_8Q => open         
    );
    
    CPLD: ATF1508 port map(
           -- 40 MHz clock
        clk => clk,
    -- spi interface 
        spiclk => spiclk,
        mosi => mosi,
        miso => miso,
        ncs => ncs,
        nhold => nhold,
    -- PRO bus interface
        binitl => binitl,
        bdcokh => bdcokh,
        ioa => ia (6 downto 1),
        a => ia (21 downto 15),
        data => ida(7 downto 0),
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
    -- memory inteface
        ma => mbank,
        mcelow => mcelow,
        nmcehigh => nmcehigh,
        moe => moe,
        mhe => mhe,
        mle => mle,
        mwe => mwe,
    -- size jumper
        msiz => msiz,
    -- dir and oe for 74ALS640-1
        busoe => busoe,
        busdir => busdir,
        asl => asl,
        mdenl => mdenl,
        sdenl => sdenl
      );


end architecture rtl;