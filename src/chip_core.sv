// SPDX-FileCopyrightText: © 2025 XXX Authors
// SPDX-License-Identifier: Apache-2.0

`default_nettype none

module chip_core #(
    parameter NUM_INPUT_PADS,
    parameter NUM_BIDIR_PADS,
    parameter NUM_ANALOG_PADS
)(
    `ifdef USE_POWER_PINS
    inout wire VDD,
    inout wire VSS,
    `endif

    input wire clk,
    input wire rst_n,

    input  wire [NUM_INPUT_PADS-1:0] input_in,
    output wire [NUM_INPUT_PADS-1:0] input_pu,
    output wire [NUM_INPUT_PADS-1:0] input_pd,

    input  wire [NUM_BIDIR_PADS-1:0] bidir_in,
    output wire [NUM_BIDIR_PADS-1:0] bidir_out,
    output wire [NUM_BIDIR_PADS-1:0] bidir_oe,
    output wire [NUM_BIDIR_PADS-1:0] bidir_cs,
    output wire [NUM_BIDIR_PADS-1:0] bidir_sl,
    output wire [NUM_BIDIR_PADS-1:0] bidir_ie,
    output wire [NUM_BIDIR_PADS-1:0] bidir_pu,
    output wire [NUM_BIDIR_PADS-1:0] bidir_pd,

    inout wire [NUM_ANALOG_PADS-1:0] analog
);

    // Disable pull-up and pull-down for inputs.
    assign input_pu = '0;
    assign input_pd = '0;

    // Configure bidirectional pads as outputs.
    assign bidir_oe = '1;
    assign bidir_cs = '0;
    assign bidir_sl = '0;
    assign bidir_ie = ~bidir_oe;
    assign bidir_pu = '0;
    assign bidir_pd = '0;

    logic _unused;
    assign _unused = &bidir_in;

    logic [NUM_BIDIR_PADS-1:0] count;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            count <= '0;
        end else if (&input_in) begin
            count <= count + 1'b1;
        end
    end

    assign bidir_out = count;

    wire pixel_read;

    (* keep *)
    ip_pixel_column_w u_pixel_c1 (
    );

    (* keep *)
    ip_pixel_column_w u_pixel_c2 (
    );

    (* keep *)
    ip_pixel_column_w u_pixel_c3 (
    );

    (* keep *)
    ip_pixel_column_w u_pixel_c4 (
    );

    (* keep *)
    ip_pixel_column_w u_pixel_c5 (
    );

    (* keep *)
    ip_pixel_column_w u_pixel_c6 (
    );

    (* keep *)
    ip_pixel_column_w u_pixel_c7 (
    );

    (* keep *)
    ip_pixel_column_w u_pixel_c8 (
    );

    wire [31:0]  col_pix_rst;
    wire [159:0] row_sel;
    wire [31:0]  col_sel;

    (* keep *)
    cis_ctrl ctrl (
        .clk_i     (clk),
        .pix_rst_i (input_in[0]),
        .cnt_rst_i (input_in[1]),
        .row_adv_i (input_in[2]),
        .col_adv_i (input_in[3]),
        .pix_rst_o (col_pix_rst),
        .row_sel_o (row_sel),
        .col_sel_o (col_sel)
    );



endmodule

`default_nettype wire