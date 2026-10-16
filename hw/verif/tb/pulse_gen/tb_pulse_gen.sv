//==============================================================================
// tb_pulse_gen.sv —— pulse_gen 模块级自检测试台（示例模块标准写法）
//
// 自检口径（tb-style 规范）：
//   - 全部检查由本 TB 自动比对，禁止人工看波形判对错；
//   - 期望来源 = pulse_gen 功能定义（模块头注释：使能后按 cfg_period 周期输出
//     单拍脉冲；cfg_period=0 为保护配置不产生脉冲），非从 RTL 行为反推；
//   - 通过：$display("TEST PASSED ...") 并 $finish；
//   - 失败：$display("FAIL: ...") —— run_sim.tcl 末尾扫描 "FAIL[: ]" 计入
//     SIM_ERRORS，SUMMARY 判 FAIL（fail-closed）；超时守护同口径。
//==============================================================================
`timescale 1ns/1ps

module tb_pulse_gen;

    localparam integer CNT_W  = 32;
    localparam integer PERIOD = 8;     // 测试用脉冲周期（拍）
    localparam integer CLK_NS = 10;    // 100 MHz

    reg              clk        = 1'b0;
    reg              rst_n      = 1'b0;
    reg              cfg_en     = 1'b0;
    reg  [CNT_W-1:0] cfg_period = {CNT_W{1'b0}};
    wire             pulse_out;
    wire             busy;
    wire [31:0]      dbg_pulse_cnt;
    wire [31:0]      dbg_cycle_cnt;

    integer errors = 0;
    integer i;
    time    t_prev, t_now, interval;

    // 时钟
    always #(CLK_NS/2) clk = ~clk;

    // DUT：统一入口 wrap，发布模式（ENABLE_DFT=0）——与 top 例化方式一致
    pulse_gen_wrap #(
        .CNT_W      (CNT_W),
        .ENABLE_DFT (1'b0)
    ) dut (
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

    // 超时守护：仿真卡死（如等不到脉冲）时判 FAIL，不让仿真挂起
    initial begin
        #200000;
        $display("FAIL: timeout, simulation did not finish");
        $finish;
    end

    // 单项检查：不成立则计数并打印（刻意不含 Error/FAIL 字样，汇总由末尾统一判）
    task check(input cond, input [8*80-1:0] msg);
        if (!cond) begin
            errors = errors + 1;
            $display("MISMATCH: %0s (time %0t)", msg, $time);
        end
    endtask

    initial begin
        // ---- 1. 复位 ----
        repeat (5) @(posedge clk);
        @(negedge clk) rst_n = 1'b1;   // 异步复位、同步释放：在时钟低电平段释放
        @(posedge clk); #1;
        check(pulse_out === 1'b0, "pulse_out low after reset");
        check(busy      === 1'b0, "busy low when disabled");

        // ---- 2. 使能（cfg_period=8），测 3 个相邻脉冲间隔 == 8 拍 ----
        @(negedge clk) begin cfg_period = PERIOD; cfg_en = 1'b1; end
        @(posedge pulse_out); t_prev = $time;
        for (i = 0; i < 3; i = i + 1) begin
            @(posedge pulse_out); t_now = $time;
            interval = t_now - t_prev;
            t_prev   = t_now;
            check(interval == PERIOD*CLK_NS, "pulse interval == cfg_period clocks");
        end
        check(busy === 1'b1, "busy high while enabled");

        // ---- 3. 脉冲宽度恰为 1 拍 ----
        @(posedge pulse_out);
        @(posedge clk); #1;
        check(pulse_out === 1'b0, "pulse width is single clock");

        // ---- 4. 关断：不再有脉冲，busy 归零 ----
        @(negedge clk) cfg_en = 1'b0;
        repeat (2*PERIOD) begin
            @(posedge clk); #1;
            check(pulse_out === 1'b0, "no pulse after disable");
        end
        check(busy === 1'b0, "busy low after disable");

        // ---- 5. 非法配置保护：cfg_period=0 使能也不产生脉冲 ----
        @(negedge clk) begin cfg_period = {CNT_W{1'b0}}; cfg_en = 1'b1; end
        repeat (3*PERIOD) begin
            @(posedge clk); #1;
            check(pulse_out === 1'b0, "no pulse when cfg_period==0");
        end
        @(negedge clk) cfg_en = 1'b0;

        // ---- 6. 发布模式 wrap 契约：调试输出 tie-off 为 0 ----
        check(dbg_pulse_cnt === 32'd0, "dbg_pulse_cnt tied to 0 in release mode");
        check(dbg_cycle_cnt === 32'd0, "dbg_cycle_cnt tied to 0 in release mode");

        // ---- 汇总 ----
        if (errors == 0) $display("TEST PASSED: tb_pulse_gen all checks passed");
        else             $display("FAIL: %0d checks failed in tb_pulse_gen", errors);
        $finish;
    end

endmodule
