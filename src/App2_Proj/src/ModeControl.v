//----------------------------------------//
// Filename     : ModeControl.v
// Description  : Sync Data Mode and Write signal
// Company      : KMITL
// Project      : Impedance Analyzer
//----------------------------------------//
// Version      : 1.0
// Date         : 6 March 2026
// Author       : Adisorn Sommart
// Remark       : New Creation
//----------------------------------------//
module ModeControl (
    input  wire       CLK48M,
    input  wire       FgRESETn,
    input  wire [3:0] ESPMode,
    input  wire       Write,

    output wire [3:0] ModeOut
);
//----------------------------------------//
// Signal Declaration
//----------------------------------------//
  reg [3:0] rMode;
  reg       rWrite_sync1;
  reg       rWrite_sync2;
//----------------------------------------//
// Output Declaration
//----------------------------------------//
  assign ModeOut = rMode;
//----------------------------------------//
// Process Declaration
//----------------------------------------//
  always @(posedge CLK48M or negedge FgRESETn) begin
    if (!FgRESETn) begin
      rWrite_sync1 <= 1'b0;
      rWrite_sync2 <= 1'b0;
      rMode        <= 4'd0;  
    end else begin
      rWrite_sync1 <= Write;
      rWrite_sync2 <= rWrite_sync1;

      if (rWrite_sync1 && !rWrite_sync2) begin
        rMode <= ESPMode;
      end
    end
  end


endmodule
