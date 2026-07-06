require("conform").setup({
  formatters = {
    ["google-java-format"] = {
      prepend_args = { "--aosp" },
    },
  },
})

return {
  "stevearc/conform.nvim",
  opts = {
    formatters_by_ft = {
      lua = { "stylua" },
      javascript = { "prettier" },
      typescript = { "prettier" },
      javascriptreact = { "prettier" },
      typescriptreact = { "prettier" },
      json = { "prettier" },
      css = { "prettier" },
      markdown = { "prettier" },
      java = { "google-java-format" },
      python = { "black" },
      sh = { "shfmt" },
      cpp = { "clang_format" },
      c = { "clang_format" },
      cs = { lsp_format = "prefer" },
    },
  },
}
