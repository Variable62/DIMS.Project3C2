module Testbench ();
    wire    [3:0]DataMode;
    wire    Ext_RESETn;
    wire    Ext_Clk;
    wire    Dac_Clk;
    wire    Ack;
    wire    Req;
    wire    [3:0]DataOut;
    wire    [11:0] DDS_Out;

  RCC m_rcc (.Ext_Clk(Ext_Clk));

  Signal_Gen m_signal_gen (
        .Ext_Clk(Ext_Clk),
        .Ext_RESETn(Ext_RESETn),
        .Write(Write),
        .DataMode(DataMode),
        .Ack(Ack),
        .Req(Req)
  );

  ImzTop m_ImzTop (
        .Ext_Clk      (Ext_Clk),
        .Ext_RESETn   (Ext_RESETn),
        .Write          (Write),
        .Ack            (Ack),
        .Req            (Req),
        .DataMode       (DataMode),
        .Dac_Clk      (Dac_Clk),
        .DDS_Out      (DDS_Out)
  );

endmodule
