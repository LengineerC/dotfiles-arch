return {
  {
    "LazyVim/LazyVim",
    init = function()
      local group = vim.api.nvim_create_augroup("c_cpp_indent", { clear = true })

      vim.api.nvim_create_autocmd("FileType", {
        group = group,
        pattern = { "c", "cpp" },
        callback = function(event)
          local options = vim.bo[event.buf]
          options.tabstop = 4
          options.shiftwidth = 4
          options.softtabstop = 4
          options.expandtab = true
        end,
        desc = "Use four-space indentation for C and C++",
      })
    end,
  },
}
