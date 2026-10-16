// 反例 fixture：宏端口无法解析 → 必须 fail-closed 报错退出（非 0），不得放行
module case5_macro (
    input  wire clk,
    `PORT_DECL_MACRO            // 宏声明，解析器无法识别
);
endmodule
