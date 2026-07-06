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
      dap.configurations.rust = {
        {
          name = "Launch",
          type = "codelldb",
          request = "launch",
          program = function()
            return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "\\target\\debug\\", "file")
          end,
          cwd = "${workspaceFolder}",
          stopOnEntry = false,
          args = {},
        },
      }

      -- node.js
      local adapter_cmd = vim.fn.stdpath("data") .. "\\mason\\bin\\js-debug-adapter.cmd"
      if not dap.adapters["pwa-node"] then
        dap.adapters["pwa-node"] = {
          type = "server",
          host = "127.0.0.1",
          port = "${port}",
          executable = {
            command = adapter_cmd,
            args = { "${port}" },
          },
        }
      end

      if not dap.adapters["pwa-chrome"] then
        dap.adapters["pwa-chrome"] = {
          type = "server",
          host = "localhost",
          port = "${port}",
           executable = {
            command = adapter_cmd,
            args = { "${port}" },
          },
        }
      end

      for _, language in ipairs({ "typescript", "javascript", "typescriptreact", "javascriptreact" }) do
        dap.configurations[language] = {
          -- --- 模式 A: 调试当前文件 (Node) ---
          {
            type = "pwa-node",
            request = "launch",
            name = "Launch Current File (pwa-node)",
            program = "${file}", -- 当前打开的文件
            cwd = "${workspaceFolder}",
            -- 针对 TS 文件，通常需要 ts-node (见下文详解)
            runtimeExecutable = "node",
            -- 如果是 TS，这里可能需要加上 runtimeArgs = {"--loader", "ts-node/esm"} 等
            sourceMaps = true,
            protocol = "inspector",
            console = "integratedTerminal",
          },
          -- --- 模式 B: 连接到已有的进程 (Attach) ---
          {
            type = "pwa-node",
            request = "attach",
            name = "Attach to Process (pwa-node)",
            processId = require("dap.utils").pick_process,
            cwd = "${workspaceFolder}",
          },
          -- --- 模式 C: 调试 Web 应用 (Chrome) ---
          -- {
          --   type = "pwa-chrome",
          --   request = "launch",
          --   name = "Launch Chrome against localhost",
          --   url = "http://localhost:3000",
          --   webRoot = "${workspaceFolder}",
          -- }

          -- --- tsx ---
          -- {
          --   type = "pwa-node",
          --   request = "launch",
          --   name = "Launch with tsx (current file)",
          --   program = "${file}",
          --   cwd = "${workspaceFolder}",
          --   runtimeExecutable = "tsx",
          --   sourceMaps = true,
          --   protocol = "inspector",
          --   console = "integratedTerminal",
          --   skipFiles = {
          --     "<node_internals>/**",
          --     "${workspaceFolder}/node_modules/**",
          --   },
          -- },
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
      local path = vim.fn.stdpath("data") .. "\\mason\\packages\\debugpy\\venv\\Scripts\\python.exe"
      require("dap-python").setup(path)
    end,
  },
}
