# pide 产品需求文档

- **文档状态**：Draft
- **产品名称**：pide.nvim
- **产品形态**：Neovim 中的 Agentic IDE
- **主要 Agent**：Pi coding agent
- **扩展方向**：通过统一能力模型兼容支持 ACP 的其他 Agent
- **需求基线**：覆盖 ThinkRail 的主要产品能力，并增加代码评论、Thread 分叉与合并等 Neovim 原生工作流

---

## 1. 产品愿景

pide 让用户不离开 Neovim，就能完成从理解项目、讨论方案、实现代码、验证行为、审查变更到交付 PR 的完整开发过程。

它不是简单的 Agent 终端，也不是在 Neovim 中复制一个 Web IDE，而是将 Agent 的会话、工具、任务和项目知识与 Neovim 的 buffer、window、tabpage、diff、diagnostics 和文件操作结合起来。

产品的核心闭环是：

```text
理解项目与需求
  → 形成 Spec 和实施计划
  → 在隔离 Workspace 中执行
  → 代码、评论和运行时证据共同驱动修改
  → 人工/Agent 审查
  → 更新长期项目知识
  → 提交并交付 PR
```

## 2. 产品目标

### 2.1 核心目标

1. **完整开发闭环**：覆盖 ThinkRail 的 workspaces、sessions、Spec、TODO、Review、Artifacts、Subagents、Background Commands、PR 和产品化能力。
2. **代码与讨论双向连接**：用户可以直接在代码或 diff 上留 comment，并将单条或一批 comment 连同精确上下文发送给 Agent。
3. **可分叉的 Agent 工作**：可以从当前 thread 或指定历史节点创建子代理任务，也可以将多个 thread 的有效上下文合并成新的工作 thread。
4. **Neovim 原生体验**：代码区始终是工作中心，Agent 面板服务于代码，不迫使大家在独立聊天应用中切换上下文。
5. **Pi 优先**：完整复用 Pi 的模型、会话、工具、skills、extensions、compaction、认证和状态，不另建 Agent 引擎。
6. **ACP 可扩展**：通用聊天、上下文、评论、workspace 和 review 不绑定 Pi；其他 ACP Agent 按能力接入并降级。
7. **少而有效的 skills**：合并 ThinkRail、Matt Pocock Skills 和 pstack 的重复能力，形成一组小型、可组合的核心工作流。
8. **复用现有 Pi extensions**：支持安装和管理已有 Pi package/extension，不要求为 pide 单独开发扩展体系。

### 2.2 产品原则

- **代码是中心，Agent 是协作者**：任何 Agent 操作都不能无故抢走代码窗口、破坏当前布局或覆盖用户未保存的修改。
- **证据优先**：完成工作必须有测试、运行输出、真实 UI、文件状态、diff 或其他可检查证据，不能只依赖 Agent 自我声明。
- **隔离与可审查**：并行工作优先使用独立 worktree；变更必须可定位、可评论、可回滚、可审查。
- **长期知识属于项目**：重要意图、决策、约束和术语不随 thread 消失。
- **原始历史不被改写**：fork、clone、merge、compact 等操作都保留源 thread 和来源关系。
- **能力按后端暴露**：Pi 的完整能力不被压缩成最低公分母；其他后端按实际接入能力开放功能，无替代方案的隐藏，有替代方案的明确标注降级差异。
- **不重复造已有能力**：Neovim 已有的编辑、文件树、终端、diff、搜索和窗口管理直接复用；已有 Pi extensions 直接安装使用。

## 3. 目标用户与典型场景

### 3.1 目标用户

- 已经在 Neovim 中完成主要开发工作的工程师。
- 希望使用 Pi 管理真实项目，而不只是进行一次性问答的用户。
- 需要并行执行多个 Agent 任务，同时保持代码审查能力的用户。
- 需要跨 thread 延续、分叉、汇总和审查长期工作的团队或个人。

### 3.2 典型场景

1. 在已有代码库中建立长期 Spec，并让后续 Agent 遵循。
2. 从一个 issue 或想法开始，先讨论产品和设计，再实施。
3. 阅读代码或 diff 时留下评论，既可单条立即发送，也可积攒后批量发送给 Pi。
4. 将单条或一批评论从当前 thread 分叉为独立任务并行处理，逐条确认结果后将有效结论合并成新的实施 thread。
5. 从当前 thread 的某个历史点分叉，让子代理尝试另一种实现。
6. 将“调查”“方案 A”“方案 B”三个 thread 的有效结论合并成一个新的实施 thread。
7. 在独立 worktree 中并行开发多个 feature，互不污染主工作区。
8. 让后台任务运行测试或 dev server，同时继续与主 Agent 开发。
9. 从 TODO 计划逐步提交、独立 review，最后生成并维护 PR。
10. 在远程 Neovim/Tailscale 环境下继续已有 Agent 工作。

## 4. 产品概念

| 概念 | 定义 |
| --- | --- |
| Project | 一个 Git 仓库，或一个无仓库的临时工作容器。 |
| Workspace | 一个独立工作目录。可以是原项目、独立 git worktree、已有外部 worktree 或临时聊天目录。 |
| Thread | 一个独立的 Agent 会话及其持久化历史，对应 Pi 的 session。产品文档与 UI 统一使用 Thread。 |
| Thread Branch | 同一个 Thread 内部的一条历史路径，不是独立 Thread，也不同于 Git branch。 |
| Turn | 一次模型响应及其产生的工具调用和结果。 |
| Comment | 用户对文件、diff、spec、artifact 或具体文本片段留下的结构化评论。 |
| Comment Batch | 一组尚未发送的 draft comments，可统一排序、编辑和发送。 |
| Plan | Agent 与用户共享的任务和步骤计划。 |
| Task | 一个独立工作单元，可以由主 Agent、子代理或后台命令执行。 |
| Artifact | Agent 产生的 spec、设计、报告、图表、截图、验证证据、PR body 等持久文件。 |
| Spec | 描述产品目标、架构、模块边界、合同和长期决策的项目文档。 |
| Fork | 从已有 Thread 的某个历史节点创建独立的新 Thread，源历史不变。 |
| Merge | pide 将多个 Thread 或 Thread Branch 的有效内容整理成一个新 Thread 的操作，不是改写或拼接原始历史。 |

## 5. 功能范围总览

| 模块 | 主要能力 |
| --- | --- |
| Projects & Workspaces | Git worktree 隔离、外部工作区、临时聊天、并行任务、Settled 生命周期 |
| Agent Threads | 多会话、多模型、流式消息、steer/follow-up/interrupt、队列编辑、恢复、compact、统计 |
| Code Comments | 文件/diff 行级评论、草稿批次、单条/批量发送、重新定位、处理闭环 |
| Thread Fork & Merge | 从当前或指定历史分叉、独立子代理、跨 thread 合并新上下文 |
| Spec Graph | 创建、搜索、导航、验证和持续维护项目长期知识 |
| Shared Plans | 共享 TODO、阻塞关系、步骤状态、验证摘要、分步提交 |
| Changes & Review | Git diff、逐行评论、独立 reviewer、修复循环、审查记录 |
| Subagents & Resources | 前台/后台子代理、并行 fan-out、后台命令、结果投递 |
| Artifacts | 持久产物、与 thread 关联、浏览、恢复和引用 |
| PR & Delivery | PR body、push/create/sync、checks、review、merge-ready |
| Skills | 精简的核心工作流，以及已有 skills 的导入和管理 |
| Pi Extensions & MCP | 安装已有扩展、启停、通用交互、MCP 配置与授权 |
| Workbench | Neovim 原生多窗口、代码/diff/chat/comments 协同 |
| Platform | Providers、自定义模型服务、远程使用、语音、语言、主题和字体 |

---

## 6. Projects 与 Workspaces

### 6.1 Project 类型

- **Git Project**：普通 Git 仓库。
- **Scratch Project**：没有仓库的临时讨论或草稿空间。
- **Remote Project**：通过远程 Neovim/SSH/Tailscale 打开的项目，体验与本地一致。

### 6.2 Workspace 类型

- **Default**：原项目目录，必须由用户显式选择，不作为并行 Agent 的默认隔离方式。
- **Managed**：pide 创建的独立 git worktree 和 branch，用于普通任务隔离。
- **External**：用户已有 worktree，pide 只接管展示和会话，不擅自移动、重命名或回收。
- **Scratch**：无 Git 的独立目录，用于问答、设计和临时文件，不提供 branch/review/PR 功能。

### 6.3 Workspace 操作

- 创建、重命名、切换、挂载、归档和恢复 Workspace。
- 创建时选择 base ref、显示名称和初始 prompt。
- 展示 branch、base、ahead/behind、未提交变更、PR、CI 和活跃任务状态。
- 支持 Agent 请求“在 side workspace 中执行”，由用户授权后创建并启动新 thread。
- 支持从 scratch chat 继续到正式 workspace：先形成 handoff summary，再创建新 thread，保留来源链接。
- 每个 workspace 有独立 artifacts、plans、reviews、resources 和 thread 列表。

### 6.4 Settled 生命周期

- PR 已合并或关闭、长期无活动的 Workspace 可进入 Settled。
- 新消息、文件变化、终端工作或用户操作会重新激活它。
- 用户可手动 park 或恢复。
- Default 和 External 不被自动回收。
- 归档前明确展示仍运行的 thread、子代理和后台命令，避免误删工作。

## 7. Agent Threads

### 7.1 多会话

- 每个 Workspace 可同时存在多个独立 threads。
- 每个 thread 可拥有独立模型、thinking level、工作目录、plan 和 resources。
- 支持主线程、普通独立线程、review thread、subagent thread 和合并产生的 thread。
- 支持活跃、等待输入、排队、后台工作、完成未读、失败、已中断等状态。

### 7.2 对话与运行控制

- 发送 prompt 并流式展示文本、thinking、工具调用和结果。
- 运行中提供：
  - **Steer**：当前 turn 的工具调用完成后插入指令（默认合并消费已排队的全部 Steer）；
  - **Follow-up**：排入后续队列，等当前自动工作结束后逐条继续执行；
  - **Interrupt**：停止当前工作并立即发送新指令；
  - **Stop**：停止当前工作；
  - **Clear queue / Remove / Edit queued item**：清空队列、删除单条，或将单条排队消息连同附件与引用撤回草稿编辑，并支持在 Steer 与 Follow-up 间改道。
- 用户主动执行 Stop 或手动 Compact 前，默认排空未消费的用户排队消息并回填至输入草稿，防止停止后意外继续执行或丢失输入。
- Thread 处于等待交互回答（如弹窗提问或确认）状态时，直接发送新的 Steer 或 Follow-up 会自动取消挂起的旧交互并继续推进。
- 支持图片、文件引用、buffer、selection、diagnostics、comment 和 git diff 上下文；在代码区选中内容或单条 comment 时，可直接免切窗向运行中的 thread 发送 Steer 或 Follow-up，不抢走编辑器焦点。
- 支持 skill 和 prompt template 调用与补全。
- 支持手动 compact、自动 compact 状态、token/cost/context usage 展示。
- 支持切换模型与 thinking level，并明确当前 thread 实际使用的模型。

### 7.3 历史与恢复

- 浏览、搜索、重命名、恢复和删除 threads。
- 刷新 Neovim、隐藏面板或关闭窗口不终止后台 thread。
- 重开后重新读取持久历史，再接入实时事件，不能只依赖已看到的流式事件。
- 支持查看完整 transcript、工具输入输出和子代理 transcript。
- 支持 Thread Tree 浏览、标签、历史节点预览和从节点继续。

## 8. 代码与 Diff Comments

这是 pide 的核心差异化能力。

### 8.1 创建 Comment

用户可以在以下内容上创建 comment：

- 普通文件的一行或连续行；
- 当前 buffer 的 visual selection；
- 未提交 diff 的新旧两侧；
- branch/commit diff；
- Spec、task-spec、plan、artifact 和 PR body；
- 支持的文档结构节点或图像区域（后续增强，不作为首版阻塞）。

Comment 类型：

- **Line**：精确行范围。
- **File**：整个文件。
- **Diff hunk**：某个变更块。
- **General**：不绑定具体文件的整体意见。

创建 comment 不修改源文件内容，不插入 `//`、`#` 等真实代码注释。

### 8.2 Comment 内容

每条 comment 保存：

- 唯一 ID；
- 正文和可选标题；
- 文件路径及所在 workspace；
- 来源类型和 diff side；
- 创建时的行范围、代码片段及必要上下文；
- 内容 hash 和可重新定位的 text quote；
- 当前状态：`draft`、`sent`、`resolved`、`dismissed`；
- 锚点状态：`anchored`、`moved`、`outdated`；
- 发送目标 thread 和发送时间；
- 后续处理记录与 Agent 回复链接。

### 8.3 草稿与批量管理

- 默认创建为 `draft`，不立即打断 Agent。
- 底部 Comment Shelf 集中展示当前 workspace 的全部草稿。
- 支持编辑、删除、排序、按文件分组、按状态过滤和批量选择。
- 支持跨文件、跨 diff、跨 thread 暂存，但发送时必须明确目标。
- 支持以下发送方式：
  1. 立即发送当前 comment；
  2. 将当前 comment 加入批次；
  3. 发送整个批次；
  4. 只发送批次中的选中项。
- 可发送到当前 thread、新 thread、指定历史 thread 或新的子代理。
- 普通文件与 diff 的单条、批量评论均可从当前 thread 最新状态分叉为独立子代理任务并行执行，完成后按第 9.4 节选择有效结论合并成新的实施 thread（源 thread 不变，不等同于自动合并 Git 代码）。
- 发送到正在运行的 thread 时默认走 Follow-up 排队，紧急纠偏可显式选 Steer；排队中的评论在消费前被撤回时自动退回 `draft`。

### 8.4 发送上下文

发送内容至少包括：

- 用户原始评论；
- comment ID；
- 相对文件路径；
- 当前行范围；
- 代码片段及必要上下文；
- diff side 和 base ref（如适用）；
- `anchored/moved/outdated` 状态；
- 用户要求的处理目标。

默认不附带整个 diff。Agent 可使用自己的文件、Git 和搜索工具继续调查。

### 8.5 重新定位与过期

- 文件未变化时保持 `anchored`。
- 文件变化后，如果原文可唯一定位，更新行号并标记 `moved`。
- 原文不存在、匹配不唯一或文件删除时标记 `outdated`，仍保留创建时快照。
- base diff 使用固定 commit，不随后续代码移动。
- 发送前重新计算定位，避免把错误行号发给 Agent。

### 8.6 处理闭环

- Agent 的回复和修改可与 comment 关联查看。
- 用户可以逐条标记 resolved/dismissed，也可以要求继续修改。
- Agent 可以提出解决建议，用户确认后关闭；已有 Pi extension 提供标准解决工具时，也可由 Agent 直接完成相同流程。
- 重开一个已解决 comment 会保留历史，不创建重复评论。
- 批量发送后，可从 Comment Shelf 查看哪些已回复、哪些仍需处理。

## 9. Thread 分叉、子代理与合并

### 9.1 Pi 原生能力确认

Pi 的 session 是由稳定 `id/parentId` 构成的 append-only entry tree，具备：

- **Fork**：从选定的早期用户消息之前创建新 session；原始 session 不变。
- **Clone**：复制当前 active branch 的当前状态，形成独立 session。
- **Tree navigation**：在同一 session 内移动历史节点，离开旧分支时保留旧分支，也可以生成 branch summary（同文件切分支目前由 Pi SDK / TUI 提供，RPC 模式仅暴露读取会话树与 `fork`/`clone` 新建会话）。
- **BranchSummary**：进入另一分支时携带旧路径的摘要，而不是全部消息。

这些能力支持 pide 的“从当前或指定历史分叉子代理”需求。

Pi 没有一个通用的、直接把多个独立 session 原生合并为一个 session 的操作。因此，跨 Thread Merge 是 pide 自己的产品能力，不能宣传为 Pi 原生 merge。

### 9.2 创建子代理

用户可以从以下来源创建子代理：

- 当前 thread 的最新状态；
- 当前 thread 的指定历史节点；
- 另一个 thread 或其指定分支；
- 一条或一批 comments；
- 一个 plan item、review item 或工作区任务；
- 多个 thread 合并后的新上下文。

创建时可设置：

- 任务目标和完成条件；
- 前台或后台运行；
- 独立模型与 thinking level；
- 角色类型，如 scout、planner、worker、reviewer；
- 使用当前 workspace 或独立 worktree；
- 上下文传递方式：常规委托默认使用干净上下文与最小任务包（fresh context），仅在需沿用前置探索状态、未提交修改或分支对比时显式继承或压缩上下文；
- 可使用的 skills、extensions 和工具范围。

### 9.3 子代理运行

- 支持前台、并行 fan-out 和后台运行。
- 子代理有独立 transcript，可随时查看和恢复。
- 后台完成结果在父 Agent 的下一个合适步骤投递，避免打断工具调用；系统回传队列与用户手工排队队列隔离，不受用户 `Clear queue` 影响。
- 同一结果被拉取后，不再重复推送。
- 支持停止单个子代理或全部子代理。
- 子代理达到轮次或预算上限时，先通过内部 Steer 要求总结当前进展与剩余问题，再终止运行，避免直接硬中断丢失线索。
- 子代理完成后可继续派生后续任务（返工与下一项默认启动干净新子代理）；递归深度、并发上限及可用工具/skills 由宿主统一硬性限制，不在各 skill 正文中重复堆叠防递归提示词。
- 非交互子代理遵循统一的 worker 自治边界：对可逆选择自行决策并说明原因，不向用户弹窗阻塞，仅在触及不可逆高危操作时停下等待确认。
- 子代理写入同一 workspace 时，必须明确共享文件风险；需要并行修改时优先独立 worktree。

### 9.4 跨 Thread Merge

Merge 的语义是：**创建一个新的工作 thread，并将多个来源的有效上下文组织进去。源 thread 永远不变。**

支持选择：

- 多个独立 threads；
- 同一 thread 的多个 Thread Branches；
- 指定历史节点之前的上下文；
- comments、plans、artifacts 和决策日志作为附加材料。

Merge 方式：

1. **Handoff Merge（默认）**：生成结构化合并摘要，包括共同目标、各来源结论、决策、证据、未解决项、冲突和 artifacts 链接。
2. **Selected Context Merge**：用户选择具体消息或条目加入新 thread，适合只需要少量原文的情况。
3. **Comparison First**：先展示各来源差异和冲突，由用户或 Agent 形成合并结论后再开始新 thread。

Merge 不采用简单时间顺序拼接全部消息，因为这样会重复上下文、混淆角色并丢失真正的决策关系。

新 thread 必须记录：

- 所有来源 thread / Thread Branch 链接；
- 使用的合并策略；
- 纳入与排除的内容；
- 未解决冲突和假设；
- 可回到原始证据的路径。

Merge 后仍可对任意来源再次 fork，形成可追踪的工作图。

## 10. Spec Graph 与长期项目知识

### 10.1 Spec 类型

- `goal-and-requirements`：产品目标、问题、用户、能力和 non-goals。
- `architecture-design`：系统拓扑、跨模块决策和 invariants。
- `module-design` / `submodule-design`：模块职责、边界和合同。
- `task-spec`：一项工作的临时设计，完成后标记 done 并保留为 artifact。

### 10.2 Spec 操作

- 搜索相关 spec 和具体段落。
- 查看 parent、depends-on、references、implements 关系。
- 创建、编辑、删除和验证 specs。
- 检查重复 ID、断链和 parent cycle。
- 支持从已有代码和文档初始化完整 spec graph。
- 支持将现有 ADR、架构文档和模块文档原地纳入，而不是制造重复副本。

### 10.3 统一语言与决策

- `GLOSSARY.md`（或单上下文仓库 `AGENTS.md` 的 Glossary 章节）维护项目统一术语，不包含实现细节。
- ADR 只记录难逆转、缺少背景会令人意外、存在真实 trade-off 的决策。
- 修改代码行为、模块边界或既有决策时，必须同时评估并更新相应 spec。
- 用户可以在 spec 上直接留 comment，并发送给 Agent 修正文档。

### 10.4 Skills 与 Compaction 后的知识连续性

- 只将与当前任务有关的 spec 和 skill 内容提供给 Agent。
- 大量 skills 采用搜索和按需加载，避免常驻上下文过大。
- compact 后恢复仍在指导当前工作的 skill/spec 摘要，必要时重新读取原文。

## 11. Shared Plans 与分步执行

### 11.1 共享 TODO

- 每个 thread 有独立 plan，用户和 Agent 都可编辑。
- Group 表示一个用户目标，Item 表示可验证步骤。
- 简单的一到两步工作不强制创建计划。
- 同一时刻只有一个 `in_progress`。
- 支持 loose items，Agent 开始处理时再 promote 为正式任务。
- 支持 blocking edges，可并行处理所有无阻塞步骤，而不只支持线性列表。
- 用户可以重排、取消、添加和重新打开步骤。
- 自动推进未阻塞步骤（Nudge）时按 thread 状态分流：空闲时直接发送，运行中排入 Follow-up，处于等待用户输入状态时不催促。

### 11.2 步骤执行记录

每个步骤可记录：

- 状态和负责人；
- 工作说明与完成条件；
- 实现摘要；
- 验证命令和结果；
- commit subject；
- 相关 files、specs、changes 和 commits；
- review 状态与反馈。

### 11.3 分步提交

- 步骤开始时记录 Git baseline。
- 步骤完成时计算该步骤的真实 delta。
- 仅在能证明文件归属、没有外部 WIP 混入且工作区未被其他任务共享时自动提交。
- 不满足条件时保留未提交 change，不盲目执行 `git add -A`。
- 重新打开步骤后产生新的修订记录，不改写旧审查历史。
- 计划完成后形成可直接用于 PR 的 Summary、Changes 和 Testing。

## 12. Changes 与 Review

### 12.1 Diff 浏览

- 支持 uncommitted、branch、commit、merge-base 和指定 ref diff。
- 展示文件状态、增删行、旧新两侧和具体 hunk。
- 与 Neovim diff 模式、quickfix 和文件跳转配合。
- 文件在外部或 Agent 修改后及时刷新，不覆盖用户未保存的 buffer。

### 12.2 Review 方式

- 用户逐行评论，可单条或批量发送，并可分叉任务并行处理、完成后汇总结论，使用第 8 节的统一 Comment 流程。
- 支持独立 reviewer 子代理进行冷审查。
- Review 至少区分两条轴：
  - **Standards**：仓库规范、架构和代码质量；
  - **Spec**：是否满足原始要求、是否遗漏或扩大范围。
- 高风险改动可增加多模型 adversarial review。
- 只有能由代码、运行或明确规范支持的 finding 才进入正式问题列表。

### 12.3 修复循环

- review findings 与计划步骤返工请求可发送到新子代理，或固定以 Follow-up 排队发回原实现 thread（不以 Steer 打断正在执行的工具调用；消费前取消或发送失败时同步回滚对应发送状态）。
- 修复后重新检查相关 finding 和 blast radius。
- 支持一次自动修复与复审，之后由人决定，避免无限循环。
- 记录 reviewed、changes requested、reviewedShas 和后续新 delta。
- 只审查新增修订，不要求每次重看全部历史变更。

## 13. Background Commands 与 Resources

### 13.1 后台命令

支持 `start`、`list`、`output`、`stop`，用于：

- dev server；
- 测试 watcher；
- 长构建；
- 日志采集；
- 其他需要持续运行但不应阻塞 Agent turn 的命令。

要求：

- 命令归属明确 thread 和 workspace；
- 保留有界日志和退出状态；
- 停止精确目标任务，不按进程名误杀；
- 页面关闭不终止任务，宿主退出时提供明确清理策略；
- 结果可在后续步骤反馈给 Agent。

### 13.2 Resources 视图

统一展示：

- 子代理；
- 后台命令；
- MCP servers 与调用；
- 相关进程和可检查日志；
- 已完成历史记录。

用户可查看状态、输出、停止任务，并跳转到对应 thread 或 artifact。

## 14. Artifacts

### 14.1 保存与分类

Artifacts 默认保存在 workspace 的 Git-ignored 区域，包括：

- task specs；
- 设计和调研文档；
- Mermaid 和比较方案；
- UI mockups；
- 截图与录屏；
- 测试和性能证据；
- TODO/review 记录；
- PR body 与 PR 图片；
- 决策日志和合并摘要。

### 14.2 使用方式

- 支持按最新列表、目录树或 Smart 视图（突出展示 Agent 交付给用户的正式结果，并将其下的中间工作文件折叠）按 workspace、thread、类型和时间浏览。
- 展示由哪个 thread/task 创建，并在每轮对话下直接列出该轮生成的 artifacts。
- 可在对话中引用、在代码区打开、重命名、复制到项目或下载。
- 新 artifacts 提供未读提示。
- 即使用户或 Agent 删除了工作文件，也保留可恢复副本和删除记录。
- 临时产物不自动进入 Git，也不应散落 `/tmp` 后失去关联。

## 15. PR 与交付

### 15.1 PR 创建

- 检查待交付变更已提交且工作区状态明确。
- 获取最新 base 并处理同步或冲突。
- 清理临时文件，审查完整 diff。
- 验证最终 tree，不机械重复已经有效的检查。
- 根据仓库 PR 模板、共享 plan 和真实证据生成 PR body。
- 支持 push、create draft/ready PR，以及 compare URL fallback。

### 15.2 PR 内容

- Summary 说明用户目标和变化原因。
- Changes 说明跨步骤变化、迁移、依赖和重要取舍。
- Testing 列出真实命令、结果和 before/after 证据。
- Merge Danger 标明可逆性、blast radius 和注意事项。
- UI 变化提供截图或录屏。

### 15.3 PR 生命周期

- 查看 checks、merge state、draft 和 review decision。
- 支持同步 base、更新 title/body、添加截图、处理 review comments。
- 支持调查 CI 失败、再次验证和修复。
- 支持 mark ready、merge、reopen 和删除远程分支，均需适当授权。
- 默认只读取一次状态；只有用户要求等待远端完成时才持续 watch。
- “CI green”不自动等于“可以 merge”，仍需独立检查完整变更和分支状态。

## 16. Skills 体系

### 16.1 设计原则

- 只保留少量核心 skills，避免把每个按钮或每种说法都做成 skill。
- Router、主要 workflow、共享 concept/reference 分离。
- 多数能力首先由产品 UI 和 Pi tools 提供，不通过新增 skill 重复实现。
- 同一概念只有一个权威定义，其他 skills 引用它。
- 支持加载用户已有 Pi skills，以及 Claude、Codex、Copilot、Gemini 等兼容 Agent Skills。
- 支持按项目启停、搜索、手动 `/skill:name` 调用和重新加载。

### 16.2 精简后的核心 Skills：12 个

| 核心 Skill | 用途 | 主要融合来源 |
| --- | --- | --- |
| `choosing-a-workflow` | 根据任务进入 onboarding、设计、调试、执行、审查、交付或直接回答，避免所有请求都走重流程。 | ThinkRail `choosing-a-workflow`；Matt `ask-matt`；pstack `poteto-mode/poteto-help/sharpen` |
| `onboarding-a-project` | 空项目形成目标文档，已有代码生成 Spec 图谱，已有 Spec 则审查和补齐。 | ThinkRail `setting-up-a-project/starting-a-new-project/importing-a-codebase`；Matt `setup-matt-pocock-skills`；pstack `setup-pstack` |
| `designing-a-change` | 通过多轮访谈明确产品和技术决策，必要时用原型比较方案，并写入 task-spec、Glossary 或 ADR。 | ThinkRail `brainstorming/asking-user-questions/writing-specs`；Matt `grill-with-docs/grilling/domain-modeling/codebase-design/prototype/to-spec`；pstack `architect/arena` |
| `diagnosing-bugs` | 建立可复现反馈回路，最小化、假设、instrument、修复和回归验证；覆盖性能和 trace 分支。 | ThinkRail `brainstorming`（`fixing-a-bug` 分支）；Matt `diagnosing-bugs`；pstack `bug-fix/perf-issue/runtime-forensics/trace-forensics/principle-attack-the-premise` |
| `executing-with-todos` | 将工作拆成可验证任务图，维护共享计划、证据和分步提交。 | ThinkRail `todos`；Matt `implement/to-tickets/tdd`；pstack `feature/refactoring/principle-sequence-verifiable-units/show-me-your-work` |
| `verifying-behavior` | 建立并维护项目验证路径，检查真实行为、性能数字和必要的形式化属性。 | pstack `create-verification-skill/create-formal-verification-skill/statechart/benchmark-checklist`；Matt `tdd`；ThinkRail 验证纪律 |
| `reviewing-changes` | 从 Standards 与 Spec 两轴审查，支持逐行评论、对抗审查和修复复审。 | ThinkRail review 工具与闭环；Matt `code-review`；pstack `interrogate/blast-radius/no-comments` |
| `shipping-a-pr` | 完成最终验证、生成 PR、同步、处理 CI/review 并交付。 | ThinkRail `shipping-a-pr`；Matt `pr`；pstack `opening-a-pr/babysit/shipping` |
| `researching-and-explaining` | 基于代码、历史、文档和 primary sources 调研，并形成引用明确的解释或 handoff。 | ThinkRail `librarian`；Matt `research/teach/handoff`；pstack `how/why/recall/teach/ketchup` |
| `coordinating-agents` | 管理子代理、并行切片、方案竞赛、后台结果和长期任务决策日志。 | ThinkRail `pi-subagents/pi-background-commands`；Matt `implement-spec/chief-of-staff`；pstack `swarm/figure-it-out/autopilot-*/worker.md` |
| `maintaining-project-knowledge` | 维护 Spec 图谱、统一术语、ADR 和跨 compact 的关键上下文。 | ThinkRail `spec-graph/writing-specs`；Matt `domain-modeling`；pstack `principle-model-the-domain` |
| `improving-agent-environment` | 将会话经验变成架构、类型、lint、CI、测试或更准确的 skill，而不是堆积提示词。 | Matt `retro/improve-codebase-architecture`；pstack `correct/reflect/automate-me` |

### 16.3 不单独新增的内容

以下能力作为上述 skills 的 sibling reference、产品功能或已有 extension 使用，不额外扩展 skill 数量：

- `ask_user_question`、visualize、web access；
- `managing-mcp-servers` 等 MCP 配置说明；
- PR body、comment package、decision log 等格式模板；
- `writing-for-agents`、`writing-workflow-skills`、`unslop/technical-writing` 等写作与工作流编写指南；
- TDD、Triage、Wayfinder、Software Factory、Formal Verification 的细分 playbook；
- UI 操作，如创建 comment、合并 thread、切换窗口。

## 17. Pi Extensions、Packages 与 MCP

### 17.1 已有 Pi Extensions

pide 不要求开发自己的 Pi extension API 或 host SDK，而是复用已有 Pi 扩展。

支持：

- 从 npm、Git 或本地路径安装 package；
- 用户级和项目级安装；
- 查看 package 提供的 extensions、skills、prompt templates 和 tools；
- 按 package 或具体资源启停；
- 更新、移除和重新加载；
- 展示加载错误和来源；
- 与当前 thread 的 tools 状态同步。

可直接使用例如：

- `ask-user-question`：结构化提问、键盘作答与多方案并排对比预览；
- `visualize`：图表、比较、文件预览，以及可在外部浏览器以无网络沙箱打开的可交互 HTML 原型；
- `web-access`：网页、仓库、PDF 等研究；
- `subagents`、background commands、spec/todo 等已有兼容实现。

### 17.2 通用 Extension UI

pide 为已有扩展提供通用交互承载：

- select、confirm、input、editor；
- notify、status、widget；
- 通用 tool start/update/end 展示；
- 通用文本、代码、diff、图片和文件链接结果。

只支持宿主通用协议，不要求为 pide 编写专用 renderer。高度依赖原 Agent TUI 的扩展在无法完整呈现时明确降级，不假装兼容。

### 17.3 MCP

- 读取 Pi 的用户级和项目级 MCP 配置。
- 添加、修改、删除、启停和重连 server。
- 项目配置只有在信任并单独批准后启用。
- 非 read-only 调用默认请求确认，可对可信工具按项目授权。
- 支持 OAuth 登录、状态和日志查看。
- 在 Resources 中显示每个 thread 的 server 状态和调用记录。

## 18. Providers、Skills 与平台能力

### 18.1 Providers 与模型

- 使用用户已有 Pi 认证，不建立 pide 账号体系。
- 支持 Pi 已支持的 provider、API key 和 OAuth。
- 支持 OpenAI-compatible 自定义网关及本地模型服务。
- 可检测模型列表、能力、上下文窗口和输入类型。
- 配置写回 Pi 的共享配置，Neovim 与 Pi CLI 保持一致。
- 明确提示不可用模型、缺失认证和上下文限制。

### 18.2 输入与输出

- Prompt 支持文本、图片、文件、selection、diagnostics、comments 和 artifacts。
- 支持本地语音输入，语音内容只进入编辑草稿，不自动发送。
- 支持 prompt template、skill 和历史消息搜索。
- Agent 输出不强行翻译；界面语言可独立选择。

### 18.3 外观与无障碍

- 默认遵循 Neovim colorscheme 和字体，不建立第二套相互冲突的主题系统。
- 支持针对 Agent 面板配置强调色、边框、状态和可访问的对比度。
- 代码字体、UI 字体、字号和 ligature 遵循用户编辑器配置。
- 所有功能（含对话浏览、行级评论和提问作答）均可通过键盘完成；提供统一快捷键表与速查视图，支持用户重绑定、扩展自带按键及配置导入导出，并支持列表快速过滤与跳转提示（hint mode）。
- 界面文案支持英语及后续语言包；缺翻译时回退英语。

### 18.4 本地与远程

- 本地 Neovim 提供完整功能。
- SSH/headless/远程 Neovim 下保持同一 thread 和 workspace 语义。
- Tailscale 只作为网络与设备访问边界，pide 不额外实现账号系统。
- 远程文件、终端、命令和 Agent 工作目录必须明确属于哪台主机，避免本机/远端混淆。

## 19. Neovim 界面与窗口设计

### 19.1 设计目标

- 默认保持代码区足够大，不一次性展示所有面板。
- 采用渐进披露：只有当前任务需要的面板出现。
- 每种内容有固定归属，避免同一个面板在多个窗口反复打开。
- 隐藏面板只隐藏 UI，不停止 thread、子代理或后台命令。
- 切换 workspace 不应破坏用户自己的其他 tabpage 和窗口布局。

### 19.2 默认工作布局

```text
┌──────────────────────────────────────────────────────────────┐
│ Workspace / Thread / Model / Status                          │
├───────────────┬──────────────────────────────┬───────────────┤
│ 可选导航栏     │                              │ Agent Dock    │
│ Workspaces    │        主代码工作区           │ Chat          │
│ Threads       │  文件 / Diff / Spec / Artifact│ Plan          │
│ Files         │                              │ Resources     │
├───────────────┴──────────────────────────────┴───────────────┤
│ 可选底部 Shelf：Comments / Queue / Diagnostics / Terminal     │
└──────────────────────────────────────────────────────────────┘
```

默认只显示“主代码工作区 + Agent Dock”，导航栏和底部 Shelf 按需打开。

### 19.3 各区域职责

#### 主代码工作区

- 始终用于文件、diff、spec、artifact 和 review。
- Agent 打开文件时优先复用此区域已有窗口。
- 支持 Neovim 原生 split、tab、quickfix、diff 和跳转。
- 用户手动切走后，Agent 不自动抢回焦点。

#### Agent Dock

- 右侧常驻或可切换，承载 Chat、Plan、Specs、Resources。
- 这些页面共用一个 dock，通过内部 tab 切换，而不是连续开多个垂直窗口。
- Chat 中可选择消息、工具、文件链接和 comment，并决定发送到代码区还是新面板。
- 长输出默认折叠，当前 turn 和需要用户处理的内容优先展示。

#### 左侧导航栏

- 按需显示 Workspaces、Threads、Files、Specs 或 Artifacts。
- 同一时间只展示一种导航内容。
- 用于切换和过滤，不承载长对话或复杂编辑。

#### 底部 Shelf

- Comments 是核心页面之一。
- Queue 页面区分显示 Steer 与 Follow-up 两条队列及条数，支持键盘删除、撤回回填编辑与改道；也可显示 diagnostics、终端、后台日志和决策日志。
- 高度可调整，默认保持较低，批量处理时再扩大。

### 19.4 Review 布局

```text
┌───────────────────────┬───────────────────────┬──────────────┐
│ Base / Original       │ Worktree / Modified   │ Review       │
│                       │                       │ Comments     │
│                       │                       │ Agent reply  │
└───────────────────────┴───────────────────────┴──────────────┘
```

- 中间两栏使用 Neovim 原生 diff。
- Review 栏展示与当前 hunk 相关的 comments 和处理状态。
- 小屏幕时改为“diff 单栏 + 底部 comments”，避免过度压缩代码。
- 可从 comment 跳回精确行，也可从代码行查看已有 comment。

### 19.5 Thread Tree 与 Merge 视图

- Thread Tree 使用独立临时页面，展示历史分支、节点、标签和当前 leaf。
- 选择节点后可预览、fork、clone 或作为子代理上下文。
- Merge 使用三步视图：
  1. 选择来源；
  2. 比较结论与冲突；
  3. 确认合并内容并创建新 thread。
- Merge 过程中不修改任何源 thread，也不在后台自动完成冲突决策。

### 19.6 临时交互

- 问题、模型选择、comment 编辑、确认和短输入使用浮窗或命令行输入。
- 多行 comment 和合并摘要在可编辑 buffer 中完成。
- 临时 UI 只用于当前交互，关闭后恢复原焦点与布局。
- Agent 等待回答时，在 dock 和状态栏同时给出明显提示。

### 19.7 Window 管理规则

- 每个 tabpage 可以有独立 workspace 视图和布局。
- 同一类 dock/shelf 在每个 tabpage 最多一个实例。
- 同一 buffer 不无故在多个窗口重复打开；需要比较时例外。
- 面板尺寸可以调整并记忆，但切换文件不重置用户比例。
- 关闭面板不删除 thread；关闭 workspace 才进入生命周期检查。
- Agent 不得在用户编辑的 split 中直接替换 buffer，所有自动跳转都遵守“代码区优先、用户焦点其次”。
- 提供统一的打开、关闭、聚焦、放大和恢复布局命令，避免每个功能各自创建窗口。

## 20. 端到端工作流

### 20.1 已有项目初始化

```text
读取 Agent docs / README / manifests / 代码
  → 判断已有 Spec、代码和文档状态
  → 只询问代码无法表达的意图与决策
  → 形成 goal → architecture → module specs
  → 验证图谱
  → 用户在代码区审查并留 comments
  → Agent 修订后确认
```

### 20.2 Feature 开发

```text
用户提出目标
  → designing-a-change 明确产品与设计
  → 创建 task-spec 和共享 plan
  → 创建独立 workspace
  → 分步实现与验证
  → 更新长期 spec
  → Review comments / 独立 reviewer
  → 修复与复审
  → PR
```

### 20.3 Bug 修复

```text
收集症状与预期
  → 建立可重复反馈回路
  → 最小化复现
  → 验证根因假设
  → 先建立回归测试或其他可执行检查
  → 修复
  → 原始场景与相关路径复验
```

### 20.4 代码评论驱动修改

```text
阅读代码或 diff
  → 留下评论：单条立即发送，或积攒后从 Comment Shelf 选择一批发送
  → 直接发送到目标 thread，或从当前 thread 分叉独立任务
  → 多个分叉任务可并行处理，并关联各条评论的回复与结果
  → 用户逐条确认或继续追问
  → 可选择已完成任务的有效结论，合并成新的实施 thread
  → 形成最终 change 和 review 记录
```

### 20.5 分叉探索

```text
主 thread 已形成若干决策
  → 从指定历史节点 fork worker A / worker B
  → 各自尝试不同方案
  → 比较实现与验证证据
  → 选中一个主路径或将优点合并到新 thread
  → 继续实施
```

### 20.6 多 Thread 合并

```text
调查 thread + 方案 thread + 审查 thread
  → 选择来源和有效历史范围
  → 比较结论、决策和未解决冲突
  → 形成 handoff merge
  → 新 thread 继续实施
  → 原始 threads 保持不变且可追溯
```

### 20.7 长时间自治执行

```text
明确完成条件与授权边界
  → 共享 plan 和 decision log
  → 主 Agent + 子代理 + 后台命令
  → 用户离开后持续执行
  → 中途状态、异常和待决策项可查看
  → 最终提供证据、变更、日志和剩余风险
```

## 21. Pi 与 ACP 能力模型

| 能力 | Pi | ACP Agent |
| --- | --- | --- |
| 流式聊天、停止、历史 | 完整支持 | 按协议支持 |
| Steer / Follow-up / Interrupt | 完整支持 | 无对应能力时使用普通排队或提示 |
| 模型与 thinking level | 完整支持 | 仅展示后端暴露的选项 |
| Neovim 上下文与 comments | 完整支持 | 完整支持，由 pide 提供 |
| Workspace / Diff / Review | 完整支持 | 完整支持，由 pide 提供 |
| Thread fork / tree | 完整支持 | 无对应能力时只允许新 thread + handoff |
| Thread merge | pide 提供 | 同样可用，不依赖 Pi 原生 merge |
| Skills / Extensions | Pi 原生发现和管理 | 仅使用后端支持的通用 skills 或提示降级 |
| Extension UI | 通用协议承载 | 映射到权限请求和普通问题 |
| Subagents | Pi 扩展及 pide 编排 | 无对应能力时使用独立普通 thread |
| Compact / Session stats | 完整支持 | 无对应能力时隐藏 |
| 后台命令与 artifacts | 完整支持 | 由 pide 提供通用部分 |

pide 自身提供的通用能力（代码评论、Workspace、Diff、Review、跨 Thread Merge）不因切换后端而消失；依赖 Agent 原生的能力按当前接入后端实际提供的能力开放。任何后端都不能把执行失败伪装成“不支持”或静默降级；用户必须能看到当前 backend 和降级状态。

## 22. 非功能需求

### 22.1 安全与隐私

- 不建立 pide 账号，不上传独立遥测或代码内容。
- 使用用户已有 Pi、Git、GitHub 和 MCP 凭证。
- 日志、comment、合并摘要和 artifacts 中的 secret 必须脱敏。
- 项目级扩展、skills、MCP 和配置必须经过明确信任。
- 不可逆操作，如 force push、删除生产数据、外部发送，默认需要确认。
- Agent 修改文件前检测 Neovim 中未保存的修改，避免静默覆盖。

### 22.2 可靠性

- UI 刷新、进程退出和 Neovim 重启不丢失持久 thread、comments 或 plans。
- 流式事件只是增量，完整状态始终可重新读取。
- 重复发送同一 comment 或后台结果要有去重策略。
- 多客户端/多窗口操作同一对象时保持状态一致。
- 所有破坏性 Git 操作明确展示影响范围。

### 22.3 性能与上下文预算

- 长 transcript、长 diff 和大型 artifacts 默认折叠、分页或按需加载。
- 大文件、批量探索和搜索结果优先交给子代理，主上下文只保留摘要与引用。
- 大量 skills/specs 按需搜索，不全部常驻 prompt。
- 频繁流式更新不能阻塞 Neovim 编辑输入。

### 22.4 可访问性

- 所有核心功能可通过命令和键盘完成。
- 状态不能只靠颜色表达，同时使用文字或图标。
- 小窗口下优先保留代码和待用户处理内容。
- 面板、diff 和评论支持清晰焦点与返回路径。

## 23. 验收标准

### 23.1 核心闭环

- 用户可以不离开 Neovim，从已有代码库初始化 Spec，完成一个 feature，审查变更并创建 PR。
- 每一步都有可见状态、证据和可返回的原始材料。
- Agent 修改代码后，代码区和 diff 能正确刷新，且不丢失用户未保存修改。

### 23.2 Comments

- 能在普通文件和 diff 两侧创建 comment。
- 普通文件和 diff 评论均可单条立即发送，或跨文件暂存、编辑后批量发送；两种方式均可从当前 thread 分叉独立任务并行执行，完成后可将有效结论合并成新的实施 thread。
- Agent 收到的文件、行号、代码片段和 comment 内容准确。
- 文件变化后 comment 能重新定位或明确标记 outdated。
- 每条 comment 的处理状态与回复可追踪。

### 23.3 Fork 与 Merge

- 能从当前或指定 thread 历史节点创建独立子代理。
- fork/clone 后原 thread 不变，新任务有独立 transcript。
- 能选择多个 threads 或 Thread Branches 创建合并 thread，并查看来源和冲突。
- Merge 不会简单拼接全部消息，也不会改写原始历史。

### 23.4 Workspaces 与 Plans

- 并行 Agent 默认在独立 worktree 中运行。
- 共享 plan 能反映步骤、阻塞、验证和提交状态。
- 不安全的情况下不自动提交，不把其他任务或用户 WIP 混入 commit。

### 23.5 Extensions 与 Skills

- 能安装并启停已有 Pi packages，使用其 tools、skills 和通用交互。
- 核心 skill 数量保持精简，没有为重复说法或单个 UI 操作新增大量 skills。
- ACP backend 下不支持的能力明确降级，不影响基本聊天、comments 和 review。

### 23.6 UI

- 默认布局同时保留清晰的代码区和 Agent 区。
- 窗口可以打开、隐藏、切换和恢复，且不重复创建同类面板。
- Review、Comment Shelf、Thread Tree 和 Merge 均有明确进入与返回路径。
- 小窗口下仍能完成代码阅读、评论和 Agent 操作。

## 24. 最终产品边界

pide 的最终目标不是成为另一个 ThinkRail 前端，而是形成一个以 Neovim 为中心的 Agentic IDE：

- ThinkRail 提供完整的项目、工作区和开发闭环参考；
- Matt Pocock Skills 提供访谈、任务图、TDD、诊断、双轴审查和环境改进；
- pstack 提供 playbook 编排、并行方案探索、运行时验证、形式化验证和自治执行纪律；
- Pi 提供 Agent、session、tools、skills 和 extensions；
- pide 自己重点创造的是：
  - Neovim 原生的代码与 Agent 协同；
  - 文件/diff comments 与批量处理；
  - 可分叉的子代理工作；
  - 可追溯的跨 thread 合并；
  - 不干扰代码工作的窗口与审查体验。
