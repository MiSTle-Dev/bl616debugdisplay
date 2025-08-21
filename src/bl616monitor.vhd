library ieee;
use ieee.std_logic_1164.all;
use  IEEE.STD_LOGIC_ARITH.all;
use  IEEE.STD_LOGIC_UNSIGNED.all;

entity bl616monitor is
port(
    clk_in          : in std_logic;
    reset           : in std_logic; -- S2 button
    user            : in std_logic; -- S1 button
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
    spi_irqn        : out std_logic;
    sd_clk          : out std_logic;
    sd_cmd          : inout std_logic;
    sd_dat          : inout std_logic_vector(3 downto 0);
    -- monitor port
    bl616_mon_tx    : out std_logic;
    bl616_mon_rx    : in std_logic;
    ws2812          : out std_logic
    );
end bl616monitor;

architecture struct of bl616monitor is

signal videoG0      : std_logic;
signal videoG       : std_logic_vector(3 downto 0);
signal hSync        : std_logic;
signal vSync        : std_logic;
signal vblank       : std_logic;
signal hblank       : std_logic;
signal uartrx       : std_logic;
signal uarttx       : std_logic;
signal dviclk       : std_logic;
signal clk_pixel_x5 : std_logic;
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
signal sdc_data_out   : std_logic_vector(7 downto 0);
signal hid_int        : std_logic;
signal usb_kbd        : std_logic_vector(7 downto 0);
signal int_ack        : std_logic_vector(7 downto 0);
signal mcu_sys_strobe : std_logic;
signal mcu_hid_strobe : std_logic;
signal mcu_osd_strobe : std_logic;
signal mcu_start      : std_logic;
signal kbd_strobe     : std_logic;
signal ws2812_color   : std_logic_vector(23 downto 0);
signal sdc_int        : std_logic :='0';
signal sdc_iack       : std_logic;
signal mcu_sdc_strobe : std_logic;
signal uart_tx_terminal : std_logic;

component CLKDIV
    generic (
        DIV_MODE : STRING := "2";
        GSREN: in string := "false"
    );
    port (
        CLKOUT: out std_logic;
        HCLKIN: in std_logic;
        RESETN: in std_logic;
        CALIB: in std_logic
    );
end component;

begin

  -- BL616 console to hw pins for external USB-UART adapter
  uart_tx <= bl616_mon_rx and uart_tx_terminal;
  bl616_mon_tx <= uart_rx;

  spi_io_din  <= spi_dat;
  spi_io_ss   <= spi_csn;
  spi_io_clk  <= spi_sclk;
  spi_dir     <= spi_io_dout;
  spi_irqn    <= int_out_n;

pll_inst: entity work.Gowin_rPLL
    port map (
        clkout => clk_pixel_x5,
        lock   => pll_lock,
        clkin  => clk_in
    );

div_inst: CLKDIV
generic map(
    DIV_MODE => "5",
    GSREN    => "false"
)
port map(
    CLKOUT => dviclk,
    HCLKIN => clk_pixel_x5,
    RESETN => pll_lock,
    CALIB  => '0'
);

led_ws2812: entity work.ws2812
  port map
  (
   clk    => dviclk,
   color  => ws2812_color,
   data   => ws2812
  );

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
  mcu_osd_strobe => mcu_osd_strobe, -- byte strobe for OSD target
  mcu_sdc_strobe => mcu_sdc_strobe, -- byte strobe for SD card target
  mcu_start      => mcu_start,
  mcu_sys_din    => sys_data_out,
  mcu_hid_din    => hid_data_out,
  mcu_osd_din    => osd_data_out,
  mcu_sdc_din    => sdc_data_out,
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
  system_reset        => open,
  -- port io (used to expose rs232)
  port_status         => (others=>'0'),
  port_out_available  => (others=>'0'),
  port_out_strobe     => open,
  port_out_data       => (others=>'0'),
  port_in_available   => (others=>'0'),
  port_in_strobe      => open,
  port_in_data        => open,

  int_out_n           => int_out_n,
  int_in              => unsigned'(x"0" & sdc_int & '0' & hid_int & '0'),
  int_ack             => int_ack,

  buttons             => unsigned'(user & reset),
  leds                => open,
  color               => ws2812_color
);

video_inst: entity work.video 
port map(
      pll_lock   => pll_lock,
      clk        => dviclk,
      clk_pixel_x5 => clk_pixel_x5,
      audio_div  => (others=>'0'),
      ntscmode  => '1',
      vb_in     => vblank,
      hb_in     => hblank,
      hs_in_n   => hSync,
      vs_in_n   => vSync,

      r_in      => "0000",
      g_in      => videoG,
      b_in      => "0010",

      audio_l => (others=>'0'),
      audio_r => (others=>'0'),
      osd_status => open,

      mcu_start => mcu_start,
      mcu_osd_strobe => mcu_osd_strobe,
      mcu_data  => mcu_data_out,

      -- values that can be configure by the user via osd
      system_wide_screen => '0',
      system_scanlines => "00",
      system_volume => "00",

      tmds_clk_n => tmds_clk_n,
      tmds_clk_p => tmds_clk_p,
      tmds_d_n   => tmds_d_n,
      tmds_d_p   => tmds_d_p
      );

vt52inst : entity work.vt52
port map (
    clk_in      => clk_in,
    clk         => dviclk,
    pll_lock    => pll_lock,
    hsync       => hSync,
    vsync       => vSync,
    vblank      => vblank,
    hblank      => hblank,
    video       => videoG0,
    usb_kbd     => usb_kbd,
    kbd_strobe  => kbd_strobe,
    rxd         => uart_rx,
    txd         => uart_tx_terminal
);

videoG  <= "1111" when videoG0 = '1' else "0000";

sdc_iack <= int_ack(3);

sd_card_inst: entity work.sd_card
generic map (
    CLK_DIV  => 1
  )
    port map (
    rstn            => pll_lock,
    clk             => dviclk,
  
    -- SD card signals
    sdclk           => sd_clk,
    sdcmd           => sd_cmd,
    sddat           => sd_dat,

    -- mcu interface
    data_strobe     => mcu_sdc_strobe,
    data_start      => mcu_start,
    data_in         => mcu_data_out,
    data_out        => sdc_data_out,

    -- interrupt to signal communication request
    irq             => sdc_int,
    iack            => sdc_iack,

    -- output file/image information. Image size is e.g. used by fdc to 
    -- translate between sector/track/side and lba sector
    image_size      => open,
    image_mounted   => open,

    -- user read sector command interface (sync with clk)
    rstart          => "00000",
    wstart          => "00000", 
    rsector         => (others=>'0'),
    rbusy           => open,
    rdone           => open,

    -- sector data output interface (sync with clk)
    inbyte          => x"00",        -- sector data output interface (sync with clk)
    outen           => open, -- when outen=1, a byte of sector content is read out from outbyte
    outaddr         => open,     -- outaddr from 0 to 511, because the sector size is 512
    outbyte         => open         -- a byte of sector content
);


end;
