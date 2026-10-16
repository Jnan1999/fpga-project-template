//==============================================================================
// top.v —— 系统顶层（只做例化与互连，不写业务逻辑）
//
// 模板示例：例化示例模块 pulse_gen_wrap。顶层永远只例化 *_wrap（铁律 3），
// 发布/调试由 ENABLE_DFT 选择（0=发布版纯核心，1=调试版带 DFT）。
// 实际项目：替换为本项目的 wrap 例化与板级引脚；调试总线可常连（ENABLE_DFT=0
// 时内部自动 tie off，零逻辑开销）。
//==============================================================================
module top #(
    parameter [0:0] ENABLE_DFT = 0   // 0=发布版  1=调试版
)(
    input  wire        clk,          // 板级时钟（引脚约束见 hw/constraints/）
    input  wire        rst_n,        // 异步复位，低有效
    input  wire        cfg_en,       // 示例：pulse_gen 使能
    input  wire [31:0] cfg_period,   // 示例：pulse_gen 周期
    output wire        pulse_out,    // 示例：脉冲输出（可接 LED）
    output wire        busy          // 示例：运行状态
);

    // 调试总线（ENABLE_DFT=0 时输出恒 0，可悬空不连引脚）
    wire [31:0] dbg_pulse_cnt;
    wire [31:0] dbg_cycle_cnt;

    pulse_gen_wrap #(
        .CNT_W     (32),
        .ENABLE_DFT(ENABLE_DFT)
    ) u_pulse_gen_wrap (
        .clk             (clk),
        .rst_n           (rst_n),
        .cfg_en          (cfg_en),
        .cfg_period      (cfg_period),
        .pulse_out       (pulse_out),
        .busy            (busy),
        .dbg_force_pulse (1'b0),
        .dbg_block_en    (1'b0),
        .dbg_pulse_cnt   (dbg_pulse_cnt),
        .dbg_cycle_cnt   (dbg_cycle_cnt)
    );

endmodule
