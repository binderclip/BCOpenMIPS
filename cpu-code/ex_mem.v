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
	input wire[5:0]				stall,
	input wire[`DoubleRegBus]	hilo_i,
	input wire[1:0]				cnt_i,

	output reg[`RegAddrBus]		mem_waddr,
	output reg 					mem_we,
	output reg[`RegBus]			mem_wdata,
	output reg 					mem_whilo,
	output reg[`RegBus]			mem_hi,
	output reg[`RegBus]			mem_lo,
	output reg[`DoubleRegBus]	hilo_o,
	output reg[1:0]				cnt_o
);

	always @(posedge clk) begin
		if (rst == `RstEnable) begin
			mem_waddr <= `NOPRegAddr;
			mem_we <= `WriteDisable;
			mem_wdata <= `ZeroWord;

			mem_whilo <= `WriteDisable;
			mem_hi <= `ZeroWord;
			mem_lo <= `ZeroWord;

			hilo_o <= {`ZeroWord, `ZeroWord};
			cnt_o <= 2'b00;
		end
		else if (stall[3] == `StallEnable && stall[4] == `StallDisable) begin
			mem_waddr <= `NOPRegAddr;
			mem_we <= `WriteDisable;
			mem_wdata <= `ZeroWord;

			mem_whilo <= `WriteDisable;
			mem_hi <= `ZeroWord;
			mem_lo <= `ZeroWord;

			hilo_o <= hilo_i;
			cnt_o <= cnt_i;
		end
		else if (stall[3] == `StallDisable) begin
			mem_waddr <= ex_waddr;
			mem_we <= ex_we;
			mem_wdata <= ex_wdata;

			mem_whilo <= ex_whilo;
			mem_hi <= ex_hi;
			mem_lo <= ex_lo;

			hilo_o <= {`ZeroWord, `ZeroWord};
			cnt_o <= 2'b00;
		end
		else begin
			hilo_o <= hilo_i;
			cnt_o <= cnt_i;
		end
	end

endmodule