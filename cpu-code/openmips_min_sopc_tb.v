`include "defines.v"

`timescale 1ns/1ps

module openmips_min_sopc_tb ();

	reg CLOCK_50;
	reg rst;

	// 每隔 10ns，CLOCK_50 信号翻转一次，所以一个周期是 20ns，对应 50MHz

	initial begin
		CLOCK_50 = 1'b1;
		#20 CLOCK_50 = 1'b0;	// 保证重启正常
		forever #10 CLOCK_50 = ~CLOCK_50;
	end

	// 最初时刻复位信号有效，在第 195ns，复位信号无效，最小 SOPC 开始运行
	// 运行 1000ns 之后，暂停仿真
	initial begin
		rst = `RstEnable;
		#195 rst = `RstDisable;
		#1000 rst = `RstEnable;
		#10 $stop;
	end

	openmips_min_sopc openmips_min_sopc0 (
		.clk(CLOCK_50),
		.rst(rst)
	);

	initial begin
		$dumpfile("openmips_min_sopc.vcd");
		$dumpvars(0, openmips_min_sopc0);
		$dumpvars(0, openmips_min_sopc0.openmips0.regfile0.regs[0]);
		$dumpvars(0, openmips_min_sopc0.openmips0.regfile0.regs[1]);
		$dumpvars(0, openmips_min_sopc0.openmips0.regfile0.regs[2]);
		$dumpvars(0, openmips_min_sopc0.openmips0.regfile0.regs[3]);
		$dumpvars(0, openmips_min_sopc0.openmips0.regfile0.regs[4]);
		// for (reg [31:0] idx = 0; idx < 32; idx++) begin
		// 	$dumpvars(0, openmips_min_sopc0.openmips0.regfile0.regs[idx]);
		// end
	end

endmodule