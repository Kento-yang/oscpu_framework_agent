EDA 环境使用介绍

本环境预装了 Synopsys / Cadence / Mentor 三套主流 EDA 工具链,以及 Python、GCC 等开发环境。

本文档简要介绍有哪些软件、哪些可用、如何正确调用,以及几点使用提示。

---

## 1. 环境概览


| 项目     | 说明                                                                     |
| -------- | ------------------------------------------------------------------------ |
| 操作系统 | CentOS 7.9 用户态(glibc2.17),内核 6.14(Ubuntu 内核)—— 这是一个混合环境 |
| Shell    | bash;登录时自动 source/etc/profile.d/eda-env.sh,工具路径和环境变量已配好 |
| EDA 目录 | /opt/eda/{Synopsys,Cadence,Mentor}                                       |
| 授权     | 各工具的授权服务已随容器自动就绪,见第 6 节                               |

首次使用无需任何配置,直接开跑即可。

---

## 2. 基础开发环境(必要工具)


| 工具    | 版本    | 状态 | 备注                                  |
| ------- | ------- | ---- | ------------------------------------- |
| gcc/g++ | 4.8.5   | ✅   | CentOS 原生,EDA 工具的编译后端        |
| make    | 3.82    | ✅   |                                       |
| perl    | 5.16.3  | ✅   | EDA 脚本依赖                          |
| git     | 1.8.3.1 | ✅   |                                       |
| python3 | 3.12.15 | ✅   | 推荐使用;路径/opt/dsbench/bin/python3 |
| python  | 2.7.5   | ✅   | CentOS 原生,兼容旧脚本                |
| python2 | 2.7.5   | ✅   | 同上                                  |

> 需要 Python 3 特性时请用 python3;python / python2 为 2.7,主要用于兼容旧脚本。 Python3 默认没有 numpy 等第三方库,需要时自行安装或用系统工具替代。

---

## 3. Synopsys 工具

> 全部工具已验证可用。


| 工具                                              | 二进制     | 用途               | 状态 | 典型用法                                                                         |
| ------------------------------------------------- | ---------- | ------------------ | ---- | -------------------------------------------------------------------------------- |
| VCS                                               | vcs/vlogan | 仿真               | ✅   | 见下方示例                                                                       |
| DC(Design Compiler)                               | dc\_shell  | 逻辑综合           | ✅   | dc\_shell -f run.tcl -output\_log\_file dc.log                                   |
| PrimeTime                                         | pt\_shell  | 静态时序分析(STA)  | ✅   | pt\_shell -f run.tcl -output\_log\_file pt.log                                   |
| Formality                                         | fm\_shell  | 等价性验证(LEC)    | ✅   | fm\_shell -file run.tcl -overwrite(注意是-file,不是 -f)                          |
| ICC                                               | icc\_shell | 布局布线(P&R)      | ✅   | icc\_shell -f run.tcl -output\_log\_file icc.log                                 |
| SpyGlass                                          | spyglass   | lint / CDC / RDC   | ✅   | 项目式 GUI;spyglass -version验版本                                               |
| Verdi                                             | verdi      | 波形/调试          | ✅   | verdi -sv top.sv &(GUI)                                                          |
| StarRC                                            | StarXtract | 寄生参数提取       | ✅   | 不在 PATH,需手动加:export PATH=/opt/eda/Synopsys/starrc/O-2018.06-SP1/bin:\$PATH |
| HSPICE / XA                                       | hspice/xa  | 电路/晶体管级仿真  | 在位 | —                                                                               |
| Custom Compiler / SiliconSmart / Library Compiler | —         | 定制/特征化/库编译 | 在位 | —                                                                               |

> P&R 的二进制叫 icc\_shell,环境里没有 icc2\_shell 这个命令。

### VCS 最小示例

```
# filelist.f 里列出 .sv 文件(建议绝对路径)
vcs -sverilog -full64 -timescale=1ns/1ps -top axi4lite_tb -f filelist.f -o simv
./simv                     # 运行
./simv +SEED=7             # 传随机种子(测试平台里用 $value$plusargs 读)
```

---

## 4. Cadence 工具

> 数字流程的综合 / 验证 / STA 建议优先使用 Synopsys 的 DC / Formality / PrimeTime,P&R 使用 Innovus 19.1。


| 工具          | 二进制    | 用途              | 状态     | 典型用法                                          |
| ------------- | --------- | ----------------- | -------- | ------------------------------------------------- |
| Innovus       | innovus   | 布局布线(P&R)     | ✅可用   | innovus -init run.tcl -log innovus.log -overwrite |
| Xcelium       | xrun      | 仿真              | 暂不支持 | 编译可用,仿真暂不支持                             |
| Incisive      | ncverilog | 仿真(旧)          | 在位     | —                                                |
| Genus         | genus     | 逻辑综合          | 暂不支持 | 建议使用 Synopsys DC                              |
| Conformal LEC | lec       | 等价性验证        | 暂不支持 | 建议使用 Synopsys Formality                       |
| Tempus        | tempus    | STA               | 暂不支持 | 建议使用 Synopsys PrimeTime                       |
| Voltus        | voltus    | 电源完整性(IR/EM) | 可启动   | voltus -init run.tcl(全流程需 PDK)                |
| QRC / Quantus | qrc       | 寄生参数提取      | 可启动   | 需工艺文件                                        |
| Spectre       | spectre   | 模拟电路仿真      | 在位     | —                                                |
| Virtuoso      | IC618     | 模拟/版图设计     | 在位     | GUI                                               |

---

## 5. Mentor 工具


| 工具    | 二进制  | 用途              | 状态   | 典型用法                                                          |
| ------- | ------- | ----------------- | ------ | ----------------------------------------------------------------- |
| Calibre | calibre | 物理验证(DRC/LVS) | ✅可用 | calibre -drc -hier -f rules.file;calibre -lvs -hier -f rules.file |

> 节点锁定授权,开箱即用。

---

## 6. License 环境变量速查

```
# Synopsys
SNPSLMD_LICENSE_FILE=27001@dsec-uvm-instance:27000@dsec-uvm-instance
# Cadence
CDS_LIC_FILE=5280@dsec-uvm-instance:/opt/eda/Cadence/license/license.dat
# Mentor Calibre(节点锁定)
MGLS_LICENSE_FILE=/opt/eda/Mentor/license/license.dat
```

这些已由 /etc/profile.d/eda-env.sh 设好,一般不用手动改。

工具目录变量也已设好:\$VCS\_HOME \$DC\_HOME \$PT\_HOME \$FM\_HOME \$ICC\_HOME \$SPYGLASS\_HOME \$VERDI\_HOME \$CALIBRE\_HOME \$QRC\_HOME 等。

---

## 7. 使用提示

### 提示 1:命令名 / 参数差异

* P&R 用 icc\_shell(没有 icc2\_shell);
* Formality 的脚本参数是 -file(不是 -f),且不支持 -output\_log\_file(日志默认写到 fm\_shell.log 和 stdout);
* StarRC 的 StarXtract/grdgenxo 不在 PATH,需手动加路径。

### 提示 2:未内置工艺库(PDK)

环境默认未附带 .lib / .lef / .db 标准单元库。因此:

* 逻辑仿真 / RTL 综合(映射到 GTECH)/ 等价验证可直接跑;
* 后端物理流程(Innovus/ICC 布局布线、StarRC 提取、Tempus STA、Voltus、QRC、Calibre DRC)需要先准备一个工艺库(如 Nangate45、SAED、Sky130)。

---

## 8. 快速上手小结


| 你想做什么   | 用什么       | 一句话命令                                                     |
| ------------ | ------------ | -------------------------------------------------------------- |
| RTL 仿真     | VCS          | vcs -sverilog -full64 -top<tb> -f filelist.f -o simv && ./simv |
| 逻辑综合     | DC           | dc\_shell -f run.tcl -output\_log\_file dc.log                 |
| 静态时序分析 | PrimeTime    | pt\_shell -f run.tcl -output\_log\_file pt.log                 |
| 等价性验证   | Formality    | fm\_shell -file run.tcl -overwrite                             |
| 布局布线     | Innovus 19.1 | innovus -init run.tcl -log run.log -overwrite                  |
| 物理验证     | Calibre      | calibre -drc -hier -f rules.file                               |
| 写脚本       | Python3      | python3 script.py                                              |

> VCS 的最小可运行示例见第 3 节。
>
