`include "defines.v"

module id (
	input wire 					rst,
	
	// 来自 IF 和 regfile
	input wire[`InstAddrBus]	pc_i,
	input wire[`InstBus]		inst_i,
	input wire[`RegBus]			reg1_data_i,
	input wire[`RegBus]			reg2_data_i,

	// 来自 EX 的输入
	input wire[`RegAddrBus]		ex_waddr_i,
	input wire 					ex_we_i,
	input wire[`RegBus]			ex_wdata_i,

	// 来自 MEM 的输入
	input wire[`RegAddrBus]		mem_waddr_i,
	input wire 					mem_we_i,
	input wire[`RegBus]			mem_wdata_i,

	// 送往 regfile
	output reg					reg1_re_o,		// regfile 的 re1
	output reg					reg2_re_o,
	output reg[`RegAddrBus]		reg1_addr_o,
	output reg[`RegAddrBus]		reg2_addr_o,

	output reg[`AluOpBus]		aluop_o,		// 运算的子类型
	output reg[`AluSelBus]		alusel_o,		// 运算类型

	output reg[`RegBus] 		reg1_o,			// 运算的源操作数 1
	output reg[`RegBus]			reg2_o,

	output reg[`RegAddrBus] 	waddr_o,		// 写入的寄存器的地址
	output reg 					we_o			// 是否有需要写入的寄存器
);

	// 取得指令的指令码
	// ori 指令只需要判断 31 - 26 bit
	wire[5:0] op_class = inst_i[31:26];		// 6
	wire[4:0] op_rs = inst_i[25:21];		// 5
	wire[4:0] op_rt = inst_i[20:16];		// 5
	wire[4:0] op_rd = inst_i[15:11];		// 5
	wire[4:0] op_sa = inst_i[10:6];			// 5
	wire[5:0] op_subclass = inst_i[5:0];	// 6
	
	wire[4:0] r_read1_address = op_rs;
	wire[4:0] r_read1b_address = op_sa;		// 在 sll、srl、sra 的时候使用
	wire[4:0] r_read2_address = op_rt;
	wire[4:0] r_write_address = op_rd;
	
	wire[4:0] i_write_address = op_rt;		// 立即数状态下的写地址

	wire[15:0] i_imm = inst_i[15:0];

	// 保存需要的立即数
	reg[`RegBus] imm;
	reg instvalid;

	// 对程序进行译码
	always @(*) begin
		if (rst == `RstEnable) begin
			// NOP 类型
			aluop_o <= `EXE_OP_NOP_NOP;
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
			aluop_o <= `EXE_OP_NOP_NOP;
			alusel_o <= `EXE_OP_NOP_NOP;
			waddr_o <= r_write_address;
			we_o <= `WriteDisable;
			instvalid <= `InstInvalid;
			reg1_re_o <= `ReadDisable;
			reg2_re_o <= `ReadDisable;
			reg1_addr_o <= r_read1_address;
			reg2_addr_o <= r_read2_address;
			imm <= `ZeroWord;
			case (op_class)
				`EXE_SPECIAL: begin
					if (op_rs == 0) begin
						reg1_addr_o <= r_read1b_address;
						case (op_subclass)
							`EXE_SPC_SLL: begin
								
							end
							`EXE_SPC_SRL: begin
								
							end
							`EXE_SPC_SRA: begin
								
							end
							default: begin
							end
						endcase
					end
					if (op_sa == 0) begin
						case (op_subclass)
							`EXE_SPC_SLLV: begin
								
							end
							`EXE_SPC_SRLV: begin
								
							end
							`EXE_SPC_SRAV: begin
								
							end
							`EXE_SPC_AND: begin
								
							end
							`EXE_SPC_OR: begin
								
							end
							`EXE_SPC_XOR: begin
								
							end
							`EXE_SPC_NOR: begin
								
							end
							default: begin
							end
						endcase
					end
				end
				`EXE_ANDI: begin
					// we_o <= `WriteEnable;

				end
				`EXE_ORI: begin
					we_o <= `WriteEnable;
					aluop_o <= `EXE_OP_LOGIC_OR;
					alusel_o <= `EXE_RES_LOGIC;
					reg1_re_o <= `ReadEnable;
					reg2_re_o <= `ReadDisable;
					imm <= {16'h0, i_imm};
					waddr_o <= i_write_address;
					instvalid <= `InstValid;					
				end
				`EXE_XORI: begin
					
				end
				`EXE_LUI: begin
					
				end
				`EXE_PREF: begin
					// 不存在 cache，此命令暂时当做 NOP 处理
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
			if (ex_we_i == `WriteEnable && ex_waddr_i == reg1_addr_o) begin
				reg1_o <= ex_wdata_i;
			end
			else if (mem_we_i == `WriteEnable && mem_waddr_i == reg1_addr_o) begin
				reg1_o <= mem_wdata_i;
			end
			else begin
				reg1_o <= reg1_data_i;
			end
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
			if (ex_we_i == `WriteEnable && ex_waddr_i == reg2_addr_o) begin
				reg2_o <= ex_wdata_i;
			end
			else if (mem_we_i == `WriteEnable && mem_waddr_i == reg2_addr_o) begin
				reg2_o <= mem_wdata_i;
			end
			else begin
				reg2_o <= reg2_data_i;
			end
		end
		else if (reg2_re_o == `ReadDisable) begin
			reg2_o <= imm;
		end
		else begin
			reg2_o <= `ZeroWord;
		end
	end

endmodule