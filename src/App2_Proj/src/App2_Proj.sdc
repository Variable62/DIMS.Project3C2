//Copyright (C)2014-2026 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//Tool Version: V1.9.11.02 (64-bit) 
//Created Time: 2026-03-03 09:19:01
create_clock -name CLK27M -period 37.037 -waveform {0 18.518} [get_ports {CLK27}]
create_generated_clock -name CLK48M -source [get_ports {CLK27}] -master_clock CLK27M -divide_by 9 -multiply_by 16 [get_nets {wPll_Clk}]
