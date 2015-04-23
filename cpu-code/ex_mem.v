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
	input wire[`AluOpBus]		ex_aluop,
	input wire[`RegBus]			ex_mem_addr,
	input wire[`RegBus]			ex_reg2,
	input wire[`RegBus]			ex_cp0_reg_data,
	input wire[`RegAddrBus]		ex_cp0_reg_waddr,
	input wire 					ex_cp0_reg_we,

	output reg[`RegAddrBus]		mem_waddr,
	output reg 					mem_we,
	output reg[`RegBus]			mem_wdata,
	output reg 					mem_whilo,
	output reg[`RegBus]			mem_hi,
	output reg[`RegBus]			mem_lo,
	output reg[`DoubleRegBus]	hilo_o,
	output reg[1:0]				cnt_o,
	output reg[`AluOpBus]		mem_aluop,
	output reg[`RegBus]			mem_mem_addr,
	output reg[`RegBus]			mem_reg2,
	output reg[`RegBus]			mem_cp0_reg_data,
	output reg[`RegAddrBus]		mem_cp0_reg_waddr,
	output reg 					mem_cp0_reg_we
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

			mem_aluop <= `EXE_OP_NOP_NOP;
			mem_mem_addr <= `ZeroWord;
			mem_reg2 <= `ZeroWord;

			mem_cp0_reg_data <= `ZeroWord;
			mem_cp0_reg_waddr <= 5'b0000;
			mem_cp0_reg_we <= `WriteDisable;
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

			mem_aluop <= `EXE_OP_NOP_NOP;
			mem_mem_addr <= `ZeroWord;
			mem_reg2 <= `ZeroWord;

			mem_cp0_reg_data <= `ZeroWord;
			mem_cp0_reg_waddr <= 5'b0000;
			mem_cp0_reg_we <= `WriteDisable;
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

			mem_aluop <= ex_aluop;
			mem_mem_addr <= ex_mem_addr;
			mem_reg2 <= ex_reg2;

			mem_cp0_reg_data <= ex_cp0_reg_data;
			mem_cp0_reg_waddr <= ex_cp0_reg_waddr;
			mem_cp0_reg_we <= ex_cp0_reg_we;
		end
		else begin
			hilo_o <= hilo_i;
			cnt_o <= cnt_i;
		end
	end

endmodule