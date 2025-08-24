/*
 table to translate from FPGA Compantions key codes into
 key codes for the terminal. The incoming FPGA Companion codes
 are mainly the USB HID key codes with the modifier keys
 mapped into the 0x68+ range.
*/

module keymap (
  input [6:0]  code,
  output [6:0] terminal
);

assign terminal = 
                           // 00: NoEvent
                           // 01: Overrun Error
                           // 02: POST fail
                           // 03: ErrorUndefined
  // characters
  (code == 7'h04)?"a":   // 04: a
  (code == 7'h05)?"b":   // 05: b
  (code == 7'h06)?"c":   // 06: c
  (code == 7'h07)?"d":   // 07: d
  (code == 7'h08)?"e":   // 08: e
  (code == 7'h09)?"f":   // 09: f
  (code == 7'h0a)?"g":   // 0a: g
  (code == 7'h0b)?"h":   // 0b: h
  (code == 7'h0c)?"i":   // 0c: i
  (code == 7'h0d)?"j":   // 0d: j
  (code == 7'h0e)?"k":   // 0e: k
  (code == 7'h0f)?"l":   // 0f: l
  (code == 7'h10)?"m":   // 10: m
  (code == 7'h11)?"n":   // 11: n
  (code == 7'h12)?"o":   // 12: o
  (code == 7'h13)?"p":   // 13: p
  (code == 7'h14)?"q":   // 14: q
  (code == 7'h15)?"r":   // 15: r
  (code == 7'h16)?"s":   // 16: s
  (code == 7'h17)?"t":   // 17: t
  (code == 7'h18)?"u":   // 18: u
  (code == 7'h19)?"v":   // 19: v
  (code == 7'h1a)?"w":   // 1a: w
  (code == 7'h1b)?"x":   // 1b: x
  (code == 7'h1c)?"y":   // 1c: y
  (code == 7'h1d)?"z":   // 1d: z

  // top number key row
  (code == 7'h1e)?"1":   // 1e: 1
  (code == 7'h1f)?"2":   // 1f: 2
  (code == 7'h20)?"3":   // 20: 3
  (code == 7'h21)?"4":   // 21: 4
  (code == 7'h22)?"5":   // 22: 5
  (code == 7'h23)?"6":   // 23: 6
  (code == 7'h24)?"7":   // 24: 7
  (code == 7'h25)?"8":   // 25: 8
  (code == 7'h26)?"9":   // 26: 9
  (code == 7'h27)?"0":   // 27: 0
  
  // other keys
  (code == 7'h28)?7'h0d:   // 28: return
  (code == 7'h29)?7'h1b:   // 29: esc
  (code == 7'h2a)?7'h08:   // 2a: backspace
  (code == 7'h2b)?7'h09:   // 2b: tab		  
  (code == 7'h2c)?7'h20:   // 2c: space

  (code == 7'h2d)?"-":   // 2d: -
  (code == 7'h2e)?"=":   // 2e: =
  (code == 7'h2f)?"[":   // 2f: [			  
  (code == 7'h30)?"]":   // 30: ]
  (code == 7'h31)?7'h47: // 31: backslash 
  (code == 7'h32)?"€":   // 32: EUR-1
  (code == 7'h33)?";":   // 33: ;
  (code == 7'h34)?"'":   // 34: ' 
  (code == 7'h35)?"`":   // 35: `
  (code == 7'h36)?":":   // 36: :
  (code == 7'h37)?".":   // 37: .
  (code == 7'h38)?"/":   // 38: /
  (code == 7'h39)?7'h62:   // 39: caps lock

  // function keys
  (code == 7'h3a)?7'h50:   // 3a: F1
  (code == 7'h3b)?7'h51:   // 3b: F2
  (code == 7'h3c)?7'h52:   // 3c: F3
  (code == 7'h3d)?7'h53:   // 3d: F4
  (code == 7'h3e)?7'h54:   // 3e: F5
  (code == 7'h3f)?7'h55:   // 3f: F6
  (code == 7'h40)?7'h56:   // 40: F7
  (code == 7'h41)?7'h57:   // 41: F8
  (code == 7'h42)?7'h58:   // 42: F9
  (code == 7'h43)?7'h59:   // 43: F10
                           // 44: F11
                           // 45: F12

                           // 46: PrtScr
                           // 47: Scroll Lock
                           // 48: Pause
                           // 49: Insert
  (code == 7'h4a)?7'h5a:   // 4a: Home -> KP-(
  (code == 7'h4b)?7'h5b:   // 4b: PageUp -> KP-)
  (code == 7'h4c)?7'h46:   // 4c: Delete
  (code == 7'h4d)?7'h5f:   // 4d: End -> HELP
  (code == 7'h4e)?7'h67:   // 4e: PageDown -> Right-Amiga
  
  // cursor keys
  (code == 7'h4f)?7'h4e:   // 4f: right
  (code == 7'h50)?7'h4f:   // 50: left
  (code == 7'h51)?7'h4d:   // 51: down
  (code == 7'h52)?7'h4c:   // 52: up
  
                           // 53: Num Lock

  // keypad
  (code == 7'h54)?7'h5c:   // 54: KP /
  (code == 7'h55)?7'h5d:   // 55: KP *
  (code == 7'h56)?7'h4a:   // 56: KP -
  (code == 7'h57)?7'h5e:   // 57: KP +
  (code == 7'h58)?7'h43:   // 58: KP Enter
  (code == 7'h59)?7'h1d:   // 59: KP 1
  (code == 7'h5a)?7'h1e:   // 5a: KP 2
  (code == 7'h5b)?7'h1f:   // 5b: KP 3
  (code == 7'h5c)?7'h2d:   // 5c: KP 4
  (code == 7'h5d)?7'h2e:   // 5d: KP 5
  (code == 7'h5e)?7'h2f:   // 5e: KP 6
  (code == 7'h5f)?7'h3d:   // 5f: KP 7
  (code == 7'h60)?7'h3e:   // 60: KP 8
  (code == 7'h61)?7'h3f:   // 61: KP 9
  (code == 7'h62)?7'h0f:   // 62: KP 0
  (code == 7'h63)?7'h3c:   // 63: KP .
  (code == 7'h64)?7'h2b:   // 64: EUR-2

  // remapped modifier keys
  (code == 7'h68)?7'h63:   // left ctrl
  (code == 7'h69)?7'h60:   // left shift
  (code == 7'h6a)?7'h64:   // left alt
  (code == 7'h6b)?7'h66:   // left meta
                           // right ctrl
  (code == 7'h6d)?7'h61:   // right shift
  (code == 7'h6e)?7'h65:   // right alt
  (code == 7'h6f)?7'h67:   // right meta

  7'h7f;   

endmodule
  
