`include "defines.v"

moudle regfile (
	input wire					rst;
	input wire					clk;
	
	input wire					we;
	input wire[`RegAddrBus]		waddr;
	input wire[`RegBus]			wdata;

	input wire					re1;
	input wire[`RegAddrBus]		raddr1;
	output reg[`RegBus]			rdata1;

	input wire					re2;
	input wire[`RegAddrBus]		raddr2;
	output reg[`RegBus]			rdata2;
);

	// 定义 32 * 32 的寄存器组
	reg[`RegBus] regs[0 : RegNum - 1];

	// write
	always @(posedge clk) begin
		if (rst == `RstDisable) begin
			// 0 号寄存器的值是 0，不能写入
			if ((we == `WriteEnable) && (waddr != `RegNumLog2'h0)) begin
				regs[waddr] <= wdata;
			end
		end
	end

	// read 1
	always @(*) begin
		// 读取的时候有很多的特殊状态
		if (rst == `RstDisable) begin
			rdata1 <= `ZeroWord;
		end
		else if (raddr1 == `RegNumLog2'b0) begin
			rdata1 <= `ZeroWord;
		end
		else if ((raddr1 == waddr) && (we == `WriteEnable) && (re1 == `ReadEnable)) begin
			rdata1 <= wdata;
		end
		else if (re1 == `ReadEnable) begin
			rdata1 <= regs[raddr1];
		end
		else begin
			rdata1 <= `ZeroWord;
		end
	end

	// read 2
	always @(*) begin
		if (rst == `RstDisable) begin
			rdata2 <= `ZeroWord;
		end
		else if (raddr2 == `RegNumLog2'b0) begin
			rdata2 <= `ZeroWord;
		end
		else if ((raddr2 == waddr) && (we == `WriteEnable) && (re2 == `ReadEnable)) begin
			rdata2 <= wdata;
		end
		else if (re2 == `ReadEnable) begin
			rdata2 <= regs[raddr2];
		end
		else begin
			rdata2 <= `ZeroWord;
		end	end

endmodule