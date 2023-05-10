# tron_on_vga
An implementation of the popular Tron arcade game on the Altera DE2-115 FPGA and displayed onto a VGA monitor.
## Overview
Tron: Light Cycles is a game with 2 players as light cycles. The players draw a trail behind themselves as they travel across the screen. When one player runs into a trail or into a wall, the game is over. The two players will be controlled using NES (Nintendo Entertainment System) controllers and the output will be displayed on a 640x480 VGA monitor. Game logic and mechanics are coded in SystemVerilog; Intel Quartus is used to simulate and synthesize the code.
## Software
- [Intel Quartus Prime](https://www.intel.com/content/www/us/en/products/details/fpga/development-tools/quartus-prime.html)
- [Visual Studio Code](https://code.visualstudio.com/)
## Hardware
- [Altera DE2-115 Development and Education Board](https://www.terasic.com.tw/cgi-bin/page/archive.pl?Language=English&CategoryNo=139&No=502&PartNo=2)
- [NES (Nintendo Entertainment System) Controllers](https://www.nintendo.com/store/products/nintendo-entertainment-system-controllers/)
- Any 640x480 VGA display
