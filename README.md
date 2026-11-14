# pide.nvim

A smooth agentic IDE experience inside Neovim.

`pide.nvim` embeds your coding agent in Neovim and sends it rich editor context, without replacing your existing editing workflow. It is agent-agnostic: use Claude Code, another interactive coding-agent CLI, or your own command.

> **Status:** early MVP. The terminal agent and code-context flow work today; deeper IDE integrations are planned below.

## Features

- Toggle an AI coding agent in a side panel or horizontal split
- Ask questions with `:PideAsk`
- Send visually selected code with its file path, line range, and language
- Keep the agent session alive while its window is hidden
- Configure any interactive agent command and working directory
- No Neovim plugin dependencies

## Requirements

- Neovim 0.10+
- An interactive coding-agent CLI, such as [Claude Code](https://github.com/anthropics/claude-code)

## Installation

With [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "ljie-PI/pide",
  opts = {
    agent = {
      command = { "claude" },
    },
  },
}
```

With [packer.nvim](https://github.com/wbthomason/packer.nvim):

```lua
use({
  "ljie-PI/pide",
  config = function()
    require("pide").setup()
  end,
})
```

The default configuration works without calling `setup()`. Run `:checkhealth pide` to verify your setup.

## Usage

| Command | Description |
| --- | --- |
| `:Pide` | Toggle the agent window |
| `:PideAsk [prompt]` | Send a prompt; omit it to open an input prompt |
| `:'<,'>PideSendSelection [instruction]` | Send the selected lines and their context |
| `:PideClose` | Stop the agent and close its window |

Example visual-mode mapping:

```lua
vim.keymap.set("v", "<leader>as", ":PideSendSelection<CR>", { desc = "Send code to agent" })
```

Example normal-mode mappings:

```lua
vim.keymap.set("n", "<leader>aa", "<Cmd>Pide<CR>", { desc = "Toggle agent" })
vim.keymap.set("n", "<leader>aq", ":PideAsk ", { desc = "Ask agent" })
```

## Configuration

Defaults:

```lua
require("pide").setup({
  agent = {
    command = { "claude" },
    cwd = nil, -- Uses Neovim's current working directory
  },
  ui = {
    position = "right", -- "right", "left", "bottom", or "top"
    width = 0.35, -- Fraction <= 1, or absolute columns
    height = 0.30, -- Fraction <= 1, or absolute rows
  },
})
```

For another agent, replace the command and its arguments:

```lua
require("pide").setup({
  agent = {
    command = { "my-agent", "--workspace", "." },
    cwd = function()
      return vim.fn.getcwd()
    end,
  },
})
```

The command must provide an interactive terminal interface and accept submitted prompts from stdin. Pide does not handle provider authentication or API keys; configure those in the agent CLI itself.

## How it works

Pide starts the configured CLI in a Neovim terminal buffer. The agent runs in your project directory, so its built-in tools can inspect and modify the project according to that CLI's permission settings. Selection prompts are formatted as Markdown with file, line, and language metadata.

**Note:** coding agents can edit files and execute commands. Review your agent's permission settings and its proposed changes.

## Roadmap

- [x] Embedded agent terminal
- [x] Prompt and code-selection context
- [ ] Buffer, diagnostics, and git-diff context providers
- [ ] Structured edit and diff-review workflow
- [ ] Multiple named agent sessions
- [ ] Tool-call activity and approval UI
- [ ] LSP-aware navigation and edit tools

## Development

```sh
make test    # Headless Neovim smoke test
make check   # Luacheck and StyLua (must be installed locally)
make format  # Format Lua files
```

## Contributing

Issues, ideas, and pull requests are welcome. Keep the core dependency-free and avoid coupling it to a single model provider.

## License

[MIT](LICENSE)
