# RVA-01 · 带 I/D Cache 的 RV64IM 五级流水线 CPU

本目录是一个 Agent CPU 开发的任务包，用于让不同 Agent 编写 RTL，并用本仓库已经跑通的 `oscpu-framework` difftest 流程做验证。任务卡的能力基线是 `projects/cpu_axi_diff`（本仓库 `bb69f74`），在本环境实测 **87/87** 通过（`cpu-tests` 33/33、`riscv-tests` 50/50、custom-output 4/4）。此外，`cpu-tests-fencei` 36/36 与 `cpu-tests-ysyx4` 35/35 也已实测通过（可选回归，见下文）。

任务元数据见 [`task.yaml`](task.yaml)。

## 状态

- **参考设计功能资格**：`projects/cpu_axi_diff` 在本仓库实测 **87/87**（83 个基础用例 + 4 个 custom-output），PASS=87、FAIL=0；另有 `cpu-tests-fencei` 36/36、`cpu-tests-ysyx4` 35/35 通过（可选回归）。
- **本任务包**：`draft`。F 组（87 例：83 基础 + 4 custom-output + difftest 一致性）可直接由现有流程自动判定；P 组（流水线/缓存/总线专项）目前是计划项，仓库尚未提供对应检查器。
- **公开 testbench**：`public/tb.sv` 与 `public/tb_cpu_elf.sv` 是自包含的 AXI 冒烟平台。2026-11-18 用 `projects/cpu_axi_diff` 复测：`tb_smoke` 输出 `PUBLIC_PASS commits=64 cycles=214 read_beats=33 write_beats=0`；`tb_elf` 在 `RESP_DELAY=8`、`BACKPRESSURE=1` 下通过 `add-riscv-tests`、`dummy/load-store/matrix-mul/quick-sort`，其中 `matrix-mul` 产生 78 次写回。Verilator 4.204 不支持 `--binary`/`--timing`，平台用配套的 C++ main 驱动时钟；权威门禁仍是 87 例（83 基础 + 4 custom）。

## 文件

- [`task.md`](task.md)：冻结任务卡，定义固定 `SimTop` 接口、ISA/CSR/异常范围、提交观察钩子、流水线与缓存要求、评分权重。
- [`acceptance.md`](acceptance.md)：验收计划，包含实际命令、通过标准、87 个用例（83 基础 + 4 custom）的分组、P 组计划项和参考资格记录。
- [`task.yaml`](task.yaml)：机器可读元数据。
- [`FREEZE.json`](FREEZE.json)：任务级冻结/来源记录（草案）。
- [`public/tb.sv`](public/tb.sv)：固定接口 + 64 条 ADDI 提交序列冒烟。
- [`public/tb_cpu_elf.sv`](public/tb_cpu_elf.sv)：ELF/bin 加载平台，支持 AXI 响应延迟与背压。
- [`public/axi_mem_model.sv`](public/axi_mem_model.sv)：256 KiB AXI4 从设备模型。
- [`public/difftest_stub.sv`](public/difftest_stub.sv)：公开冒烟使用的 difftest 空壳模块与统计包。
- [`public/tb_smoke_main.cpp`](public/tb_smoke_main.cpp)、[`public/tb_elf_main.cpp`](public/tb_elf_main.cpp)：Verilator 4.204 的 C++ main，驱动 `clock`/`reset` 直到 SV TB `$finish`。
- [`public/cpu_axi_diff/`](public/cpu_axi_diff/)：从 `projects/cpu_axi_diff/vsrc` 抽取的公开 RTL 骨架；固定 `SimTop`/`top`/`defines`/`uni2axi`/`stdlib` 与全部模块端口，`core/`、`cache/` 只留接口和 TODO，供 Agent 实现逻辑。使用说明见其 [`README.md`](public/cpu_axi_diff/README.md)。

## 固定接口

DUT 顶层必须是 `SimTop`，端口名/方向/位宽与 [`task.md`](task.md#固定顶层接口) 中的列表完全一致。要点：

- `clock`、`reset`（高有效）；
- 64-bit AXI4 master：`io_memAXI_0_aw_*`、`w_*`、`b_*`、`ar_*`、`r_*`；
- UART：`io_uart_out_valid/io_uart_out_ch`、`io_uart_in_valid/io_uart_in_ch`；
- 框架输入：`io_logCtrl_*`、`io_perfInfo_*`（可忽略）。

AXI 数据 lane 只使用 `w_bits_data[0]`/`r_bits_data[0]`；参考 cache line 为 128 bit，一次事务为 `len=1` 的两拍、`size=3`、`burst=INCR`。

## 参考设计

`projects/cpu_axi_diff/vsrc` 是本仓库的参考设计（`bb69f74`，39 个 SystemVerilog 文件）：

- `SimTop.sv` 是固定 difftest 顶层；
- `top.sv` 实例化 `core_top`、`iCache_wrapper`、`dCache_wrapper`、UNI 仲裁和 `uni2axi`；
- `core/` 实现 IF/ID、ID/EX、EX/MEM、MEM/WB 五级流水线，含 RV64I/RV64M、CSR、CLINT、ECALL/MRET；
- `cache/` 为独立的 I/D cache（4-way、128 组、16-byte line、8 KiB），支持 `fence.i` 与 `0x7b` UART 打印；普通 `fence` 按 NOP 处理。

复现命令与逐用例数据见下文“本次基准实测”和“使用流程”。

### 本次基准实测（2026-11-17/18，`projects/cpu_axi_diff`）

> 以下数据基于 `projects/cpu_axi_diff`（本仓库 `bb69f74`），可作为后续 Agent 设计的 IPC 基准对照。

#### 测试使用的文件

- **被测 RTL**：`projects/cpu_axi_diff/vsrc/`，共 39 个 SystemVerilog 文件：
  - 顶层与总线：`SimTop.sv`、`top.sv`、`uni2axi.sv`、`defines.sv`；
  - 核：`core/core_top.sv`、`core/ifu/ifu.sv`、`core/idu/{idu,idu_normal,idu_system}.sv`、`core/exu/exu.sv`、`core/exu/div/div.sv`、`core/exu/mult/**`、`core/lsu/lsu.sv`、`core/other/{bru,clint}.sv`、`core/csr_file/csrfile.sv`、`core/regfile/{regfile,bypass}.sv`、`core/wbu/{wbu,iru}.sv`；
  - Cache：`cache/iCache_wrapper.sv`、`cache/dCache_wrapper.sv`、`cache/cache/{iCache,dCache}.sv`、`cache/cache/cache_lib/**`；
  - 标准库：`stdlib/**`（AXI/UNI 接口、mux、reg、reset）。
- **测试用例（`bin/`）**：
  - `non-output/cpu-tests`：33 个 `.bin`；
  - `non-output/riscv-tests`：50 个 `.bin`；
  - `custom-output/yield-test/amtest-yield-test.bin`；
  - `custom-output/time-test/amtest-time-test.bin`；
  - `custom-output/interrupt-test/amtest-interrupt-test.bin`；
  - `custom-output/rt-thread/rtthread.bin`。
- **框架与依赖**：
  - `build.sh`、`run.sh`、`bin/README.md`、主 [`README.md`](../README.md)；
  - `libraries/NEMU` @ `e402575a`（gitee `oscpu/NEMU`）；
  - `libraries/difftest` @ `56d947bb`；
  - `libraries/DRAMsim3` @ `5723f6b1`；
  - `libraries/ysyxSoC` @ `53540d03`。
- **构建产物**：`projects/cpu_axi_diff/build/emu`，编译参数 `EMU_TRACE=1 WITH_DRAMSIM3=1`。
- **主机环境**：Ubuntu 22.04（WSL2，Linux 5.15）、Verilator 4.204、g++ 11.4.0、cmake 3.22.6、16 核。

#### 通过指标与停止点

- **cpu-tests / riscv-tests**：日志出现 `HIT GOOD TRAP at pc = ...` 且无 `difftest mismatch`、无 `FAIL/BAD TRAP` 即通过。83 个用例全部通过。
- **custom-output 四例**：这四个程序**设计上不终止**（yield/time/interrupt 是 AM 主循环，rt-thread 进入 shell/idle），不存在 `HIT GOOD TRAP`。用 `-C/--max-cycles` 在确定周期点停止，检查预期输出 + 无 mismatch/assertion，并通过退出时的 `EXCEEDING CYCLE/INSTR LIMIT` 行记录 IPC：
  - **yield-test**：停止于 20,000,000 周期（实际 `cycleCnt=19,999,998`），host 110,444 ms，2026-11-18 00:24:08 结束；输出 `Hello, AM World @ riscv64`、`t = timer, d = device, y = yield`，随后约 1302 个 `y`，无报错。
  - **time-test**：停止于 20,000,000 周期（`cycleCnt=19,999,998`），host 110,747 ms，2026-11-18 00:25:59 结束；RTC 连续打印到 `1970-1-1 00:00:19 GMT (19 seconds).`，无报错。
  - **interrupt-test**：停止于 20,000,000 周期（`cycleCnt=19,999,998`），host 105,059 ms，2026-11-18 00:27:44 结束；输出 20 次 `t`（定时器中断）与 1351 次 `y`（yield），无报错。
  - **rt-thread**：停止于 **50,000,000 周期**（实际 `cycleCnt=49,999,998`），host 267,438 ms（约 4 分 27 秒），**2026-11-18 00:32:11** 结束；在此时间点之前已完整输出 RT-Thread 4.0.4 Banner、`Hello OSCPU!`、进入 `msh />`，且 `thread1/thread2 count` 交替打印到 4，`thread2` 正常退出，无 assertion/panic/mismatch。

#### 结果总览


| 类别           | 用例数 |   通过 |  失败 | 判定                                      |
| -------------- | -----: | -----: | ----: | ----------------------------------------- |
| cpu-tests      |     33 |     33 |     0 | `HIT GOOD TRAP`                           |
| riscv-tests    |     50 |     50 |     0 | `HIT GOOD TRAP`                           |
| yield-test     |      1 |      1 |     0 | 20M 周期内 1302 个`y`，无失配             |
| time-test      |      1 |      1 |     0 | 20M 周期内 RTC 到 19 秒，无失配           |
| interrupt-test |      1 |      1 |     0 | 20M 周期内 20 个`t` + 1351 个 `y`，无失配 |
| rt-thread      |      1 |      1 |     0 | 50M 周期内完成启动与线程调度，无失配      |
| **合计**       | **87** | **87** | **0** | —                                        |

#### IPC 基准数据

测量条件统一为：Verilator 4.204、单核、`-O3`、`WITH_DRAMSIM3=1`、`EMU_TRACE=1`。数值直接取自 emulator 退出时的 `instrCnt / cycleCnt / IPC`；包含复位与启动开销，适合做同环境下的相对比较，不宜与其它仿真器或不同 DRAM 配置直接横比。

**分类汇总**：cpu-tests 平均 IPC **0.218538**（33 例）；riscv-tests 平均 IPC **0.066065**（50 例）。

**custom-output 四例（周期限制式）**


| 用例           |   周期上限 | 实际 cycleCnt |  host 时间 |   instrCnt |      IPC |
| -------------- | ---------: | ------------: | ---------: | ---------: | -------: |
| yield-test     | 20,000,000 |    19,999,998 | 110,444 ms | 11,929,242 | 0.596462 |
| time-test      | 20,000,000 |    19,999,998 | 110,747 ms |  9,886,796 | 0.494340 |
| interrupt-test | 20,000,000 |    19,999,998 | 105,059 ms | 12,384,199 | 0.619210 |
| rt-thread      | 50,000,000 |    49,999,998 | 267,438 ms | 25,129,585 | 0.502592 |

**逐用例 IPC（cpu-tests，33 个）**

以下 33 个用例全部 **PASS**（`HIT GOOD TRAP`，无 `difftest mismatch`）；IPC 为 emulator 退出时打印值。


| 用例                    | instrCnt | cycleCnt |      IPC |
| ----------------------- | -------: | -------: | -------: |
| add-cpu-tests           |     1580 |    11200 | 0.141071 |
| add-longlong-cpu-tests  |     1526 |    12182 | 0.125267 |
| bit-cpu-tests           |      907 |     9714 | 0.093370 |
| bubble-sort-cpu-tests   |     4492 |    15894 | 0.282622 |
| div-cpu-tests           |    21578 |    51148 | 0.421874 |
| dummy-cpu-tests         |      544 |     6919 | 0.078624 |
| fact-cpu-tests          |     6032 |    19481 | 0.309635 |
| fib-cpu-tests           |     1173 |    10091 | 0.116242 |
| goldbach-cpu-tests      |     9952 |    27894 | 0.356779 |
| hello-str-cpu-tests     |     3818 |    37519 | 0.101762 |
| if-else-cpu-tests       |      873 |     8952 | 0.097520 |
| leap-year-cpu-tests     |    11274 |    31960 | 0.352753 |
| load-store-cpu-tests    |      984 |    10344 | 0.095128 |
| matrix-mul-cpu-tests    |   271889 |   561574 | 0.484155 |
| max-cpu-tests           |     1654 |    11472 | 0.144177 |
| min3-cpu-tests          |     1852 |    12034 | 0.153897 |
| mov-c-cpu-tests         |      637 |     8374 | 0.076069 |
| movsx-cpu-tests         |      701 |     9178 | 0.076378 |
| mul-longlong-cpu-tests  |     4400 |    16592 | 0.265188 |
| pascal-cpu-tests        |     4717 |    16588 | 0.284362 |
| prime-cpu-tests         |    69246 |   145887 | 0.474655 |
| quick-sort-cpu-tests    |     4400 |    17604 | 0.249943 |
| recursion-cpu-tests     |     8366 |    25818 | 0.324037 |
| select-sort-cpu-tests   |     4224 |    16266 | 0.259683 |
| shift-cpu-tests         |      924 |     9434 | 0.097944 |
| shuixianhua-cpu-tests   |   179614 |   367370 | 0.488919 |
| string-cpu-tests        |     2259 |    14572 | 0.155023 |
| sub-longlong-cpu-tests  |     1526 |    12182 | 0.125267 |
| sum-cpu-tests           |     1261 |     8614 | 0.146390 |
| switch-cpu-tests        |      837 |     8824 | 0.094855 |
| to-lower-case-cpu-tests |     2917 |    12940 | 0.225425 |
| unalign-cpu-tests       |      734 |     8718 | 0.084194 |
| wanshu-cpu-tests        |    22528 |    52568 | 0.428550 |

**逐用例 IPC（riscv-tests，50 个）**

以下 50 个用例全部 **PASS**（`HIT GOOD TRAP`，无 `difftest mismatch`）；IPC 为 emulator 退出时打印值。


| 用例               | instrCnt | cycleCnt |      IPC |
| ------------------ | -------: | -------: | -------: |
| add-riscv-tests    |      450 |     6761 | 0.066558 |
| addi-riscv-tests   |      216 |     3357 | 0.064343 |
| addiw-riscv-tests  |      213 |     3285 | 0.064840 |
| addw-riscv-tests   |      445 |     6669 | 0.066727 |
| and-riscv-tests    |      525 |     7313 | 0.071790 |
| andi-riscv-tests   |      187 |     2639 | 0.070860 |
| auipc-riscv-tests  |       25 |      599 | 0.041736 |
| beq-riscv-tests    |      282 |     3687 | 0.076485 |
| bge-riscv-tests    |      309 |     4137 | 0.074692 |
| bgeu-riscv-tests   |      399 |     5585 | 0.071441 |
| blt-riscv-tests    |      282 |     3687 | 0.076485 |
| bltu-riscv-tests   |      368 |     4651 | 0.079123 |
| bne-riscv-tests    |      284 |     3691 | 0.076944 |
| jal-riscv-tests    |       22 |      593 | 0.037099 |
| jalr-riscv-tests   |       92 |     1393 | 0.066045 |
| lb-riscv-tests     |      218 |     3091 | 0.070527 |
| lbu-riscv-tests    |      218 |     3091 | 0.070527 |
| ld-riscv-tests     |      352 |     5421 | 0.064933 |
| lh-riscv-tests     |      230 |     3247 | 0.070835 |
| lhu-riscv-tests    |      237 |     3393 | 0.069850 |
| lui-riscv-tests    |       30 |      675 | 0.044444 |
| lw-riscv-tests     |      240 |     3399 | 0.070609 |
| lwu-riscv-tests    |      266 |     3781 | 0.070352 |
| or-riscv-tests     |      558 |     7860 | 0.070992 |
| ori-riscv-tests    |      180 |     2559 | 0.070340 |
| sb-riscv-tests     |      407 |     5665 | 0.071845 |
| sd-riscv-tests     |      579 |     8695 | 0.066590 |
| sh-riscv-tests     |      460 |     6343 | 0.072521 |
| simple-riscv-tests |        5 |      163 | 0.030675 |
| sll-riscv-tests    |      520 |     8033 | 0.064733 |
| slli-riscv-tests   |      241 |     3803 | 0.063371 |
| slliw-riscv-tests  |      248 |     3949 | 0.062801 |
| sllw-riscv-tests   |      520 |     8033 | 0.064733 |
| slt-riscv-tests    |      439 |     6525 | 0.067280 |
| slti-riscv-tests   |      208 |     3209 | 0.064818 |
| sltiu-riscv-tests  |      208 |     3209 | 0.064818 |
| sltu-riscv-tests   |      456 |     6839 | 0.066676 |
| sra-riscv-tests    |      492 |     7481 | 0.065767 |
| srai-riscv-tests   |      229 |     3581 | 0.063949 |
| sraiw-riscv-tests  |      275 |     4399 | 0.062514 |
| sraw-riscv-tests   |      532 |     8197 | 0.064902 |
| srl-riscv-tests    |      534 |     8051 | 0.066327 |
| srli-riscv-tests   |      250 |     3821 | 0.065428 |
| srliw-riscv-tests  |      257 |     4033 | 0.063724 |
| srlw-riscv-tests   |      526 |     8126 | 0.064730 |
| sub-riscv-tests    |      441 |     6595 | 0.066869 |
| subw-riscv-tests   |      437 |     6521 | 0.067014 |
| sw-riscv-tests     |      467 |     6497 | 0.071879 |
| xor-riscv-tests    |      553 |     7784 | 0.071043 |
| xori-riscv-tests   |      178 |     2555 | 0.069667 |

## 使用流程

以下命令可复现本次验证结果（`projects/cpu_axi_diff`，87/87）。第 3 节把 `SimTop.v` 副本提前放入 `build/`，可避免首次编译时 difftest 的 Chisel 误判；若仍停在 difftest，使用该节末尾的手动补编译兜底。该前置拷贝流程已在 2026-11-18 用骨架工程完整验证（`build.sh` 返回 0）。

### 1. 准备依赖（本仓库没有 `.gitmodules`，`libraries/` 默认为空）

```bash
cd ~/oscpu-dyw

git clone https://gitee.com/oscpu/NEMU.git libraries/NEMU
git -C libraries/NEMU checkout e402575a33b6bb910a40f5114e53b1dd55b72da2

git clone https://github.com/OpenXiangShan/difftest.git libraries/difftest
git -C libraries/difftest checkout 56d947bbfd420a0ee3f5794ad2ac4b1525892540

git clone https://github.com/OpenXiangShan/DRAMsim3.git libraries/DRAMsim3
git -C libraries/DRAMsim3 checkout 5723f6b1cc157ac2d7b4154b50fd1799c9cf54aa

git clone https://github.com/OSCPU/ysyxSoC.git libraries/ysyxSoC
git -C libraries/ysyxSoC checkout 53540d038ed567fcf5e10d3fb3c4069922735ead
```

> NEMU 的 `e402575a` 已不在 GitHub 上游，需要从 gitee 的 `oscpu/NEMU` 获取（本环境使用本机已有同源克隆交叉 fetch 也可以）。

### 2. 环境变量（本机缺 readline/zlib/SDL2/sqlite3 开发包且无免密 sudo）

先把所需的 dev 包免 root 解包到**持久目录** `~/tools/oscpu-dev-deps`（不要用 `/tmp`：本机重启后会被清理，导致编译找不到 `SDL2/_real_SDL_config.h`、`sqlite3.h` 等）：

```bash
mkdir -p /tmp/debs ~/tools/oscpu-dev-deps
cd /tmp/debs
apt-get download libreadline-dev libtinfo-dev zlib1g-dev \
  libsqlite3-dev libsdl2-dev
for f in *.deb; do dpkg-deb -x "$f" ~/tools/oscpu-dev-deps; done
```

```bash
cd ~/oscpu-dyw
export NEMU_HOME=$PWD/libraries/NEMU
export PATH=$HOME/tools/oscpu-dev-deps/usr/bin:$PATH
export CPATH=$HOME/tools/oscpu-dev-deps/usr/include/x86_64-linux-gnu:$HOME/tools/oscpu-dev-deps/usr/include
export LIBRARY_PATH=$HOME/tools/oscpu-dev-deps/usr/lib/x86_64-linux-gnu
```

`~/tools/oscpu-dev-deps` 是自包含的：提供 readline/zlib/SDL2/sqlite3 的头文件、静态库和 `sdl2-config`，不依赖其它本地前缀。

> 本仓库固定的 difftest 版本不支持 `LOCAL_LIB_PATH` 变量，必须用 `CPATH/LIBRARY_PATH` 让编译器找到这些头文件和库。

### 3. 编译

```bash
cd ~/oscpu-dyw
mkdir -p projects/cpu_axi_diff/build
# 必须先放置 build/SimTop.v：build.sh 不会自动创建它，
# 否则 difftest 会把 Verilog 工程误判为 Chisel 工程并报
# "No rule to make target 'sim-verilog'"
cp projects/cpu_axi_diff/vsrc/SimTop.sv projects/cpu_axi_diff/build/SimTop.v

./build.sh -e cpu_axi_diff -d -b -m "EMU_TRACE=1 WITH_DRAMSIM3=1"
```

若编译停在 difftest 一步（例如 `SimTop.v` 副本比 `libraries/difftest/src/main/scala/Difftest.scala` 旧），手动补：

```bash
(cd libraries/difftest && make \
  DESIGN_DIR=$PWD/../../projects/cpu_axi_diff \
  EMU_TRACE=1 WITH_DRAMSIM3=1)
```

成功后产物为 `projects/cpu_axi_diff/build/emu`。运行时必须设置 `NEMU_HOME`，否则 emu 会报 `FATAL: $(NEMU_HOME) is not defined!`。

### 4. 运行 83 个基础用例（cpu-tests + riscv-tests）

```bash
cd ~/oscpu-dyw/projects/cpu_axi_diff/build
export NEMU_HOME=$(cd ../../.. && pwd)/libraries/NEMU

for f in ../../../bin/non-output/cpu-tests/*.bin \
         ../../../bin/non-output/riscv-tests/*.bin; do
  log=/tmp/$(basename "$f" .bin).log
  timeout 300 ./emu -i "$f" > "$log" 2>&1
  if grep -q "HIT GOOD TRAP" "$log" && ! grep -q "difftest mismatch" "$log"; then
    echo "PASS $(basename "$f")"
  else
    echo "FAIL $(basename "$f")  (see $log)"
  fi
done
```

**通过指标**：每个用例日志出现 `HIT GOOD TRAP at pc = ...`，且没有 `difftest mismatch`、`HIT BAD TRAP`、`ABORT` 或超时。本次 33/33 + 50/50 全部 PASS。

### 5. 运行 4 个 custom-output 用例（设计上不终止）

这四个程序没有退出路径，因此不能用 `HIT GOOD TRAP` 判定。用 `-C/--max-cycles` 在**确定的周期点**停止，emulator 会打印 `EXCEEDING CYCLE/INSTR LIMIT` 和 `instrCnt/cycleCnt/IPC`，再结合预期输出判定：

```bash
cd ~/oscpu-dyw/projects/cpu_axi_diff/build
export NEMU_HOME=$(cd ../../.. && pwd)/libraries/NEMU

# yield-test
./emu -C 20000000 -i ../../../bin/custom-output/yield-test/amtest-yield-test.bin

# time-test
./emu -C 20000000 -i ../../../bin/custom-output/time-test/amtest-time-test.bin

# interrupt-test
./emu -C 20000000 -i ../../../bin/custom-output/interrupt-test/amtest-interrupt-test.bin

# rt-thread（启动较慢，给 5000 万周期）
./emu -C 50000000 -i ../../../bin/custom-output/rt-thread/rtthread.bin
```

**通过指标与明确停止点**


| 用例           |   周期上限 | 本次实际停止点 |                       host 时间 | 通过判据                                                                                                                      |
| -------------- | ---------: | -------------: | ------------------------------: | ----------------------------------------------------------------------------------------------------------------------------- |
| yield-test     | 20,000,000 |     19,999,998 |                      110,444 ms | 输出 AM 头信息 + 约 1302 个`y`（yield 事件），无 mismatch/assert                                                              |
| time-test      | 20,000,000 |     19,999,998 |                      110,747 ms | RTC 连续打印到 19 秒（`1970-1-1 00:00:19 GMT (19 seconds).`），无报错                                                         |
| interrupt-test | 20,000,000 |     19,999,998 |                      105,059 ms | `t`（定时器中断）与 `y`（yield）交替输出；本次 20 个 `t`、1351 个 `y`                                                         |
| rt-thread      | 50,000,000 | **49,999,998** | **267,438 ms（约 4 分 27 秒）** | 在**2026-11-18 00:32:11** 之前已输出 RT-Thread 4.0.4 Banner、`Hello OSCPU!`、`msh />`，线程计数打印到 4 且 `thread2` 正常退出 |

> 注意：这些用例不要用退出码判断通过；请以上述控制台输出和 `EXCEEDING CYCLE/INSTR LIMIT` 行作为完成/判定依据。IPC 基准值见“参考设计”的 IPC 表。

### 6. 单用例调试

```bash
cd ~/oscpu-dyw/projects/cpu_axi_diff/build
NEMU_HOME=$(cd ../../.. && pwd)/libraries/NEMU \
./emu -i ../../../bin/non-output/riscv-tests/add-riscv-tests.bin
```

顶层模块名必须是 `SimTop`。如果 Agent 的顶层文件是 `.v`，保持文件名 `SimTop.v` 并在编译前放入 `build/` 即可。建议在仓库根目录放置 `.no_commit`，避免 `build.sh` 的 tracer 自动提交。

**路径注意**：若 emu 打印的 `The image is ...` 中原样出现 `$HOME`，说明该变量没有被 shell 展开（例如被单引号包住），随后会在 `ram.cpp` 的 `init_ram` 断言处 abort。请使用上面从 `build/` 出发的相对路径（`../../../bin/...`），或显式写成 `/home/kento/oscpu-dyw/bin/...` 绝对路径。

## 范围与限制

- 验收以 83 个基础用例 + 4 个 custom-output 用例为准。83 例覆盖 RV64I、RV64M 和程序级行为；4 个 custom-output 覆盖 CLINT 定时器中断、`0x7b` UART、yield 与 RT-Thread 调度。cache 专项目前还没有随仓库提供的自动检查器；这些结果也不等于 RISC-V 认证。
- 可选回归：`bin/non-output/cpu-tests-fencei` 36/36、`bin/non-output/cpu-tests-ysyx4` 35/35 在当前基线均已实测通过，但不在 87 例主门禁内。
- P 组、ACT4、Sail、PPA 不在本任务包当前的自动验收内；详见 [`acceptance.md`](acceptance.md)。
- 参考设计不实现非法指令异常与 EBREAK 异常（未知指令/EBREAK 按 NOP 处理），也不实现非对齐宽访存的精确异常；`fence.i` 已实现，普通 `fence` 按 NOP 处理。任务卡明确把上述未实现项列为范围外。
- 4 个 custom-output 用例设计上不终止，不能以 `HIT GOOD TRAP` 判定；各自的周期上限、输出判据和明确停止点见“参考设计 → 本次基准实测”。
