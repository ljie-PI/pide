if vim.g.loaded_pide == 1 then
  return
end
vim.g.loaded_pide = 1

vim.api.nvim_create_user_command("Pide", function()
  require("pide").toggle()
end, { desc = "Toggle the Pide agent" })

vim.api.nvim_create_user_command("PideAsk", function(command)
  require("pide").ask(command.args)
end, { nargs = "*", desc = "Ask the Pide agent" })

vim.api.nvim_create_user_command("PideSendSelection", function(command)
  require("pide").send_selection(command.line1, command.line2, command.args)
end, { nargs = "*", range = true, desc = "Send a line range to the Pide agent" })

vim.api.nvim_create_user_command("PideClose", function()
  require("pide").close()
end, { desc = "Stop the Pide agent and close its window" })
