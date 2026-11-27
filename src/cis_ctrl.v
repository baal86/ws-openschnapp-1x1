// CMOS image sensor scan controller: 32 columns x 160 rows
// Target: GF180MCU, gf180mcu_fd_sc_mcu7t5v0, LibreLane
//
// pix_rst_i : ASYNCHRONOUS pixel reset, combinational buffer tree to pix_rst_o
// pix_rst_o : one buffered copy per column, same polarity as pix_rst_i
// cnt_rst_i : synchronous, active high. Row/column -> 0. Does NOT touch pix_rst_o
// row_adv_i : synchronous. +1 row per rising clk_i edge while high, 159 -> 0
// col_adv_i : synchronous. +1 column per rising clk_i edge while high, 31 -> 0
// row_sel_o : registered one-hot row select
// col_sel_o : registered one-hot column select
//
// All synchronous inputs must meet setup/hold to clk_i (no synchronizers here).
// State is undefined after power-up: assert cnt_rst_i for >= 1 clock.

`default_nettype none

module cis_ctrl (
    input  wire         clk_i,
    input  wire         pix_rst_i,
    input  wire         cnt_rst_i,
    input  wire         row_adv_i,
    input  wire         col_adv_i,
    output wire [31:0]  pix_rst_o,
    output wire [159:0] row_sel_o,
    output wire [31:0]  col_sel_o
);
    localparam integer N_ROWS = 160;
    localparam integer N_COLS = 32;
    localparam [7:0] LAST_ROW = 8'd159;
    localparam [4:0] LAST_COL = 5'd31;

    // ------------------------------------------------------------ counters
    reg [7:0] row_q;
    reg [4:0] col_q;

    wire [7:0] row_next = cnt_rst_i             ? 8'd0 :
                          !row_adv_i            ? row_q :
                          (row_q >= LAST_ROW)   ? 8'd0 : row_q + 8'd1;

    wire [4:0] col_next = cnt_rst_i             ? 5'd0 :
                          !col_adv_i            ? col_q :
                          (col_q >= LAST_COL)   ? 5'd0 : col_q + 5'd1;

    always @(posedge clk_i) begin
        row_q <= row_next;
        col_q <= col_next;
    end

    // ------------------------------------------- registered one-hot decode
    // Decoding the NEXT count into flip-flops gives glitch-free selects with
    // no extra cycle of latency relative to the counters.
    reg [N_ROWS-1:0] row_sel_q;
    reg [N_COLS-1:0] col_sel_q;
    integer r, c;

    always @(posedge clk_i) begin
        for (r = 0; r < N_ROWS; r = r + 1)
            row_sel_q[r] <= (row_next == r[7:0]);
        for (c = 0; c < N_COLS; c = c + 1)
            col_sel_q[c] <= (col_next == c[4:0]);
    end

    // ------------------------------------------------------ output drivers
    // Pixel reset tree: input -> 1 root -> 4 branches -> 8 columns each.
    // Fanout stays below 10 and every column has the same number of stages.
    localparam integer PIX_GRP = 8;
    wire                      pix_rst_root;
    wire [N_COLS/PIX_GRP-1:0] pix_rst_branch;

    cis_outbuf u_pix_root (.a(pix_rst_i), .y(pix_rst_root));

    genvar i;
    generate
        for (i = 0; i < N_COLS/PIX_GRP; i = i + 1) begin : g_pix_branch
            cis_outbuf u_buf (.a(pix_rst_root), .y(pix_rst_branch[i]));
        end
        for (i = 0; i < N_COLS; i = i + 1) begin : g_pix
            cis_outbuf u_buf (.a(pix_rst_branch[i/PIX_GRP]), .y(pix_rst_o[i]));
        end
        for (i = 0; i < N_ROWS; i = i + 1) begin : g_row
            cis_outbuf u_buf (.a(row_sel_q[i]), .y(row_sel_o[i]));
        end
        for (i = 0; i < N_COLS; i = i + 1) begin : g_col
            cis_outbuf u_buf (.a(col_sel_q[i]), .y(col_sel_o[i]));
        end
    endgenerate
endmodule

// Two-stage tapered driver, non-inverting: buf_4 -> buf_20 (largest buffer).
// Input load 9.3 fF; buf_20 max load 4.75 pF (tt, 25 C, 5 V Liberty).
module cis_outbuf (
    input  wire a,
    output wire y
);
    (* keep *) wire obuf_mid;

    /* verilator lint_off PINMISSING */
    (* keep *) gf180mcu_fd_sc_mcu7t5v0__buf_4  u_obuf_pre (.I(a),        .Z(obuf_mid));
    (* keep *) gf180mcu_fd_sc_mcu7t5v0__buf_20 u_obuf_drv (.I(obuf_mid), .Z(y));
    /* verilator lint_on PINMISSING */
endmodule

`default_nettype wire