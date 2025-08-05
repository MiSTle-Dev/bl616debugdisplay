# Tang onboard BL616 Debug Console Display

This special Core is intended exclusively for the [FPGA-Companion](https://github.com/harbaum/FPGA-Companion) firmware running on the Tang **onboard** BL616 µC use case.

It's a tool to display the debug console running at 2M Baud on a HDMI Monitor like a [VT52 Terminal](https://en.wikipedia.org/wiki/VT52).  
It might be useful to debug USB Hub or USB HID detect / compatibility issues.  
It's unidirectional only. Due to lack of HW interface signals in between FPGA and BL616 it's only possible to watch and no interaction possible.

By the way, you could also connect RX pin of a USB-UART adapter + Putty or mincom to get identical results if you have one. This project is intended for users who don't have such USB-UART adapter at hand.  

**Prerequiste**  
You need to have [FPGA-Companion](https://github.com/harbaum/FPGA-Companion/releases) for onboard BL616 µC installed on you Tang board.

Program the FPGA debug core that fit's to your Tang: bl616monitor_**xyz**.fs

Just connect the Tang board via a power feedthrough USB Hub (or TN20k bare +5V / GND) and have **no** other USB devices connected !

You will get a green color VT52 Terminal on your Monitor.  
Likely there is nothing else on the green display rather than a blinking curor.  After short time there might be also a core timeout message which is expected.  

Connect a USB HID device like a Keyboard, Mouse, Joystick etc.  
Each device shall generate a register message and show USB VID:PID etc.  
You might need your mobile camera video function as messages arrive at tremendous speed and there is no scroll back.

A Joystick or Gamepad button/stick press will generate debug messages.  
Keyboard / Mouse will not show any press/move message apart from initial registering.

Note:  
It is planned to add later on Tang button keypress functions to reboot the µc or to show more advanced USB details ``lsusb``  

At the moment we can't start to observe at boot time the µC as for that need to extend the companion firmware 


![bl616](\.assets/bl616_debug.png) 