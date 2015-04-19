测试的步骤

- id
	- inst_i 检测读入的指令是否正确
	- reg1_o & reg2_o 重要
		- 如果不正确就去测试
		- reg1_re_o & reg2_re_o
		- imm
		- reg1_data_i & reg2_data_i
	- waddr_o 和 we_o
- ex
	- reg1_i & reg2_i 输入
	- wdata_o 运算结果
- regfile
	- 主要会用到前四个寄存器