library IEEE;
use IEEE.std_logic_1164.all;


entity gowin_rpll_126mhz is
    port (
        clkin: in std_logic;
        init_clk: in std_logic;
        clkout0: out std_logic;
        lock: out std_logic
    );
end gowin_rpll_126mhz;


architecture Behavioral of gowin_rpll_126mhz is
    signal icpsel: std_logic_vector(5 downto 0);
    signal lpfres: std_logic_vector(2 downto 0);
    signal pll_lock: std_logic;
    signal pll_rst: std_logic;


    component gowin_rpll_126mhz_MOD
        port (
            clkout0: out std_logic;
            lock: out std_logic;
            reset: in std_logic;
            clkin: in std_logic;
            icpsel: in std_logic_vector(5 downto 0);
            lpfres: in std_logic_vector(2 downto 0);
            lpfcap: in std_logic_vector(1 downto 0)
        );
    end component;


    component PLL_INIT
        generic (
            CLK_PERIOD: INTEGER:= 50;
            MULTI_FAC: INTEGER:= 30
        );
        port (
            I_RST: in std_logic;
            O_RST: out std_logic;
            PLLLOCK: in std_logic;
            O_LOCK: out std_logic;
            CLKIN: in std_logic;
            ICPSEL: out std_logic_vector(5 downto 0);
            LPFRES: out std_logic_vector(2 downto 0)
        );
    end component;


begin
    u_pll: gowin_rpll_126mhz_MOD
        port map (
            clkout0 => clkout0,
            lock => pll_lock,
            clkin => clkin,
            reset => pll_rst,
            icpsel => icpsel,
            lpfres => lpfres,
            lpfcap => "00"
        );


    u_pll_init: PLL_INIT
        generic map (
            CLK_PERIOD => 20,
            MULTI_FAC => 15
        )
        port map (
            I_RST => '0',
            O_RST => pll_rst,
            PLLLOCK => pll_lock,
            O_LOCK => lock,
            CLKIN => init_clk,
            ICPSEL => icpsel,
            LPFRES => lpfres
        );


end Behavioral; --gowin_rpll_126mhz
