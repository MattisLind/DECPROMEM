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
    biosel: in std_logic
);
end entity decpromem;

architecture rtl of decpromem is

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
signal msiz: std_logic;
signal hida: std_logic_vector (23 downto 16);
signal hibdal: std_logic_vector (23 downto 16);
signal hia: std_logic_vector (23 downto 16);
signal mbank: std_logic_vector (21 downto 15);

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
        A : inout std_logic_vector (7 downto 0);
        B: inout std_logic_vector (7 downto 0);
        nT: in std_logic;
        nR: in std_logic
    );
end component;

component SN74LS373 is
    port(
        D : in std_logic_vector (7 downto 0);
        Q: out std_logic_vector (7 downto 0);
        C: in std_logic;
        nOC: in std_logic
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
        bssxl: in std_logic;
        bdsl: in std_logic;
        basl: in std_logic;
        biosel: in std_logic;
        -- memory inteface
        ma: out std_logic_vector(21 downto 15);
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
        busdir: out std_logic
    );
end component;

begin
    ma(21 downto 15) <= mbank(21 downto 15);
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

    LOWXCEIVER: DP8307 port map (
        A => bdal(7 downto 0),
        B => ida(7 downto 0),
        nT => bmdenl,
        nR => bsdenl
    );

    MIDXCEIVER: DP8307 port map (
        A => bdal(15 downto 8),
        B => ida(15 downto 8),
        nT => bmdenl,
        nR => bsdenl
    );

    HIXCEIVER: DP8307 port map (
        A => hibdal(23 downto 16),
        B => hida(23 downto 16),
        nT => bmdenl,
        nR => bsdenl
    );  

    hibdal(21 downto 16) <= bdal(21 downto 16);
    ida(21 downto 16) <= hida(21 downto 16);

    LOWLATCH: SN74LS373 port map(
        D => ida(7 downto 0),
        Q => ia (7 downto 0),
        C => basl,
        nOC => '0'
    );
    
    MIDLATCH: SN74LS373 port map(
        D => ida(15 downto 8),
        Q => ia (15 downto 8),
        C => basl,
        nOC => '0'
    );

    HILATCH: SN74LS373 port map(
        D => hida(23 downto 16),
        Q => hia (23 downto 16),
        C => basl,
        nOC => '0'
    );

    ia (21 downto 16) <= hia(21 downto 16);
    
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
        busdir => busdir
      );

    msiz <= '0';

end architecture rtl;