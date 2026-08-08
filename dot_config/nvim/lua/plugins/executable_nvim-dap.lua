return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "nvim-neotest/nvim-nio",
      "jay-babu/mason-nvim-dap.nvim",
      "rcarriga/nvim-dap-ui",
      "theHamsta/nvim-dap-virtual-text",
    },
    opts = function()
      vim.fn.sign_define("DapBreakpoint", {
        text = "",
        texthl = "DiagnosticSignError",
      })
    end,
    config = function()
      local dap = require("dap")
      local dapui = require("dapui")

      -- c/cpp
      local function cppdbg_config(program, cwd, name)
        return {
          name = name or "C/C++: Launch",
          type = "cppdbg",
          request = "launch",
          program = program,
          cwd = cwd,
          stopAtEntry = false,
          externalConsole = false,
          MIMode = "gdb",
          miDebuggerPath = vim.fn.exepath("gdb"),
          setupCommands = {
            {
              description = "Enable GDB pretty-printing",
              text = "-enable-pretty-printing",
              ignoreFailures = true,
            },
          },
        }
      end

      local cppdbg_path = vim.fn.stdpath("data") .. "/mason/bin/OpenDebugAD7"
      dap.adapters.cppdbg = {
        id = "cppdbg",
        type = "executable",
        command = cppdbg_path,
      }

      local single_file_args = {}

      local function compiler_for(filetype)
        local candidates = filetype == "c" and { "gcc", "clang" } or { "g++", "clang++" }
        for _, compiler in ipairs(candidates) do
          local path = vim.fn.exepath(compiler)
          if path ~= "" then
            return path
          end
        end
      end

      local function show_compiler_errors(output)
        local lines = vim.split(output, "\n", { trimempty = true })
        vim.fn.setqflist({}, " ", {
          title = "C/C++ single-file build",
          lines = lines,
          efm = vim.o.errorformat,
        })
        vim.cmd("botright copen")
      end

      local function debug_cpp_single_file()
        local filetype = vim.bo.filetype
        if filetype ~= "c" and filetype ~= "cpp" then
          dap.continue()
          return
        end

        local source = vim.api.nvim_buf_get_name(0)
        if source == "" then
          vim.notify("请先保存当前 C/C++ 文件", vim.log.levels.WARN)
          return
        end

        vim.cmd("silent update")

        local compiler = compiler_for(filetype)
        if not compiler then
          vim.notify("找不到 gcc/g++ 或 clang/clang++", vim.log.levels.ERROR)
          return
        end
        if vim.fn.executable(cppdbg_path) ~= 1 then
          vim.notify("找不到 Mason cpptools，请执行 :MasonInstall cpptools", vim.log.levels.ERROR)
          return
        end
        if vim.fn.exepath("gdb") == "" then
          vim.notify("cpptools 需要系统中安装 gdb", vim.log.levels.ERROR)
          return
        end

        local build_dir = vim.fn.stdpath("cache") .. "/cpp-single-file"
        vim.fn.mkdir(build_dir, "p")
        local stem = vim.fn.fnamemodify(source, ":t:r")
        local executable = build_dir .. "/" .. stem .. "-" .. vim.fn.sha256(source):sub(1, 12)

        local command = {
          compiler,
          filetype == "c" and "-std=c17" or "-std=c++20",
          "-g",
          "-O0",
          "-Wall",
          "-Wextra",
          source,
          "-o",
          executable,
        }

        local extra_flags = filetype == "c" and vim.g.c_single_file_flags or vim.g.cpp_single_file_flags
        if type(extra_flags) == "table" then
          vim.list_extend(command, extra_flags)
        end

        vim.notify("正在编译 " .. vim.fn.fnamemodify(source, ":t") .. " ...")
        vim.system(command, { text = true }, function(result)
          vim.schedule(function()
            local output = (result.stdout or "") .. (result.stderr or "")
            if result.code ~= 0 then
              show_compiler_errors(output)
              vim.notify("编译失败，错误已写入 quickfix", vim.log.levels.ERROR)
              return
            end

            if vim.fn.getqflist({ winid = 0 }).winid ~= 0 then
              vim.cmd("cclose")
            end
            dap.run(
              vim.tbl_extend("force", cppdbg_config(executable, vim.fs.dirname(source), "C/C++: 当前单文件"), {
                args = single_file_args,
              })
            )
          end)
        end)
      end

      local function smart_f5()
        if dap.session() then
          dap.continue()
          return
        end

        if vim.bo.filetype == "c" or vim.bo.filetype == "cpp" then
          local cmake_root = vim.fs.root(0, "CMakeLists.txt")
          local cwd = vim.uv.cwd()
          if cmake_root and cwd and vim.fs.normalize(cmake_root) == vim.fs.normalize(cwd) then
            vim.cmd("CMakeDebugCurrentFile")
            return
          end
          debug_cpp_single_file()
          return
        end

        dap.continue()
      end

      local function current_frame_line(session)
        local frame = session and session.current_frame
        local source = frame and frame.source
        if not (frame and source and source.path and frame.line) then
          return
        end

        local current_file = vim.api.nvim_buf_get_name(0)
        if current_file ~= "" and vim.fs.normalize(current_file) == vim.fs.normalize(source.path) then
          return vim.api.nvim_buf_get_lines(0, frame.line - 1, frame.line, false)[1]
        end

        local lines = vim.fn.readfile(source.path, "", frame.line)
        return lines[frame.line]
      end

      local function is_outermost_closing_brace(path, target_line)
        local ok, lines = pcall(vim.fn.readfile, path, "", target_line)
        if not ok then
          return false
        end

        local depth = 0
        local in_block_comment = false
        for line_number, text in ipairs(lines) do
          local index = 1
          local quote
          while index <= #text do
            local char = text:sub(index, index)
            local pair = text:sub(index, index + 1)

            if in_block_comment then
              if pair == "*/" then
                in_block_comment = false
                index = index + 2
              else
                index = index + 1
              end
            elseif quote then
              if char == "\\" then
                index = index + 2
              elseif char == quote then
                quote = nil
                index = index + 1
              else
                index = index + 1
              end
            elseif pair == "//" then
              break
            elseif pair == "/*" then
              in_block_comment = true
              index = index + 2
            elseif char == '"' or char == "'" then
              quote = char
              index = index + 1
            elseif char == "{" then
              depth = depth + 1
              index = index + 1
            elseif char == "}" then
              if line_number == target_line then
                return depth == 1
              end
              depth = math.max(0, depth - 1)
              index = index + 1
            else
              index = index + 1
            end
          end
        end

        return false
      end

      local function smart_step_over()
        local session = dap.session()
        local frame = session and session.current_frame
        local line = current_frame_line(session)
        local frame_is_main = frame and frame.name and (frame.name == "main" or frame.name:match("^main%s*%("))
        local source_line = line and vim.trim((line:gsub("//.*$", "")))

        if
          session
          and session.config.type == "cppdbg"
          and frame_is_main
          and (source_line == "}" or source_line == "};")
          and is_outermost_closing_brace(frame.source.path, frame.line)
        then
          dap.continue()
          return
        end

        dap.step_over()
      end

      local function close_debug_session()
        dapui.close()
        if dap.session() then
          dap.terminate({ all = true, hierarchy = true })
        end
      end

      dapui.setup()
      dap.listeners.after.event_initialized["dapui_config"] = function()
        dapui.open()
      end

      vim.keymap.set("n", "<leader>db", dap.toggle_breakpoint, { desc = "DAP Toggle Breakpoint" })
      vim.keymap.set("n", "<leader>dB", function()
        dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
      end, { desc = "DAP Set Conditional Breakpoint" })

      vim.keymap.set("n", "<F5>", smart_f5, { desc = "Debug / Continue" })
      vim.keymap.set("n", "<F10>", smart_step_over, { desc = "DAP Step Over" })
      vim.keymap.set("n", "<F11>", dap.step_into, { desc = "DAP Step Into" })
      vim.keymap.set("n", "<F12>", dap.step_out, { desc = "DAP Step Out" })
      vim.keymap.set("n", "<leader>dr", dap.repl.open, { desc = "DAP REPL Open" })
      vim.keymap.set("n", "<leader>du", dapui.toggle, { desc = "DAP UI Toggle" })
      vim.keymap.set("n", "<leader>dq", close_debug_session, { desc = "DAP Terminate and Close UI" })
      vim.keymap.set("n", "<leader>da", function()
        vim.ui.input({ prompt = "程序参数: " }, function(input)
          if input ~= nil then
            single_file_args = vim.split(input, "\\s+", { trimempty = true })
          end
        end)
      end, { desc = "Set C/C++ Single-file Args" })

      dap.configurations.c = {
        cppdbg_config(function()
          return vim.fn.input("可执行文件: ", vim.fn.getcwd() .. "/", "file")
        end, "${workspaceFolder}", "C: 选择可执行文件"),
      }
      dap.configurations.cpp = dap.configurations.c

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
