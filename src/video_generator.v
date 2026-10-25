/**
 * 80x25 char generator (8x16 char size) & sync generator
 */
module video_generator
   (input clk,
    input reset,
    // video output
    output reg hsync,
    output reg vsync,
    output reg video,
    // video output extra info
    output reg hblank,
    output reg vblank,
    // cursor
    input  [7-1:0] cursor_x,
    input  [5-1:0] cursor_y,
    input  cursor_blink_on,
    // scrolling
    input  [11-1:0] first_char,
    // char buffer
    output  [11-1:0] char_buffer_address,
    input  [7:0] char_buffer_data,
    // char rom
    output  [11:0] char_rom_address,
    input  [7:0] char_rom_data
    );
   localparam PAST_LAST_ROW = 25 * 80;
   localparam hbits = 10;
   localparam hpixels = 799;
   localparam hbp = 48;
   localparam hvisible = 640;
   localparam hfp = 16;
   localparam hpulse = 96;
   localparam vbits = 9;
   localparam vlines = 448;
   localparam vbp = 35;
   localparam vvisible = 400;
   localparam vfp = 12;
   localparam vpulse = 2;
   // sync polarity
   localparam hsync_on = 1'b0;
   localparam vsync_on = 1'b1;
   localparam hsync_off = ~hsync_on;
   localparam vsync_off = ~vsync_on;
   // video polarity
   localparam video_on = 1'b1;
   localparam video_off = ~video_on;

   // These are to combine the chars & the cursor for video output
   reg is_under_cursor;
   reg cursor_pixel;
   reg char_pixel;
   reg combined_pixel;

   // horizontal & vertical counters
   reg [hbits-1:0] hc, next_hc;
   reg [vbits-1:0] vc, next_vc;
   // syncs and blanks
   reg next_hblank, next_vblank, next_hsync, next_vsync;
   wire active_pixel = !next_hblank && !next_vblank;
   wire [9:0] pixel_x = active_pixel ? next_hc - 10'd48 : 10'd0;
   wire [8:0] pixel_y = active_pixel ? next_vc - 9'd35 : 9'd0;
   wire [6:0] col = pixel_x[9:3];
   wire [4:0] row = pixel_y[8:4];
   wire [2:0] colc = pixel_x[2:0];
   wire [9:0] fetch_hc = hc >= 10'd797 ? hc - 10'd797 : hc + 10'd3;
   wire [8:0] fetch_vc = hc >= 10'd797 ?
                        (vc == vlines ? 9'd0 : vc + 9'd1) : vc;
   wire fetch_active = fetch_hc >= hbp && fetch_hc < hbp + hvisible &&
                       fetch_vc >= vbp && fetch_vc < vbp + vvisible;
   wire [9:0] fetch_x = fetch_active ? fetch_hc - 10'd48 : 10'd0;
   wire [8:0] fetch_y = fetch_active ? fetch_vc - 9'd35 : 9'd0;
   wire [4:0] fetch_row = fetch_y[8:4];
   wire [6:0] fetch_col = fetch_x[9:3];
   reg [10:0] display_first_char;
   wire [11:0] buffer_offset = {1'b0, display_first_char} +
                              ({7'b0, fetch_row} << 6) +
                              ({7'b0, fetch_row} << 4) + {5'b0, fetch_col};
   wire [11:0] wrapped_address = buffer_offset >= PAST_LAST_ROW ?
                                buffer_offset - 12'd2000 : buffer_offset;

   reg [7:0] glyph_pixels;

   // Prefetch two pixels early so both 2x-clocked memories settle even when
   // clock edges coincide. Hold each glyph while fetching the following one.
   assign char_buffer_address = wrapped_address[10:0];
   assign char_rom_address = { char_buffer_data, fetch_y[3:0] };

   always @(posedge clk) begin
      if (reset || vblank)
         display_first_char <= first_char;
   end

   //
   // horizontal & vertical counters, syncs and blanks
   //
   always @(posedge clk) begin
      if (reset) begin
         hc <= 0;
         vc <= 0;
         hsync <= hsync_off;
         vsync <= vsync_off;
         hblank <= 1;
         vblank <= 1;
      end
      else begin
         hc <= next_hc;
         vc <= next_vc;
         hsync <= next_hsync;
         vsync <= next_vsync;
         hblank <= next_hblank;
         vblank <= next_vblank;
      end
   end

   always @(*) begin
      if (hc == hpixels) begin
         next_hc = 0;
         next_vc = (vc == vlines)? 0 : vc + 1;
      end
      else begin
         next_hc = hc + 1;
         next_vc = vc;
      end
      next_hsync = (next_hc >= hbp + hvisible + hfp)? hsync_on : hsync_off;
      next_vsync = (next_vc >= vbp + vvisible + vfp)? vsync_on : vsync_off;
      next_hblank = (next_hc < hbp || next_hc >= hbp + hvisible);
      next_vblank = (next_vc < vbp || next_vc >= vbp + vvisible);
   end

   //
   // pixel out (char & cursor combination)
   //
   always @(posedge clk) begin
      if (reset) begin
         video <= video_off;
         glyph_pixels <= 0;
      end
      else begin
         video <= combined_pixel;
         if (active_pixel && colc == 0)
            glyph_pixels <= char_rom_data;
      end
   end

   always @(*) begin
      // cursor pixel: invert video when we are under the cursor (if it's blinking)
      is_under_cursor = (cursor_x == col) & (cursor_y == row);
      cursor_pixel = is_under_cursor & cursor_blink_on;
      // char pixel: read from the appropiate char, row & col on the font ROM,
      // Font pixels are ordered MSB first.
      char_pixel = colc == 0 ? char_rom_data[7] : glyph_pixels[7 - colc];
      // combine, but only emit video on non-blanking periods
      combined_pixel = (next_hblank || next_vblank)?
                       video_off :
                       char_pixel ^ cursor_pixel;
   end
endmodule // video_generator
