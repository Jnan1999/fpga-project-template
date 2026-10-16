// 反例 fixture：与 core 分组声明不同（b → c），必须被检出
module case2_group_dft (
    input  wire clk,
    input  wire a,
    c                    // 故意与 core 的 b 不一致
);
endmodule
