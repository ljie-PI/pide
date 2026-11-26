# pide 产品需求文档

- **文档状态**：Draft
- **产品名称**：pide.nvim
- **产品形态**：Neovim 0.12+ 原生 Agentic IDE（交互规格原型见 [`doc/ui.html`](./ui.html)）
- **主要 Agent**：Pi coding agent
- **扩展方向**：通过统一能力模型兼容支持 ACP 的其他 Agent
- **需求基线**：覆盖项目管理、隔离工作区、Agent 会话、规划、审查与交付的完整开发闭环，并提供代码评论、Thread 分叉与合并等 Neovim 原生工作流

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

1. **完整开发闭环**：支持项目与工作区管理、Agent 会话、Spec、共享计划、代码审查、产物管理、子代理、后台命令和 PR 交付。
2. **代码与讨论双向连接**：用户可以直接在代码或 diff 上留行级 comment，勾选不同草稿子集连同精确上下文分批发送给目标 Thread。
3. **可分叉的 Agent 工作**：可以从当前 thread 或指定历史节点创建子代理任务，也可以将多个 thread 的有效上下文合并成新的工作 thread。
4. **Neovim 原生体验**：代码区始终是工作中心，Agent 面板服务于代码，不迫使大家在独立聊天应用中切换上下文。
5. **Pi 优先**：完整复用 Pi 的模型、会话、工具、skills、extensions、compaction、认证和状态，不另建 Agent 引擎。
6. **ACP 可扩展**：通用聊天、上下文、评论、workspace 和 review 不绑定 Pi；其他 ACP Agent 按能力接入并降级。
7. **少而有效的 skills**：整合重复能力，形成一组小型、可组合的核心工作流，覆盖设计、执行、验证、审查与交付。
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
3. 阅读代码或 diff 时通过 `<Space>ac` 留下行级评论，积攒草稿后按需勾选不同子集分别投递给不同的 Thread 或新建 Thread。
4. 通过显式 Fork 或拆分 skill 从当前 thread 创建关联子 Thread 并行处理，完成后选择有效结论通过公共前缀或 handoff 合并成新的实施 thread。
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
| Comment | 用户对文件、diff、spec 或 artifact 留下的结构化行级评论。 |
| Comment Batch | 一组勾选待发的 draft comments，可发往当前、已有或新建 Thread。 |
| Plan | 当前 Thread 内嵌的步骤计划。 |
| Artifact | Agent 产生的 spec、设计、报告、验证证据、PR body 等持久文件。 |
| Spec | 描述产品目标、架构、模块边界、合同和长期决策的项目文档。 |
| Fork | 从已有 Thread 的某个历史节点创建关联的新 Thread，记录父子关系且源历史不变。 |
| Merge | pide 将多个 Thread 的有效上下文通过公共前缀继承或 handoff 整理成一个新 Thread 的操作，不改写原始历史。 |

## 5. 功能范围总览

| 模块 | 主要能力 |
| --- | --- |
| Projects & Workspaces | Git worktree 隔离、外部工作区、临时聊天、并行任务、Settled 生命周期 |
| Agent Threads | 主区域双 Buffer 会话、多模型、流式消息、steer/follow-up/interrupt、队列撤回、恢复、compact |
| Code Comments | 文件/diff 行级评论、勾选子集分批投递、重定位、常驻回复展示、一键跳转所属 Thread |
| Thread Fork & Merge | 显式 Fork、拆分 skill 派生子 Thread、公共前缀与 handoff 合并 |
| Spec Graph | 创建、搜索、导航、验证和持续维护项目长期知识 |
| Shared Plans | Thread 内嵌共享计划、步骤状态、验证摘要、分步提交 |
| Changes & Review | 双侧/单栏 Git diff、逐行评论、独立 reviewer、修复循环 |
| Subagents & Background | 关联子 Threads、并行 fan-out、后台命令状态记录与结果投递 |
| Artifacts | 持久产物、与 thread 关联、浏览和引用 |
| PR & Delivery | PR body、push/create/sync、checks、review、merge-ready |
| Skills & Extensions | 精简核心 skills，直接复用用户已有 Pi packages、extensions、MCP 与认证 |
| Workbench | Neovim 0.12+ 原生 TUI 窗口、代码/diff/thread/comments 协同与远程透明运行 |

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
- 支持从已有 thread（包括 merge 产生的 thread）创建 Managed workspace：携带 handoff 摘要与来源链接、当前 plan/task-spec、相关 comments、未解决冲突、假设和完成条件；新 worktree 中创建执行 thread，原 thread 作为设计来源保持不变。
- 每个 workspace 有独立 artifacts、plans、comments 和 thread 列表。

### 6.4 Settled 生命周期

- PR 已合并或关闭、长期无活动的 Workspace 可进入 Settled。
- 新消息、文件变化、终端工作或用户操作会重新激活它。
- 用户可手动 park 或恢复。
- Default 和 External 不被自动回收。
- 归档前明确展示仍运行的 thread、子代理和后台命令，避免误删工作。

## 7. Agent Threads

### 7.1 多会话

- 每个 Workspace 可同时存在多个独立 threads。
- 每个 thread 可拥有独立模型、thinking level、工作目录、plan 和后台命令记录。
- 支持普通独立线程、Fork 线程、拆分 skill 派生的子代理线程和合并产生的 thread（统一使用同一 Thread 模型）。
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
- 支持图片、文件引用、buffer、selection、diagnostics、comment 和 git diff 上下文；在代码区选中内容时可通过 `<Space>as` / `<Space>aS` 免切窗快速提问（默认发往当前活跃 Thread，运行中默认 Follow-up，显式 `S` 才走 Steer），不抢走编辑器焦点。
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

用户可以在以下内容上创建行级或选区 comment：

- 普通文件的一行或连续行（visual selection）；
- 未提交 diff 或指定 branch/commit diff 的新旧两侧（`Base` / `Modified`）；
- 在主工作区打开的 Spec、task-spec、artifact 或 PR body 文本。

创建 comment 不修改源文件内容，不插入 `//`、`#` 等真实代码注释。

### 8.2 Comment 内容

每条 comment 保存：

- 唯一 ID；
- 正文；
- 文件路径及所在 workspace；
- diff side（`base` / `modified`）与固定 `base_ref`；
- 创建时的行范围、代码片段及必要上下文；
- 内容 hash 和可重新定位的 text quote；
- 当前状态：`draft`、`sent`、`dismissed`（不再设置独立的 `resolved` / `reopen` 状态机，避免与 Thread 会话形成双轨维护）；
- 锚点状态：`anchored`、`moved`、`outdated`；
- 发送目标 thread、发送时间与最新回复摘要；
- 关联的 Thread 消息引用（Thread 为评论回复与后续讨论的唯一事实来源）。

### 8.3 草稿与分批投递管理

- 在普通文件或 Diff 中按 `<Space>ac` 直接打开轻量浮窗：当前行无草稿时新建，已有草稿时直接载入编辑；不提供单条评论的“发给当前 Thread”或常驻“编辑”按钮。
- 默认创建为 `draft`，不立即打断 Agent；代码行保留下划线与行号标记，并在代码行下方通过只读 `virt_lines` 常驻直接展示评论正文与回复。
- 右侧评论列表（宽屏）与底部评论架（窄屏或用户显式打开）集中、完整展示当前 workspace 的评论原文与回复，不截断省略。
- 支持跨文件、跨 diff 暂存草稿，并支持**勾选任意子集分批投递**：例如先勾选一批草稿发往已有 Thread A，再勾选另一批发往已有 Thread B，剩余草稿发往新建独立 Thread。
- 默认发送目标是当前活跃 Thread，可显式切换为其他已有 Thread 或新建独立 Thread；向非活跃 Thread 投递评论不会自动切换当前活跃 Thread，也不会抢走代码区焦点。
- 评论列表头部清晰展示当前发送目标与已勾选条数，未勾选草稿（`N = 0`）时禁止发送。
- 发送意味着立即把真实 prompt 交给目标 Thread 或其专属队列，不是填入输入框等待。目标 Thread 空闲时立即执行；运行中默认进入该目标自己的 Follow-up 队列，仅显式触发（`S`）才进入 Steer。
- 已发送评论的撤回入口统一位于目标 Thread / Queue（按 `r`），不在代码行内重复提供。只有显式撤回尚未消费的排队项（或执行 Stop / Compact / Interrupt 排空）时，才统一回滚文字、引用并将关联未消费评论退回 `draft`；系统队列 `queue.system` 独立保留。

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

- 评论身份由 ID、创建时快照、内容 hash 和 text quote 保持；行号是可更新的位置，不是评论身份本身。
- 文件未变化时保持 `anchored`。
- 文件变化后，结合 `vim.text.diff` 与唯一文本匹配重新定位：如果原文可唯一定位，更新行号并标记 `moved`。
- 原文不存在、匹配不唯一或文件删除时标记 `outdated`，仍保留创建时快照供核对。
- base diff 使用固定 commit，不随后续代码移动。
- 发送前重新计算定位，避免把错误行号发给 Agent。

### 8.6 处理与后续沟通闭环

- Agent 的回复摘要会直接回写并在代码行下方的只读 `virt_lines` 以及右侧评论列表中常驻完整显示，无需移动光标才展开。
- 已发送评论不设单独的“继续修改（followup）”输入框或“解决（resolve）”按钮：**所有后续追问与讨论统一回到所属 Thread 主视图进行**（在评论列表按 `v`、点击“查看 Thread”，或在代码行按 `<Space>av` 直接打开目标 Thread）。
- 阅读完毕或不再需要保留锚点提示的评论（无论草稿还是已发送），均可在评论列表按 `d` 清理（`dismissed`），从代码下划线和列表中移除，不影响目标 Thread 的持久聊天记录。

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

1. **Common-prefix Merge（有真实公共祖先时优先）**：对于通过显式 Fork 或拆分 skill 派生、共享真实 `parent_id` / `fork_entry_id` 谱系的 Threads，先定位最深公共祖先，**公共前缀只继承或引用一次**，仅比较和合并分叉点之后的后缀结论、证据与冲突。
2. **Handoff Merge（无公共祖先时默认）**：对于完全独立的 Threads（或跨后端无谱系会话），生成结构化合并摘要，包括共同目标、各来源结论、决策、证据、未解决项、冲突和 artifacts 链接，**绝不伪造共享历史前缀**。
3. **Selected Context / Comparison First**：支持先对比各来源差异与冲突，或按需挑选关键条目组织进新 Thread。

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

- 用户在代码或双侧 Diff 上逐行留草稿评论，按第 8 节统一流程勾选不同子集分批投递给目标 Thread 或新建 Thread；也可通过 Fork / 拆分 skill 派生子 Thread 并行排查，完成后汇总结论。
- Review 直接复用代码行下方的常驻 `virt_lines` 与右侧评论列表展示原文和 Agent 回复，所有追问与讨论统一跳转到所属 Thread 进行，不单独拆出与 Thread 脱节的审查页。
- 支持独立 reviewer 子代理从两条轴进行冷审查：
  - **Standards**：仓库规范、架构和代码质量；
  - **Spec**：是否满足原始要求、是否遗漏或扩大范围。
- 只有能由代码、运行或明确规范支持的 finding 才进入正式问题列表。

### 12.3 修复循环

- review findings 与计划步骤返工请求可发送到新子 Thread，或以 Follow-up 排队发回原实现 Thread（不以 Steer 打断正在执行的工具调用；消费前撤回或发送失败时统一回滚对应状态）。
- 排队项的撤回只在目标 Thread / Queue 进行（按 `r`），不在代码行内提供第二入口。
- 修复后重新检查相关 finding 和 blast radius；只审查新增修订，不要求每次重看全部历史变更。

## 13. 后台命令与子代理归属

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

### 13.2 子代理与后台资源的呈现归属

不单独设置常驻的“任务（Resources）”侧栏页签，按真实对象语义归位：

- **子代理（Subagents）即关联子 Threads**：由显式 Fork 或拆分 skill 创建的子代理本身就是带 `parent_id` 的 Thread，直接在主区域 Thread 选择器、左导航 Threads 和谱系树中查看与切换，拥有完整 transcript。
- **后台命令与服务记录在发起 Thread 中**：后台命令不是聊天会话，其启动原因、运行状态、退出码和有界日志链接直接记录在发起 Thread 的消息流、`queue.system` 回传通知或底部 Shelf 终端/队列页中，支持随时查看输出和精确停止，不强行伪装成 chat session。

## 14. Artifacts

- Agent 在会话中产生的临时或正式交付文件（如 task-spec、调研报告、架构图、验证日志、PR body、合并摘要）默认保存在 workspace 的 Git-ignored 区域，避免散落 `/tmp` 或污染 Git 工作树。
- 左导航 `Artifacts` 支持按当前 workspace 查看交付物并在主代码区直接打开、引用或留 comment；临时产物不自动纳入提交。

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

| 核心 Skill | 用途 |
| --- | --- |
| `choosing-a-workflow` | 根据任务进入 onboarding、设计、调试、执行、审查、交付或直接回答，避免所有请求都走重流程。 |
| `onboarding-a-project` | 空项目形成目标文档，已有代码生成 Spec 图谱，已有 Spec 则审查和补齐。 |
| `designing-a-change` | 通过多轮访谈明确产品和技术决策，必要时用原型比较方案，并写入 task-spec、Glossary 或 ADR。 |
| `diagnosing-bugs` | 建立可复现反馈回路，最小化、假设、instrument、修复和回归验证；覆盖性能和 trace 分支。 |
| `executing-with-todos` | 将工作拆成可验证任务图，维护共享计划、证据和分步提交。 |
| `verifying-behavior` | 建立并维护项目验证路径，检查真实行为、性能数字和必要的形式化属性。 |
| `reviewing-changes` | 从 Standards 与 Spec 两轴审查，支持逐行评论、对抗审查和修复复审。 |
| `shipping-a-pr` | 完成最终验证、生成 PR、同步、处理 CI/review 并交付。 |
| `researching-and-explaining` | 基于代码、历史、文档和 primary sources 调研，并形成引用明确的解释或 handoff。 |
| `coordinating-agents` | 管理子代理、并行切片、方案竞赛、后台结果和长期任务决策日志。 |
| `maintaining-project-knowledge` | 维护 Spec 图谱、统一术语、ADR 和跨 compact 的关键上下文。 |
| `improving-agent-environment` | 将会话经验变成架构、类型、lint、CI、测试或更准确的 skill，而不是堆积提示词。 |

### 16.3 不单独新增的内容

以下能力作为上述 skills 的 sibling reference、产品功能或已有 extension 使用，不额外扩展 skill 数量：

- `ask_user_question`、visualize、web access；
- `managing-mcp-servers` 等 MCP 配置说明；
- PR body、comment package、decision log 等格式模板；
- `writing-for-agents`、`writing-workflow-skills`、`unslop/technical-writing` 等写作与工作流编写指南；
- TDD、Triage、Wayfinder、Software Factory、Formal Verification 的细分 playbook；
- UI 操作，如创建 comment、合并 thread、切换窗口。

## 17. Pi Extensions、Packages 与 MCP

### 17.1 复用已有 Pi 生态（不重复造包管理器）

- pide 直接复用用户通过 Pi CLI 已安装和配置的 packages、extensions、skills、prompt templates 和 tools，**不在 Neovim 内重复实现一套 npm/Git 包管理与商店 UI**。
- 在当前 Thread 中展示已加载的 tools / skills 状态与加载错误，支持调用已有能力（如结构化提问、网页调研、子代理与自定义工具）。

### 17.2 通用 Extension UI 承载

pide 为 Pi 扩展提供 Neovim 原生通用交互映射：

- `select`、`confirm`、`input` → `minimal` 浮窗选择或单行输入；
- `editor` → 可编辑 scratch buffer；
- `notify`、`status` → 状态栏与非侵入消息提示；
- 工具执行的 `start / update / end` 流式输出与文件行号跳转链接直接在 Thread Markdown buffer 中呈现。

只承载宿主通用协议，不要求扩展为 pide 编写专用 renderer；高度依赖独立终端画布的扩展明确提示降级。

### 17.3 MCP

- 直接读取并遵循 Pi 的用户级和项目级 MCP 配置；项目级配置需明确信任后启用，非只读调用遵循确认策略，调用记录体现在所属 Thread 的工具输出中。

## 18. 模型、外观与运行环境

### 18.1 Providers 与模型

- 直接复用用户已有 Pi 认证与模型配置（provider、API key、OAuth、自定义网关），不在 pide 中另建账号或密钥管理体系。
- 支持在 Thread 中切换可用模型与 thinking level，配置与 Pi CLI 保持一致，并清晰提示缺失认证或上下文限制。

### 18.2 输入与上下文

- Prompt 支持文本、文件引用、visual selection、diagnostics、comments、diff 和 artifacts；支持 `/skill:name` 与 prompt template 调用补全。

### 18.3 外观与键盘可访问性

- 完全继承用户当前 Neovim colorscheme、字体与 `'winborder'`，不建立第二套冲突的主题/字体配置系统；仅提供语义化的 `Pide*` highlight groups（默认链接到标准高亮组）供按需覆盖。
- 所有功能（会话阅读、多行输入、行级评论、分批投递、提问作答、Fork/Merge）100% 可通过键盘完成，状态同时通过文字与符号表达，不只依赖颜色。

### 18.4 本地与远程

- 本地 Neovim 与 SSH / Tailscale 远程 Neovim 下保持完全一致的纯文本 TUI、Thread 和 Workspace 语义；远程工作目录在状态栏清晰标明，避免本机/远端混淆。

## 19. Neovim 0.12+ 界面与交互设计

> 完整可交互视觉与按键原型见 [`doc/ui.html`](./ui.html)。

### 19.1 设计目标与原生 TUI 边界

- **纯正 Neovim 0.12+ 原生 TUI**：所有界面完全由普通窗口、真实命名 buffer、单行 `winbar`（含 `%@` 可点击文本段）、`nvim_buf_set_extmark`（行号标记 + 下划线 + 只读 `virt_lines`）和轻量 `minimal` 浮窗构成，**绝不假设存在 Web/HTML 按钮控件**。
- **键位边界绝对干净**：在可编辑代码与 Diff buffer 中，pide 仅注册 `<leader>a…`（如 `<Space>ac`、`<Space>ai`）前缀键，绝不覆盖 `c/C`、`r`、`gd`、`gt`、`gq` 等原生 Vim 操作符，也不篡改原生窗口跳转 `<C-w>h/j/k/l`；单字符短键（`j/k`、`Space`、`s`、`t`、`v`、`d`、`q`）仅在 pide 只读插件 buffer 与浮窗内局部生效。
- **主区域承载重阅读，侧栏保持单一轻量**：长对话、代码块、Plan 与多行输入放在宽敞的主区域 Thread 视图；右侧栏只承载“评论列表”，不再把聊天和任务塞进狭窄侧边栏。
- **隐藏面板不杀进程**：收起侧栏或切回代码只隐藏窗口，不终止后台 Thread、子代理或后台命令。

### 19.2 核心工作布局

**模式 A：日常代码阅读与行级评论（默认）**

```text
┌──────────────────────────────────────────────────────────────────┐
│ Tabline: 1: feat/auth · jwt.lua │ ...                  feat/auth │
├───────────────┬──────────────────────────────┬───────────────────┤
│ 可选左导航     │ 主工作区：代码文件 / Diff     │ 右侧：评论列表     │
│ Workspaces    │  7  local token = ...        │ 发送到: 鉴权Thread │
│ Threads       │     ↳ [草稿] 是否兼容小写？   │ 已勾选 2 条  发送  │
│ Specs         │ 12  if claims.exp < ...      │ [x] 草稿 Mod:L7   │
│ Artifacts     │     ↳ [已回复] ...            │ 已回复 Mod:L12    │
│               │     ↳ 回复: 已加入校验...     │   ↳ 回复: ...     │
├───────────────┴──────────────────────────────┴───────────────────┤
│ 可选底部 Shelf：评论架（窄屏自动接管） / 排队消息 / 诊断          │
└──────────────────────────────────────────────────────────────────┘
```

**模式 B：主区域宽版 Thread 会话（按 `<Space>ai` 打开，按 `q` 栈式返回代码）**

```text
┌──────────────────────────────────────────────────────────────────┐
│ pide://thread/t1 │ #1 鉴权 Thread  #2 副 Thread │ +Thread Fork q │
│ ──────────────────────────────────────────────────────────────── │
│ ## Plan                                                          │
│ - [x] 1. 提取 Bearer 令牌格式校验                                 │
│ ### 你 / ### Agent（只读 Markdown transcript，支持搜索与折叠）     │
├──────────────────────────────────────────────────────────────────┤
│ pide://composer/t1 · claude-sonnet-4      r 撤回 · Stop · Send   │
│ 多行可编辑输入 buffer（Enter 发送，Shift+Enter 换行，Esc 回会话）  │
└──────────────────────────────────────────────────────────────────┘
```

### 19.3 各区域职责

#### 主区域：代码 / Diff 与双 Buffer Thread 栈式切换

- 日常用于文件编辑、双侧/单栏 Diff、Spec 与 Artifact 阅读。
- 按 `<Space>ai` 在主区域打开当前活跃 Thread（尚无 Thread 时自动新建），由两个真实 buffer 上下组合：
  - **上方会话窗（`pide://thread/<id>`）**：只读 Markdown buffer，复用 Neovim 0.12 原生 Markdown Treesitter 高亮与折叠，内嵌展示可选 `## Plan`、消息流、文件行号引用与后台输出链接；顶栏 `winbar` 支持 `#1/#2` 或 `Tab` 切换不同 Thread，以及 `n` 新建独立 Thread、`f` Fork、`s` 调用拆分 skill、`m` 进入 Merge、`a` 并排开关右侧评论列表。
  - **下方输入窗（`pide://composer/<id>`）**：固定高度普通可编辑 buffer，天然支持多行粘贴、编辑与补全；`winbar` 显示当前模型、未消费队列摘要及 `r` 撤回、`Stop`、发送模式。
- 按 `q` 从 `viewStack` 精确恢复进入 Thread 前的代码/Diff buffer、光标滚动位置和侧栏开闭状态。

#### 右侧评论列表（Comments Sidebar）

- 右侧栏**仅承载评论列表**（不再包含 Thread 页和任务页），为纯文本只读 buffer，开启软换行完整展示每条评论正文与 `↳ 回复：...`，不作单行截断。
- 顶部清晰展示 `发送到：<目标 Thread 名称> ▾ (按 t 切换)` 与 `已勾选 N 条草稿 / 发送勾选草稿 (s)`（不使用晦涩缩写）。
- 键盘闭环：`j/k` 移动并联动预览代码位置、`Space` 勾选草稿、`e` 打开小窗编辑草稿、`t` 选择发送目标（当前 Thread / 其他已有 Thread / 新建独立 Thread）、`s/S` 批量发送（Follow-up / Steer）、`Enter` 跳回对应代码侧与行号、`v` 跳转到关联 Thread、`d` 清理草稿或已读评论。

#### 代码行内常驻虚拟行（`virt_lines`）

- 有未清理评论的代码行保留行号旁标记与代码下划线，并在该行下方通过只读 `virt_lines` **常驻直接展示评论内容、`outdated` 原文快照及 `↳ 回复：...`**，无需把光标移到该行才展开；`virt_lines` 内不包含任何按钮，编辑按 `<Space>ac`，打开关联会话按 `<Space>av`。
- `moved` 行号偏移静默更新；仅 `outdated` 高亮提示需核对快照。
- 真实验证信息留在 Plan 步骤或 Thread 记录中，不在状态栏放置无数据支撑的“已验证”徽章；Thread 运行态直接联动 Neovim 0.12 原生 `'busy'` 状态与进度提示。

#### 左侧导航栏与底部 Shelf

- **左导航（`<Space>an`）**：按需切换浏览 Workspaces、Threads、Specs、Artifacts。
- **底部 Shelf（`<Space>al` / `<Space>aq`）**：窄屏 Diff 下自动接管评论列表（与右侧评论列表共享同一份评论状态，绝不同时双开）；Queue 页展示当前 Thread 的 Steer / Follow-up 待消费项并支持 `r` 撤回回填草稿。

### 19.4 Review 布局

```text
┌───────────────────────┬───────────────────────┬──────────────────┐
│ Base (HEAD~1)         │ Modified (Worktree)   │ 评论列表          │
│ 可留旧侧评论与定位     │ 可留新侧评论与定位     │ 分批勾选投递 / v  │
└───────────────────────┴───────────────────────┴──────────────────┘
```

- 宽屏左中两栏使用 Neovim 0.12 原生 diff（默认含 `indent-heuristic` 与 `inline:char` 字符级高亮），右侧复用评论列表（严格最多三栏）。
- 窄屏跨过断点时自动收起右侧栏，改为“单栏 Diff（顶栏及 `<Space>ab` 切换 Base ⇄ Modified）+ 底部评论架”；跨回宽屏时仅收起由窄屏自动展开的 Shelf，尊重用户手动开关状态。
- 选中或定位 Base 评论时自动切到 Base 侧对应行，选回 Modified 评论自动切回 Modified 侧。

### 19.5 Thread Tree 与 Merge 视图

- Thread Tree（`<Space>at`）使用主区域只读 buffer，展示 Pi 会话历史分支、节点摘要与当前节点，支持 `f` Fork、`s` 干净上下文派发子代理、`m` 进入合并、`q` 栈式返回。
- Merge（`<Space>am`）使用主区域三步只读视图：
  1. 勾选来源 Threads；
  2. 自动检测谱系：有公共祖先时明确提示“公共前缀只继承一次，仅合并分叉后缀”，无公共祖先时走 Handoff Merge；
  3. 预览/在 scratch buffer（`e`）中修订合并摘要后回车创建新 Thread 并切入主视图。

### 19.6 临时交互与窗口保护

- `<Space>ac` 行级评论输入、`<Space>as` 选区快速提问、发送目标选择、模型切换、工作区切换和 `<Space>ar` 待回答问题均使用 `style = "minimal"` 浮窗，关闭后精确归还焦点；Agent 发起提问时先在状态栏/会话条给出非侵入提示，不强弹窗打断打字。
- 多行评论（`<Space>aC`）与合并摘要修订使用可编辑 scratch buffer。
- 所有插件专用窗口（评论列表、底部 Shelf、左导航、Thread 上下双窗口）统一启用 Neovim 0.12 `winfixbuf = true`（配合 `winfixwidth` / `winfixheight`），防止 `:e`、`:bnext`、`:cnext` 误替换插件面板，同时严禁覆盖用户带有未保存修改 `[+]` 的编辑窗口。

## 20. 核心端到端工作流

### 20.1 Feature 开发与分步验证

```text
明确需求与设计（更新 Spec / 创建共享 Plan）
  → 在隔离 Managed worktree 中按步骤实现与验证
  → 代码区审查 Diff、留评论修正细节
  → 生成证据明确的 PR 并交付
```

### 20.2 代码评论驱动修改

```text
阅读代码或双侧 Diff
  → 按 Space ac 在小窗新建/编辑行级评论草稿（代码行下方常驻展示 virt_lines）
  → 在右侧评论列表勾选一批草稿发往 Thread A，另一批草稿发往 Thread B 或新建 Thread
  → 各目标 Thread 独立执行或入队，回复直接回写显示在代码行下方与评论列表中
  → 需要深入沟通时按 v（或 Space av）直接进入目标 Thread 主视图继续对话；看完可按 d 清理评论锚点
```

### 20.3 分叉探索与多 Thread 合并

```text
当前 Thread 遇到复杂子任务或多方案取舍
  → 按 f 显式 Fork 或按 s 调用拆分 skill 创建关联子 Threads 并行推进
  → 按 m 选择多个来源 Threads：有公共祖先时公共前缀只继承一次并合并分叉后缀，无公共祖先时走 handoff merge
  → 在合并产生的新 Thread 中继续实施，源 Threads 历史保持只读可追溯
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

- 能在普通文件和 diff 新旧两侧通过 `<Space>ac` 直接新建或编辑行级草稿评论。
- 跨文件、跨 diff 暂存草稿后，可勾选不同子集分别批量投递给当前活跃 Thread、指定已有 Thread 或新建独立 Thread，且不改变当前活跃 Thread、不抢走代码焦点。
- Agent 收到的文件、行号、diff side、base_ref、代码片段和 comment 内容准确。
- 文件变化后 comment 能通过 `vim.text.diff` 与 quote/hash 重新定位，或明确标记 `outdated`。
- 评论正文与 Agent 回复在代码行下方 `virt_lines` 和右侧评论列表中均常驻完整可见；可通过 `Enter` 跳回代码侧与行号、`v` 跳转所属 Thread 继续对话、`d` 清理评论。

### 23.3 Fork 与 Merge

- 能通过显式 Fork 或拆分 skill 从当前或指定历史节点创建关联子 Thread（记录 `parent_id` 与 `fork_entry_id`）。
- Fork / 拆分后原 Thread 不变，子 Thread 拥有独立 transcript 与队列。
- 能选择多个 Threads 创建合并 Thread：有真实公共祖先时公共前缀只继承一次并合并分叉后缀；无公共祖先时执行 Handoff Merge，不简单拼接全部消息，也不伪造共享历史或改写源历史。

### 23.4 Workspaces 与 Plans

- 并行 Agent 默认在独立 worktree 中运行。
- 能从已有或合并 thread 创建 Managed worktree，并携带 handoff、plan/task-spec、相关 comments 和来源链接。
- 共享 plan 能反映步骤、阻塞、验证和提交状态。
- 不安全的情况下不自动提交，不把其他任务或用户 WIP 混入 commit。

### 23.5 Extensions 与 Skills

- 能直接复用用户已安装的 Pi packages、skills 与通用交互协议。
- 核心 skill 数量保持精简，没有为重复说法或单个 UI 操作新增大量 skills。
- ACP backend 下不支持的能力明确降级，不影响基本聊天、comments 和 review。

### 23.6 UI（Neovim 0.12+ 原生 TUI）

- 界面全部使用 Neovim 0.12+ 原生 buffer、window、`winbar`、extmark `virt_lines` 与 `minimal` 浮窗实现，不依赖任何 HTML 按钮假设；专用窗口启用 `winfixbuf` 保护。
- 可编辑代码/Diff buffer 仅使用 `<leader>a…` 前缀键，不覆盖任何原生 Vim 操作符或窗口跳转键。
- `<Space>ai` 在主区域打开「上只读 Markdown transcript + 下可编辑 composer」双 Buffer Thread 视图，`q` 栈式精确恢复原代码布局；右侧栏仅承载“评论列表”，不设独立“任务”tab。
- 宽屏右侧评论列表与窄屏底部评论架共享同一评论数据与状态，同一时刻只展示一份；评论与回复均完整展示不截断，且不设 `resolved` / 行内撤回按钮。
- Review、评论架、Thread、Thread Tree 和 Merge 均有明确键盘进入与栈式返回路径，窄屏下仍能完整完成双侧切换、评论与会话操作。

## 24. 最终产品边界

pide 的最终目标是形成一个以 Neovim 为中心的 Agentic IDE：

- 覆盖项目、工作区、规划、实现、验证、审查与交付的完整开发闭环；
- 通过可组合的工作流支持需求访谈、任务图、TDD、诊断、双轴审查和环境改进；
- 支持并行方案探索、运行时验证和有明确授权边界的自治执行；
- 复用 Pi 的 Agent、session、tools、skills 和 extensions；
- pide 自己重点创造的是：
  - Neovim 原生的代码与 Agent 协同；
  - 文件/diff comments 与批量处理；
  - 可分叉的子代理工作；
  - 可追溯的跨 thread 合并；
  - 不干扰代码工作的窗口与审查体验。
