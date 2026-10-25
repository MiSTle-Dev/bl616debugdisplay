module vt52 (
            input clk,
            input clk_pixel,
            input uart_clk,
            input pll_lock,
            output hsync,
            output vsync,
            output vblank,
            output hblank,
            output video,
            output led,
            input [7:0] usb_kbd,
            input kbd_strobe,
            input  rxd,
            output txd
            );
   localparam ROWS = 25;
   localparam COLS = 80;
   localparam ROW_BITS = 5;
   localparam COL_BITS = 7;
   localparam ADDR_BITS = 11;


   // scroll
   wire [ADDR_BITS-1:0] new_first_char;
   wire new_first_char_wen;
   wire [ADDR_BITS-1:0] first_char;
   // cursor
   wire [ROW_BITS-1:0]  new_cursor_y;
   wire [COL_BITS-1:0]  new_cursor_x;
   wire new_cursor_wen;
   wire cursor_blink_on;
   wire [ROW_BITS-1:0] cursor_y;
   wire [COL_BITS-1:0] cursor_x;
   // char buffer
   wire [7:0] new_char;
   wire [ADDR_BITS-1:0] new_char_address;
   wire new_char_wen;
   wire [ADDR_BITS-1:0] char_address;
   wire [7:0] char;
   wire graphic_character;
   wire graphic_mode;
   // char rom
   wire [11:0] char_rom_address;
   wire [7:0] char_rom_data;

   // uart input/output
   wire [7:0] uart_out_data;
   wire uart_out_valid;

   wire [7:0] keyboard_data;
   wire keyboard_valid, keyboard_ready;
   wire [7:0] reply_data;
   wire reply_valid, reply_ready;
   wire tx_fifo_ready;
   wire [7:0] uart_in_data;
   wire uart_in_valid;
   wire uart_in_ready;

   assign reply_ready = tx_fifo_ready;
   assign keyboard_ready = tx_fifo_ready && !reply_valid;

   fifo_async #(.DW(8), .EA(4))
      tx_fifo (
         .i_rstn(pll_lock),
         .i_clk(clk),
         .i_tready(tx_fifo_ready),
         .i_tvalid(reply_valid || keyboard_valid),
         .i_tdata(reply_valid ? reply_data : keyboard_data),
         .o_rstn(pll_lock),
         .o_clk(uart_clk),
         .o_tready(uart_in_ready),
         .o_tvalid(uart_in_valid),
         .o_tdata(uart_in_data)
      );

   // led follows the cursor blink
   assign led = cursor_blink_on;

   keyboard keyboard(.clk(clk),
                     .reset(~pll_lock),
                     .usb_kbd(usb_kbd),
                     .kbd_strobe(kbd_strobe),
                     .data(keyboard_data),
                     .valid(keyboard_valid),
                     .ready(keyboard_ready)
                   );

   cursor #(.ROW_BITS(ROW_BITS), .COL_BITS(COL_BITS))
      cursor(.clk(clk),
             .reset(~pll_lock),
             .tick(vblank),
             .x(cursor_x),
             .y(cursor_y),
             .blink_on(cursor_blink_on),
             .new_x(new_cursor_x),
             .new_y(new_cursor_y),
             .wen(new_cursor_wen)
            );

   simple_register #(.SIZE(ADDR_BITS))
      scroll_register(.clk(clk),
                      .reset(~pll_lock),
                      .idata(new_first_char),
                      .wen(new_first_char_wen),
                      .odata(first_char)
                      );

   char_buffer char_buffer(.clk(clk),
                           .din(new_char),
                           .waddr(new_char_address),
                           .wen(new_char_wen),
                           .raddr(char_address),
                           .dout(char),
                           .graphic_mode(graphic_mode),
                           .graphic_character(graphic_character)
                           );

   char_rom char_rom(.clk(clk),
                     .addr(char_rom_address),
                     .dout(char_rom_data),
                     .graphic_character(graphic_character)
                     );

   video_generator video_generator(
                      .clk(clk_pixel),
                      .reset(~pll_lock),
                      .hsync(hsync),
                      .vsync(vsync),
                      .video(video),
                      .hblank(hblank),
                      .vblank(vblank),
                      .cursor_x(cursor_x),
                      .cursor_y(cursor_y),
                      .cursor_blink_on(cursor_blink_on),
                      .first_char(first_char),
                      .char_buffer_address(char_address),
                      .char_buffer_data(char),
                      .char_rom_address(char_rom_address),
                      .char_rom_data(char_rom_data)
                      );

   wire uart_rxd_int;

   sync_signal #(
      .WIDTH(1),
      .N(4))
   sync_signal_inst (
      .clk(uart_clk),
      .in(rxd),
      .out(uart_rxd_int)
   );

   wire fifo_full;
   uart uart(
      .clk(uart_clk),
      .rst(~pll_lock),
      .rxd(uart_rxd_int),

      .txd(txd),
       // uart pipeline in (keyboard->usb)
      .s_axis_tdata(uart_in_data),
      .s_axis_tvalid(uart_in_valid),
      .s_axis_tready(uart_in_ready),

      // uart pipeline out
      .m_axis_tdata(uart_out_data),
      .m_axis_tvalid(uart_out_valid),
      .m_axis_tready(fifo_full),
      // status
      .tx_busy(),
      .rx_busy(),
      .rx_overrun_error(),
      .rx_frame_error(),
      //config
      .prescale(16'd4) //64000000/(2000000*8)
      );

   wire [7:0] fifo_data;
   wire fifo_valid, fifo_ready;

   fifo_async #(
      .DW(8),
      .EA(7))
   fifo_async(
      .i_rstn(pll_lock),
      .i_clk(uart_clk),
      .i_tready(fifo_full),
      .i_tvalid(uart_out_valid),
      .i_tdata(uart_out_data),

      .o_rstn(pll_lock),
      .o_clk(clk),
      .o_tready(fifo_ready),
      .o_tvalid(fifo_valid),
      .o_tdata(fifo_data)
   );

   command_handler #(.ROWS(ROWS),
                     .COLS(COLS),
                     .ROW_BITS(ROW_BITS),
                     .COL_BITS(COL_BITS),
                     .ADDR_BITS(ADDR_BITS))
      command_handler(.clk(clk),
                      .reset(~pll_lock),
                      .data(fifo_data),
                      .valid(fifo_valid),
                      .ready(fifo_ready),
                      .reply_data(reply_data),
                      .reply_valid(reply_valid),
                      .reply_ready(reply_ready),
                      .graphic_mode(graphic_mode),
                      .new_first_char(new_first_char),
                      .new_first_char_wen(new_first_char_wen),
                      .new_char(new_char),
                      .new_char_address(new_char_address),
                      .new_char_wen(new_char_wen),
                      .new_cursor_x(new_cursor_x),
                      .new_cursor_y(new_cursor_y),
                      .new_cursor_wen(new_cursor_wen)
                      );

 endmodule
