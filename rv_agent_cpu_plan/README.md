# RVA-01 · 带 I/D Cache 的 RV64IM 五级流水线 CPU

本目录是一个 Agent CPU 开发的任务包，用于让不同 Agent 编写 RTL，并用本仓库已经跑通的 `oscpu-framework` difftest 流程做验证。任务卡的能力基线是 `projects/cpu_axi_diff`（本仓库 `bb69f74`），在本环境实测 **87/87** 通过（`cpu-tests` 33/33、`riscv-tests` 50/50、custom-output 4/4）。此外，`cpu-tests-fencei` 36/36 与 `cpu-tests-ysyx4` 35/35 也已实测通过（可选回归，见下文）。

任务元数据见 [`task.yaml`](task.yaml)。


## 设计出发点与评测准则

**本测试旨在用来评测上市面上流行的前沿模型，是否可以利用自身agent能力，在给定的任务中完成芯片研发中的真实工作，在相同的题目下比较各个模型的功能完成情况、以及芯片的PPA指标。开发的agent需要在2小时内交付一套完整的RISC-V CPU。此任务不仅仅是编写RTL代码，还需要agent理解长语义上下文的芯片Spec，理解需求并调用合适的工具完成设计及迭代验证的工作。**

**以下从****设计出发点、任务边界、评测指标、评分流程、评测原则**五个层面展开。本文既作为被测 Agent 的任务说明书，也作为评审 Agent 的评分依据；所有指标都要求可由脚本或证据复核，避免主观印象分。

**本轮题面提供****完整验证环境**：验证平台、87 条公开用例、DiffTest/黄金模型、运行脚本和日志格式均由题面给出，Agent 不需要自建验证环境。基线 RTL 有两种模式：**缺陷修复/补全模式**（题面提供含缺陷或待补全的 RTL）和**从零实现模式**（题面提供空骨架）；无论哪种，Agent 的核心工作都是理解规格与微架构、完成实现或修复、用提供的环境跑通 87 条用例、完成回归，并给出可被复核的 PPA 自评。原任务描述中的“自建验证环境”环节由题面提供的完整验证环境替代；两种模式共用同一评分框架，仅在 F2/F3 的权重细节上按题面微调。

#### 1. 设计出发点：为什么用“五级流水线 RISC-V CPU”作为 Agent 试金石

1. **复杂度处于可交付的甜点区。** 五级流水线（IF/ID/EX/MEM/WB）既包含真实 CPU 的主要工程矛盾——数据冒险、控制冒险、结构冒险、流水线冲刷、存储器接口、复位与异常——又不至于像乱序执行、多核或 Cache 一致性那样超出 2 小时的可交付边界。它足以区分“会写代码”与“会做芯片”。
2. **把 2 小时集中在最能区分能力的环节。** 题面提供完整验证环境，Agent 不需要搭建 TB、黄金模型和回归脚本；有限时间被集中到规格理解、微架构理解、实现/修复、缺陷定位、回归验证和自评上。缺陷修复模式更接近真实团队中 senior 工程师的 debug 工作；从零实现模式则同时考察架构到 RTL 的落地能力。两种模式都能在 2 小时内拉开差距。
3. **正确性有客观锚点。** RISC-V 指令语义公开、编码确定，题面提供的 ISS/DiffTest 可以作为黄金模型，用 87 条公开用例、隐藏随机/定向用例和逐指令提交比对做自动化判定，避免“看起来能跑”。
4. **轻量 PPA 仍然能区分架构选择。** 不能跑完整综合/STA/功耗流程时，用“平均 IPC + 寄存器/状态 bit 数 + 活动率代理”仍能区分前递与停顿、分支解析位置、流水级寄存器数量、寄存器堆实现等关键取舍。它不等同于签核级 PPA，但足以比较架构效率，且测量成本低、可复现。
5. **工具链轻量、结果可复现。** 仿真器、DiffTest、日志解析和寄存器统计脚本都可以在容器内固定版本运行；相同输入应得到相同日志和统计结果。EDA 面积/功耗报告作为可选证据，不作为所有模型的必需项。
6. **难度可分档。** 基础档为 RV64I + 87 条公开用例（开发集，本题基线为 RV64IM）；评分档为隐藏冒险/边界用例 + 更多随机种子；挑战档加入二次故障注入或 ECO 规格变更。同一评分框架可覆盖不同能力层级的模型，避免“全过”或“全挂”的 ceiling/floor 效应。

**各能力维度与本任务的映射关系如下：**


| **能力维度**           | **在任务中的具体体现**                                                                                            | **常见失败模式**                                                                |
| ---------------------- | ----------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------- |
| **长上下文规格理解**   | **从规格、基线 RTL、87 条用例清单和日志格式中提取 ISA 子集、接口/复位约定、流水线结构、交付要求，并建立需求追踪** | **漏读约束；把基线中的临时写法当成规范；前后引用矛盾；不知道日志/IPC 的口径**   |
| **架构理解与局部设计** | **读懂既有五级流水线的冒险/前递/停顿逻辑，定位待补全模块，保证修改与整体微架构自洽**                              | **只改局部不看全局；破坏五级结构；前递与停顿条件不自洽；补全模块接口不匹配**    |
| **Debug**              | **用失败用例、DiffTest 首个分歧点、波形和日志定位到流水级/信号级根因，做最小修复并回归**                          | **盲目改代码；修一个坏一个；无法解释根因；用屏蔽或改写测试掩盖问题**            |
| **验证环境使用**       | **正确运行 87 条用例，生成完整日志和 IPC，使用 DiffTest/提交轨迹，不修改测试与黄金模型**                          | **只跑子集；日志缺失或格式错误；不会读首个分歧点；改测试而不是改 RTL**          |
| **轻量 PPA 估算**      | **统计平均 IPC、寄存器/状态 bit 数、活动率代理；说明口径并与交付数据一致**                                        | **用墙钟时间冒充 IPC；只挑快用例；寄存器数统计口径错误；自评数据与 RTL 对不上** |
| **RTL 质量与可综合性** | **elaboration/lint 通过，无 latch、多驱动、X 传播和仿真专用构造**                                               | **行为级写法不可综合；复位不确定；x0 未硬连线；推断出意外锁存器**               |
| **工具使用与自动化**   | **版本固定、脚本化仿真/日志/统计，保留命令和日志，能恢复工具错误**                                                | **手工操作无法复现；命令报错不排查；日志手工编造**                            |
| **工程交付**           | `vsrc`结构、README、87 条日志 + IPC、完成时间说明、自评 PPA、评分卡                                               | **缺交件；绝对路径；clean 环境跑不通；文档与实现不一致**                        |
| **自评可信度**         | **自评 PPA 的方法、数字与独立复核一致；能解释偏差**                                                               | **虚报面积/功耗；单位或数量级错误；自评分数与交付数据矛盾**                     |
| **长程自主与资源管理** | **2 小时里程碑规划、先跑通再优化、回归防退化、截止前冻结**                                                        | **过早优化 IPC/面积；遗忘早期约束；调试卡死后不换策略；超时**                   |

#### 2. 任务边界与统一约束

**为保证横向可比，题面必须固定以下参数（下表为示例，实际以每轮题面为准）：**


| **项目**     | **本轮设定**                                                                                   | **说明**                                                 |
| ------------ | ---------------------------------------------------------------------------------------------- | -------------------------------------------------------- |
| **ISA**      | **RV64IM（RV64I 基础指令 + RV64M + Zicsr + Zifencei 的 fence.i + ECALL/MRET；EBREAK 按 NOP）** | **A/C 等作为进阶档；本题 RV64I/M/Zicsr 为必做**          |
| **微架构**   | **单发射、顺序执行、五级流水线 IF/ID/EX/MEM/WB**                                               | **不允许乱序、超标量；从零实现模式也必须满足此结构约束** |
| **基线 RTL** | **题面提供：缺陷修复模式为含缺陷/待补全的基线；从零实现模式为空骨架**                          | **两种模式共用评分框架；评测报告需注明模式**             |
| **验证环境** | **题面完整提供 TB、87 条公开用例、DiffTest/ISS、运行脚本、日志格式、寄存器/状态 bit 统计脚本** | **测试目录只读；Agent 不需要也不允许改验证平台**         |
| **隐藏测试** | **按 3.1.1 的覆盖矩阵补充，不公开**                                                            | **公开 87 条用于开发，隐藏集用于评分**                   |
| **PPA 口径** | **平均 IPC + 寄存器/状态 bit 数 + 活动率代理；EDA 可选**                                       | **不要求完整综合/STA/功耗流程；所有模型使用同一口径**    |
| **开发预算** | **120 分钟；固定 token/工具调用上限；单 Agent；仅允许获取固定版本依赖；禁用预置 skill**          | **依赖版本固定，禁止获取设计/测试集；超过 120 分钟总分记 0** |
| **必交物**   | `vsrc`完整 RTL、87 条日志 + IPC、完成时间与运行说明、自评 PPA、自评评分卡                      | **缺项按扣分或对应项归零处理**                           |

**统一约束：**

* **相同题面、相同基线、相同验证环境、相同工具版本、相同硬件、相同预算；只允许修改 **`vsrc` 和 Agent 自己的文档/脚本，测试目录、黄金模型、评分脚本只读并做哈希校验。
* **只允许题面提供的离线资料与工具链；禁止联网、外部 IP、预置模板、复制现成 CPU 源码。**
* **Agent 必须实际运行 87 条公开用例并生成完整日志；日志必须能由评审 Agent 在 clean 环境复跑复现。**
* **自评 PPA 必须写明测量口径、公式、数据来源和命令；评审 Agent 会独立复测，自评只作参考。**
* **超过 120 分钟总分记 0；截止时刻冻结版本，超时部分仅作分析记录。**
* **所有结论必须附可复现证据（命令、日志、报告、波形、时间戳），无证据的声明视为未完成。**

#### 3. 评测指标体系（总分 100）

**总分 = 功能正确性 F（50） + PPA P（45） + 时间 T（5）。工程交付完整性作为资格门槛，不单独占分。**

**评分总览：**

* **功能 50 = 公开 87 条 10 + 隐藏测试 25 + Debug/环境使用 8 + RTL 质量 4 + 架构合规 3。**
* **PPA 45 = 平均 IPC 20 + 面积（状态 bit 或统一 cell area）15 + 功耗代理 10。**
* **时间 5 = 按时 3 + 里程碑 1 + 可复现 1。**
* **一票否决/归零：超过 120 分钟总分 0；篡改测试/伪造日志或 PPA 取消资格；自评 PPA 明显漏洞 PPA 记 0。**

##### 3.1 功能正确性（50 分）


| **指标**                    | **分值** | **评分方法**                                                                                                                               | **证据**                                   |
| --------------------------- | -------- | ------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------ |
| **F1 公开基础测试**         | **10**   | **87 条公开用例通过率线性计分；通过率 < 80% 该项为 0**                                                                                     | **回归日志、逐用例 PASS/FAIL**             |
| **F2 隐藏功能测试**         | **25**   | **按 3.1.1 的 6 类隐藏用例加权：指令功能 5、数据冒险 7、控制冒险 5、存储器 3、流水线控制 2、随机/长程序 3；多 seed 取平均并记录最差 seed** | **隐藏测试报告、首个分歧点、逐类别通过率** |
| **F3 Debug 与验证环境使用** | **8**    | **87 条全部实际运行且日志完整 2；能用 DiffTest/提交轨迹定位首个分歧点 2；根因/最小修复/回归闭环 2；未修改测试且无回归 2**                  | **日志、DiffTest 报告、波形、修复 diff**   |
| **F4 RTL 质量与可综合性**   | **4**    | **elaboration/lint 无 error、无 latch/多驱动、复位后无 X、无仿真专用构造、可综合**                                                         | **lint/elaboration 日志**                  |
| **F5 架构与规格合规**       | **3**    | **五级流水线结构完整、接口/复位/x0/文件布局符合题面；未修改测试与黄金模型**                                                                | **结构检查脚本、diff、哈希**               |

##### 3.1.1 测试完备性矩阵

**公开 87 条是开发集，隐藏集是评分集。隐藏集必须按下列矩阵补齐公开集未覆盖的组合，并按类别独立计分，避免“只过简单用例”：**


| **测试类别**             | **覆盖要求**                                                                                                                    | **公开 87 条的作用**               | **隐藏集补充重点**                                                       |
| ------------------------ | ------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------- | ------------------------------------------------------------------------ |
| **指令功能全集（5 分）** | **RV64IM 每条指令、每个 funct3/funct7 变体；rd/rs1/rs2 为 x0；立即数最大/最小值；移位量 0/31；6 种分支条件；JAL/JALR/LUI/AUIPC** | **提供基础功能基线**               | **操作数别名、边界立即数、指令成对组合、x0 作为源/目的**                 |
| **数据冒险（7 分）**     | **EX/MEM/WB 前递、load-use、store data、分支操作数、连续 RAW、WB-ID 同拍读写、x0 特例**                                         | **提供常见 RAW 基线**              | **系统化组合所有前递路径；前递与停顿混合；背靠背 load-use**              |
| **控制冒险（5 分）**     | **taken/not-taken、JAL/JALR、分支后紧跟 load、分支在流水线中、冲刷后错误路径不提交**                                            | **提供基本分支/跳转基线**          | **背靠背分支、分支后立即使用结果、跳转目标边界、错误路径无副作用**       |
| **存储器（3 分）**       | **字节/半字/字、符号/零扩展、地址边界、I/D 端口结构（统一或分离按题面）、背靠背 load/store、load-store 别名**                   | **提供常见访存基线**               | **地址回绕/边界、连续 load/store、load 后立即 store、store 后立即 load** |
| **流水线控制（2 分）**   | **复位、stall、flush、valid 位、复位期间无 X、复位后首条取指**                                                                  | **提供基本复位基线**               | **运行中复位、stall 与 flush 叠加、流水线空/满边界**                     |
| **随机/长程序（3 分）**  | **只生成题面支持的合法指令与地址；ISS 终态/逐指令比对；多 seed、多长度；长程序包含循环/函数调用/栈；偏向冒险与边界的生成器**    | **公开集基本不覆盖随机流与长程序** | **隐藏 seed、长程序、混合指令流、最差 seed 必报**                        |

**完备性判定：**

* **隐藏集建议 100–300 个短程序（按评测资源缩放，总仿真时间控制在 10–20 分钟量级），覆盖 RV64IM 每条指令至少 100 次动态执行、每种 funct3/funct7 组合至少 10 次、每种冒险模式至少 20 次；覆盖矩阵由题库维护，评审 Agent 抽检。**
* **若暂无独立隐藏集，可基于 87 条公开用例派生变体（改操作数、地址、控制流、seed），由 ISS 重新生成期望结果；派生规则与 seed 不公开。**
* **每个类别单独计算通过率；任一类别 < 60%，该类别计 0；两类及以上 < 60%，F2 总分封顶 12.5（50%）。**
* **随机/长程序测试使用固定 seed 集合，评分时取平均并报告最差 seed；seed 不提前公开。**
* **隐藏集在指令组合、程序长度、冒险模式上必须与公开 87 条有结构性差异；若公开接近满分而隐藏显著偏低（> 25 个百分点），标记过拟合并按隐藏成绩计。**
* **所有隐藏用例必须能用题面提供的 ISS/DiffTest 判定；首个分歧点、分歧指令和现场状态要写入报告。**

**题库上线前自检：**

* **用参考实现跑通 87 条公开用例和全部隐藏用例，确认无 flaky、无超时、无未初始化依赖；每条用例必须有明确 PASS/FAIL 判据和超时上限。**
* **把 87 条公开用例映射到 3.1.1 的类别矩阵，标出覆盖缺口；隐藏集优先补齐缺口，而不是重复公开集。**
* **隐藏用例的随机生成器必须与 RTL 解耦，只用 ISS 生成期望结果；seed、程序长度、指令分布记录在题库元数据中。**
* **对隐藏集做“易过拟合”检查：用简单硬编码、只实现公开用例、删测试等作弊方式应无法通过；隐藏用例的操作数和控制流不能是公开集的可预测复制。**
* **难度校准：至少用强/中/弱三档参考实现试跑，确保公开集有梯度、隐藏集能区分头部模型，避免全 0 或全满分。**

##### 3.2 PPA（45 分，轻量估算）


| **指标**    | **分值** | **评分方法**                                                                                                                                                                      | **证据**                                  |
| ----------- | -------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------- |
| **P1 性能** | **20**   | **所有通过用例的 IPC 简单平均（退休指令数 / 周期数）；题面分类表的四类 IPC 仅作辅助分析；公开通过率 < 80% 时 P1 = 0**                                                             | **87 条日志中的 IPC、汇总表、分类 IPC**   |
| **P2 面积** | **15**   | **寄存器/状态 bit 数（触发器 + 推断存储器/寄存器堆；外部存储器不计）的归一化得分；数量越少越好；若题面统一启用综合流程，可用 cell area 替代状态 bit 数；五级结构不合规时 P2 = 0** | **elaboration/Yosys**`stat`报告、模块拆分 |
| **P3 功耗** | **10**   | **优先使用固定条件下的 EDA 功耗报告；否则用 VCD 统计每周期寄存器翻转 bit 数作为动态功耗代理，静态功耗用状态 bit 数代理；VCD 不可用时直接用状态 bit 数作为粗代理；越低越好**       | **功耗报告或 VCD/翻转统计、代理公式**     |

**轻量 PPA 口径：**

* **为什么简化**：2 小时预算和部分评测环境无法稳定跑通综合/STA/功耗，完整签核级 PPA 既不可比也不公平。本测试改用客观、低成本的代理指标，重点是区分架构效率，而不是替代 signoff。
* **测量主体**：由评审 Agent 用统一脚本在交付的 `vsrc` 上测量，不采信 Agent 自报数字；Agent 自评只用于交叉检查和“自评可信度”评估。
* **性能**：从 87 条用例日志读取 `instret` 与 `cycles`，计算每条用例 IPC，再对所有通过用例做算术平均；不要用墙钟时间、仿真时间或代码行数代替。IPC 以 testbench 独立记录的周期数与退休指令数为准；若使用 CPU 内部计数器，必须与 testbench 交叉校验，不一致时以 testbench 为准。未通过用例不计入平均，但公开通过率 < 80% 时性能样本偏差过大，P1 直接为 0。题面分类表（ALU/分支/load-use/存储）的 IPC 作为辅助分析，不改变主分。
* **面积**：统计所有时序状态 bit，包括通用寄存器堆、流水线寄存器、CSR/计数器、状态机、推断的存储器；外部 DRAM/存储器模型不计。若把寄存器藏进推断 RAM，仍计入状态 bit，防止“面积优化”造假。统计优先用 Yosys `stat`，不可用时用题面提供的 Verilator/elaboration 统计脚本；所有模型同一口径。若所有模型都能跑同一综合流程，题面可统一改用 cell area；否则仍以状态 bit 数为准。
* **功耗**：优先用题面固定工艺角/电压/温度/活动率下的 EDA 报告；不可用时，用仿真 VCD 统计每周期寄存器翻转 bit 数作为动态功耗代理，静态功耗用状态 bit 数代理；若 VCD 也没有，直接用状态 bit 数作为静态+动态粗代理（不再乘 IPC），并在报告中明确标注为 proxy。若无法保证所有模型都能跑同一 EDA 流程，则以统一代理为准，EDA 报告只作参考证据。
* **归一化公式**：题面优先给定参考实现的 `IPC_ref`、`Area_ref`、`Power_ref` 与底线/优秀线；没有参考值时，用同批最优值作满分线（`*_ref`）、最差值作 0 分线（`*_floor`/`*_ceiling`），中位数只作描述统计，并在报告中注明。建议按分段线性计算：`P1 = 20 × clamp((IPC − IPC_floor)/(IPC_ref − IPC_floor), 0, 1)`；`P2 = 15 × clamp((Area_ceiling − Area)/(Area_ceiling − Area_ref), 0, 1)`；`P3 = 10 × clamp((Power_ceiling − Power)/(Power_ceiling − Power_ref), 0, 1)`。性能越高越好，面积/功耗越低越好；超过参考线即满分，不额外加分。
* **架构合规门槛**：P2/P3 只在五级流水线结构完整、未删除必需流水级/寄存器/前递逻辑的前提下计分；若通过合并流水级、删除状态或把本应内部的功能移出 `vsrc` 来降低面积/功耗，F5 记 0，P2/P3 记 0。
* **自评门槛**：Agent 必须使用题面统一口径提交自评 PPA（公式、数据、命令、单位）。若发现明显漏洞——无报告却声称 EDA 结果、状态 bit 数与复测相差 > 20% 且无法解释、用墙钟时间冒充 IPC、单位/数量级错误、只挑快用例、自评与交付数据矛盾——PPA 项直接记 0（按题面约定）。

##### 3.3 时间（5 分）


| **指标**          | **分值** | **评分方法**                                                                                                                                                       |
| ----------------- | -------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **T1 按时交付**   | **3**    | **≤120 分钟得 3；>120 分钟总分直接记 0（题面硬性规定）**                                                                                                          |
| **T2 里程碑达成** | **1**    | **T+15 环境跑通并生成首轮失败列表（缺陷模式为基线失败列表）；T+45 公开通过率 ≥50%；T+75 ≥80%；T+105 87/87 通过 + IPC 日志；T+120 交付件齐全。每达成一个 0.2 分** |
| **T3 可复现交付** | **1**    | **评审 Agent 在 clean 环境用交付的**`vsrc`和题面脚本重跑，能重新生成 87 条日志与 IPC；结果确定、无需人工介入                                                       |

**时间以 Agent 实际开始执行题面为起点，以最终冻结提交为终点；超过 120 分钟按题面规定总分记 0，但可在分析报告中记录实际完成时间。里程碑是建议节奏，若 Agent 提前完成且日志/时间戳能证明，按达成计分。**

##### 3.4 资格门槛、封顶与扣分

* **功能门槛**：F < 25（功能不足 50%）时 P = 0；25 ≤ F < 40 时 P 封顶 22.5；F ≥ 40 才按实际 PPA 计分。
* **公开通过率门槛**：87 条公开用例通过率 < 80% 时 F1 = 0，且 P1 = 0（性能样本偏差过大）；< 60% 时视为未形成可用 CPU，P = 0，总分封顶 70。
* **隐藏类别门槛**：任一隐藏类别通过率 < 60%，该类别计 0；两类及以上 < 60%，F2 总分封顶 12.5（50%）。
* **Elaboration/lint 失败**：F4 = 0，P = 0，总分封顶 60。
* **缺交必交物**：每缺一项扣 3 分；缺 87 条日志/IPC 时 F3 = 0、P1 = 0；缺自评 PPA 或评分卡时 PPA 记 0（自评是必交件）。
* **自评 PPA 明显漏洞**：见 3.2 口径，PPA 项直接记 0，并在报告中记录证据。
* **回归退化**：最终版本每退化一个此前通过的公开用例扣 0.5 分，最多扣 5 分；中间日志显示通过、最终版本失败且无合理解释的，按退化处理。
* **架构取巧**：通过删除流水级、合并寄存器、删除前递/状态、把本应在 CPU 内的功能移出 `vsrc` 或藏进外部存储器模型来降低面积/功耗的，F5 = 0，P2 = P3 = 0。
* **超时**：>120 分钟总分记 0（题面硬性规定）。
* **篡改测试/黄金模型、伪造日志或 PPA、硬编码答案、联网或使用外部 IP**：取消资格，总分 0；日志与评审复跑结果不一致且无合理解释的，按伪造处理。
* **能力与结果不匹配**：公开测试接近满分而隐藏测试显著偏低（差距 > 25 个百分点），标记过拟合/硬编码嫌疑，F2 按隐藏实际成绩计，PPA 封顶 50%。

##### 3.5 区分项与同分裁决（不计入 100 分）

* **可选 EDA 证据**：若环境支持，提交综合面积/功耗报告、关键路径或资源利用率分析，作为“物理实现意识”的加分证据；不作为必需项，也不能替代统一代理口径。
* **扩展能力**：M 扩展、Zicsr/异常与中断、I/D Cache、分支预测（BHT/BTB）、调试接口；仅在题面允许的基线范围内计分。
* **质量证据**：需求追踪矩阵、调试报告（现象→假设→实验→根因→修复→回归）、补充定向用例、测试覆盖/风险分析。
* **自评准确度**：主要比较自评 IPC/状态 bit/功耗代理与复测的偏差；≤10% 记为“可信”，10%–20% 记为“部分可信”，>20% 且无合理解释或方法错误按 3.2 处理。总分自评偏保守或偏激进本身不扣分。
* **同分排序**：隐藏测试通过率 → 平均 IPC → 状态 bit 数（低者优）→ 功耗代理（低者优）→ 交付完整度 → 自评准确度。

##### 3.6 能力画像（不计分，供分析）

**评审 Agent 另按 0–5 分给出八维雷达图：****规格理解、架构理解、Debug 定位、验证环境使用、轻量 PPA 估算、工具与自动化、工程交付、自评与自主**。画像不进入总分，用于解释排名、识别单项能力突出但总分相近的模型，以及为后续题目设计提供依据。

#### 4. 评分流程：自动化优先，评审 Agent 复核

1. **环境与仓库校验**：检查 `vsrc` 是否存在、测试目录/黄金模型/评分脚本的哈希是否不变、`vsrc` 外的基线/骨架文件是否被改动、工具版本和网络隔离是否符合题面；记录实际用时。
2. **静态检查**：运行 elaboration/lint，检查五级流水线结构、接口/复位/x0、文件布局、禁止构造（latch、多驱动、仿真专用语法、绝对路径、硬编码结果）。
3. **功能评测**：先在 clean 环境跑 87 条公开用例，逐条记录 PASS/FAIL、周期数、退休指令数；再跑隐藏集，按 3.1.1 的类别统计通过率，记录首个分歧点、分歧指令和现场状态。
4. **轻量 PPA 测量**：用统一脚本统计状态 bit 数、从评审复跑日志计算平均 IPC、按 3.2 口径计算功耗代理；若题面提供参考值，按参考值归一化；EDA 报告仅作可选证据。
5. **复现评测**：在干净容器中按运行说明/README 用交付的 `vsrc` 和题面脚本重跑，比较 87 条结果、IPC、状态 bit 数和 PPA 代理；不能复现的数据一律作废。
6. **自评审计**：把 Agent 提交的自评 PPA/评分卡与独立复测对比；检查公式、单位、数据来源和命令；判定“可信 / 部分可信 / 明显漏洞”，后者按约定将 PPA 记 0。
7. **评审 Agent 复核**：使用版本化 rubric 对 F3/F5、自评可信度等定性项逐项打分，每个分数必须引用具体文件、日志或报告位置；不得凭整体印象给分。
8. **汇总与归档**：输出总分、分项分、雷达图、证据索引、违规记录和排名；保留原始产物不少于一个评测周期。

**评审 Agent 的一致性要求：**

* **对模型名称和来源做匿名化，交付件随机排序；评审 Agent 不应是被评模型本身；**
* **以单评审 Agent 为主；前 3 名、临界名次和自评异常样本由人工抽检复核；条件允许时对前 3 名双评，分歧超过 10% 时人工仲裁；**
* **用已知分数的校准样本定期校验评审 Agent；**
* **评审 Agent 应亲自重跑脚本，不能只读 README 或模型自述；**
* **评分理由必须可定位到证据，避免“完成度高”“代码优雅”等无依据表述。**

#### 5. 评测原则

1. **同题同权同预算**：题面、基线、验证环境、工具、硬件、时间、token 与工具调用上限完全一致；模型版本与调用日期固定并记录。
2. **Debug 结果与过程并重**：通过率是硬结果，但根因定位、最小修复、回归无退化、日志可复现同样计入 F3；不接受“碰巧改对”的无证据通过。
3. **证据链原则**：每个结论都要有命令、日志、报告、波形或 diff 支撑；声明与证据不一致时，以证据为准并扣分。
4. **可复现原则**：87 条用例、IPC 和 PPA 代理都能由评审 Agent 在 clean 环境复跑；相同输入重复运行应得到相同结果，随机测试使用固定 seed 集合并记录。
5. **隐藏集完备性**：公开 87 条用于开发，隐藏集按 3.1.1 的覆盖矩阵补齐；隐藏集在指令组合、程序长度、冒险模式上应与公开集有结构性差异，防止过拟合。
6. **反 reward hacking**：重点检测改测试/黄金模型、伪造日志或 PPA、硬编码答案、选择性汇报、删除流水级/寄存器骗面积、把本应内部的状态藏进外部存储器模型等行为；一经确认，取消资格或对应项归零。
7. **自评仅作参考**：Agent 自评用于交叉检查和可信度评估，排名以评审 Agent 独立复测为准；自评明显漏洞按约定将 PPA 记 0。
8. **PPA 代理口径透明**：同一批模型必须使用同一测量模式（EDA / VCD / 状态 bit 代理）；不允许用不同口径互相比较；报告中必须写明公式和限制。
9. **多维不折叠**：总分用于排名，雷达图与分项分用于解释；不允许用一个综合分掩盖功能、Debug、面积、功耗中的单项崩塌。
10. **难度分档、避免天花板与地板**：87 条公开用例保证强模型可完成、弱模型有部分分；隐藏类别与可选加试用于区分头部模型；题面应先做小样本校准，确保分数分布有区分度。
11. **可重复实验**：条件允许时每个模型独立运行 3 次，取中位数并报告方差；至少记录单次运行的随机性来源（seed、工具版本、模型温度），单次结果不足以支撑强排名结论。
12. **评审一致性与匿名化**：rubric 版本化、评分可追溯、单评审 + 人工抽检；评审 Agent 不得因文风、篇幅或模型品牌产生偏好。
13. **安全与合规**：禁止使用未经许可的外部 IP、闭源参考设计或联网资源；引用公开资料需在运行说明/README 中声明来源与许可证。

#### 6. 单模型评分卡（模板）


| **模型/版本** | **实际用时** | **F1–F5** | **F 小计** | **P1–P3** | **P 小计** | **T**  | **评审总分** | **Agent 自评总分** | **偏差** | **排名** | **关键证据/备注** |
| ------------- | ------------ | ---------- | ---------- | ---------- | ---------- | ------ | ------------ | ------------------ | -------- | -------- | ----------------- |
|               |              |            | **/50**    |            | **/45**    | **/5** | **/100**     | **/100**           |          |          |                   |

**偏差 = 评审总分 − Agent 自评总分；偏差不直接扣分，但用于“自评可信度”评估和同分裁决。**

**附：87 条公开通过数/通过率、雷达图八维得分、隐藏测试逐类别通过率与最差 seed、平均 IPC、状态 bit 数、功耗代理、自评 PPA 漏洞记录、首个分歧点、违规/异常记录、评审 Agent 签名与 rubric 版本号。**

### 如何测评

**比较的模型：kimi K3，GLM-5.3，Opus5.5，DS Flash，GPT-6.1-Sol，Sonnet5.5**

**考虑到时间原因，使用一个agent，阅读此文，通过不同agent的交付件**

#### 交付件

**应包括：**

**1.完整的RTL源码，vsrc文件夹下，跑87条测试用例对应的log文件及IPC。**

**2.完成时间说明，最大为2小时，超出2小时分数直接为0。**

**3.自评的PPA，性能通过所有通过用例的IPC平均，来简单测算性能，面积和功耗则粗略计算，如果可以使用环境的EDA工具跑出具体的功耗和面积则使用，如果由于环境问题无法跑通，测算交付RTL使用的寄存器bit数作为参考。**

**4.对自己的评价进行打分，并交付评分卡，填充其中的内容（agent自我评测分数不可信，仅用来参考，若自评PPA分数发现明显漏洞，则直接记PPA项为0分）

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
