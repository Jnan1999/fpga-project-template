// 反例 fixture：位宽表达式不同（W ≠ CNT_W），必须被检出
module case3_width_dft (
    input  wire         clk,
    input  wire [W-1:0] data
);
endmodule
