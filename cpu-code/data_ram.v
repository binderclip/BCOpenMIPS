`include "defines.v"

module data_ram(
	input wire				clk,
	input wire				ce,
	input wire				we,
	input wire[`RegBus]		addr,
	input wire[3:0]			sel,
	input wire[`RegBus]		data_i,

	output reg[`RegBus]		data_o
);

	// 定义四个字节数组
	reg[`ByteWidth] data_mem0[0:`DataMemNumber - 1];
	reg[`ByteWidth] data_mem1[0:`DataMemNumber - 1];
	reg[`ByteWidth] data_mem2[0:`DataMemNumber - 1];
	reg[`ByteWidth] data_mem3[0:`DataMemNumber - 1];

	// 写操作
	always @(posedge clk) begin
		if (ce == `ChipDisable) begin
		end
		else if (we == `WriteEnable) begin
			if (sel[3] == 1'b1) begin
				data_mem3[addr[`DataMemNumberLog2 + 1 : 2]] <= data_i[31:24];
			end
			if (sel[2] == 1'b1) begin
				data_mem2[addr[`DataMemNumberLog2 + 1 : 2]] <= data_i[23:16];
			end
			if (sel[1] == 1'b1) begin
				data_mem1[addr[`DataMemNumberLog2 + 1 : 2]] <= data_i[15:8];
			end
			if (sel[0] == 1'b1) begin
				data_mem0[addr[`DataMemNumberLog2 + 1 : 2]] <= data_i[7:0];
			end
		end
	end

	// 读操作
	always @(*) begin
		if (ce == `ChipDisable) begin
			data_o <= `ZeroWord;
		end
		else if (we == `WriteDisable) begin
			data_o <= {data_mem3[addr[`DataMemNumberLog2 + 1 : 2]],
					   data_mem2[addr[`DataMemNumberLog2 + 1 : 2]],
					   data_mem1[addr[`DataMemNumberLog2 + 1 : 2]],
					   data_mem0[addr[`DataMemNumberLog2 + 1 : 2]]};
		end
		else begin
			data_o <= `ZeroWord;
		end
	end

endmodule