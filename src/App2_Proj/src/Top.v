//----------------------------------------//
// Filename     : data_sender.v
// Description  : Send Data To ESP32
// Company      : KMITL
// Project      : Impedance Analyzer
//----------------------------------------//
// Version      : 1.0
// Date         : 6 March 2026
// Author       : Adisorn Sommart
// Remark       : New Creation
//----------------------------------------//
module top(
    input   wire    CLK27,
    input   wire    ExtRESETn,

    input   wire    [3:0] ESPMode,
    input   wire    Write,
    input   wire    VdiffPulse,
    input   wire    VsPulse,
    input   wire    ACK,

    output  wire    Req,
    output  wire    [3:0] CountOut, // To ESP
    output  wire    [2:0] LedMode
);
    //--- Internal Signals ---
    wire        wPll_RESETn;
    wire        wPll_Clk;
    wire        wPll_Lock;
    wire        wFg_RESETn;   
    wire        [3:0] wMode;
    
    wire [18:0] wPhaseVal;
    wire        wPhaseDone;
    wire [18:0] wWidthVal;
    wire        wWidthDone;

    reg  [18:0] rFinalCount;
    reg         rFinalDone;

    always @(*) begin
        if (wMode == 4'd5) begin
            rFinalCount = wWidthVal; 
            rFinalDone  = wWidthDone;
        end else begin
            rFinalCount = wPhaseVal;  
            rFinalDone  = wPhaseDone;
        end
    end

    pll_module u_pll_module(
        .clkin(CLK27),
        .reset(~wPll_RESETn),
        .lock(wPll_Lock),
        .clkout(wPll_Clk)
    );

    ResetGen_Module u_ResetGen_Module(
        .CLK(CLK27),
        .ExtRESETn(ExtRESETn),
        .PllLocked(wPll_Lock),
        .PllRESETn(wPll_RESETn),
        .FgRESETn(wFg_RESETn)
    );

    ModeControl u_ModeControl (
        .CLK48M(wPll_Clk),
        .FgRESETn(wFg_RESETn),
        .ESPMode(ESPMode),
        .Write(Write),
        .ModeOut(wMode)
    );
    
    phase_counter u_phase_counter (
        .CLK48MHz(wPll_Clk),
        .RESETn(wFg_RESETn),
        .Mode(wMode),
        .VdiffPulse(VdiffPulse),
        .VsPulse(VsPulse),
        .Done(wPhaseDone),
        .CountPhase(wPhaseVal)
    );

    pulse_width_counter u_pulse_width_counter (
        .CLK48MHz(wPll_Clk),
        .RESETn(wFg_RESETn),
        .Mode(wMode),
        .VdiffPulse(VdiffPulse),
        .Done(wWidthDone),
        .CountWidth(wWidthVal)
    );

    data_sender u_data_sender(
        .CLK48MHz(wPll_Clk),
        .RESETn(wFg_RESETn),
        .start(rFinalDone),       
        .FinalCount(rFinalCount),   
        .ACK(ACK),
        .Req(Req),
        .CountOut(CountOut) 
    );

    LED_Debug u_LED_Debug(
        .CLK48M(wPll_Clk),
        .ExtRESETn(wFg_RESETn),
        .Mode(wMode),
        .LedMode(LedMode)
    );

endmodule