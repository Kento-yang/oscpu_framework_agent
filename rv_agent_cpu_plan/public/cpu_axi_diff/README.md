# cpu_axi_diff 公开 RTL 骨架

本目录是从 `projects/cpu_axi_diff/vsrc` 抽取的**标准模块输入件**，用于给其他 Agent 出题：固定接口与集成层，留出可实现的逻辑空间。骨架已用 Verilator 4.204 做过 lint（与构建脚本相同的告警抑制下 0 error），但**功能未实现**，直接运行不会通过用例。

## 目录结构

```text
cpu_axi_diff/
├── SimTop.sv              # 固定：difftest 顶层接口
├── top.sv                 # 固定：core + I/D cache + 仲裁 + uni2axi 的集成
├── defines.sv             # 固定：位宽、编码、CSR/异常相关宏
├── uni2axi.sv             # 固定：UNI 到 AXI4 的转换
├── stdlib/                # 固定：axi4_if / uni_if / mux / reg / reset
├── core/                  # 待实现：CPU 核内部模块（仅保留端口）
│   ├── core_top.sv
│   ├── ifu/ifu.sv
│   ├── idu/{idu,idu_normal,idu_system}.sv
│   ├── exu/exu.sv
│   ├── exu/div/div.sv
│   ├── exu/mult/{mult.sv,booth/booth.sv,wallace/wallace_tree_33.sv,
│   │              wallace/adder/{csa_nbit,rca_nbit}.sv}
│   ├── lsu/lsu.sv
│   ├── other/{bru,clint}.sv
│   ├── csr_file/csrfile.sv
│   ├── regfile/{regfile,bypass}.sv
│   └── wbu/{wbu,iru}.sv
└── cache/                 # 待实现：I/D cache（仅保留端口）
    ├── iCache_wrapper.sv
    ├── dCache_wrapper.sv
    ├── cache/{iCache,dCache}.sv
    └── cache/cache_lib/{iCache_tag_ary,dCache_tag_ary,data_ary}.sv
```

`cache/cache/cache_lib/S011HD1P_X32Y2D128_BW.sv` 是厂商 SRAM 行为模型，**保持原样，不要修改**；它是 `data_ary.sv` 的底层存储单元。

## 固定文件（禁止修改）

- `SimTop.sv`：difftest 顶层，端口必须与任务卡完全一致。
- `top.sv`：固定集成关系，已实例化 `core_top`、`iCache_wrapper`、`dCache_wrapper`、UNI 仲裁和 `uni2axi`。
- `defines.sv`：宏与编码定义。
- `uni2axi.sv`：总线转换。
- `stdlib/**`：接口与基础库；`uni_if.Slave/Master`、`axi4_if` 的 modport 是模块间连接契约。
- `cache/cache/cache_lib/S011HD1P_X32Y2D128_BW.sv`：SRAM 厂商模型。
- 所有骨架文件中**已有的模块名、参数列表、端口方向/位宽/类型**。

允许新增内部信号、内部子模块和新的 `.sv` 文件；不得修改上述固定文件或改动既有端口契约。

## 需要实现的模块

| 模块 | 位置 | 职责 |
|---|---|---|
| `core_top` | `core/core_top.sv` | 连接 IFU/IDU/EXU/LSU/WBU 五级流水线、REGFILE/BYPASS/CSR/CLINT/IRU/BRU；对外提供 I/D cache 的 `uni_if` Master 端口、cache 维护信号、UART/difftest 观察信号 |
| `ifu` | `core/ifu/ifu.sv` | 维护 PC，经 `iCacheIf_M` 取指，处理 flush/分支重定向，输出 PC 与指令 |
| `idu` | `core/idu/idu.sv` | 译码与流水控制：寄存器/CSR 读地址、执行/访存/写回控制、分支信息、握手 |
| `idu_normal` | `core/idu/idu_normal.sv` | R/I/U/J/B 型普通指令译码 |
| `idu_system` | `core/idu/idu_system.sv` | ecall/mret/csrrw/csrrs/csrrc 等 SYSTEM 指令译码 |
| `exu` | `core/exu/exu.sv` | 整数 ALU、移位、比较、乘除法与 CSR 操作数选择 |
| `div` | `core/exu/div/div.sv` | 多周期有符号/无符号除法器（start/busy/end 握手） |
| `mult` | `core/exu/mult/mult.sv` | 64 位乘法器，输出高/低 64 位结果 |
| `booth` | `core/exu/mult/booth/booth.sv` | Booth 3-bit 编码 |
| `wallace_tree_33` | `core/exu/mult/wallace/wallace_tree_33.sv` | 33 个部分积的 Wallace 树压缩 |
| `csa_nbit` / `rca_nbit` | `core/exu/mult/wallace/adder/` | 进位保留加法器 / 行波进位加法器 |
| `lsu` | `core/lsu/lsu.sv` | load/store、CLINT MMIO、fence.i、异常/中断清空 |
| `bru` | `core/other/bru.sv` | 分支解析与下一 PC，产生 if/id nop |
| `clint` | `core/other/clint.sv` | mtime/mtimecmp MMIO 与 MTIP |
| `csrfile` | `core/csr_file/csrfile.sv` | CSR 读写与 difftest 影子 CSR |
| `regfile` | `core/regfile/regfile.sv` | 32×64-bit 寄存器堆，双读单写 |
| `bypass` | `core/regfile/bypass.sv` | 旁路选择、load-use/结构冒险停顿 |
| `wbu` | `core/wbu/wbu.sv` | 写回、提交、difftest 提交包 |
| `iru` | `core/wbu/iru.sv` | ecall/mret/中断处理与 mstatus/mepc/mcause 更新 |
| `iCache` | `cache/cache/iCache.sv` | 指令 cache（参考实现：4-way、128 组、16 B line） |
| `dCache` | `cache/cache/dCache.sv` | 数据 cache（参考实现：4-way、128 组、16 B line，write-back + write-allocate） |
| `iCache_wrapper` / `dCache_wrapper` | `cache/` | 按地址 bit31（dCache 还受 `i_clean` 影响）区分 cacheable/uncacheable 通路 |
| `iCache_tag_ary` / `dCache_tag_ary` | `cache/cache/cache_lib/` | tag/valid(/dirty) 数组，128 深度 |
| `data_ary` | `cache/cache/cache_lib/data_ary.sv` | 128×128-bit 数据数组（两片 SRAM 拼接），支持 16 字节写掩码 |

## 给 Agent 的题目描述（可直接使用）

> 你需要在 `rv_agent_cpu_plan/public/cpu_axi_diff` 提供的固定骨架上，实现一个单发射、顺序提交的 64-bit RV64IM 五级流水线 CPU，包含独立 I/D cache、Zicsr、CLINT 定时器、ECALL/MRET 和 `0x7b` UART 打印。`SimTop`、`top`、`defines`、`uni2axi`、`stdlib` 以及所有骨架模块的模块名、参数和端口已经固定，不能修改；你只需在 `core/` 和 `cache/` 下的 TODO 位置实现逻辑，也可以新增内部模块和 `.sv` 文件。完成后必须通过 `bin/non-output/cpu-tests` 33/33、`bin/non-output/riscv-tests` 50/50（每条 `HIT GOOD TRAP` 且无 difftest mismatch），并在 2000 万周期内通过 yield/time/interrupt、在 5000 万周期内完成 rt-thread 启动（判定标准见任务卡）。不得硬编码测试名、PC 或终止地址，不得修改 difftest 参考模型与验收脚本。

## 编译与验证

先按 `rv_agent_cpu_plan/README.md` 的「使用流程」准备依赖与环境变量，然后：

```bash
cd ~/oscpu-dyw
mkdir -p projects/<agent_name>/vsrc
cp -r rv_agent_cpu_plan/public/cpu_axi_diff/. projects/<agent_name>/vsrc/

mkdir -p projects/<agent_name>/build
cp projects/<agent_name>/vsrc/SimTop.sv projects/<agent_name>/build/SimTop.v

export NEMU_HOME=$PWD/libraries/NEMU
./build.sh -e <agent_name> -d -b -m "EMU_TRACE=1 WITH_DRAMSIM3=1"
```

运行 83 个基础用例、4 个 custom-output 用例以及 IPC 基准的完整命令见 `rv_agent_cpu_plan/README.md` 的「使用流程」。

## 验收标准

- 基础用例：83/83 `HIT GOOD TRAP`，无 `difftest mismatch`、无超时、无 BAD TRAP/ABORT；加上 4 个 custom-output 后总计 **87/87**。
- custom-output（不终止用例，用 `-C` 固定周期点）：
  - `yield-test`：20,000,000 周期内出现 AM 头信息并持续输出 `y`；
  - `time-test`：20,000,000 周期内 RTC 递增到至少 19 秒；
  - `interrupt-test`：20,000,000 周期内 `t`（timer）与 `y`（yield）交替出现；
  - `rt-thread`：50,000,000 周期内输出 RT-Thread Banner、`Hello OSCPU!`、`msh />`，线程计数正常运行。
- IPC 基准（同一环境、`WITH_DRAMSIM3=1`）：见 `rv_agent_cpu_plan/README.md` 的「IPC 基准数据」逐用例表；分类均值 cpu-tests 0.218538、riscv-tests 0.066065。

## 注意

- 骨架中空的 `logic` 输出在编译时可能产生 UNDRIVEN 警告，属正常现象；实现逻辑后应消除。
- 不要修改 `libraries/difftest`、`build.sh` 或验收脚本；无 root 环境的头文件/库路径适配见 `README.md` 的使用流程。
- 建议在仓库根目录放置 `.no_commit`，避免 `build.sh` 的 tracer 自动提交。
