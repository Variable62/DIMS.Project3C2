`timescale 1ns / 1ps

module Signal_Gen (
    input   wire Ext_Clk,
    output  reg  Ext_RESETn,
    output  reg  Write,
    output  reg  [3:0]DataMode,
    output  reg   Ack,
    output  reg   Req
);

initial begin
    // Initial values
    Ext_RESETn = 1;
    Write      = 0;
    DataMode   = 0;

    // Reset sequence
    #2400;
    Ext_RESETn = 0;
    #5;
    Ext_RESETn = 1;
    #2400;
     wait(m_ImzTop.m_ModeControl.Ready == 1);

    // Wait clock edge properly
    @(posedge Ext_Clk);
    DataMode <= 4'b0000;

    @(posedge Ext_Clk);
    Write <= 1;

    repeat (10000) @(posedge Ext_Clk);

    Write <= 0;
    repeat (1000) @(posedge Ext_Clk);

    @(posedge Ext_Clk);
    DataMode <= 4'b0001;

    @(posedge Ext_Clk);
    Write <= 1;

    repeat (10000) @(posedge Ext_Clk);

    Write <= 0;
    repeat (1000) @(posedge Ext_Clk);


    @(posedge Ext_Clk);
    DataMode <= 4'b0010;

    @(posedge Ext_Clk);
    Write <= 1;

    repeat (10000) @(posedge Ext_Clk);

    Write <= 0;
    repeat (1000) @(posedge Ext_Clk);

    @(posedge Ext_Clk);
    DataMode <= 4'b0011;

    @(posedge Ext_Clk);
    Write <= 1;

    repeat (400) @(posedge Ext_Clk);

    Write <= 0;
    $stop;
end
        
endmodule