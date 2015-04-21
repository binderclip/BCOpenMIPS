`include "defines.v"

module pc_reg (
	input wire					clk,
	input wire					rst,
	input wire[5:0]				stall,
	input wire					branch_flag_i,
	input wire[`InstAddrBus]	branch_target_address_i,

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
		if (ce == `ChipDisable) begin
			pc <= `ZeroWord;
		end
		else if (stall[0] == `StallDisable) begin
			if (branch_flag_i == `Branch) begin
				pc <= branch_target_address_i;
			end
			else begin
				pc <= pc + 4'h4;
			end
		end
	end

endmodule