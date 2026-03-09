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
  wire        wVs_rise = (rVs_sync[2:1] == 2'b01);
  wire        wVd_rise = (rVd_sync[2:1] == 2'b01);

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

      // Found Vs ==> (Auto-Reset)
      if (wVs_rise) begin
        rCounter  <= 19'd0;
        rCounting <= 1'b1;
      end 
            
            // Stop when found VdiffPulse
      else if (wVd_rise && rCounting) begin
        rCounting  <= 1'b0;
        CountPhase <= rCounter; 
        Done       <= 1'b1;  
      end
            
            // 3 Protect Timeout
      else if (rCounter == 19'h7FFFF) begin
        rCounting <= 1'b0;
      end

      else if (rCounting) begin
        rCounter <= rCounter + 1;
      end
    end
  end
endmodule
