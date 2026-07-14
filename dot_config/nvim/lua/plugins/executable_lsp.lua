local lspconfig = require("lspconfig")

return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        marksman = false,
      },
    },
  },
  {
    "omnisharp/omnisharp-roslyn",
    ft = "cs",
    opts = {
      cmd = {
        vim.fn.stdpath("data") .. "/mason/bin/OmniSharp",
        "--languageserver",
        "--hostPID",
        tostring(vim.fn.getpid()),
      },

      enable_editorconfig_support = true,

      settings = {
        FormattingOptions = {
          EnableEditorConfigSupport = true,
          OrganizeImports = true,
        },
      },
    },

    config = function(_, opts)
      require("lspconfig").omnisharp.setup(opts)
    end,
  },
  {
    "mfussenegger/nvim-jdtls",
    ft = { "java" },
    config = function()
      local jdtls = require("jdtls")

      -- Mason 安装路径
      local jdtls_cmd = {
        vim.fn.stdpath("data") .. "/mason/bin/jdtls",
        "--jvm-arg=-Dorg.eclipse.jdt.core.formatter.settings=file:///D:/jdks/java-style.xml",
        "--jvm-arg=-Dorg.eclipse.jdt.core.formatter.profile=Default",
      }

      -- 自动找项目根目录
      local root_dir = vim.fs.dirname(vim.fs.find({
        ".git",
        "mvnw",
        "gradlew",
        "pom.xml",
        "build.gradle",
      }, { upward = true })[1])

      local config = {
        cmd = jdtls_cmd,
        root_dir = root_dir,
        settings = {
          java = {
            format = {
              enabled = true,
              settings = {
                url = "file:///D:/jdks/java-style.xml",
                profile = "Default",
              },
            },
          },
        },
      }

      jdtls.start_or_attach(config)

      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if client and client.name == "jdtls" then
            client.server_capabilities.documentFormattingProvider = true
            client.server_capabilities.documentRangeFormattingProvider = true
          end
        end,
      })
    end,
  },
}
