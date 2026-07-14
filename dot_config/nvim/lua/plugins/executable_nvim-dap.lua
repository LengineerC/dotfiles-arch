return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "nvim-neotest/nvim-nio",
      "jay-babu/mason-nvim-dap.nvim",
      "rcarriga/nvim-dap-ui",
      "theHamsta/nvim-dap-virtual-text",
    },
    config = function()
      local dap = require("dap")
      local dapui = require("dapui")

      dapui.setup()
      dap.listeners.after.event_initialized["dapui_config"] = function()
        dapui.open()
      end
      dap.listeners.before.event_terminated["dapui_config"] = function()
        dapui.close()
      end
      dap.listeners.before.event_exited["dapui_config"] = function()
        dapui.close()
      end

      vim.keymap.set("n", "<leader>db", dap.toggle_breakpoint, { desc = "DAP Toggle Breakpoint" })
      vim.keymap.set("n", "<leader>dB", function()
        dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
      end, { desc = "DAP Set Conditional Breakpoint" })

      vim.keymap.set("n", "<F5>", dap.continue, { desc = "DAP Continue" })
      vim.keymap.set("n", "<F10>", dap.step_over, { desc = "DAP Step Over" })
      vim.keymap.set("n", "<F11>", dap.step_into, { desc = "DAP Step Into" })
      vim.keymap.set("n", "<F12>", dap.step_out, { desc = "DAP Step Out" })
      vim.keymap.set("n", "<leader>dr", dap.repl.open, { desc = "DAP REPL Open" })

      -- Rust 配置
      dap.adapters.codelldb = {
        type = "server",
        port = "${port}",

        executable = {
          command = vim.fn.stdpath("data") .. "/mason/bin/codelldb",

          args = {
            "--port",
            "${port}",
          },
        },
      }
      dap.configurations.rust = {
        {
          name = "Launch",
          type = "codelldb",
          request = "launch",
          program = function()
            return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/target/debug/", "file")
          end,
          cwd = "${workspaceFolder}",
          stopOnEntry = false,
          args = {},
        },
      }

      -- c#
      dap.adapters.coreclr = {
        type = "executable",
        command = vim.fn.stdpath("data") .. "/mason/bin/netcoredbg",
        args = {
          "--interpreter=vscode",
        },
      }
      dap.configurations.cs = {
        {
          type = "coreclr",
          name = "Launch .NET",
          request = "launch",

          program = function()
            local dll = vim.fn.glob(vim.fn.getcwd() .. "/bin/Debug/**/*.dll")

            return vim.fn.input("DLL: ", dll, "file")
          end,

          cwd = "${workspaceFolder}",
          stopOnEntry = false,
        },
      }

      -- node.js
      local adapter_cmd = vim.fn.stdpath("data") .. "/mason/bin/js-debug-adapter"

      dap.adapters["pwa-node"] = {
        type = "server",
        host = "127.0.0.1",
        port = "${port}",
        executable = {
          command = adapter_cmd,
          args = { "${port}" },
        },
      }

      dap.adapters["pwa-chrome"] = {
        type = "server",
        host = "127.0.0.1",
        port = "${port}",
        executable = {
          command = adapter_cmd,
          args = { "${port}" },
        },
      }

      local node_common = {
        cwd = "${workspaceFolder}",
        sourceMaps = true,
        protocol = "inspector",

        skipFiles = {
          "<node_internals>/**",
          "${workspaceFolder}/node_modules/**",
        },

        console = "integratedTerminal",
      }

      local function tsx_config()
        return vim.tbl_extend("force", node_common, {
          type = "pwa-node",
          request = "launch",
          name = "Launch TSX",

          program = "${file}",

          runtimeExecutable = "tsx",

          runtimeArgs = {
            "--inspect-brk",
          },
        })
      end

      local function js_config()
        return vim.tbl_extend("force", node_common, {
          type = "pwa-node",
          request = "launch",
          name = "Launch JavaScript",

          program = "${file}",

          runtimeExecutable = "node",

          runtimeArgs = {
            "--inspect-brk",
          },
        })
      end

      local attach_config = {
        type = "pwa-node",
        request = "attach",
        name = "Attach Node Process",

        processId = require("dap.utils").pick_process,

        cwd = "${workspaceFolder}",
      }

      for _, language in ipairs({
        "javascript",
        "javascriptreact",
        "typescript",
        "typescriptreact",
      }) do
        dap.configurations[language] = {
          js_config(),
          tsx_config(),
          attach_config,
        }
      end
    end,
  },
  {
    "mfussenegger/nvim-dap-python",
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "nvim-neotest/nvim-nio",
    },
    ft = { "python" },
    config = function()
      local path = vim.fn.stdpath("data") .. "/mason/packages/debugpy/venv/bin/python"
      require("dap-python").setup(path)
    end,
  },
}
