/**
 * Char Buffer RAM (2000x8)
 * (25 lines of 80 characters)
 */
module char_buffer
  #(parameter BUF_SIZE = 2000,
    parameter ADDR_BITS = 11)
   (input  clk,
    input  [7:0] din,
    input  [ADDR_BITS-1:0] waddr,
    input  wen,
    input  [ADDR_BITS-1:0] raddr,
    output reg [7:0] dout,
    input graphic_mode,
    output reg graphic_character
    );

   reg [8:0] mem [BUF_SIZE-1:0];
   wire select_graphic_glyph = graphic_mode &&
                               din > 8'd96 && din < 8'd128;

   initial begin
      //$readmemh("mem/test.hex", mem) ;
      $readmemh("mem/empty.hex", mem) ;
   end

   always @(posedge clk) begin
      if (wen) begin
         mem[waddr] <= {select_graphic_glyph,
                        select_graphic_glyph ? (din | 8'h80) : din};
      end
      dout <= mem[raddr][7:0];
      graphic_character <= mem[raddr][8];
   end
endmodule
