local agent = require("pide.agent")

local M = {}

local defaults = {
  agent = {
    -- Any interactive coding agent that reads prompts from stdin can be used.
    command = { "claude" },
    -- Defaults to Neovim's current working directory. A string or function is accepted.
    cwd = nil,
  },
  ui = {
    position = "right", -- "right", "left", "bottom", or "top"
    width = 0.35, -- A fraction <= 1, or an absolute number of columns
    height = 0.30, -- A fraction <= 1, or an absolute number of rows
  },
}

M.config = vim.deepcopy(defaults)

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", vim.deepcopy(defaults), opts or {})
end

function M.toggle()
  agent.toggle(M.config)
end

function M.open()
  agent.open(M.config)
end

function M.close()
  agent.close()
end

function M.ask(prompt)
  if not prompt or vim.trim(prompt) == "" then
    prompt = vim.fn.input("Pide prompt: ")
  end

  if vim.trim(prompt) ~= "" then
    agent.send(M.config, prompt)
  end
end

function M.send_selection(first_line, last_line, instruction)
  local lines = vim.api.nvim_buf_get_lines(0, first_line - 1, last_line, false)
  if #lines == 0 then
    return
  end

  local path = vim.api.nvim_buf_get_name(0)
  path = path ~= "" and vim.fn.fnamemodify(path, ":.") or "[No Name]"
  instruction = vim.trim(instruction or "")
  if instruction == "" then
    instruction = "Please help me with the following code."
  end

  local prompt = string.format(
    "%s\n\nFile: `%s`\nLines: %d-%d\n```%s\n%s\n```",
    instruction,
    path,
    first_line,
    last_line,
    vim.bo.filetype,
    table.concat(lines, "\n")
  )

  agent.send(M.config, prompt)
end

function M.is_running()
  return agent.is_running()
end

return M
