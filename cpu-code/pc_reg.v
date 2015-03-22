`include "defines.v"

module pc_reg (
	input wire					clk,
	input wire					rst,
	output reg[`InstAddrBus]	pc,
	output reg 					ce
);

	always @(posedge clk) begin
		// 判断是否处于复位状态
		if (rst == `RstEnable) begin
			ce <= `ChipDisable;
		end
		else begin
			ce <= `ChipEnable;
		end
	end

	always @(posedge clk) begin
		// 非复位状态地址自增
		if (ce == `ChipEnable) begin
			pc <= pc + 4'h4;
		end
		// 复位状态地址清零
		else begin
			pc <= `ZeroWord;
		end
	end

endmodule