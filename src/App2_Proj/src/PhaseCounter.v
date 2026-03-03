module phase_counter (
    input  wire        CLK48MHz,
    input  wire        RESETn,
    input  wire [3:0]  Mode,         // รับจาก Top Module (ESP32 Mode)
    input  wire        VdiffPulse,   // สัญญาณ Vdiff จาก Analog
    input  wire        VsPulse,      // สัญญาณ Vs จาก Analog
    output reg         Done,         // ส่งไปปลุก data_sender ให้เริ่มส่ง
    output reg  [18:0] CountPhase    // ค่าที่นับได้ (19-bit)
);

    // --- ส่วนการ Sync สัญญาณเพื่อกัน Noise (Double Flip-Flop) ---
    reg [2:0] rVs_sync;
    reg [2:0] rVd_sync;
    
    always @(posedge CLK48MHz) begin
        rVs_sync <= {rVs_sync[1:0], VsPulse};
        rVd_sync <= {rVd_sync[1:0], VdiffPulse};
    end

    // ตรวจจับขอบขาขึ้น (Rising Edge Detection)
    wire wVs_rise = (rVs_sync[2:1] == 2'b01);
    wire wVd_rise = (rVd_sync[2:1] == 2'b01);

    // --- ส่วนการนับค่า (Core Logic) ---
    reg [18:0] rCounter;
    reg        rCounting;

    always @(posedge CLK48MHz or negedge RESETn) begin
        if (!RESETn) begin
            rCounter   <= 19'd0;
            rCounting  <= 1'b0;
            Done       <= 1'b0;
            CountPhase <= 19'd0;
        end else begin
            Done <= 1'b0; // เคลียร์ Done ทุก Clock Cycle

            // 1. เจอขอบ Vs: เริ่มนับใหม่เสมอ (Auto-Reset)
            if (wVs_rise) begin
                rCounter  <= 19'd0;
                rCounting <= 1'b1;
            end 
            
            // 2. เจอขอบ Vdiff: หยุดนับและส่งข้อมูลออก
            else if (wVd_rise && rCounting) begin
                rCounting  <= 1'b0;
                CountPhase <= rCounter; // ล็อคค่าที่นับได้
                Done       <= 1'b1;     // ปลุก data_sender
            end
            
            // 3. ป้องกันการนับค้าง (Timeout) ถ้าไม่มีสัญญาณหยุด
            else if (rCounter == 19'h7FFFF) begin
                rCounting <= 1'b0;
            end
            
            // 4. กำลังนับ: เพิ่มค่าไปเรื่อยๆ ตามความถี่ 48MHz
            else if (rCounting) begin
                rCounter <= rCounter + 1;
            end
        end
    end
endmodule