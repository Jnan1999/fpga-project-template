//==============================================================================
// pulse_gen_dft.v —— 可测性包装层（DFT Wrapper，可综合）
//
// 关键设计：
//   1) 本模块【内部例化】功能核心 pulse_gen，功能行为只存在一份，不可能与核心漂移；
//   2) 功能端口（clk/rst_n/cfg_en/cfg_period/pulse_out/busy）与 pulse_gen
//      【逐字一致】，由 scripts/check_ports.py 在 CI 中强制校验；
//   3) 所有可测性能力（观测、故障注入）走独立的 dbg_ 前缀调试总线，
//      不混入功能端口；release 版由 pulse_gen_wrap 自动 tie off，不影响功能接口；
//   4) 只在数据边界做注入/观测，不改动核心内部任何代码。
//==============================================================================
module pulse_gen_dft #(
    parameter integer CNT_W = 32,
    parameter [0:0]   ENABLE_DFT = 1
)(
    //---------------- 功能端口（与 pulse_gen 完全一致，禁止增删改）----------------
    input  wire             clk,
    input  wire             rst_n,
    input  wire             cfg_en,
    input  wire [CNT_W-1:0] cfg_period,
    output wire             pulse_out,
    output wire             busy,
    //---------------- 调试/可测性端口（dbg_ 前缀，仅调试版使用）----------------
    input  wire             dbg_force_pulse, // 注入：强制输出脉冲
    input  wire             dbg_block_en,    // 注入：门控内部使能（模拟使能丢失）
    output wire [31:0]      dbg_pulse_cnt,   // 观测：累计脉冲个数
    output wire [31:0]      dbg_cycle_cnt    // 观测：累计运行周期数（可做溢出/卡死判断）
);

    // 内部功能信号
    wire core_pulse;
    wire core_busy;
    wire core_en_gated;

    // 故障注入：在输入边界门控使能（不改动核心）
    assign core_en_gated = cfg_en & ~dbg_block_en;

    // 功能核心：唯一可信源
    pulse_gen #(
        .CNT_W(CNT_W)
    ) u_core (
        .clk        (clk),
        .rst_n      (rst_n),
        .cfg_en     (core_en_gated),
        .cfg_period (cfg_period),
        .pulse_out  (core_pulse),
        .busy       (core_busy)
    );

    // 功能输出透传 + 输出故障注入（强制脉冲）
    assign pulse_out = core_pulse | dbg_force_pulse;
    assign busy      = core_busy;

    // 观测计数器：仅统计可观测信号，零侵入、可综合
    reg [31:0] pulse_cnt_r;
    reg [31:0] cycle_cnt_r;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pulse_cnt_r <= 32'd0;
            cycle_cnt_r <= 32'd0;
        end else begin
            cycle_cnt_r <= cycle_cnt_r + 32'd1;
            if (core_pulse)
                pulse_cnt_r <= pulse_cnt_r + 32'd1;
        end
    end

    assign dbg_pulse_cnt = pulse_cnt_r;
    assign dbg_cycle_cnt = cycle_cnt_r;

endmodule
