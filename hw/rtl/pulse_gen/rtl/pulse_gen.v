//==============================================================================
// pulse_gen.v —— 功能核心（唯一可信源，资源最少）
//
// 说明：
//   - 纯功能实现，禁止出现任何调试/观测/注入代码与 dbg_ 端口；
//   - 可测性逻辑全部放在 dft_wrap/pulse_gen_dft.v（它内部例化本模块）；
//   - 顶层不直接例化本模块，统一例化 pulse_gen_wrap，由 ENABLE_DFT 选择。
//
// 功能：使能后按 cfg_period 周期在 pulse_out 上输出单拍脉冲。
//==============================================================================
module pulse_gen #(
    parameter integer CNT_W = 32          // 计数器位宽
)(
    input  wire             clk,          // 工作时钟
    input  wire             rst_n,        // 异步复位，低有效（同步释放）
    input  wire             cfg_en,       // 使能：1 运行，0 停止并清计数
    input  wire [CNT_W-1:0] cfg_period,   // 脉冲周期（计数拍数，>=1）
    output wire             pulse_out,    // 周期脉冲（单拍高电平）
    output wire             busy          // 运行状态
);

    reg [CNT_W-1:0] cnt;
    reg             pulse_r;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt     <= {CNT_W{1'b0}};
            pulse_r <= 1'b0;
        end else if (!cfg_en) begin
            cnt     <= {CNT_W{1'b0}};
            pulse_r <= 1'b0;
        end else if (cfg_period == {CNT_W{1'b0}}) begin
            // 非法配置保护：周期为 0 不计数，不产生脉冲
            cnt     <= {CNT_W{1'b0}};
            pulse_r <= 1'b0;
        end else if (cnt == cfg_period - 1'b1) begin
            cnt     <= {CNT_W{1'b0}};
            pulse_r <= 1'b1;
        end else begin
            cnt     <= cnt + 1'b1;
            pulse_r <= 1'b0;
        end
    end

    assign pulse_out = pulse_r;
    assign busy      = cfg_en;

endmodule
