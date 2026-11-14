local M = {}

function M.check()
  vim.health.start("pide.nvim")

  if vim.fn.has("nvim-0.10") == 1 then
    vim.health.ok("Neovim 0.10 or newer")
  else
    vim.health.error("pide.nvim requires Neovim 0.10 or newer")
  end

  local command = require("pide").config.agent.command
  if type(command) == "string" then
    command = { command }
  end

  local executable = type(command) == "table" and command[1] or nil
  if executable and vim.fn.executable(executable) == 1 then
    vim.health.ok(string.format("Agent executable found: %s", executable))
  else
    vim.health.warn(string.format("Agent executable not found: %s", executable or "not configured"))
  end
end

return M
