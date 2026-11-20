# RVA-01 自主 CPU 设计任务（容器 Agent 专用）

你是参加 RVA-01 评测的自主 Agent。请在收到本 prompt 后立即记录开始时间，并在 120 分钟内端到端完成：
环境准备 → 阅读题面与依赖说明 → 基于公开骨架实现 RV64IM 五级流水线 CPU（含 I/D Cache、CSR、CLINT、ECALL/MRET、fence.i、0x7b UART）→ 用仓库 difftest 跑通 87 条公开用例 → 自测与调优 → 按优先级完成 EDA/代理 PPA 评测 → 提交交付件。
不要向人类提问；遇到不确定先读题面再自行决策，并把决策、命令、日志与证据写入报告。

## 0. 工作目录与识别

- 仓库根目录：包含 requirements.txt、rv_agent_cpu_plan/、bin/、build.sh、projects/ 的目录（通常是 ~/oscpu-dyw）。
  REPO_ROOT=$(pwd)   # 若当前不在该目录，先 cd 到包含 requirements.txt 的目录
- 工作项目名：rva01_agent；交付路径：$REPO_ROOT/projects/rva01_agent/。
- 立即执行并保存：date -Is、nproc、free -h、df -h、verilator --version、g++ --version、cmake --version、make --version、python3 --version。
- 本题是 RV64IM：以 task.md 的设计需求、固定 SimTop 接口、bin/ 下 RV64 用例和公开骨架为准。若文档某处出现 RV32I 字样，按 RV64I 子集理解，不得缩减为 32 位实现。

## 1. 必读文件（按顺序）

1) requirements.txt：需要的工具/组件清单、固定依赖 commit、不同发行版的差异说明（不含安装命令）。
2) rv_agent_cpu_plan/task.md：规格、固定接口、ISA/CSR/异常、流水线/cache、评分与交付要求。
3) rv_agent_cpu_plan/README.md：已验证的构建/回归命令、87 例判据、IPC 基准、环境准备。
4) rv_agent_cpu_plan/acceptance.md：验收口径与命令。
5) rv_agent_cpu_plan/EDA环境使用介绍.md：EDA 工具清单、启动命令、license、PDK 限制与使用提示。
6) rv_agent_cpu_plan/public/cpu_axi_diff/README.md 与 public/cpu_axi_diff/**：唯一 RTL 起点与固定/可实现边界。
7) rv_agent_cpu_plan/public/difftest_stub.sv：difftest 模块端口参考（只读接口）。
8) bin/README.md 与 bin/ 用例清单：理解用例分类、输出约定和回归目录；不得修改测试。
9) libraries/difftest 的接口声明（如 difftest.v）：仅用于核对端口签名，不得修改、不得翻译其实现。

## 2. 可查阅范围（考场规范）

- **禁止查阅 `projects/` 下任何已有文件**：
  - `projects/cpu_axi_diff/**`（参考实现/答案）及其 build 产物；
  - `projects/chisel_cpu_diff/**` 及其 build 产物；
  - 其他任何已有项目目录、RTL、日志、emu。
  - 禁止打开、搜索、复制、diff、反编译、strings、objdump，或通过 git 历史查看这些内容。
- **允许查阅其他目录**：根目录 requirements.txt、README.md、run.sh、submit.sh，`bin/**`、`libraries/**`、`build.sh` 等。用途仅限于：环境配置、接口理解、测试执行、日志格式确认。
- **允许创建并读写自己的项目**：`projects/rva01_agent/**`（vsrc、build、logs、eda、报告等）。
- **测试诚信**：可以阅读 bin/README.md、测试清单和日志格式；不得针对测试名、PC、指令或地址硬编码，不得跳过指令、伪造提交/日志/PPA。功能修改必须由实际回归输出驱动。
- **EDA 例外**：`/opt/eda` 工具链与 PDK 可按 `EDA环境使用介绍.md` 执行和引用；不得从 EDA 目录或 PDK 中获取 CPU 设计/测试参考。
- **违规判定**：查阅 `projects/` 下已有实现、修改测试/黄金模型、硬编码或伪造结果，均视为考试违规，成绩无效。

## 3. 硬约束

- 120 分钟硬截止；截止时冻结最终版本并记录时间戳；超时总分 0。
- RTL 起点只能是 `rv_agent_cpu_plan/public/cpu_axi_diff`。除该骨架外，不得参考仓库内已有 CPU 实现（`projects/` 全部禁读）。
- 不得修改：`bin/` 测试、`libraries/difftest`、`libraries/NEMU`、`libraries/DRAMsim3`、`build.sh`、`rv_agent_cpu_plan/` 下的文档与骨架模板。
- 不得修改固定文件：`SimTop.sv`、`top.sv`、`defines.sv`、`uni2axi.sv`、`stdlib/**`、`cache/cache/cache_lib/S011HD1P_X32Y2D128_BW.sv`，以及骨架中既有模块的模块名/参数/端口。
- 不得硬编码测试名/PC/终止地址、跳过指令、伪造提交/日志/PPA；不得联网获取外部 IP 或闭源参考设计。允许获取题面指定的固定版本依赖与安装工具本身。
- EDA 工具链属于题面环境，允许使用；但 EDA 只用于 PPA 评测，不能替代 Verilator/difftest 的 87 例功能验收。
- difftest/NEMU 只用于验证与接口，不得把其实现翻译成 RTL，也不得修改它们。
- 允许新增内部模块和新的 .sv 文件；全部实现必须在 `projects/rva01_agent/vsrc` 下，并能由 clean 环境复现。

## 4. 环境配置与首次构建

完整组件清单见 `requirements.txt`。不同发行版的包名、默认版本和安装方式不同，本节只列必须自备的工具，不提供安装命令。

### 4.1 必须具备的工具
- **Verilator 4.204**（必须；Ubuntu 22.04 默认 4.038、CentOS 7 默认版本均不满足）。
- **C++ 编译器**：支持 C++14 的 GCC/G++（建议 ≥8；验证版本 11.4）。CentOS 7 默认的 gcc/g++ 4.8.5 不支持本仓库使用的 `-std=gnu++14`，需使用 devtoolset 或更新版本。
- **GNU Make**。
- **CMake ≥3.13**（验证版本 3.22.6；CentOS 7 自带 CMake 可能过旧）。
- **Python 3**（构建脚本使用；版本不敏感）。
- **Git**。
- **Bison / Flex**（NEMU kconfig/Verilator 构建；CentOS 7 自带版本可能过旧）。
- **GNU time**（`/usr/bin/time`，difftest Makefile 使用 `-a -o`）。
- **开发头文件与库**：readline、ncurses/tinfo、zlib、SDL2（含 `sdl2-config`）、SQLite3。
- 可选：ccache（加速编译）、gtkwave（波形）、Yosys（PPA fallback 的 `stat`）。

### 4.2 不同系统的差异
- **Ubuntu 22.04**：已验证环境；开发包通常叫 `*-dev`。
- **CentOS 7.9 / EDA 容器**：开发包通常叫 `*-devel`；默认 gcc/g++ 4.8.5 不足以编译本仓库，需 devtoolset 或更新 GCC；CMake、Flex、Verilator 也需要更新或预装版本。
- **EDA 容器**：EDA 工具（DC/PT/ Innovus/Calibre 等）由 `/opt/eda` 提供，但 EDA 工具链的 gcc 4.8.5 不等于可用的构建工具链；功能构建仍需满足 C++14 的编译器。
- **无 root**：可把所需的开发头文件/库放到一个**持久**本地前缀（不要放 `/tmp`，重启会丢），再通过 `PATH/CPATH/LIBRARY_PATH` 指向它；前缀路径不影响构建。
- `requirements.txt` 只列组件，不绑定发行版命令；按本机包管理器或预装环境提供即可。
- `rv_agent_cpu_plan/README.md`/`acceptance.md` 中的环境示例以 Ubuntu 为主；在 CentOS 或其它发行版上，按 `requirements.txt` 的组件清单用本机包管理器/预装环境提供，不要照搬包名。

### 4.3 固定版本依赖
若 `libraries/` 为空，按 `requirements.txt` 列出的 URL + commit 获取：
NEMU `e402575a`、difftest `56d947bb`、DRAMsim3 `5723f6b1`、ysyxSoC `53540d03`。
不要使用其它版本。

### 4.4 环境变量与首次构建
必须设置 `NEMU_HOME`；若使用本地开发前缀，同时设置 `PATH/CPATH/LIBRARY_PATH`：

```bash
export NEMU_HOME=$REPO_ROOT/libraries/NEMU
# 使用系统开发包时下面三行可省略；使用本地前缀时指向该前缀
export PATH=<your-prefix>/bin:$PATH
export CPATH=<your-prefix>/include:$CPATH
export LIBRARY_PATH=<your-prefix>/lib:$LIBRARY_PATH
```

创建项目并首次构建：

```bash
mkdir -p $REPO_ROOT/projects/rva01_agent/vsrc \
         $REPO_ROOT/projects/rva01_agent/build \
         $REPO_ROOT/projects/rva01_agent/logs
cp -r $REPO_ROOT/rv_agent_cpu_plan/public/cpu_axi_diff/. $REPO_ROOT/projects/rva01_agent/vsrc/
cp $REPO_ROOT/projects/rva01_agent/vsrc/SimTop.sv $REPO_ROOT/projects/rva01_agent/build/SimTop.v
cd $REPO_ROOT
./build.sh -e rva01_agent -d -b -m "EMU_TRACE=1 WITH_DRAMSIM3=1"
```

若构建停在 difftest，按 README 第 3 节手动补编译；记录完整命令、版本和日志。
EDA 工具环境可能与本仓库的 Verilator 构建环境不同；功能回归始终使用 Verilator 4.204 流程。EDA 配置见第 8 节。

## 5. 实现要求（以 task.md 为准）

- 五级流水线 IF/ID/EX/MEM/WB，四组级间寄存器真实存在；实现 EX/MEM、MEM/WB、WB→ID 前递、load-use 停顿、分支/JAL/JALR 在 EX 解析并冲刷；顺序提交。
- RV64I + RV64M；x0 恒 0；JALR 清目标 bit0；取指 4 字节对齐；支持 unalign 字节/半字/字访问。
- 独立 I/D cache：4-way、128 组、16-byte line、8 KiB；I-cache 缺失整行填充；D-cache write-back + write-allocate。
- Zicsr 六种操作；ECALL/MRET；CLINT mtime/mtimecmp/MTIP；0x6b 终止；0x7b UART；fence.i（普通 fence 按 NOP 处理）。
- 固定顶层接口、difftest 钩子、cache/CLINT 透明性要求见 task.md。

## 6. 里程碑（以开始时刻为 T+0）

- T+15：环境配置完成，首次 build 跑通，生成公开用例首轮失败列表（logs/first_failures.md）。
- T+45：公开通过率 ≥50%。
- T+75：≥80%。
- T+105：87/87 通过，生成完整日志与 IPC。
- T+105–T+120：冻结前完成 PPA 评测（优先 EDA）、自评、报告与评分卡。
  每个里程碑执行 date -Is 并写入 TIME.log；若环境配置超时，优先保证可构建和 87/87，再做 PPA；不得超 120 分钟。

## 7. 验证与调试规则

- 83 个基础用例：按 README 第 4 节逐例运行，日志保存到 projects/rva01_agent/logs/；PASS 判据 = HIT GOOD TRAP 且无 difftest mismatch/超时。
- 4 个 custom-output：yield/time/interrupt 用 -C 20000000，rt-thread 用 -C 50000000；按 README 第 5 节判据检查输出；日志同样保存。
- 用 results.tsv 记录：category、case、status、instrCnt、cycleCnt、IPC、log_path。
- 可以阅读测试说明与日志格式，但不得针对测试名/PC/地址硬编码，不得跳过指令或伪造日志。
- 调试依据：编译/lint 错误、emu/difftest 输出（首个 mismatch 的 PC/指令/寄存器/提交现场）、你自己生成的日志与自建定向测试。修改代码必须遵循：复现失败 → 定位首个分歧 → 根因假设 → 最小修改 → 回归验证，并写入 logs/debug_report.md。
- 可用 acceptance.md 第 C 节的 tb_smoke/tb_elf 做快速自检；时间允许时加跑 cpu-tests-fencei（36）与 cpu-tests-ysyx4（35）作为补充自检，单独记录，不计入 87。

## 8. EDA 与 PPA 评测（EDA 优先）

先阅读 `rv_agent_cpu_plan/EDA环境使用介绍.md`。EDA 工具预装在 `/opt/eda`，license 和路径由 `/etc/profile.d/eda-env.sh` 配置；不要手工改 license。允许使用 Synopsys DC/PrimeTime/Formality、Cadence Innovus、Mentor Calibre 等已就绪工具。

### 8.1 工具与 PDK 检查

- 检查 `which dc_shell pt_shell fm_shell innovus calibre`、`echo $SNPSLMD_LICENSE_FILE`。
- 查找可用的标准单元库（`.db` / `.lib` / `.lef`，如 Nangate45、SAED、Sky130）。EDA 文档说明默认未内置 PDK；没有库时，DC 可做 GTECH 综合，但 PrimeTime/Innovus/Calibre 的物理/功耗/时序结果不能作为签核级数据。
- 记录实际使用的工具版本、库名、corner、电压、温度、时钟约束；没有库时明确写“无 PDK，GTECH/代理”。

### 8.2 EDA 可用时（优先）

按以下顺序完成，并把命令、日志、报告保存在 `projects/rva01_agent/eda/`：

1) DC 逻辑综合：`dc_shell -f run.tcl -output_log_file dc.log`；在脚本中 `report_area`、`report_timing`、`report_power`；记录面积、时序、功耗。
2) PrimeTime STA：`pt_shell -f run.tcl -output_log_file pt.log`；记录 WNS/TNS、关键路径起点/终点、逻辑级数、Fmax、是否满足时钟约束。
3) 可选 Formality 等价验证：`fm_shell -file run.tcl -overwrite`。
4) 可选 Innovus/Calibre：仅在有 PDK 时执行；无 PDK 不要声称物理实现结果。
5) 输出四类数据：
   - **Performance**：87 例平均 IPC（来自功能回归日志）；若综合成功，另报 Fmax/时钟频率与关键路径。
   - **Timing**：WNS/TNS、关键路径、逻辑级数、Fmax、约束与 corner。
   - **Power**：总功耗/动态/静态，单位（mW），活动率、电压、温度、时钟频率假设。
   - **Area**：cell area（有库时，um²）或 GTECH 面积；同时给出寄存器/状态 bit 数。

- 若只有 GTECH、没有 PDK：可以报告 GTECH 结构/面积与 DC 的时序估计，但必须标注“无 PDK，非签核级”，不得伪造绝对 power/timing 数字。
- EDA 运行不得阻塞 87/87 功能回归；若 EDA 超时或失败，停止 EDA，保留日志，按 8.3 fallback 完成自评。

### 8.3 EDA 不可用或无 PDK 时（fallback）

- **Performance**：用 87 例日志的 instrCnt/cycleCnt 计算 IPC（83 基础均值、4 custom 均值、87 全量均值）。
- **面积/状态**：统计寄存器/状态 bit 数（GPR、流水线寄存器、CSR/计数器、状态机、推断 RAM；外部 DRAM 不计）；优先 Yosys `stat`，不可用时用 RTL 结构统计脚本。
- **关键逻辑级数**：统计最长组合路径的逻辑级数（从输入/寄存器到寄存器/输出）；优先用 Yosys/DC 报告，不可用时按 RTL 模块手工分析，并在报告中说明方法和路径。
- **功耗**：优先用 VCD 统计每周期寄存器翻转 bit 数作为动态功耗 proxy；无 VCD 时用状态 bit 数作为粗 proxy；写明公式、数据来源和局限。
- 所有 fallback 数据必须标注“proxy/estimate”，不得与 EDA 签核数据混用。

## 9. 自评 PPA 与评分卡（必交）

- 性能：87 例平均 IPC（必须来自日志）；EDA 可用时另报 Fmax/关键路径。
- 面积：优先 cell area（EDA+PDK）；否则状态 bit 数 + 关键逻辑级数，并写清方法/命令。
- 功耗：优先 EDA power report；否则 VCD 翻转 proxy；再否则状态 bit 数 proxy。
- 按 task.md 第 6 节评分卡模板填写 F1–F5、P1–P3、T、自评总分；隐藏测试 F2 无法本地运行，标 N/A/估计并说明依据，不得编造。
- 所有数字必须能由日志/脚本/EDA 报告复算；自评与交付数据必须一致；EDA 数据与 fallback 数据分表列出。

## 10. 必交交付件（projects/rva01_agent/）

1) vsrc/：完整可综合 RTL；固定文件与骨架契约保持不变。
2) logs/：87 条用例日志（+ 可选 suite 日志）、results.tsv、first_failures.md、debug_report.md。
3) eda/：DC/PT/Formality 等脚本、日志、报告、库/corner 说明；无 EDA 时为 ppa/ 下的状态 bit/逻辑级数统计脚本与结果。
4) run.sh：从 clean 环境复现 build + 87 例回归 + IPC 汇总的脚本。
5) REPORT.md：环境版本、start/end 时间与实际用时、设计概述、固定文件哈希、87 例逐例 PASS/FAIL + IPC、失败与修复、自测覆盖、PPA 口径/公式/数据（Power/Timing/Performance/Area）、EDA 与 fallback 对照、评分卡、局限与诚实声明。
6) SELF_EVAL.md（或 REPORT.md 内的评分卡）：自评 F/P/T 与总分。
7) 提交前用 sha256sum 记录固定文件与测试目录哈希。

## 11. 最终回复格式（给评测方）

- 实际用时（start/end，是否 ≤120 分钟）。
- 公开 87/87 通过数、通过率；可选 suite 结果。
- **Performance**：平均 IPC（83 / 4 / 87），EDA 可用时附 Fmax/关键路径。
- **Timing**：WNS/TNS、关键路径、逻辑级数、corner；无 EDA 时说明 fallback。
- **Power**：EDA 报告或 proxy 数值、公式、单位与假设。
- **Area**：cell area 或状态 bit 数 + 关键逻辑级数。
- 交付件路径列表。
- 失败/未完成项与根因；自评总分与评分卡摘要。
- 任何违规或偏差（必须诚实报告）。

现在开始：先记录开始时间，读 requirements.txt 与题面，配置环境并完成首次构建；不要等待确认。
