module ModeControl (
    input  wire       CLK48M,
    input  wire       FgRESETn,
    input  wire [3:0] ESPMode,
    input  wire       Write,
    output wire [3:0] ModeOut
);

    reg [3:0] rMode;
    reg       rWrite_sync1;
    reg       rWrite_sync2;

    assign ModeOut = rMode;

    // Synchronize Edge Detection
    always @(posedge CLK48M or negedge FgRESETn) begin
        if (!FgRESETn) begin
            rWrite_sync1 <= 1'b0;
            rWrite_sync2 <= 1'b0;
            rMode        <= 4'd0; // Default mode (เช่น 100Hz)
        end else begin
            rWrite_sync1 <= Write;
            rWrite_sync2 <= rWrite_sync1;

            // เมื่อเจอขอบขาขึ้นของ Write ให้บันทึกค่า Mode เข้าไป
            if (rWrite_sync1 && !rWrite_sync2) begin
                rMode <= ESPMode;
            end
        end
    end


endmodule