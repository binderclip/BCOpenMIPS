`include "defines.v"

module inst_rom (
	input wire					ce,
	input wire[`InstAddrBus]	addr,
	output reg[`InstBus]		inst
);

	reg[`InstBus] inst_mem[0 : `InstMemNum - 1];

	// 使用文件来初始化
	initial $readmemh ("inst_rom.data", inst_mem);

	always @(*) begin
		if (ce == `ChipDisable) begin
			inst <= `ZeroWord;
		end
		else begin
			// 去掉第二位的地址
			inst <= inst_mem[addr[`InstMemNumLog2 + 1 : 2]];
		end
	end

endmodule