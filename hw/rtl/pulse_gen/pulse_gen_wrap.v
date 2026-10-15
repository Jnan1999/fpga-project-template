//==============================================================================
// pulse_gen_wrap.v —— 模块对外统一入口（顶层只例化本模块）
//
// 这是替代“在 top 里手改例化模块名”的标准做法：
//   - top 永远只例化 pulse_gen_wrap，功能端口、连接、例化名【永不改动】；
//   - 发布/调试切换只需改一个参数 ENABLE_DFT（顶层 localparam 或综合命令传参）；
//   - ENABLE_DFT=1：内部例化 pulse_gen_dft（核心 + 可测性）；
//   - ENABLE_DFT=0：内部例化 pulse_gen（纯核心），调试输入悬空、调试输出固定为 0，
//     所有 DFT 逻辑被 generate 整体裁断，零逻辑开销。
//
// 功能端口与 pulse_gen / pulse_gen_dft 完全一致；编译期即可保证三者匹配。
//==============================================================================
module pulse_gen_wrap #(
    parameter integer CNT_W = 32,
    parameter [0:0]   ENABLE_DFT = 0   // 0=发布版（纯核心）  1=调试版（带 DFT）
)(
    //---------------- 功能端口（与 pulse_gen 完全一致）----------------
    input  wire             clk,
    input  wire             rst_n,
    input  wire             cfg_en,
    input  wire [CNT_W-1:0] cfg_period,
    output wire             pulse_out,
    output wire             busy,
    //---------------- 调试总线（=0 时由内部自动 tie off，top 可常连）----------------
    input  wire             dbg_force_pulse,
    input  wire             dbg_block_en,
    output wire [31:0]      dbg_pulse_cnt,
    output wire [31:0]      dbg_cycle_cnt
);

    generate
        if (ENABLE_DFT == 1'b1) begin : g_dft
            // 调试版：核心 + 可测性包装
            pulse_gen_dft #(
                .CNT_W     (CNT_W),
                .ENABLE_DFT(1'b1)
            ) u_impl (
                .clk             (clk),
                .rst_n           (rst_n),
                .cfg_en          (cfg_en),
                .cfg_period      (cfg_period),
                .pulse_out       (pulse_out),
                .busy            (busy),
                .dbg_force_pulse (dbg_force_pulse),
                .dbg_block_en    (dbg_block_en),
                .dbg_pulse_cnt   (dbg_pulse_cnt),
                .dbg_cycle_cnt   (dbg_cycle_cnt)
            );
        end else begin : g_release
            // 发布版：纯核心；调试输入为 input 悬空无害，调试输出固定为 0
            pulse_gen #(
                .CNT_W(CNT_W)
            ) u_impl (
                .clk        (clk),
                .rst_n      (rst_n),
                .cfg_en     (cfg_en),
                .cfg_period (cfg_period),
                .pulse_out  (pulse_out),
                .busy       (busy)
            );

            assign dbg_pulse_cnt = 32'd0;
            assign dbg_cycle_cnt = 32'd0;
        end
    endgenerate

endmodule
