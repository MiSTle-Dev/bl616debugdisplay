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
    uart_rx         : in std_logic; -- from BL616
    uart_tx         : out std_logic; -- to BL616
    spi_sclk        : in std_logic;
    spi_csn         : in std_logic;
    spi_dir         : out std_logic;
    spi_dat         : in std_logic;
    spi_irqn        : out std_logic
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
signal spi_io_din     : std_logic;
signal spi_io_ss      : std_logic;
signal spi_io_clk     : std_logic;
signal spi_io_dout    : std_logic;
signal int_out_n      : std_logic;
signal mcu_data_out   : std_logic_vector(7 downto 0);
signal hid_data_out   : std_logic_vector(7 downto 0);
signal osd_data_out   : std_logic_vector(7 downto 0) :=  X"55";
signal sys_data_out   : std_logic_vector(7 downto 0);
signal hid_int        : std_logic;
signal usb_kbd        : std_logic_vector(7 downto 0);
signal int_ack        : std_logic_vector(7 downto 0);
signal mcu_sys_strobe : std_logic;
signal mcu_hid_strobe : std_logic;
signal mcu_osd_strobe : std_logic;
signal mcu_start      : std_logic;
signal kbd_strobe     : std_logic;

begin

  spi_io_din  <= spi_dat;
  spi_io_ss   <= spi_csn;
  spi_io_clk  <= spi_sclk;
  spi_dir     <= spi_io_dout;
  spi_irqn    <= int_out_n;

mcu_spi_inst: entity work.mcu_spi 
port map (
  clk            => dviclk,
  reset          => not pll_lock,
  -- SPI interface to BL616 MCU
  spi_io_ss      => spi_io_ss,      -- SPI CSn
  spi_io_clk     => spi_io_clk,     -- SPI SCLK
  spi_io_din     => spi_io_din,     -- SPI MOSI
  spi_io_dout    => spi_io_dout,    -- SPI MISO
  -- byte interface to the various core components
  mcu_sys_strobe => mcu_sys_strobe, -- byte strobe for system control target
  mcu_hid_strobe => mcu_hid_strobe, -- byte strobe for HID target  
  mcu_osd_strobe => open, -- byte strobe for OSD target
  mcu_sdc_strobe => open, -- byte strobe for SD card target
  mcu_start      => mcu_start,
  mcu_sys_din    => sys_data_out,
  mcu_hid_din    => hid_data_out,
  mcu_osd_din    => osd_data_out,
  mcu_sdc_din    => (others=>'0'),
  mcu_dout       => mcu_data_out
);

-- decode SPI/MCU data received for human input devices (HID) 
hid_inst: entity work.hid
 port map 
 (
  clk             => dviclk,
  reset           => not pll_lock,
  -- interface to receive user data from MCU (mouse, kbd, ...)
  data_in_strobe  => mcu_hid_strobe,
  data_in_start   => mcu_start,
  data_in         => mcu_data_out,
  data_out        => hid_data_out,

  -- input local db9 port events to be sent to MCU
  db9_port        => 6x"00",
  irq             => hid_int,
  iack            => int_ack(1),

  -- output HID data received from USB
  usb_kbd         => usb_kbd,
  kbd_strobe      => kbd_strobe,
  joystick0       => open,
  joystick1       => open,
  mouse_btns      => open,
  mouse_x         => open,
  mouse_y         => open,
  mouse_strobe    => open,
  joystick0ax     => open,
  joystick0ay     => open,
  joystick1ax     => open,
  joystick1ay     => open,
  joystick_strobe => open,
  extra_button0   => open,
  extra_button1   => open
  );

module_inst: entity work.sysctrl 
 port map 
 (
  clk                 => dviclk,
  reset               => not pll_lock,
--
  data_in_strobe      => mcu_sys_strobe,
  data_in_start       => mcu_start,
  data_in             => mcu_data_out,
  data_out            => sys_data_out,
  -- values that can be configured by the user

  -- port io (used to expose rs232)
  port_status         => (others=>'0'),
  port_out_available  => (others=>'0'),
  port_out_strobe     => open,
  port_out_data       => (others=>'0'),
  port_in_available   => (others=>'0'),
  port_in_strobe      => open,
  port_in_data        => open,

  int_out_n           => int_out_n,
  int_in              => unsigned'(x"0" & '0' & '0' & hid_int & '0'),
  int_ack             => int_ack,

  buttons             => "00",
  leds                => open,
  color               => open
);

vt52inst : entity work.vt52
port map (
    clk_in      => clk_in,
    clk         => dviclk, -- 25.2Mhz 
    pll_lock    => pll_lock,
    start       => framestart,
    hsync       => hSync,
    vsync       => vSync,
    video       => videoG0,
    usb_kbd     => usb_kbd,
    kbd_strobe  => kbd_strobe,
    rxd         => uart_rx,
    txd         => uart_tx
);

videoG  <= "11111111" when videoG0 = '1' else "00000000";

dvi1 : entity work.display_dvi
port map
(
    CLK             => clk_in,
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
