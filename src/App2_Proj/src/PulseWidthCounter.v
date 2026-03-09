//----------------------------------------//
// Filename     : pulse_width_counter.v
// Description  : Reasd Count Pulse Width
// Company      : KMITL
// Project      : Impedance Analyzer
//----------------------------------------//
// Version      : 1.0
// Date         : 6 March 2026
// Author       : Adisorn Sommart
// Remark       : New Creation
//----------------------------------------//
module pulse_width_counter (
    input  wire         CLK48MHz,
    input  wire         RESETn,
    input  wire [ 3:0]  Mode,
    input  wire         VdiffPulse,
    output reg          Done,
    output reg  [18:0]  CountWidth
);
  //----------------------------------------//
  // Signal Declaration
  //----------------------------------------//
  reg  [ 5:0] rVd_debounce;
  reg         rVd_clean;    
  reg  [ 2:0] rVd_sync;
  reg  [18:0] rCounter;
  reg         rCounting;
  wire wVd_rise = (rVd_sync[2:1] == 2'b01);
  wire wVd_fall = (rVd_sync[2:1] == 2'b10);
//----------------------------------------//
// Process Declaration
//----------------------------------------//
  always @(posedge CLK48MHz or negedge RESETn) begin
    if (!RESETn) begin
      rVd_debounce <= 6'd0;
      rVd_clean    <= 1'b0;
    end else begin

      if (VdiffPulse != rVd_clean) begin
        if (rVd_debounce < 6'd32) 
          rVd_debounce <= rVd_debounce + 1'b1;
        else begin
          rVd_clean    <= VdiffPulse;
          rVd_debounce <= 6'd0;
        end
      end else begin
        rVd_debounce <= 6'd0;
      end
    end
  end

  always @(posedge CLK48MHz) begin
    rVd_sync <= {rVd_sync[1:0], rVd_clean};
  end

  //----------------------------------------//
  // Measurement Process
  //----------------------------------------//
  always @(posedge CLK48MHz or negedge RESETn) begin
    if (!RESETn) begin
      rCounter   <= 19'd0;
      rCounting  <= 1'b0;
      Done       <= 1'b0;
      CountWidth <= 19'd0;
    end else begin
      Done <= 1'b0;  

      if (wVd_rise) begin
        rCounter  <= 19'd0;
        rCounting <= 1'b1;
      end 

      else if (wVd_fall && rCounting) begin
        rCounting  <= 1'b0;
        CountWidth <= rCounter; 
        Done       <= 1'b1;  
      end

      else if (rCounter == 19'h7FFFF) begin
        rCounting <= 1'b0;
      end

      else if (rCounting) begin
        rCounter <= rCounter + 1'b1;
      end
    end
  end
endmodule