//----------------------------------------//
// Filename     : phase_counter.v
// Description  : High-precision Phase Counter (48MHz)
// Project      : ImpedanceAnalyzer (KMITL)
//----------------------------------------//

module phase_counter (
    input  wire        CLK48MHz,
    input  wire        RESETn,
    input  wire [3:0]  Mode,         // สำหรับรองรับหลายความถี่ในอนาคต
    input  wire        VdiffPulse,
    input  wire        VsPulse,
    
    output reg         Done,
    output reg  [18:0] CountPhase    // เก็บค่าจำนวน Clock ที่นับได้
);

    //----------------------------------------//
    // Signal Declaration
    //----------------------------------------//
    reg [18:0] rCounter;
    reg        rCounting;

    reg [2:0]  rVs_sync;
    reg [2:0]  rVd_sync;

    wire wVs_rise = (~rVs_sync[2] & rVs_sync[1]); 
    wire wVd_rise = (~rVd_sync[2] & rVd_sync[1]);

    always @(posedge CLK48MHz) begin
        rVs_sync <= {rVs_sync[1:0], VsPulse};
        rVd_sync <= {rVd_sync[1:0], VdiffPulse};
    end 
    //----------------------------------------//
    // Counter Control Logic
    //----------------------------------------//
    always @(posedge CLK48MHz or negedge RESETn) begin
        if (!RESETn) begin
            rCounter   <= 19'd0;
            rCounting  <= 1'b0;
            CountPhase <= 19'd0;
            Done       <= 1'b0;
        end 
        else begin
            // Default: Clear Done flag ทุกรอบ clock
            Done <= 1'b0;

            // CASE 1: เจอขอบ Vs (Start counting)
            if (wVs_rise) begin
                rCounter  <= 19'd1;     // เริ่มนับที่ 1 ทันทีในรอบที่เจอ Edge
                rCounting <= 1'b1;
            end
            
            // CASE 2: เจอขอบ Vdiff ขณะที่กำลังนับอยู่ (Stop & Store)
            else if (wVd_rise && rCounting) begin
                rCounting  <= 1'b0;
                CountPhase <= rCounter; // บันทึกค่าสะสม
                Done       <= 1'b1;     // ส่งสัญญาณบอก Module ถัดไปว่าข้อมูลพร้อมแล้ว
            end
            
            // CASE 3: กำลังนับปกติ (Accumulate)
            else if (rCounting) begin
                rCounter <= rCounter + 19'd1;
            end
        end
    end

endmodule