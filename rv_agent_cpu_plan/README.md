# RVA-01 · 带 I/D Cache 的 RV64IM 五级流水线 CPU

本目录是一个按 [DigitallCDesignBenchmark T09](../../DigitallCDesignBenchmark/benchmark/tasks/T09) 题目须知组织的 CPU 任务包，用于让不同 Agent 编写 RTL，并用本仓库已经跑通的 `oscpu-framework` difftest 流程做验证。任务卡的能力基线是 `projects/cpu_axi_diff_cache` 的参考快照（`origin/CPUwithCache` 提交 `3cb21fd`），该快照在本环境实测 **83/83** 通过（`cpu-tests` 33/33，`riscv-tests` 50/50）。

任务元数据见 [`task.yaml`](task.yaml)。

## 状态

- **参考设计功能资格**：已在本仓库验证 83/83；2026-11-17 复跑结果为 PASS=83、FAIL=0（此前两次完整回归一致，单次约 59 秒）。
- **本任务包**：`draft`。F 组（83 个基础用例 + difftest 一致性）可直接由现有流程自动判定；P 组（流水线/缓存/总线专项）目前是计划项，仓库尚未提供对应检查器。
- **公开 testbench**：`public/tb.sv` 与 `public/tb_cpu_elf.sv` 是自包含的 AXI 冒烟平台，已用参考设计在 2026-11-17 验证：`tb_smoke` 输出 `PUBLIC_PASS commits=64`；`tb_elf` 通过 `add-riscv-tests`、`dummy/load-store/matrix-mul/quick-sort cpu-tests`，包含 AXI 响应延迟与背压条件。Verilator 4.204 不支持 `--binary`/`--timing`，平台用配套的 C++ main 驱动时钟；权威门禁仍是 83 个用例。

## 文件

- [`task.md`](task.md)：冻结任务卡，定义固定 `SimTop` 接口、ISA/CSR/异常范围、提交观察钩子、流水线与缓存要求、评分权重。
- [`acceptance.md`](acceptance.md)：验收计划，包含实际命令、通过标准、83 个用例的分组、P 组计划项和参考资格记录。
- [`task.yaml`](task.yaml)：机器可读元数据。
- [`FREEZE.json`](FREEZE.json)：任务级冻结/来源记录（草案）。
- [`public/tb.sv`](public/tb.sv)：固定接口 + 64 条 ADDI 提交序列冒烟。
- [`public/tb_cpu_elf.sv`](public/tb_cpu_elf.sv)：ELF/bin 加载平台，支持 AXI 响应延迟与背压。
- [`public/axi_mem_model.sv`](public/axi_mem_model.sv)：256 KiB AXI4 从设备模型。
- [`public/difftest_stub.sv`](public/difftest_stub.sv)：公开冒烟使用的 difftest 空壳模块与统计包。
- [`public/tb_smoke_main.cpp`](public/tb_smoke_main.cpp)、[`public/tb_elf_main.cpp`](public/tb_elf_main.cpp)：Verilator 4.204 的 C++ main，驱动 `clock`/`reset` 直到 SV TB `$finish`。

## 固定接口

DUT 顶层必须是 `SimTop`，端口名/方向/位宽与 [`task.md`](task.md#固定顶层接口) 中的列表完全一致。要点：

- `clock`、`reset`（高有效）；
- 64-bit AXI4 master：`io_memAXI_0_aw_*`、`w_*`、`b_*`、`ar_*`、`r_*`；
- UART：`io_uart_out_valid/io_uart_out_ch`、`io_uart_in_valid/io_uart_in_ch`；
- 框架输入：`io_logCtrl_*`、`io_perfInfo_*`（可忽略）。

AXI 数据 lane 只使用 `w_bits_data[0]`/`r_bits_data[0]`；参考 cache line 为 128 bit，一次事务为 `len=1` 的两拍、`size=3`、`burst=INCR`。

## 参考设计

`projects/cpu_axi_diff_cache/vsrc` 是 `origin/CPUwithCache` 提交 `3cb21fd`（“add i/dcache and pass cpu/riscv tests”）的 RTL 快照：

- `SimTop.sv` 是固定顶层；
- `top_axirw.sv` 实例化 `icache u_icache` 与 `dcache u_dcache`；
- `top.sv` 是实现五级流水线并实例化 `Difftest*` 钩子的核；
- 参考实现还包括 RV64M 乘除法、CSR、CLINT 定时器、ECALL/MRET 和 `0x7b` UART 打印。

复现结论与版本选择原因见主 [`README.md`](../README.md) 的“复现记录”一节。

## 使用流程

```bash
cd ~/oscpu-framework
source env_local.sh

# 1. 把 Agent 的 RTL 放到 projects/<project_name>/vsrc/
#    顶层模块名必须是 SimTop
# 2. 编译（difftest + NEMU + DRAMsim3）
export NEMU_HOME=$PWD/libraries/NEMU
./build.sh -e <project_name> -d -b \
  -m "WITH_DRAMSIM3=1 LOCAL_LIB_PATH=$HOME/tools/nemu-deps/usr/lib/x86_64-linux-gnu"

# 3. 运行 83 个基础用例（-r 隐含 difftest）
./build.sh -e <project_name> -b \
  -r "non-output/cpu-tests non-output/riscv-tests" \
  -m "WITH_DRAMSIM3=1 LOCAL_LIB_PATH=$HOME/tools/nemu-deps/usr/lib/x86_64-linux-gnu"
```

通过标准：每个用例日志出现 `HIT GOOD TRAP`，且没有 `difftest mismatch`。单用例调试：

```bash
cd projects/<project_name>/build
NEMU_HOME=$HOME/oscpu-framework/libraries/NEMU \
LD_LIBRARY_PATH=$HOME/tools/nemu-deps/usr/lib/x86_64-linux-gnu \
./emu -i non-output/riscv-tests/add-riscv-tests.bin
```

构建脚本会把 `SimTop.sv` 额外软链为 `build/SimTop.v`；如果 Agent 的顶层是 `.v`，保持文件名 `SimTop.v` 即可。建议在仓库根目录放置 `.no_commit`，避免 `build.sh` 的 tracer 自动提交。

## 范围与限制

- 验收以 83 个基础用例为准；它们覆盖 RV64I、RV64M 和程序级行为，不覆盖 CSR/ECALL/MRET/CLINT/UART/cache 专项，也不等于 RISC-V 认证。
- P 组、ACT4、Sail、PPA 不在本任务包当前的自动验收内；详见 [`acceptance.md`](acceptance.md)。
- 参考快照不支持非法指令异常、EBREAK 异常、非对齐宽访存异常；任务卡明确把这些列为范围外。
- `bin/custom-output` 用例不在范围内；当前实测 `hello` 通过、`time-test` 在 200k 内无失配，`interrupt-test` 在 168k 处 ABORT，`rt-thread` 未通过（详见主 README 的“扩展用例”和“CPU 验证环境完备性”）。
