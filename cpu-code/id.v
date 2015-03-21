`include "defines.v"

moudle id {
	input wire 					rst;
	
	input wire[`InstAddrBus]	pc_i;
	input wire[`InstBus]		inst_i;
	input wire[`RegBus]			reg1_data_i;
	input wire[`RegBus]			reg2_data_i;

	output reg					reg1_re_o;		// regfile 的 re1
	output reg					reg2_re_o;
	output reg[`RegAddrBus]		reg1_addr_o;
	output reg[`RegAddrBus]		reg2_addr_o;

	output reg[`AluOpBus]		aluop_o;		// 运算的子类型
	output reg[`AluSelBus]		alusel_o;		// 运算类型

	output reg[`RegBus] 		reg1_o;			// 运算的源操作数 1
	output reg[`RegBus]			reg2_o;

	output reg[`RegAddrBus] 	waddr_o;		// 写入的寄存器的地址
	output reg 					we_o;			// 是否有需要写入的寄存器
};

	// 取得指令的指令码
	// ori 指令只需要判断 31 - 26 bit
	wire[5:0] op1 = inst_i[31:26];		// 6
	wire[4:0] op2 = inst_i[10:6];		// 5
	wire[5:0] op3 = inst_i[5:0];		// 6
	// wire[4:0] op4 = inst_i[20:16];		// 5

	wire[4:0] write_address = inst_i[15:11];	// 5
	wire[4:0] read1_address = inst_i[25:21];
	wire[4:0] read2_address = inst_i[20:16];

	wire [4:0] imm_i = inst_i[15:0];

	// 保存需要的立即数
	reg[`RegBus] imm;
	reg instvalid;

	// 对程序进行译码
	always @(*) begin
		if (rst == `RstEnable) begin
			// NOP 类型
			aluop_o <= `EXE_NOP_OP;
			alusel_o <= `EXE_RES_NOP;
			waddr_o <= `NOPRegAddr;
			we_o <= `WriteDisable;
			instvalid <= `InstValid;
			reg1_re_o <= `ReadDisable;
			reg2_re_o <= `ReadDisable;
			reg1_addr_o <= `NOPRegAddr;
			reg2_addr_o <= `NOPRegAddr;
			imm <= `ZeroWord;
		end
		else begin
			aluop_o <= `EXE_NOP_OP;
			alusel_o <= `EXE_NOP_OP;
			waddr_o <= write_address;
			we_o <= `WriteDisable;
			instvalid <= `InstInvalid;
			reg1_re_o <= `ReadDisable;
			reg2_re_o <= `ReadDisable;
			reg1_addr_o <= read1_address;
			reg2_addr_o <= read2_address;
			imm <= `ZeroWord;
			case (op)
				`EXE_ORI: begin
					we_o <= `WriteEnable;
					aluop_o <= `EXE_ORI_OP;
					alusel_o <= `EXE_RES_LOGIC;
					reg1_re_o <= `ReadEnable;
					reg2_re_o <= `ReadDisable;
					instvalid <= InstValid;
					imm <= {16'h0, }
				end
				default: begin
				end
			endcase
		end
	end

	// 源操作数 1
	always @(*) begin
		if (rst == `RstEnable) begin
			reg1_o <= `ZeroWord;
		end
		else if (reg1_re_o == `ReadEnable) begin
			reg1_o <= reg1_data_i;
		end
		else if (reg1_re_o == `ReadDisable) begin
			reg1_o <= imm;
		end
		else begin
			reg1_o <= `ZeroWord;
		end
	end

	// 源操作数 2
	always @(*) begin
		if (rst == `RstEnable) begin
			reg2_o <= `ZeroWord;
		end
		else if (reg2_re_o == `ReadEnable) begin
			reg2_o <= reg2_data_i;
		end
		else if (reg2_re_o == `ReadDisable) begin
			reg2_o <= imm;
		end
		else begin
			reg2_o <= `ZeroWord;
		end
	end

endmodule