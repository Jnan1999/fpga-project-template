// 反例 fixture：分组声明（评审#6 曾漏检的形态）
module case2_group_core (
    input  wire clk,
    input  wire a,
    b                    // 分组声明：承袭 input wire
);
endmodule
