计算机组成与设计 P58 图 2-6


## 逻辑操作指令

### add or xor nor

```
SPECIAL(000000) rs rt rd 0000 AND/OR/XOR/NOR
```

```
rd <- rs AND/OR/XOR/NOR rt
```

### addi ori xori

```
ADDI/ORI/XORI rs rt immediate
```

### lui

```
ADDI/ORI/XORI 0 rt immediate
```

```
rt <- immediate || 0^16
```

把立即数保存在高 16 位，并用 0 填充低 16 位

## 移位操作

### sll sra srl

这里的 sa 不是寄存器名字，而像是一个立即数

```
SPECIAL 000000 rt rd sa SLL/SRA/SRL
```

```
rd <- rt <</>> sa (logic/arithmetic)
```

### sllv srav srlv

```
SPECIAL rs rt rd 000000 SLLV/SRAV/SRLV
```

```
rd <- rt <</>> rs[4:0] (logic/arithmetic)
```
