module gw_gao(
    \wCountPhase[18] ,
    \wCountPhase[17] ,
    \wCountPhase[16] ,
    \wCountPhase[15] ,
    \wCountPhase[14] ,
    \wCountPhase[13] ,
    \wCountPhase[12] ,
    \wCountPhase[11] ,
    \wCountPhase[10] ,
    \wCountPhase[9] ,
    \wCountPhase[8] ,
    \wCountPhase[7] ,
    \wCountPhase[6] ,
    \wCountPhase[5] ,
    \wCountPhase[4] ,
    \wCountPhase[3] ,
    \wCountPhase[2] ,
    \wCountPhase[1] ,
    \wCountPhase[0] ,
    wDone,
    wPll_Clk,
    tms_pad_i,
    tck_pad_i,
    tdi_pad_i,
    tdo_pad_o
);

input \wCountPhase[18] ;
input \wCountPhase[17] ;
input \wCountPhase[16] ;
input \wCountPhase[15] ;
input \wCountPhase[14] ;
input \wCountPhase[13] ;
input \wCountPhase[12] ;
input \wCountPhase[11] ;
input \wCountPhase[10] ;
input \wCountPhase[9] ;
input \wCountPhase[8] ;
input \wCountPhase[7] ;
input \wCountPhase[6] ;
input \wCountPhase[5] ;
input \wCountPhase[4] ;
input \wCountPhase[3] ;
input \wCountPhase[2] ;
input \wCountPhase[1] ;
input \wCountPhase[0] ;
input wDone;
input wPll_Clk;
input tms_pad_i;
input tck_pad_i;
input tdi_pad_i;
output tdo_pad_o;

wire \wCountPhase[18] ;
wire \wCountPhase[17] ;
wire \wCountPhase[16] ;
wire \wCountPhase[15] ;
wire \wCountPhase[14] ;
wire \wCountPhase[13] ;
wire \wCountPhase[12] ;
wire \wCountPhase[11] ;
wire \wCountPhase[10] ;
wire \wCountPhase[9] ;
wire \wCountPhase[8] ;
wire \wCountPhase[7] ;
wire \wCountPhase[6] ;
wire \wCountPhase[5] ;
wire \wCountPhase[4] ;
wire \wCountPhase[3] ;
wire \wCountPhase[2] ;
wire \wCountPhase[1] ;
wire \wCountPhase[0] ;
wire wDone;
wire wPll_Clk;
wire tms_pad_i;
wire tck_pad_i;
wire tdi_pad_i;
wire tdo_pad_o;
wire tms_i_c;
wire tck_i_c;
wire tdi_i_c;
wire tdo_o_c;
wire [9:0] control0;
wire gao_jtag_tck;
wire gao_jtag_reset;
wire run_test_idle_er1;
wire run_test_idle_er2;
wire shift_dr_capture_dr;
wire update_dr;
wire pause_dr;
wire enable_er1;
wire enable_er2;
wire gao_jtag_tdi;
wire tdo_er1;

IBUF tms_ibuf (
    .I(tms_pad_i),
    .O(tms_i_c)
);

IBUF tck_ibuf (
    .I(tck_pad_i),
    .O(tck_i_c)
);

IBUF tdi_ibuf (
    .I(tdi_pad_i),
    .O(tdi_i_c)
);

OBUF tdo_obuf (
    .I(tdo_o_c),
    .O(tdo_pad_o)
);

GW_JTAG  u_gw_jtag(
    .tms_pad_i(tms_i_c),
    .tck_pad_i(tck_i_c),
    .tdi_pad_i(tdi_i_c),
    .tdo_pad_o(tdo_o_c),
    .tck_o(gao_jtag_tck),
    .test_logic_reset_o(gao_jtag_reset),
    .run_test_idle_er1_o(run_test_idle_er1),
    .run_test_idle_er2_o(run_test_idle_er2),
    .shift_dr_capture_dr_o(shift_dr_capture_dr),
    .update_dr_o(update_dr),
    .pause_dr_o(pause_dr),
    .enable_er1_o(enable_er1),
    .enable_er2_o(enable_er2),
    .tdi_o(gao_jtag_tdi),
    .tdo_er1_i(tdo_er1),
    .tdo_er2_i(1'b0)
);

gw_con_top  u_icon_top(
    .tck_i(gao_jtag_tck),
    .tdi_i(gao_jtag_tdi),
    .tdo_o(tdo_er1),
    .rst_i(gao_jtag_reset),
    .control0(control0[9:0]),
    .enable_i(enable_er1),
    .shift_dr_capture_dr_i(shift_dr_capture_dr),
    .update_dr_i(update_dr)
);

ao_top u_ao_top(
    .control(control0[9:0]),
    .data_i({\wCountPhase[18] ,\wCountPhase[17] ,\wCountPhase[16] ,\wCountPhase[15] ,\wCountPhase[14] ,\wCountPhase[13] ,\wCountPhase[12] ,\wCountPhase[11] ,\wCountPhase[10] ,\wCountPhase[9] ,\wCountPhase[8] ,\wCountPhase[7] ,\wCountPhase[6] ,\wCountPhase[5] ,\wCountPhase[4] ,\wCountPhase[3] ,\wCountPhase[2] ,\wCountPhase[1] ,\wCountPhase[0] ,wDone}),
    .clk_i(wPll_Clk)
);

endmodule
