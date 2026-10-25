/**
 * Character Font ROM (4kx8)
 * This could be a RAM to allow font modifications, but not for now
 * latin-1 subset of Terminus Font 8x16 (http://terminus-font.sourceforge.net)
 * Terminus Font is licensed under the SIL Open Font License, Version 1.1.
 * The license is included as ofl.txt, and is also available with a FAQ
 * at http://scripts.sil.org/OFL
 */
module char_rom
  (input  clk,
   input  [11:0] addr,
   output  [7:0] dout,
   input graphic_character
   );

   reg [7:0] doutreg;
   reg [7:0] mem [4095:0];
   // Thirty 8x16 graphics glyphs, packed with row zero in the most
   // significant byte; these are selected for character codes E1 through FE.
   reg [127:0] graphics_mem [0:29];

   initial begin
      $readmemh("mem/terminus_816_latin1.hex", mem) ;
      $readmemh("mem/vt52_graphics_816.hex", graphics_mem);
//      $readmemh("mem/terminus_816_bold_latin1.hex", mem) ;
   end

   always @(posedge clk) begin
      if (graphic_character && addr[11:4] >= 8'he1 &&
          addr[11:4] <= 8'hfe)
         doutreg <= graphics_mem[addr[8:4] - 5'd1]
                    [127 - (addr[3:0] * 8) -: 8];
      else
         doutreg <= mem[addr];
   end

   assign dout = doutreg;

endmodule
