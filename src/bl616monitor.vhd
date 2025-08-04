library ieee;
use ieee.std_logic_1164.all;
use  IEEE.STD_LOGIC_ARITH.all;
use  IEEE.STD_LOGIC_UNSIGNED.all;

entity bl616monitor is
port(
    clk_in          : in std_logic;
    tmds_clk_p      : out std_logic;
    tmds_clk_n      : out std_logic;
    tmds_d_p        : out std_logic_vector(2 downto 0);
    tmds_d_n        : out std_logic_vector(2 downto 0);
    uart_rx         : in std_logic
  );
end bl616monitor;

architecture struct of bl616monitor is

signal videoG0      : std_logic;
signal videoG       : std_logic_vector(7 downto 0) := "00000000";
signal hSync        : std_logic;
signal vSync        : std_logic;
signal uartrx       : std_logic;
signal uarttx       : std_logic;
signal dviclk       : std_logic;
signal vgaclk       : std_logic;
signal framestart   : std_logic;
signal clk_lock     : std_logic;
signal pll_lock     : std_logic;
signal pixel_clk    : std_logic;
signal clk160m      : std_logic;

begin

pll_inst:entity work.Gowin_PLL_160
    port map (
        lock => open,
        clkout0 => clk160m,
        clkin => clk_in
    );

vt52inst : entity work.vt52
port map (
    clk         => dviclk, -- 25.2Mhz 
    pll_lock    => pll_lock,
    pixel_clk   => clk160m, -- 160Mhz
    start       => framestart,
    hsync       => hSync,
    vsync       => vSync,
    video       => videoG0,
    ps2_data    => '1',
    ps2_clk     => '1',
    rxd         => uart_rx
);

videoG  <= "11111111" when videoG0 = '1' else "00000000";

dvi1 : entity work.display_dvi
port map
(
    CLK             => clk_in,
    pixel_clk       => pixel_clk,
    hdmi_tx_clk_n   => tmds_clk_n,
    hdmi_tx_clk_p   => tmds_clk_p,
    hdmi_tx_n       => tmds_d_n,
    hdmi_tx_p       => tmds_d_p,
    pll_lock        => pll_lock,
    red             => "00000000",
    green           => videoG,
    blue            => "00100000",
    dviclk          => dviclk,
    framestart      => framestart
);

end;
