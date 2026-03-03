 module top(
    input   wire    CLK27,
    input   wire    ExtRESETn,
    input   wire    [3:0]ESPMode,
    input   wire    Write,
    input   wire    VdiffPulse,
    input   wire    VsPulse,

    output  wire    [1:0] LedMode
);
    wire        wPll_RESETn;
    wire        wPll_Clk;
    wire        wPll_Lock;
    wire        wFg_RESETn;   
    wire        [3:0]wMode;
    wire        [18:0]wCountPhase;
    wire    wDone;

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
        .Done(wDone),
        .CountPhase(wCountPhase)
    );

    LED_Debug u_LED_Debug(
        .CLK48M(wPll_Clk),
        .ExtRESETn(wFg_RESETn),
        .Mode(wMode),
        .LedMode(LedMode)
    );
endmodule