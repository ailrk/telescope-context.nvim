if vim.g.loaded_telescope_context then
  return
end
vim.g.loaded_telescope_context = true

require("telescope-context").setup()
