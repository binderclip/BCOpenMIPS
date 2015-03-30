`include "defines.v"

module mem (
	input wire				rst,
	input wire[`RegAddrBus]	waddr_i,
	input wire				we_i,
	input wire[`RegBus]		wdata_i,

	// 输出给 mem_wb
	output reg[`RegAddrBus] waddr_o,
	output reg 				we_o,
	output reg[`RegBus]		wdata_o,

	// 输出给 ID
	output reg[`RegAddrBus] waddr_id_o,
	output reg 				we_id_o,
	output reg[`RegBus]		wdata_id_o
);

	always @(*) begin
		if (rst == `RstEnable) begin
			waddr_o <= `NOPRegAddr;
			we_o <= `WriteDisable;
			wdata_o <= `ZeroWord;

			waddr_id_o <= `NOPRegAddr;
			we_id_o <= `WriteDisable;
			wdata_id_o <= `ZeroWord;
		end
		else begin
			waddr_o <= waddr_i;
			we_o <= we_i;
			wdata_o <= wdata_i;

			waddr_id_o <= waddr_i;
			we_id_o <= we_i;
			wdata_id_o <= wdata_i;
		end
	end

endmodule