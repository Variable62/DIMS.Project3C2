//----------------------------------------//
// Filename     : phase_counter.v
// Description  : Read Count Phase
// Company      : KMITL
// Project      : Impedance Analyzer
//----------------------------------------//
// Version      : 1.0
// Date         : 6 March 2026
// Author       : Adisorn Sommart
// Remark       : New Creation
//----------------------------------------//
module phase_counter (
    input  wire        CLK48MHz,
    input  wire        RESETn,
    input  wire [ 3:0] Mode,
    input  wire        VdiffPulse,
    input  wire        VsPulse,
    
    output reg         Done,
    output reg  [18:0] CountPhase
);
  //----------------------------------------//
  // Signal Declaration
  //----------------------------------------//
  reg  [ 2:0] rVs_sync;
  reg  [ 2:0] rVd_sync;
  reg  [18:0] rCounter;
  reg         rCounting;
 wire wVs_fall = (rVs_sync[2:1] == 2'b10); 
  wire wVd_fall = (rVd_sync[2:1] == 2'b10);

  always @(posedge CLK48MHz) begin
    rVs_sync <= {rVs_sync[1:0], VsPulse};
    rVd_sync <= {rVd_sync[1:0], VdiffPulse};
  end
//----------------------------------------//
// Process Declaration
//----------------------------------------//
 always @(posedge CLK48MHz or negedge RESETn) begin
    if (!RESETn) begin
      rCounter   <= 19'd0;
      rCounting  <= 1'b0;
      Done       <= 1'b0;
      CountPhase <= 19'd0;
    end else begin
      Done <= 1'b0;  

      if (wVs_fall) begin
        rCounter   <= 19'd0;
        rCounting  <= 1'b1;
      end 

      else if (wVd_fall && rCounting) begin
        rCounting  <= 1'b0;
        CountPhase <= rCounter; 
        Done       <= 1'b1;  
      end

      else if (rCounting) begin
        if (rCounter < 19'h7FFFF) 
            rCounter <= rCounter + 1;
        else
            rCounting <= 1'b0;
      end
    end
  end
  endmodule