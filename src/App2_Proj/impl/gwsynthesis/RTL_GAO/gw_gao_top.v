module gw_gao(
    \ESPMode[3] ,
    \ESPMode[2] ,
    \ESPMode[1] ,
    \ESPMode[0] ,
    \wWidthVal[18] ,
    \wWidthVal[17] ,
    \wWidthVal[16] ,
    \wWidthVal[15] ,
    \wWidthVal[14] ,
    \wWidthVal[13] ,
    \wWidthVal[12] ,
    \wWidthVal[11] ,
    \wWidthVal[10] ,
    \wWidthVal[9] ,
    \wWidthVal[8] ,
    \wWidthVal[7] ,
    \wWidthVal[6] ,
    \wWidthVal[5] ,
    \wWidthVal[4] ,
    \wWidthVal[3] ,
    \wWidthVal[2] ,
    \wWidthVal[1] ,
    \wWidthVal[0] ,
    \wPhaseVal[18] ,
    \wPhaseVal[17] ,
    \wPhaseVal[16] ,
    \wPhaseVal[15] ,
    \wPhaseVal[14] ,
    \wPhaseVal[13] ,
    \wPhaseVal[12] ,
    \wPhaseVal[11] ,
    \wPhaseVal[10] ,
    \wPhaseVal[9] ,
    \wPhaseVal[8] ,
    \wPhaseVal[7] ,
    \wPhaseVal[6] ,
    \wPhaseVal[5] ,
    \wPhaseVal[4] ,
    \wPhaseVal[3] ,
    \wPhaseVal[2] ,
    \wPhaseVal[1] ,
    \wPhaseVal[0] ,
    wPll_Clk,
    tms_pad_i,
    tck_pad_i,
    tdi_pad_i,
    tdo_pad_o
);

input \ESPMode[3] ;
input \ESPMode[2] ;
input \ESPMode[1] ;
input \ESPMode[0] ;
input \wWidthVal[18] ;
input \wWidthVal[17] ;
input \wWidthVal[16] ;
input \wWidthVal[15] ;
input \wWidthVal[14] ;
input \wWidthVal[13] ;
input \wWidthVal[12] ;
input \wWidthVal[11] ;
input \wWidthVal[10] ;
input \wWidthVal[9] ;
input \wWidthVal[8] ;
input \wWidthVal[7] ;
input \wWidthVal[6] ;
input \wWidthVal[5] ;
input \wWidthVal[4] ;
input \wWidthVal[3] ;
input \wWidthVal[2] ;
input \wWidthVal[1] ;
input \wWidthVal[0] ;
input \wPhaseVal[18] ;
input \wPhaseVal[17] ;
input \wPhaseVal[16] ;
input \wPhaseVal[15] ;
input \wPhaseVal[14] ;
input \wPhaseVal[13] ;
input \wPhaseVal[12] ;
input \wPhaseVal[11] ;
input \wPhaseVal[10] ;
input \wPhaseVal[9] ;
input \wPhaseVal[8] ;
input \wPhaseVal[7] ;
input \wPhaseVal[6] ;
input \wPhaseVal[5] ;
input \wPhaseVal[4] ;
input \wPhaseVal[3] ;
input \wPhaseVal[2] ;
input \wPhaseVal[1] ;
input \wPhaseVal[0] ;
input wPll_Clk;
input tms_pad_i;
input tck_pad_i;
input tdi_pad_i;
output tdo_pad_o;

wire \ESPMode[3] ;
wire \ESPMode[2] ;
wire \ESPMode[1] ;
wire \ESPMode[0] ;
wire \wWidthVal[18] ;
wire \wWidthVal[17] ;
wire \wWidthVal[16] ;
wire \wWidthVal[15] ;
wire \wWidthVal[14] ;
wire \wWidthVal[13] ;
wire \wWidthVal[12] ;
wire \wWidthVal[11] ;
wire \wWidthVal[10] ;
wire \wWidthVal[9] ;
wire \wWidthVal[8] ;
wire \wWidthVal[7] ;
wire \wWidthVal[6] ;
wire \wWidthVal[5] ;
wire \wWidthVal[4] ;
wire \wWidthVal[3] ;
wire \wWidthVal[2] ;
wire \wWidthVal[1] ;
wire \wWidthVal[0] ;
wire \wPhaseVal[18] ;
wire \wPhaseVal[17] ;
wire \wPhaseVal[16] ;
wire \wPhaseVal[15] ;
wire \wPhaseVal[14] ;
wire \wPhaseVal[13] ;
wire \wPhaseVal[12] ;
wire \wPhaseVal[11] ;
wire \wPhaseVal[10] ;
wire \wPhaseVal[9] ;
wire \wPhaseVal[8] ;
wire \wPhaseVal[7] ;
wire \wPhaseVal[6] ;
wire \wPhaseVal[5] ;
wire \wPhaseVal[4] ;
wire \wPhaseVal[3] ;
wire \wPhaseVal[2] ;
wire \wPhaseVal[1] ;
wire \wPhaseVal[0] ;
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
    .data_i({\ESPMode[3] ,\ESPMode[2] ,\ESPMode[1] ,\ESPMode[0] ,\wWidthVal[18] ,\wWidthVal[17] ,\wWidthVal[16] ,\wWidthVal[15] ,\wWidthVal[14] ,\wWidthVal[13] ,\wWidthVal[12] ,\wWidthVal[11] ,\wWidthVal[10] ,\wWidthVal[9] ,\wWidthVal[8] ,\wWidthVal[7] ,\wWidthVal[6] ,\wWidthVal[5] ,\wWidthVal[4] ,\wWidthVal[3] ,\wWidthVal[2] ,\wWidthVal[1] ,\wWidthVal[0] ,\wPhaseVal[18] ,\wPhaseVal[17] ,\wPhaseVal[16] ,\wPhaseVal[15] ,\wPhaseVal[14] ,\wPhaseVal[13] ,\wPhaseVal[12] ,\wPhaseVal[11] ,\wPhaseVal[10] ,\wPhaseVal[9] ,\wPhaseVal[8] ,\wPhaseVal[7] ,\wPhaseVal[6] ,\wPhaseVal[5] ,\wPhaseVal[4] ,\wPhaseVal[3] ,\wPhaseVal[2] ,\wPhaseVal[1] ,\wPhaseVal[0] }),
    .clk_i(wPll_Clk)
);

endmodule
