//RCC only sim.

//`timescale 1ms/1us
`timescale 1ns / 1ps

module RCC (
    output wire Ext_Clk
    //output wire RESETn  //wait Reset Gen
);
  reg rExt_Clk;
  //reg rRESETn;

  assign Ext_Clk = rExt_Clk;
  //assign RESETn = rRESETn;

  initial begin : u_rExt_Clk
    rExt_Clk <= 1'd0;
    forever begin 
      #18.5185  // from freq of clk tang 9k : 27 Mhz ( 1/27 MHz)  
      rExt_Clk <= ~rExt_Clk;
    end
    //$stop;
  end
  
endmodule
