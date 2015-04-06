`include "defines.v"

module ex_mem (
	input wire					rst,
	input wire					clk,
	input wire[`RegAddrBus]		ex_waddr,
	input wire					ex_we,
	input wire[`RegBus]			ex_wdata,
	input wire 					ex_whilo,
	input wire[`RegBus]			ex_hi,
	input wire[`RegBus]			ex_lo,

	output reg[`RegAddrBus]		mem_waddr,
	output reg 					mem_we,
	output reg[`RegBus]			mem_wdata,
	output reg 					mem_whilo,
	output reg[`RegBus]			mem_hi,
	output reg[`RegBus]			mem_lo
);

	always @(posedge clk) begin
		if (rst == `RstEnable) begin
			mem_waddr <= `NOPRegAddr;
			mem_we <= `WriteDisable;
			mem_wdata <= `ZeroWord;

			mem_whilo <= `WriteDisable;
			mem_hi <= `ZeroWord;
			mem_lo <= `ZeroWord;
		end
		else begin
			mem_waddr <= ex_waddr;
			mem_we <= ex_we;
			mem_wdata <= ex_wdata;
			
			mem_whilo <= ex_whilo;
			mem_hi <= ex_hi;
			mem_lo <= ex_lo;
		end
	end

endmodule