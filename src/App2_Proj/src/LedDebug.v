//----------------------------------------//
// Filename     : LED_Debug.v
// Description  : Rotary Encoder Module for DDSFG
// Company      : KMITL
// Project      : DDSFG
//----------------------------------------//
// Version      : 00.01
// Date         : 04.08.2025
// Author       : Adisorn Sommart
// Remark       :   
//----------------------------------------//
module LED_Debug (
    input wire CLK48M, 
    input wire ExtRESETn,  
    input wire [3:0] Mode,  
    output wire [1:0] LedMode
);
  //----------------------------------------//
  // Signal Declaration
  //----------------------------------------//
  reg [1:0] rLedMode; 

  //----------------------------------------//
  // Output Assignments
  //----------------------------------------//
  assign LedMode = rLedMode;

  always @(posedge CLK48M or negedge ExtRESETn) begin
    if (!ExtRESETn) begin
      rLedMode <= 4'd0;  // Reset Mode display to 0
    end else begin
      rLedMode <= Mode;  // Update registered Mode with input
    end
  end
endmodule