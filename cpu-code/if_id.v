`include "defines.v"

module if_id (
	input wire					clk,
	input wire					rst,
	input wire[`InstAddrBus]	if_pc,
	input wire[`InstBus] 		if_inst,
	input wire[5:0]				stall,
	input wire 					flush,

	output reg[`InstAddrBus]	id_pc,
	output reg[`InstBus]		id_inst
);

	always @(posedge clk) begin
		// 非复位状态传送
		if (rst == `RstEnable) begin
			id_pc <= `ZeroWord;
			id_inst <= `ZeroWord;
		end
		else begin
			if (flush == `Flush) begin
				id_pc <= `ZeroWord;
				id_inst <= `ZeroWord;
			end
			else if (stall[1] == `StallEnable && stall[2] == `StallDisable) begin
				id_pc <= `ZeroWord;
				id_inst <= `ZeroWord;
			end
			else if (stall[1] == `StallDisable) begin
				id_pc <= if_pc;
				id_inst <= if_inst;
			end
		end
	end

endmodule