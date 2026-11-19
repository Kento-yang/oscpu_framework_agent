# RVA-01：CPU 验收计划

本计划是 [RVA-01 任务卡](task.md) 的强制附件，描述如何在本仓库（`oscpu-dyw`）现有的 difftest 流程中验收一个符合固定 `SimTop` 接口的 RV64IM CPU。T09 使用 ACT4、Sail、定向程序和随机差分；本计划复用本仓库已经跑通的 NEMU + DRAMsim3 + **87 个用例**（83 个基础用例 + 4 个 custom-output 用例），并明确标注哪些项目尚未自动化。

## 固定执行环境

| 项目 | 固定值 |
| --- | --- |
| 框架 | `oscpu-dyw`（本任务包所在仓库），difftest 子模块 |
| Verilator | 4.204 |
| 参考模型 | `libraries/NEMU` @ `e402575a`，`riscv64-ysyx-ref_defconfig`，产物 `build/riscv64-nemu-interpreter-so` |
| 存储器模型 | `libraries/DRAMsim3` @ `5723f6b1`，`WITH_DRAMSIM3=1`，`configs/XiangShan.ini` |
| 工具链 | 无 root 环境按 `README.md`「使用流程」的 `~/tools/oscpu-dev-deps` + `~/tools/nemu-deps` 方案；或等价的系统安装 |
| 复位 | `SimTop.reset` 高有效；框架启动时拉高 10 个周期后释放 |
| 镜像 | 二进制加载到 `0x8000_0000`；仿真器可访问 256 MiB DRAM（`0x8000_0000`–`0x8FFF_FFFF`），AXI 地址在 difftest 后端减去 `0x8000_0000` 后访问 DRAMsim3 |
| 终止 | 程序执行 `0x0000006b`；NEMU 打印 `HIT GOOD TRAP` 表示 `a0=0`，否则失败 |
| 超时 | 框架默认周期/指令上限；单用例超时记为失败 |

每次编译/运行前，按 `README.md`「使用流程」第 2 节设置：

```bash
cd ~/oscpu-dyw
export NEMU_HOME=$PWD/libraries/NEMU
export PATH=$HOME/tools/oscpu-dev-deps/usr/bin:$PATH
export CPATH=$HOME/tools/oscpu-dev-deps/usr/include/x86_64-linux-gnu:$HOME/tools/oscpu-dev-deps/usr/include
export LIBRARY_PATH=$HOME/tools/oscpu-dev-deps/usr/lib/x86_64-linux-gnu
```

## A. 功能回归（F 组，当前唯一自动门禁）

测试组：

| 组 ID | 目录 | 用例数 | 说明 |
| --- | --- | ---: | --- |
| `CPU-RV64I` | `bin/non-output/riscv-tests` | 50 | RV64I 基础指令、分支、跳转、load/store |
| `CPU-CPUTEST` | `bin/non-output/cpu-tests` | 33 | 程序级用例，含 `div`、`mul-longlong` 等 M 扩展用例 |
| `CPU-CUSTOM` | `bin/custom-output/{yield-test,time-test,interrupt-test,rt-thread}` | 4 | 不终止用例；用 `-C` 在确定周期点判定 |
| 合计 | — | **87** | 参考设计 87/87 |

编译（本机无 root 环境按 `README.md` 使用 `CPATH/LIBRARY_PATH`；`build.sh` **不会**自动生成 `build/SimTop.v`，必须先手动拷贝）：

```bash
cd ~/oscpu-dyw
# 先按 README「使用流程」第 2 节设置 NEMU_HOME/CPATH/LIBRARY_PATH

mkdir -p projects/<project_name>/build
cp projects/<project_name>/vsrc/SimTop.sv projects/<project_name>/build/SimTop.v
./build.sh -e <project_name> -d -b -m "EMU_TRACE=1 WITH_DRAMSIM3=1"
```

其中 `<project_name>` 是 `projects/` 下的目录名。`WITH_DRAMSIM3=1` 是必须的：本设计通过 AXI 访问存储器，没有 DRAMsim3 时 emu 不会响应 AXI 请求。`build.sh` 会在构建期间导出 `NEMU_HOME`。构建脚本会：

1. 编译 DRAMsim3（若 `libraries/DRAMsim3/build/libdramsim3.a` 不存在）；
2. 编译 NEMU（若 `build/riscv64-nemu-interpreter-so` 不存在）；
3. 把 `projects/<project_name>/vsrc` 下的 `.v`/`.sv` 软链到 `projects/<project_name>/build/`；
4. 调用 difftest Makefile 生成 `build/emu`；`build/SimTop.v` 需由第 3 步之前的 `cp` 提供。

83 个基础用例回归（逐例判定，见 `README.md`「使用流程」第 4 节；通过 `HIT GOOD TRAP` 判定）：

```bash
cd projects/<project_name>/build
export NEMU_HOME=$(cd ../../.. && pwd)/libraries/NEMU
for f in ../../../bin/non-output/cpu-tests/*.bin \
         ../../../bin/non-output/riscv-tests/*.bin; do
  log=/tmp/$(basename "$f" .bin).log
  timeout 300 ./emu -i "$f" > "$log" 2>&1
  grep -q "HIT GOOD TRAP" "$log" && ! grep -q "difftest mismatch" "$log" \
    && echo "PASS $(basename "$f")" || echo "FAIL $(basename "$f") ($log)"
done
```

4 个 custom-output 用例（不终止；用 `-C` 固定周期点，判据见 `README.md`「使用流程」第 5 节）：

```bash
./emu -C 20000000 -i ../../../bin/custom-output/yield-test/amtest-yield-test.bin
./emu -C 20000000 -i ../../../bin/custom-output/time-test/amtest-time-test.bin
./emu -C 20000000 -i ../../../bin/custom-output/interrupt-test/amtest-interrupt-test.bin
./emu -C 50000000 -i ../../../bin/custom-output/rt-thread/rtthread.bin
```

单用例调试：

```bash
cd projects/<project_name>/build
NEMU_HOME=$(cd ../../.. && pwd)/libraries/NEMU \
./emu -i ../../../bin/non-output/riscv-tests/add-riscv-tests.bin
```

判定：

- 83 个基础用例全部 `HIT GOOD TRAP`，任意日志中没有 `difftest mismatch`、`FAIL`、超时。
- 4 个 custom-output 用例按 `README.md` 的明确停止点判定：yield/time/interrupt 在 20M 周期内、rt-thread 在 50M 周期内出现预期输出且无 mismatch/assertion。
- **87/87 全部通过才达到 F 组满分门槛**；部分通过按通过用例数比例计分。
- 参考设计在本环境实测 87/87：2026-11-17/18 `PASS=87, FAIL=0`；另有 `cpu-tests-fencei` 36/36、`cpu-tests-ysyx4` 35/35 作为可选回归。

## B. difftest 提交一致性

每个用例运行时，NEMU 参考模型与 DUT 的 `DifftestInstrCommit` 逐条比较：

- 退休顺序、PC、指令字、目的寄存器、写回值；
- 错误路径指令不得产生提交；同一条指令不得重复提交；
- `skip` 必须覆盖 `0x7b` UART 指令、`mcycle` CSR 指令和 CLINT 访存指令（参考实现 `cmt_skip`）；
- 第一次失配时，difftest 会打印 DUT/参考的 PC、指令、寄存器等现场；该用例判失败；
- 程序必须以 `0x6b` 正常终止；只有 `a0=0` 才是 `HIT GOOD TRAP`。

DUT 不得修改 `libraries/difftest`、NEMU 或 DRAMsim3 来放宽比较；观察钩子只用于验收，不得参与执行。

## C. 公开冒烟平台

`public/` 下提供两个自包含的 AXI 平台，供 Agent 在提交前做快速自检。它们不依赖 NEMU/DRAMsim3，只依赖 Verilator 和 DUT RTL：

- `public/tb.sv`：固定接口 + 64 条无相关 ADDI 的提交序列检查。使用 `public/axi_mem_model.sv` 作为 256 KiB AXI 从设备，`public/difftest_stub.sv` 替代真实 DPI 模块并记录提交/终止。
- `public/tb_cpu_elf.sv`：从 `+IMAGE=` 加载原始二进制，运行完整程序，支持 `+RESP_DELAY=0..8` 和 `+BACKPRESSURE=0/1`，以 `0x6b` 终止指令的 `a0` 判定通过。

编译/运行命令（`<project_name>` 替换为实际目录）。Verilator 4.204 **不支持** `--binary`/`--timing`，因此两个平台各带一个 C++ main 来驱动 `clock`/`reset`；SV testbench 内部完成检查并 `$finish`：

```bash
verilator --cc --exe --build -j 4 -Wno-fatal -Wno-WIDTH \
  --top-module tb_rva01_smoke -o tb_smoke \
  -Iprojects/<project_name>/vsrc \
  rv_agent_cpu_plan/public/difftest_stub.sv \
  rv_agent_cpu_plan/public/tb.sv \
  rv_agent_cpu_plan/public/axi_mem_model.sv \
  rv_agent_cpu_plan/public/tb_smoke_main.cpp \
  $(find projects/<project_name>/vsrc \( -name '*.sv' -o -name '*.v' \) ! -name 'SimTop.v')
./obj_dir/tb_smoke
```

```bash
verilator --cc --exe --build -j 4 -Wno-fatal -Wno-WIDTH \
  --top-module tb_rva01_elf -o tb_elf \
  -Iprojects/<project_name>/vsrc \
  rv_agent_cpu_plan/public/difftest_stub.sv \
  rv_agent_cpu_plan/public/tb_cpu_elf.sv \
  rv_agent_cpu_plan/public/axi_mem_model.sv \
  rv_agent_cpu_plan/public/tb_elf_main.cpp \
  $(find projects/<project_name>/vsrc \( -name '*.sv' -o -name '*.v' \) ! -name 'SimTop.v')
./obj_dir/tb_elf +IMAGE=bin/non-output/riscv-tests/add-riscv-tests.bin \
  +RESP_DELAY=0 +BACKPRESSURE=0
```

说明：

- `difftest_stub.sv` 必须排在 `tb.sv`/`tb_cpu_elf.sv` **之前**：Verilator 4.204 要求 package 先声明。
- 公开平台使用 `public/difftest_stub.sv` 中的同名空壳模块，不能再同时编译 `libraries/difftest/src/test/vsrc/common/difftest.v`，否则模块重复定义。
- `tb.sv` 只检查固定端口、复位、取指、64 条 ADDI 的退休顺序和写回；不检查 cache 结构或 AXI 性能。
- `tb_cpu_elf.sv` 的 AXI 从设备假设“先 AW 后 W”、单笔未完成事务；参考设计的 `uni2axi` 与 cache 通路满足该顺序。
- **2026-11-18 实测（参考设计 `projects/cpu_axi_diff`）**：`tb.sv` 输出 `PUBLIC_PASS commits=64 cycles=214 read_beats=33 write_beats=0`；`tb_cpu_elf` 在 `+RESP_DELAY=8`、`+BACKPRESSURE=1` 下通过 `add-riscv-tests`、`dummy`、`load-store`、`matrix-mul`、`quick-sort`，其中 `matrix-mul` 触发 78 次 AXI 写回。权威门禁仍是 A 组的 87 个用例（83 基础 + 4 custom）。

## D. 计划中的专项检查（P 组，尚未自动化）

以下项目是任务卡 P 组的验收目标，当前仓库没有对应检查器/程序，不能据此宣称已通过；补齐后应按组独立计分，不重复扣 F 组的分。

| 组 ID | 检查 | 计划方法 |
| --- | --- | --- |
| `CPU-PIPE-STRUCT` | 五级结构与顺序提交 | 源码审查 + 提交轨迹；四组级间寄存器必须存在，不能靠延迟提交伪造 |
| `CPU-PIPE-HAZ` | 旁路、load-use、双源相关 | 定向微程序：EX→EX、MEM/WB→EX、WB→ID、x0、load→branch/store；与无相关版本比较退休间隔 |
| `CPU-PIPE-FLUSH` | 分支/JAL/JALR 冲刷 | 正确/错误路径写不同 store 标记，检查只有正确路径到达 AXI |
| `CPU-CACHE-I` | I-cache 缺失/替换 | 跨 line 取指、跳转回已缓存 line、强制替换；difftest 提交一致 |
| `CPU-CACHE-D` | D-cache 写回/写分配 | store miss、dirty 替换、同地址读写、字节 lane；最终内存与 NEMU 一致 |
| `CPU-BUS-RESP` | AXI 响应延迟 | `RESP_DELAY=1..8`，请求在等待期间稳定，响应不重放 |
| `CPU-BUS-BP` | AXI 背压 | `aw/w/ar/r/b` 各类 ready 随机拉低；事务不丢失/不重复 |
| `CPU-RESET` | 复位 | 在空闲、ALU 流、load 等待、分支附近注入 `reset`；释放后从 `0x80000000` 重新开始，无旧提交 |
| `CPU-CSR-TRAP` | CSR/异常/UART | CSRRW/S/C 及立即数形式、`mstatus` 进出异常、`mepc/mcause`、CLINT 定时器、ECALL/MRET、`0x7b` UART；定向程序待补充 |

已有可用素材：`bin/custom-output/interrupt-test`（CSR/异常/定时器）、`time-test`、`yield-test`、`rt-thread`。当前基线（`projects/cpu_axi_diff`）实测：yield/time/interrupt 在 20M 周期内正常，rt-thread 在 50M 周期内完成启动，`hello` 也通过。它们可作为 P 组定向检查的素材，但 P 组仍需专门的自动检查器，不能仅凭这些用例宣称 P 组通过。

参考实现的能力边界（用于设计这些检查，不构成已验收证据）：

- `mcycle` 每周期自增；CLINT 的 `mtime` 在 `mtime < mtimecmp` 时每周期自增，达到/超过后保持；
- `mstatus` 的 MIE/MPIE/MPP 在 trap/MRET 时按任务卡更新；MRET 时 MPP 清零；
- `mip[7]` 读 0，MTIP 由内部比较直接送入中断逻辑；
- 未列出的 CSR 读 0、写忽略；非法指令、EBREAK、非对齐异常不实现。

## E. 评分与判定（rva01_plan_v1）

| 层 | 分值 | 组 | 自动化状态 |
| --- | ---: | --- | --- |
| F | 30 | `CPU-RV64I`（50 用例） | 已可自动判定 |
| F | 15 | `CPU-CPUTEST`（33 用例） | 已可自动判定 |
| F | 5 | `CPU-DIFF`（83 基础 + 4 custom 无失配/超时/非正常终止） | 已可自动判定（随 A 组） |
| P | 20 | `CPU-PIPE-*` | 计划项 |
| P | 15 | `CPU-CACHE-*` | 计划项 |
| P | 15 | `CPU-BUS-*` / `CPU-RESET` | 计划项 |
| 时间 | 5 | 完成时间 | 可选，需 F 满分 |

- F 组按通过用例数线性计分；任何一个 difftest 失配、超时或非 `0x6b` 终止使该用例为 0。
- F 组满分要求 **87/87**：83 个基础用例 + 4 个 custom-output 用例。4 个 custom-output 用例的失配/超时会扣减 `CPU-DIFF` 的 5 分。
- P 组在检查器补齐前只报告、不计分；不能把“公开冒烟通过”当成 P 组满分。
- 安全/诚信缺陷（硬编码测试地址、跳过指令、伪造提交、修改参考模型）使所在子项为 0。
- 本任务没有 PPA 流程；`task.yaml` 中 `ppa_status: not_run`。87 个用例通过不等于 RISC-V 认证或完整 CPU 验证。

## F. 参考资格与证据

- 参考设计路径：`projects/cpu_axi_diff/vsrc`。
- 本仓库提交：`bb69f74`（`add rv_agent_cpu_plan testbench files`）。
- 依赖版本：NEMU `e402575a`、difftest `56d947bb`、DRAMsim3 `5723f6b1`、ysyxSoC `53540d03`。
- 顶层链路：`SimTop.sv` → `top.sv`（实例化 `core_top`、`iCache_wrapper`、`dCache_wrapper`、UNI 仲裁和 `uni2axi`）。
- 实测：`bin/non-output/cpu-tests` 33/33、`bin/non-output/riscv-tests` 50/50、`bin/custom-output` 4/4，合计 **87/87**；逐例 IPC 见 `README.md` 的「IPC 基准数据」。
- 可选回归：`bin/non-output/cpu-tests-fencei` 36/36、`bin/non-output/cpu-tests-ysyx4` 35/35。
- 公开 TB：`tb_smoke` 输出 `PUBLIC_PASS commits=64 cycles=214 read_beats=33 write_beats=0`；`tb_elf` 在 `RESP_DELAY=8`、`BACKPRESSURE=1` 下通过 `add-riscv-tests`、`dummy`、`load-store`、`matrix-mul`、`quick-sort`。
- 该证据覆盖 87 个功能用例，但不覆盖 P 组专项检查，也不等于 RISC-V 认证。

## G. 不在本任务包范围内

- ACT4、Sail、RISC-V 官方认证；
- 浮点、原子、压缩指令、S/U-mode、MMU、外部中断控制器；
- 非对齐宽访存异常、非法指令异常、EBREAK 异常（未知指令/EBREAK 按 NOP 处理）；
- 普通 `fence`（`fence.i` 已实现，并纳入 `cpu-tests-fencei` 可选回归）；
- 分支预测器、多核、cache 一致性；
- PPA/物理实现。

这些项目如后续加入，必须单独版本化验收配置，不能把新规则追溯套用到本次 87/87 结果上。`bin/custom-output` 的 4 个用例已纳入主门禁；`hello` 等其余 custom-output 仍仅作调试素材。
