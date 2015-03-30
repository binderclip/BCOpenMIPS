交叉编译工具链

关键词：mips cross toolchain for mac

## 入口

从大学的 FPGA 项目入手

从 OpenWRT 项目入手

这里有一些，包括 ARM，但是没有 MIPS 的 [homebrew-gcc_cross_compilers/arm-elf-gcc.rb at master · sevki/homebrew-gcc_cross_compilers](https://github.com/sevki/homebrew-gcc_cross_compilers/blob/master/arm-elf-gcc.rb)

## 资源

- [MIPS Cross-Compilers](http://www-inst.eecs.berkeley.edu/~cs162/sp08/Nachos/xgcc.html)
- [Cross-compiling user programs](http://www-inst.eecs.berkeley.edu/~cs162/sp08/Nachos/cross-compiler.html)


- 推荐用虚拟机，后面的似乎不行 [linux - Best way to build cross toolchains on Mac OS X - Stack Overflow](http://stackoverflow.com/questions/6396165/best-way-to-build-cross-toolchains-on-mac-os-x)
- 要用 GCC 来编译 GCC？[Building a cross compile of GCC for MIPS on OS X - The AirPort Wiki](http://www.theairportwiki.com/index.php/Building_a_cross_compile_of_GCC_for_MIPS_on_OS_X)
- 制作 AVR/ARM 的[AVR/ARM Cross Toolchains for OS X](http://www.ethernut.de/en/documents/cross-toolchain-osx.html)
- 这个好像也有用[lion - How do I install GCC via Homebrew? - Ask Different](http://apple.stackexchange.com/questions/38222/how-do-i-install-gcc-via-homebrew)
- 这里好像有用啊 [crosstool-howto](http://kegel.com/crosstool/current/doc/crosstool-howto.html)


- 不知道有没有用 [Guylhem's most recent funny hacks & thoughts — Mips toolchain for OSX](http://en.blog.guylhem.net/post/9130880536/mips-toolchain-for-osx)


## 疑问

交叉编译的原理是？如何去构建一个交叉编译的环境？不同时候各自需要什么样的编译环境呢？
在 mac osx 下使用要怎么办呢？

[Cross compiler - Wikipedia, the free encyclopedia](http://en.wikipedia.org/wiki/Cross_compiler)