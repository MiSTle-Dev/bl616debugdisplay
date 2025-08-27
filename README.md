# Tang onboard BL616 Debug Console Display

This special Core is intended exclusively for the [FPGA-Companion](https://github.com/MiSTle-Dev/FPGA-Companion) firmware running on the Tang **onboard** BL616 µC use case.

It's a tool to display the debug console running at 2M Baud on a HDMI Monitor like a [VT52 Terminal](https://en.wikipedia.org/wiki/VT52) and communicate via Shell.  
It might be useful to debug USB Hub or USB HID detect / compatibility issues.  

By the way, you could also connect RX / TX pin of a USB-UART adapter + Putty or mincom to get identical results if you have one. This project is intended for users who don't have such USB-UART adapter at hand.  

**Prerequiste**  
You need to have [FPGA-Companion](https://github.com/MiSTle-Dev/FPGA-Companion/releases) for onboard BL616 µC installed on you Tang board.

Program the FPGA debug core that fit's to your Tang: bl616monitor_**xyz**.fs

Just connect the Tang board via a power feedthrough USB Hub (or TN20k bare +5V / GND) and have **no** other USB devices connected !

You will get a green color VT52 Terminal on your Monitor with some FPGA-Companion debug messages.  

Connect a USB HID device like a Keyboard, Mouse, Joystick etc.  
Each device shall generate a register message and show USB VID:PID etc.  
You might need your mobile camera video function as messages arrive at tremendous speed and there is no scroll back.

A Joystick or Gamepad button/stick press will generate debug messages.  
Keyboard / Mouse will not show any press/move message apart from initial registering.

Note:  
You can enter with you keyboard commands like ``help`` or ``lsusb``  

Press Tang Button S2 to observe µC at boot time.  


![bl616](\.assets/bl616_debug.png) 

# Credits
Uses sources from [VT52](https://github.com/AndresNavarro82/vt52-fpga)

