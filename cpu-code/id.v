`include "defines.v"

module id (
	input wire 					rst,

	// 来自 IF 和 regfile
	input wire[`InstAddrBus]	pc_i,
	input wire 					current_inst_loaded_i,
	input wire[`InstBus]		inst_i,
	input wire[`RegBus]			reg1_data_i,
	input wire[`RegBus]			reg2_data_i,
	// 来自 EX 的输入
	input wire[`RegAddrBus]		ex_waddr_i,
	input wire 					ex_we_i,
	input wire[`RegBus]			ex_wdata_i,
	input wire 					is_in_delayslot_i,
	input wire[`AluOpBus]		ex_aluop_i,
	// 来自 MEM 的输入
	input wire[`RegAddrBus]		mem_waddr_i,
	input wire 					mem_we_i,
	input wire[`RegBus]			mem_wdata_i,

	// 送往 regfile
	output reg					reg1_re_o,		// regfile 的 re1
	output reg					reg2_re_o,
	output reg[`RegAddrBus]		reg1_addr_o,
	output reg[`RegAddrBus]		reg2_addr_o,
	// 送往 EX
	output reg[`AluSelBus]		alusel_o,		// 运算类型
	output reg[`AluOpBus]		aluop_o,		// 运算的子类型
	output reg[`RegBus] 		reg1_o,			// 运算的源操作数 1
	output reg[`RegBus]			reg2_o,
	output reg[`RegAddrBus] 	waddr_o,		// 写入的寄存器的地址
	output reg 					we_o,			// 是否有需要写入的寄存器
	output wire[`RegBus]		inst_o,
	output wire[`RegBus]		excepttype_o,
	output wire[`RegBus]		current_inst_address_o,
	output wire 				current_inst_loaded_o,
	// 转移指令
	output reg 					next_inst_in_delayslot_o,
	output reg 					branch_flag_o,
	output reg[`RegBus]			branch_target_address_o,
	output reg[`RegBus]			link_addr_o,
	output reg 					is_in_delayslot_o,
	output wire					stallreq		// 请求流水线中断
);

	// 取得指令的指令码
	// ori 指令只需要判断 31 - 26 bit
	wire[5:0] op_class = inst_i[31:26];		// 6
	wire[4:0] op_rs = inst_i[25:21];		// 5
	wire[4:0] op_rt = inst_i[20:16];		// 5
	wire[4:0] op_rd = inst_i[15:11];		// 5
	wire[4:0] op_sa = inst_i[10:6];			// 5 在 sll、srl、sra 的时候使用
	wire[5:0] op_subclass = inst_i[5:0];	// 6

	wire[4:0] r_read1_address = op_rs;
	wire[4:0] r_read2_address = op_rt;
	wire[4:0] r_write_address = op_rd;

	wire[4:0] i_write_address = op_rt;		// 立即数状态下的写地址

	wire[15:0] i_imm = inst_i[15:0];

	// 保存需要的立即数
	reg[`RegBus] imm;
	reg instvalid;

	wire[`RegBus] pc_plus_8;
	wire[`RegBus] pc_plus_4;

	wire[`RegBus] imm_sll2_signedext;

	wire pre_inst_is_load;		// 上一条是装载指令
	reg stallreq_for_reg1_loadrelate;
	reg stallreq_for_reg2_loadrelate;

	reg excepttype_is_syscall;
	reg excepttype_is_eret;

	assign inst_o = inst_i;
	assign pc_plus_8 = pc_i + 8;
	assign pc_plus_4 = pc_i + 4;

	assign imm_sll2_signedext = {{14{inst_i[15]}}, inst_i[15:0], 2'b00};	// 左移过两位的地址

	assign pre_inst_is_load = ((ex_aluop_i == `EXE_OP_LOAD_STORE_LB) ||
							   (ex_aluop_i == `EXE_OP_LOAD_STORE_LH) ||
							   (ex_aluop_i == `EXE_OP_LOAD_STORE_LWL) ||
							   (ex_aluop_i == `EXE_OP_LOAD_STORE_LW) ||
							   (ex_aluop_i == `EXE_OP_LOAD_STORE_LBU) ||
							   (ex_aluop_i == `EXE_OP_LOAD_STORE_LHU) ||
							   (ex_aluop_i == `EXE_OP_LOAD_STORE_LWR)) ? 1'b1 : 1'b0;
	assign stallreq = stallreq_for_reg1_loadrelate | stallreq_for_reg2_loadrelate;

	assign excepttype_o = {19'b0, excepttype_is_eret, 2'b0, instvalid, excepttype_is_syscall, 8'b0};
	assign current_inst_address_o = pc_i;
	assign current_inst_loaded_o = current_inst_loaded_i;

	// 对程序进行译码
	always @(*) begin
		if (rst == `RstEnable) begin
			// NOP 类型
			alusel_o <= `EXE_RES_NOP;
			aluop_o <= `EXE_OP_NOP_NOP;
			instvalid <= `InstValid;
			we_o <= `WriteDisable;
			waddr_o <= `NOPRegAddr;
			reg1_re_o <= `ReadDisable;
			reg2_re_o <= `ReadDisable;
			reg1_addr_o <= `NOPRegAddr;
			reg2_addr_o <= `NOPRegAddr;
			imm <= `ZeroWord;
			link_addr_o <= `ZeroWord;
			branch_target_address_o <= `ZeroWord;
			branch_flag_o <= `NotBranch;
			next_inst_in_delayslot_o <= `NotInDelaySlot;
			excepttype_is_syscall <= 1'b0;
			excepttype_is_eret <= 1'b0;
		end
		else begin
			alusel_o <= `EXE_RES_NOP;
			aluop_o <= `EXE_OP_NOP_NOP;
			instvalid <= `InstInvalid;
			we_o <= `WriteDisable;
			waddr_o <= r_write_address;
			reg1_re_o <= `ReadDisable;
			reg2_re_o <= `ReadDisable;
			reg1_addr_o <= r_read1_address;
			reg2_addr_o <= r_read2_address;
			imm <= `ZeroWord;
			link_addr_o <= `ZeroWord;
			branch_target_address_o <= `ZeroWord;
			branch_flag_o <= `NotBranch;
			next_inst_in_delayslot_o <= `NotInDelaySlot;
			excepttype_is_syscall <= 1'b0;
			excepttype_is_eret <= 1'b0;
			case (op_class)
				`EXE_SPECIAL: begin
					if (op_rs == 0) begin
						case (op_subclass)
							`EXE_SPC_SLL: begin
								alusel_o <= `EXE_RES_SHIFT;
								aluop_o <= `EXE_OP_SHIFT_SLL;
								instvalid <= `InstValid;
								we_o <= `WriteEnable;
								waddr_o <= r_write_address;
								reg1_re_o <= `ReadDisable;
								reg2_re_o <= `ReadEnable;
								// imm <= {`ZeroWord[`RegWidth - 1 : 5], op_sa};	// 不晓得这里这样对不对
								// imm <= {16'h0000[16:5], op_sa};	// 不晓得这里这样对不对
								imm <= {11'h000, op_sa};	// 不晓得这里这样对不对
							end
							`EXE_SPC_SRL: begin
								alusel_o <= `EXE_RES_SHIFT;
								aluop_o <= `EXE_OP_SHIFT_SRL;
								instvalid <= `InstValid;
								we_o <= `WriteEnable;
								waddr_o <= r_write_address;
								reg1_re_o <= `ReadDisable;
								reg2_re_o <= `ReadEnable;
								imm <= {11'h000, op_sa};	// 不晓得这里这样对不对
							end
							`EXE_SPC_SRA: begin
								alusel_o <= `EXE_RES_SHIFT;
								aluop_o <= `EXE_OP_SHIFT_SRA;
								instvalid <= `InstValid;
								we_o <= `WriteEnable;
								waddr_o <= r_write_address;
								reg1_re_o <= `ReadDisable;
								reg2_re_o <= `ReadEnable;
								imm <= {11'h000, op_sa};	// 不晓得这里这样对不对
							end
							default: begin
							end
						endcase
					end
					if (op_sa == 0) begin
						case (op_subclass)
							`EXE_SPC_SLLV: begin
								alusel_o <= `EXE_RES_SHIFT;
								aluop_o <= `EXE_OP_SHIFT_SLL;
								instvalid <= `InstValid;
								we_o <= `WriteEnable;
								waddr_o <= r_write_address;
								reg1_re_o <= `ReadEnable;
								reg2_re_o <= `ReadEnable;
							end
							`EXE_SPC_SRLV: begin
								alusel_o <= `EXE_RES_SHIFT;
								aluop_o <= `EXE_OP_SHIFT_SRL;
								instvalid <= `InstValid;
								we_o <= `WriteEnable;
								waddr_o <= r_write_address;
								reg1_re_o <= `ReadEnable;
								reg2_re_o <= `ReadEnable;
							end
							`EXE_SPC_SRAV: begin
								alusel_o <= `EXE_RES_SHIFT;
								aluop_o <= `EXE_OP_SHIFT_SRA;
								instvalid <= `InstValid;
								we_o <= `WriteEnable;
								waddr_o <= r_write_address;
								reg1_re_o <= `ReadEnable;
								reg2_re_o <= `ReadEnable;
							end
							`EXE_SPC_AND: begin
								alusel_o <= `EXE_RES_LOGIC;
								aluop_o <= `EXE_OP_LOGIC_AND;
								instvalid <= `InstValid;
								we_o <= `WriteEnable;
								waddr_o <= r_write_address;
								reg1_re_o <= `ReadEnable;
								reg2_re_o <= `ReadEnable;
							end
							`EXE_SPC_OR: begin
								alusel_o <= `EXE_RES_LOGIC;
								aluop_o <= `EXE_OP_LOGIC_OR;
								instvalid <= `InstValid;
								we_o <= `WriteEnable;
								waddr_o <= r_write_address;
								reg1_re_o <= `ReadEnable;
								reg2_re_o <= `ReadEnable;
							end
							`EXE_SPC_XOR: begin
								alusel_o <= `EXE_RES_LOGIC;
								aluop_o <= `EXE_OP_LOGIC_XOR;
								instvalid <= `InstValid;
								we_o <= `WriteEnable;
								waddr_o <= r_write_address;
								reg1_re_o <= `ReadEnable;
								reg2_re_o <= `ReadEnable;
							end
							`EXE_SPC_NOR: begin
								alusel_o <= `EXE_RES_LOGIC;
								aluop_o <= `EXE_OP_LOGIC_NOR;
								instvalid <= `InstValid;
								we_o <= `WriteEnable;
								waddr_o <= r_write_address;
								reg1_re_o <= `ReadEnable;
								reg2_re_o <= `ReadEnable;
							end
							`EXE_SPC_MOVZ: begin
								alusel_o <= `EXE_RES_MOVE;
								aluop_o <= `EXE_OP_MOVE_MOVZ;
								instvalid <= `InstValid;
								if (reg2_o == `ZeroWord) begin
									we_o <= `WriteEnable;
								end
								else begin
									we_o <= `WriteDisable;
								end
								reg1_re_o <= `ReadEnable; // 两个寄存器写使能之后会默认读取 rs 和 rt
								reg2_re_o <= `ReadEnable;
							end
							`EXE_SPC_MOVN: begin
								alusel_o <= `EXE_RES_MOVE;
								aluop_o <= `EXE_OP_MOVE_MOVN;
								instvalid <= `InstValid;
								if (reg2_o != `ZeroWord) begin
									we_o <= `WriteEnable;
								end
								else begin
									we_o <= `WriteDisable;
								end
								reg1_re_o <= `ReadEnable;
								reg2_re_o <= `ReadEnable;
							end
							`EXE_SPC_MFHI: begin
								alusel_o <= `EXE_RES_MOVE;
								aluop_o <= `EXE_OP_MOVE_MFHI;
								instvalid <= `InstValid;
								we_o <= `WriteEnable;
								reg1_re_o <= `ReadDisable;
								reg2_re_o <= `ReadDisable;
							end
							`EXE_SPC_MTHI: begin
								// alusel_o <= `EXE_RES_MOVE;
								aluop_o <= `EXE_OP_OTHER_MTHI;
								instvalid <= `InstValid;
								we_o <= `WriteEnable;
								reg1_re_o <= `ReadEnable;
								reg2_re_o <= `ReadDisable;
							end
							`EXE_SPC_MFLO: begin
								alusel_o <= `EXE_RES_MOVE;
								aluop_o <= `EXE_OP_MOVE_MFLO;
								instvalid <= `InstValid;
								we_o <= `WriteEnable;
								reg1_re_o <= `ReadDisable;
								reg2_re_o <= `ReadDisable;
							end
							`EXE_SPC_MTLO: begin
								// alusel_o <= `EXE_RES_MOVE;
								aluop_o <= `EXE_OP_OTHER_MTLO;
								instvalid <= `InstValid;
								we_o <= `WriteEnable;
								reg1_re_o <= `ReadEnable;
								reg2_re_o <= `ReadDisable;
							end
							`EXE_SPC_MULT: begin
								// alusel_o <= `EXE_RES_MATH;
								aluop_o <= `EXE_OP_MATH_MULT;
								instvalid <= `InstValid;
								we_o <= `WriteEnable;
								reg1_re_o <= `ReadEnable;
								reg2_re_o <= `ReadEnable;
							end
							`EXE_SPC_MULTU: begin
								// alusel_o <= `EXE_RES_MATH;
								aluop_o <= `EXE_OP_MATH_MULTU;
								instvalid <= `InstValid;
								we_o <= `WriteEnable;
								reg1_re_o <= `ReadEnable;
								reg2_re_o <= `ReadEnable;
							end
							`EXE_SPC_ADD: begin
								alusel_o <= `EXE_RES_MATH;
								aluop_o <= `EXE_OP_MATH_ADD;
								instvalid <= `InstValid;
								we_o <= `WriteEnable;
								reg1_re_o <= `ReadEnable;
								reg2_re_o <= `ReadEnable;
							end
							`EXE_SPC_ADDU: begin
								alusel_o <= `EXE_RES_MATH;
								aluop_o <= `EXE_OP_MATH_ADDU;
								instvalid <= `InstValid;
								we_o <= `WriteEnable;
								reg1_re_o <= `ReadEnable;
								reg2_re_o <= `ReadEnable;
							end
							`EXE_SPC_SUB: begin
								alusel_o <= `EXE_RES_MATH;
								aluop_o <= `EXE_OP_MATH_SUB;
								instvalid <= `InstValid;
								we_o <= `WriteEnable;
								reg1_re_o <= `ReadEnable;
								reg2_re_o <= `ReadEnable;
							end
							`EXE_SPC_SUBU: begin
								alusel_o <= `EXE_RES_MATH;
								aluop_o <= `EXE_OP_MATH_SUBU;
								instvalid <= `InstValid;
								we_o <= `WriteEnable;
								reg1_re_o <= `ReadEnable;
								reg2_re_o <= `ReadEnable;
							end
							`EXE_SPC_SLT: begin
								alusel_o <= `EXE_RES_MATH;
								aluop_o <= `EXE_OP_MATH_SLT;
								instvalid <= `InstValid;
								we_o <= `WriteEnable;
								reg1_re_o <= `ReadEnable;
								reg2_re_o <= `ReadEnable;
							end
							`EXE_SPC_SLTU: begin
								alusel_o <= `EXE_RES_MATH;
								aluop_o <= `EXE_OP_MATH_SLTU;
								instvalid <= `InstValid;
								we_o <= `WriteEnable;
								reg1_re_o <= `ReadEnable;
								reg2_re_o <= `ReadEnable;
							end
							`EXE_SPC_DIV: begin
								aluop_o <= `EXE_OP_MATH_DIV;
								instvalid <= `InstValid;
								we_o <= `WriteDisable;
								reg1_re_o <= `ReadEnable;
								reg2_re_o <= `ReadEnable;
							end
							`EXE_SPC_DIVU: begin
								aluop_o <= `EXE_OP_MATH_DIVU;
								instvalid <= `InstValid;
								we_o <= `WriteDisable;
								reg1_re_o <= `ReadEnable;
								reg2_re_o <= `ReadEnable;
							end
							`EXE_SPC_JR: begin
								alusel_o <= `EXE_RES_JUMP_BRANCH;
								aluop_o <= `EXE_OP_JUMP_BRANCH_JR;
								instvalid <= `InstValid;
								we_o <= `WriteDisable;
								reg1_re_o <= `ReadEnable;
								reg2_re_o <= `ReadDisable;
								link_addr_o <= `ZeroWord;
								branch_target_address_o <= reg1_o;
								branch_flag_o <= `Branch;
								next_inst_in_delayslot_o <= `InDelaySlot;
							end
							`EXE_SPC_JALR: begin
								alusel_o <= `EXE_RES_JUMP_BRANCH;
								aluop_o <= `EXE_OP_JUMP_BRANCH_JALR;
								instvalid <= `InstValid;
								we_o <= `WriteEnable;
								waddr_o <= r_write_address;
								reg1_re_o <= `ReadEnable;
								reg2_re_o <= `ReadDisable;
								link_addr_o <= pc_plus_8;
								branch_target_address_o <= reg1_o;
								branch_flag_o <= `Branch;
								next_inst_in_delayslot_o <= `InDelaySlot;
							end
							default: begin
							end
						endcase
					end
					case (op_subclass)
						`EXE_SPC_SYSCALL: begin
							alusel_o <= `EXE_RES_NOP;
							aluop_o <= `EXE_OP_EXCEPTION_SYSCALL;
							instvalid <= `InstValid;
							we_o <= `WriteDisable;
							reg1_re_o <= `ReadDisable;
							reg2_re_o <= `ReadDisable;
							excepttype_is_syscall <= 1'b1;
						end
						`EXE_SPC_TGE: begin
							alusel_o <= `EXE_RES_NOP;
							aluop_o <= `EXE_OP_EXCEPTION_TGE;
							instvalid <= `InstValid;
							we_o <= `WriteDisable;
							reg1_re_o <= `ReadEnable;
							reg2_re_o <= `ReadEnable;
						end
						`EXE_SPC_TGEU: begin
							alusel_o <= `EXE_RES_NOP;
							aluop_o <= `EXE_OP_EXCEPTION_TGEU;
							instvalid <= `InstValid;
							we_o <= `WriteDisable;
							reg1_re_o <= `ReadEnable;
							reg2_re_o <= `ReadEnable;
						end
						`EXE_SPC_TLT: begin
							alusel_o <= `EXE_RES_NOP;
							aluop_o <= `EXE_OP_EXCEPTION_TLT;
							instvalid <= `InstValid;
							we_o <= `WriteDisable;
							reg1_re_o <= `ReadEnable;
							reg2_re_o <= `ReadEnable;
						end
						`EXE_SPC_TLTU: begin
							alusel_o <= `EXE_RES_NOP;
							aluop_o <= `EXE_OP_EXCEPTION_TLTU;
							instvalid <= `InstValid;
							we_o <= `WriteDisable;
							reg1_re_o <= `ReadEnable;
							reg2_re_o <= `ReadEnable;
						end
						`EXE_SPC_TEQ: begin
							alusel_o <= `EXE_RES_NOP;
							aluop_o <= `EXE_OP_EXCEPTION_TEQ;
							instvalid <= `InstValid;
							we_o <= `WriteDisable;
							reg1_re_o <= `ReadEnable;
							reg2_re_o <= `ReadEnable;
						end
						`EXE_SPC_TNE: begin
							alusel_o <= `EXE_RES_NOP;
							aluop_o <= `EXE_OP_EXCEPTION_TNE;
							instvalid <= `InstValid;
							we_o <= `WriteDisable;
							reg1_re_o <= `ReadEnable;
							reg2_re_o <= `ReadEnable;
						end
					endcase
				end
				`EXE_J: begin
					alusel_o <= `EXE_RES_JUMP_BRANCH;
					aluop_o <= `EXE_OP_JUMP_BRANCH_J;
					instvalid <= `InstValid;
					we_o <= `WriteDisable;
					reg1_re_o <= `ReadDisable;
					reg2_re_o <= `ReadDisable;
					link_addr_o <= `ZeroWord;
					branch_target_address_o <= {pc_plus_4[31:28], inst_i[25:0], 2'b00};
					branch_flag_o <= `Branch;
					next_inst_in_delayslot_o <= `InDelaySlot;
				end
				`EXE_JAL: begin
					alusel_o <= `EXE_RES_JUMP_BRANCH;
					aluop_o <= `EXE_OP_JUMP_BRANCH_JAL;
					instvalid <= `InstValid;
					we_o <= `WriteEnable;
					waddr_o <= `RegRAAddr;
					reg1_re_o <= `ReadDisable;
					reg2_re_o <= `ReadDisable;
					link_addr_o <= pc_plus_8;
					branch_target_address_o <= {pc_plus_4[31:28], inst_i[25:0], 2'b00};
					branch_flag_o <= `Branch;
					next_inst_in_delayslot_o <= `InDelaySlot;
				end
				`EXE_BEQ: begin
					alusel_o <= `EXE_RES_JUMP_BRANCH;
					aluop_o <= `EXE_OP_JUMP_BRANCH_BEQ;
					instvalid <= `InstValid;
					we_o <= `WriteDisable;
					reg1_re_o <= `ReadEnable;
					reg2_re_o <= `ReadEnable;
					if (reg1_o == reg2_o) begin
						branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
						branch_flag_o <= `Branch;
						next_inst_in_delayslot_o <= `InDelaySlot;
					end
				end
				`EXE_BNE: begin
					alusel_o <= `EXE_RES_JUMP_BRANCH;
					aluop_o <= `EXE_OP_JUMP_BRANCH_BNE;
					instvalid <= `InstValid;
					we_o <= `WriteDisable;
					reg1_re_o <= `ReadEnable;
					reg2_re_o <= `ReadEnable;
					if (reg1_o != reg2_o) begin
						branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
						branch_flag_o <= `Branch;
						next_inst_in_delayslot_o <= `InDelaySlot;
					end
				end
				`EXE_BLEZ: begin
					alusel_o <= `EXE_RES_JUMP_BRANCH;
					aluop_o <= `EXE_OP_JUMP_BRANCH_BLEZ;
					instvalid <= `InstValid;
					we_o <= `WriteDisable;
					reg1_re_o <= `ReadEnable;
					reg2_re_o <= `ReadDisable;
					if ((reg1_o[31] == 1'b1) || (reg1_o == `ZeroWord)) begin
						branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
						branch_flag_o <= `Branch;
						next_inst_in_delayslot_o <= `InDelaySlot;
					end
				end
				`EXE_BGTZ: begin
					alusel_o <= `EXE_RES_JUMP_BRANCH;
					aluop_o <= `EXE_OP_JUMP_BRANCH_BGTZ;
					instvalid <= `InstValid;
					we_o <= `WriteDisable;
					reg1_re_o <= `ReadEnable;
					reg2_re_o <= `ReadDisable;
					if ((reg1_o[31] == 1'b0) && (reg1_o != `ZeroWord)) begin
						branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
						branch_flag_o <= `Branch;
						next_inst_in_delayslot_o <= `InDelaySlot;
					end
				end
				`EXE_REGIMM_INST: begin
					case (op_rt)
						`EXE_REGIMM_BLTZ: begin
							alusel_o <= `EXE_RES_JUMP_BRANCH;
							aluop_o <= `EXE_OP_JUMP_BRANCH_BLTZ;
							instvalid <= `InstValid;
							we_o <= `WriteDisable;
							reg1_re_o <= `ReadEnable;
							reg2_re_o <= `ReadDisable;
							if (reg1_o[31] == 1'b1) begin
								branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
								branch_flag_o <= `Branch;
								next_inst_in_delayslot_o <= `InDelaySlot;
							end
						end
						`EXE_REGIMM_BGEZ: begin
							alusel_o <= `EXE_RES_JUMP_BRANCH;
							aluop_o <= `EXE_OP_JUMP_BRANCH_BGEZ;
							instvalid <= `InstValid;
							we_o <= `WriteDisable;
							reg1_re_o <= `ReadEnable;
							reg2_re_o <= `ReadDisable;
							if (reg1_o[31] == 1'b0) begin
								branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
								branch_flag_o <= `Branch;
								next_inst_in_delayslot_o <= `InDelaySlot;
							end
						end
						`EXE_REGIMM_BLTZAL: begin
							alusel_o <= `EXE_RES_JUMP_BRANCH;
							aluop_o <= `EXE_OP_JUMP_BRANCH_BLTZAL;
							instvalid <= `InstValid;
							we_o <= `WriteEnable;
							waddr_o <= `RegRAAddr;
							reg1_re_o <= `ReadEnable;
							reg2_re_o <= `ReadDisable;
							link_addr_o <= pc_plus_8;
							if (reg1_o[31] == 1'b1) begin
								branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
								branch_flag_o <= `Branch;
								next_inst_in_delayslot_o <= `InDelaySlot;
							end
						end
						`EXE_REGIMM_BGEZAL: begin
							alusel_o <= `EXE_RES_JUMP_BRANCH;
							aluop_o <= `EXE_OP_JUMP_BRANCH_BGEZAL;
							instvalid <= `InstValid;
							we_o <= `WriteEnable;
							waddr_o <= `RegRAAddr;
							reg1_re_o <= `ReadEnable;
							reg2_re_o <= `ReadDisable;
							link_addr_o <= pc_plus_8;
							if (reg1_o[31] == 1'b0) begin
								branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
								branch_flag_o <= `Branch;
								next_inst_in_delayslot_o <= `InDelaySlot;
							end
						end
						`EXE_REGIMM_TGEI: begin
							alusel_o <= `EXE_RES_NOP;
							aluop_o <= `EXE_OP_EXCEPTION_TGEI;
							instvalid <= `InstValid;
							we_o <= `WriteDisable;
							reg1_re_o <= `ReadEnable;
							reg2_re_o <= `ReadDisable;
							imm <= {{16{inst_i[15]}}, inst_i[15:0]};
						end
						`EXE_REGIMM_TGEIU: begin
							alusel_o <= `EXE_RES_NOP;
							aluop_o <= `EXE_OP_EXCEPTION_TGEIU;
							instvalid <= `InstValid;
							we_o <= `WriteDisable;
							reg1_re_o <= `ReadEnable;
							reg2_re_o <= `ReadDisable;
							imm <= {{16{inst_i[15]}}, inst_i[15:0]};
						end
						`EXE_REGIMM_TLTI: begin
							alusel_o <= `EXE_RES_NOP;
							aluop_o <= `EXE_OP_EXCEPTION_TLTI;
							instvalid <= `InstValid;
							we_o <= `WriteDisable;
							reg1_re_o <= `ReadEnable;
							reg2_re_o <= `ReadDisable;
							imm <= {{16{inst_i[15]}}, inst_i[15:0]};
						end
						`EXE_REGIMM_TLTIU: begin
							alusel_o <= `EXE_RES_NOP;
							aluop_o <= `EXE_OP_EXCEPTION_TLTIU;
							instvalid <= `InstValid;
							we_o <= `WriteDisable;
							reg1_re_o <= `ReadEnable;
							reg2_re_o <= `ReadDisable;
							imm <= {{16{inst_i[15]}}, inst_i[15:0]};
						end
						`EXE_REGIMM_TEQI: begin
							alusel_o <= `EXE_RES_NOP;
							aluop_o <= `EXE_OP_EXCEPTION_TEQI;
							instvalid <= `InstValid;
							we_o <= `WriteDisable;
							reg1_re_o <= `ReadEnable;
							reg2_re_o <= `ReadDisable;
							imm <= {{16{inst_i[15]}}, inst_i[15:0]};
						end
						`EXE_REGIMM_TNEI: begin
							alusel_o <= `EXE_RES_NOP;
							aluop_o <= `EXE_OP_EXCEPTION_TNEI;
							instvalid <= `InstValid;
							we_o <= `WriteDisable;
							reg1_re_o <= `ReadEnable;
							reg2_re_o <= `ReadDisable;
							imm <= {{16{inst_i[15]}}, inst_i[15:0]};
						end
						default: begin
						end
					endcase
				end
				`EXE_ADDI: begin
					alusel_o <= `EXE_RES_MATH;
					aluop_o <= `EXE_OP_MATH_ADD;
					instvalid <= `InstValid;
					we_o <= `WriteEnable;
					waddr_o <= r_read2_address;
					reg1_re_o <= `ReadEnable;
					reg2_re_o <= `ReadDisable;
					imm <= {{16{i_imm[15]}}, i_imm};
				end
				`EXE_ADDIU: begin
					alusel_o <= `EXE_RES_MATH;
					aluop_o <= `EXE_OP_MATH_ADDU;
					instvalid <= `InstValid;
					we_o <= `WriteEnable;
					waddr_o <= r_read2_address;
					reg1_re_o <= `ReadEnable;
					reg2_re_o <= `ReadDisable;
					imm <= {{16{i_imm[15]}}, i_imm};
				end
				`EXE_SLTI: begin
					alusel_o <= `EXE_RES_MATH;
					aluop_o <= `EXE_OP_MATH_SLT;
					instvalid <= `InstValid;
					we_o <= `WriteEnable;
					waddr_o <= r_read2_address;
					reg1_re_o <= `ReadEnable;
					reg2_re_o <= `ReadDisable;
					imm <= {{16{i_imm[15]}}, i_imm};
				end
				`EXE_SLTIU: begin
					alusel_o <= `EXE_RES_MATH;
					aluop_o <= `EXE_OP_MATH_SLTU;
					instvalid <= `InstValid;
					we_o <= `WriteEnable;
					waddr_o <= r_read2_address;
					reg1_re_o <= `ReadEnable;
					reg2_re_o <= `ReadDisable;
					imm <= {{16{i_imm[15]}}, i_imm};
				end
				`EXE_ANDI: begin
					alusel_o <= `EXE_RES_LOGIC;
					aluop_o <= `EXE_OP_LOGIC_AND;
					instvalid <= `InstValid;
					we_o <= `WriteEnable;
					waddr_o <= i_write_address;
					reg1_re_o <= `ReadEnable;
					reg2_re_o <= `ReadDisable;
					imm <= {16'h0, i_imm};
				end
				`EXE_ORI: begin
					alusel_o <= `EXE_RES_LOGIC;
					aluop_o <= `EXE_OP_LOGIC_OR;
					instvalid <= `InstValid;
					we_o <= `WriteEnable;
					waddr_o <= i_write_address;
					reg1_re_o <= `ReadEnable;
					reg2_re_o <= `ReadDisable;
					imm <= {16'h0, i_imm};
				end
				`EXE_XORI: begin
					alusel_o <= `EXE_RES_LOGIC;
					aluop_o <= `EXE_OP_LOGIC_XOR;
					instvalid <= `InstValid;
					we_o <= `WriteEnable;
					waddr_o <= i_write_address;
					reg1_re_o <= `ReadEnable;
					reg2_re_o <= `ReadDisable;
					imm <= {16'h0, i_imm};
				end
				`EXE_LUI: begin
					alusel_o <= `EXE_RES_LOGIC;
					aluop_o <= `EXE_OP_LOGIC_OR;
					instvalid <= `InstValid;
					we_o <= `WriteEnable;
					waddr_o <= i_write_address;
					reg1_re_o <= `ReadEnable;
					reg2_re_o <= `ReadDisable;
					imm <= {i_imm, 16'h0};
				end
				`EXE_SPECIAL2: begin
					case (op_subclass)
						`EXE_SPC2_MUL: begin
							alusel_o <= `EXE_RES_MUL;
							aluop_o <= `EXE_OP_MATH_MUL;
							instvalid <= `InstValid;
							we_o <= `WriteEnable;
							reg1_re_o <= `ReadEnable;
							reg2_re_o <= `ReadEnable;
						end
						`EXE_SPC2_CLZ: begin
							alusel_o <= `EXE_RES_MATH;
							aluop_o <= `EXE_OP_MATH_CLZ;
							instvalid <= `InstValid;
							we_o <= `WriteEnable;
							reg1_re_o <= `ReadEnable;
							reg2_re_o <= `ReadDisable;
						end
						`EXE_SPC2_CLO: begin
							alusel_o <= `EXE_RES_MATH;
							aluop_o <= `EXE_OP_MATH_CLO;
							instvalid <= `InstValid;
							we_o <= `WriteEnable;
							reg1_re_o <= `ReadEnable;
							reg2_re_o <= `ReadDisable;
						end
						`EXE_SPC2_MADD: begin
							alusel_o <= `EXE_RES_MUL;
							aluop_o <= `EXE_OP_MATH_MADD;
							instvalid <= `InstValid;
							we_o <= `WriteDisable;
							reg1_re_o <= `ReadEnable;
							reg2_re_o <= `ReadEnable;
						end
						`EXE_SPC2_MADDU: begin
							alusel_o <= `EXE_RES_MUL;
							aluop_o <= `EXE_OP_MATH_MADDU;
							instvalid <= `InstValid;
							we_o <= `WriteDisable;
							reg1_re_o <= `ReadEnable;
							reg2_re_o <= `ReadEnable;
						end
						`EXE_SPC2_MSUB: begin
							alusel_o <= `EXE_RES_MUL;
							aluop_o <= `EXE_OP_MATH_MSUB;
							instvalid <= `InstValid;
							we_o <= `WriteDisable;
							reg1_re_o <= `ReadEnable;
							reg2_re_o <= `ReadEnable;
						end
						`EXE_SPC2_MSUBU: begin
							alusel_o <= `EXE_RES_MUL;
							aluop_o <= `EXE_OP_MATH_MSUBU;
							instvalid <= `InstValid;
							we_o <= `WriteDisable;
							reg1_re_o <= `ReadEnable;
							reg2_re_o <= `ReadEnable;
						end
					endcase
				end
				`EXE_LB: begin
					alusel_o <= `EXE_RES_LOAD_STORE;
					aluop_o <= `EXE_OP_LOAD_STORE_LB;
					instvalid <= `InstValid;
					we_o <= `WriteEnable;
					waddr_o <= i_write_address;
					reg1_re_o <= `ReadEnable;
					reg2_re_o <= `ReadDisable;
				end
				`EXE_LH: begin
					alusel_o <= `EXE_RES_LOAD_STORE;
					aluop_o <= `EXE_OP_LOAD_STORE_LH;
					instvalid <= `InstValid;
					we_o <= `WriteEnable;
					waddr_o <= i_write_address;
					reg1_re_o <= `ReadEnable;
					reg2_re_o <= `ReadDisable;
				end
				`EXE_LWL: begin
					alusel_o <= `EXE_RES_LOAD_STORE;
					aluop_o <= `EXE_OP_LOAD_STORE_LWL;
					instvalid <= `InstValid;
					we_o <= `WriteEnable;
					waddr_o <= i_write_address;
					reg1_re_o <= `ReadEnable;
					reg2_re_o <= `ReadEnable;
				end
				`EXE_LW: begin
					alusel_o <= `EXE_RES_LOAD_STORE;
					aluop_o <= `EXE_OP_LOAD_STORE_LW;
					instvalid <= `InstValid;
					we_o <= `WriteEnable;
					waddr_o <= i_write_address;
					reg1_re_o <= `ReadEnable;
					reg2_re_o <= `ReadDisable;
				end
				`EXE_LBU: begin
					alusel_o <= `EXE_RES_LOAD_STORE;
					aluop_o <= `EXE_OP_LOAD_STORE_LBU;
					instvalid <= `InstValid;
					we_o <= `WriteEnable;
					waddr_o <= i_write_address;
					reg1_re_o <= `ReadEnable;
					reg2_re_o <= `ReadDisable;
				end
				`EXE_LHU: begin
					alusel_o <= `EXE_RES_LOAD_STORE;
					aluop_o <= `EXE_OP_LOAD_STORE_LHU;
					instvalid <= `InstValid;
					we_o <= `WriteEnable;
					waddr_o <= i_write_address;
					reg1_re_o <= `ReadEnable;
					reg2_re_o <= `ReadDisable;
				end
				`EXE_LWR: begin
					alusel_o <= `EXE_RES_LOAD_STORE;
					aluop_o <= `EXE_OP_LOAD_STORE_LWR;
					instvalid <= `InstValid;
					we_o <= `WriteEnable;
					waddr_o <= i_write_address;
					reg1_re_o <= `ReadEnable;
					reg2_re_o <= `ReadEnable;
				end
				`EXE_SB: begin
					alusel_o <= `EXE_RES_LOAD_STORE;
					aluop_o <= `EXE_OP_LOAD_STORE_SB;
					instvalid <= `InstValid;
					we_o <= `WriteDisable;
					reg1_re_o <= `ReadEnable;
					reg2_re_o <= `ReadEnable;
				end
				`EXE_SH: begin
					alusel_o <= `EXE_RES_LOAD_STORE;
					aluop_o <= `EXE_OP_LOAD_STORE_SH;
					instvalid <= `InstValid;
					we_o <= `WriteDisable;
					reg1_re_o <= `ReadEnable;
					reg2_re_o <= `ReadEnable;
				end
				`EXE_SWL: begin
					alusel_o <= `EXE_RES_LOAD_STORE;
					aluop_o <= `EXE_OP_LOAD_STORE_SWL;
					instvalid <= `InstValid;
					we_o <= `WriteDisable;
					reg1_re_o <= `ReadEnable;
					reg2_re_o <= `ReadEnable;
				end
				`EXE_SW: begin
					alusel_o <= `EXE_RES_LOAD_STORE;
					aluop_o <= `EXE_OP_LOAD_STORE_SW;
					instvalid <= `InstValid;
					we_o <= `WriteDisable;
					reg1_re_o <= `ReadEnable;
					reg2_re_o <= `ReadEnable;
				end
				`EXE_SWR: begin
					alusel_o <= `EXE_RES_LOAD_STORE;
					aluop_o <= `EXE_OP_LOAD_STORE_SWR;
					instvalid <= `InstValid;
					we_o <= `WriteDisable;
					reg1_re_o <= `ReadEnable;
					reg2_re_o <= `ReadEnable;
				end
				`EXE_LL: begin
					alusel_o <= `EXE_RES_LOAD_STORE;
					aluop_o <= `EXE_OP_LOAD_STORE_LL;
					instvalid <= `InstValid;
					we_o <= `WriteEnable;
					waddr_o <= i_write_address;
					reg1_re_o <= `ReadEnable;
					reg2_re_o <= `ReadDisable;
				end
				`EXE_SC: begin
					alusel_o <= `EXE_RES_LOAD_STORE;
					aluop_o <= `EXE_OP_LOAD_STORE_SC;
					instvalid <= `InstValid;
					we_o <= `WriteEnable;
					waddr_o <= i_write_address;
					reg1_re_o <= `ReadEnable;
					reg2_re_o <= `ReadEnable;
				end
				`EXE_PREF: begin
					// 不存在 cache，此命令暂时当做 NOP 处理
				end
				default: begin
				end
			endcase
			if (inst_i[31:21] == 11'b01000000000 && inst_i[10:0] == 11'b00000000000) begin
				alusel_o <= `EXE_RES_MOVE;
				aluop_o <= `EXE_OP_MOVE_MFC0;
				instvalid <= `InstValid;
				we_o <= `WriteEnable;
				waddr_o <= op_rt;
				reg1_re_o <= `ReadDisable;
				reg2_re_o <= `ReadDisable;
			end
			if (inst_i[31:21] == 11'b01000000100 && inst_i[10:0] == 11'b00000000000) begin
				alusel_o <= `EXE_RES_MOVE;
				aluop_o <= `EXE_OP_MOVE_MTC0;
				instvalid <= `InstValid;
				we_o <= `WriteDisable;
				reg1_re_o <= `ReadEnable;
				reg1_addr_o <= op_rt;
				reg2_re_o <= `ReadDisable;
			end
			if (inst_i == `EXE_ERET) begin
				alusel_o <= `EXE_RES_NOP;
				aluop_o <= `EXE_OP_EXCEPTION_ERET;
				instvalid <= `InstValid;
				we_o <= `WriteDisable;
				reg1_re_o <= `ReadDisable;
				reg2_re_o <= `ReadDisable;
				excepttype_is_eret <= 1'b1;
			end
		end
	end

	// 源操作数 1
	always @(*) begin
		stallreq_for_reg1_loadrelate <= `StallDisable;
		if (rst == `RstEnable) begin
			reg1_o <= `ZeroWord;
		end
		else if (reg1_re_o == `ReadEnable) begin
			if (pre_inst_is_load == 1'b1 && ex_waddr_i == reg1_addr_o) begin
				stallreq_for_reg1_loadrelate <= `StallEnable;
			end
			else if (ex_we_i == `WriteEnable && ex_waddr_i == reg1_addr_o) begin
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
		stallreq_for_reg2_loadrelate <= `StallDisable;
		if (rst == `RstEnable) begin
			reg2_o <= `ZeroWord;
		end
		else if (reg2_re_o == `ReadEnable) begin
			if (pre_inst_is_load == 1'b1 && ex_waddr_i == reg2_addr_o) begin
				stallreq_for_reg2_loadrelate <= `StallEnable;
			end
			else if (ex_we_i == `WriteEnable && ex_waddr_i == reg2_addr_o) begin
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

	always @(*) begin
		if (rst == `RstEnable) begin
			is_in_delayslot_o <= `NotInDelaySlot;
		end
		else begin
			is_in_delayslot_o <= is_in_delayslot_i;
		end
	end

endmodule