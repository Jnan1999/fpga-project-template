// 正例 fixture：功能端口一致 + dbg_ 前缀调试端口（应豁免，退出 0）
module case6_dbg_dft (
    input  wire       clk,
    input  wire [7:0] din,
    output wire [7:0] dout,
    output wire [7:0] dbg_cnt,   // 调试端口：豁免
    output wire       dbg_valid  // 调试端口：豁免
);
endmodule
