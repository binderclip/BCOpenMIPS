`include "defines.v"

module LLbit_reg (
	input wire		clk,
	input wire		rst,

	input wire		flush,
	input wire		LLbit_i,
	input wire		we,

	output reg		LLbit_o
);

	always @(posedge clk) begin
		if (rst == `RstEnable) begin
			LLbit_o <= 1'b0;
		end
		else begin
			if (flush == 1'b1) begin 	// 异常发生置 0
				LLbit_o <= 1'b0;
			end
			else if (we == `WriteEnable) begin
				LLbit_o <= LLbit_i;
			end
		end
	end

endmodule