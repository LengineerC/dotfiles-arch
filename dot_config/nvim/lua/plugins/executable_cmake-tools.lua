return {
  {
    "Civitasv/cmake-tools.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "mfussenegger/nvim-dap",
    },
    cmd = {
      "CMakeGenerate",
      "CMakeBuild",
      "CMakeRun",
      "CMakeDebug",
      "CMakeDebugCurrentFile",
      "CMakeSelectLaunchTarget",
      "CMakeSelectBuildType",
      "CMakeSelectKit",
      "CMakeLaunchArgs",
      "CMakeSelectCwd",
    },
    keys = {
      { "<leader>mg", "<cmd>CMakeGenerate<cr>", desc = "CMake Configure" },
      { "<leader>mb", "<cmd>CMakeBuild<cr>", desc = "CMake Build" },
      { "<leader>mr", "<cmd>CMakeRun<cr>", desc = "CMake Run" },
      { "<leader>md", "<cmd>CMakeDebug<cr>", desc = "CMake Debug" },
      { "<leader>mt", "<cmd>CMakeSelectLaunchTarget<cr>", desc = "CMake Select Target" },
      { "<leader>mv", "<cmd>CMakeSelectBuildType<cr>", desc = "CMake Select Build Type" },
      { "<leader>mk", "<cmd>CMakeSelectKit<cr>", desc = "CMake Select Kit" },
      { "<leader>ma", "<cmd>CMakeLaunchArgs<cr>", desc = "CMake Launch Args" },
      { "<leader>ms", "<cmd>CMakeSelectCwd<cr>", desc = "CMake Select Source Directory" },
      { "<F6>", "<cmd>CMakeBuild<cr>", desc = "CMake Build" },
      { "<F7>", "<cmd>CMakeRun<cr>", desc = "CMake Run" },
    },
    config = function()
      require("cmake-tools").setup({
        cmake_use_preset = true,
        cmake_regenerate_on_save = true,
        cmake_generate_options = { "-DCMAKE_EXPORT_COMPILE_COMMANDS=1" },
        cmake_build_directory = "build/${variant:buildType}",
        cmake_compile_commands_options = {
          action = "soft_link",
          target = vim.uv.cwd,
        },
        cmake_dap_configuration = {
          name = "CMake target",
          type = "cppdbg",
          request = "launch",
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
        },
        cmake_executor = {
          name = "quickfix",
          opts = {
            show = "only_on_error",
            position = "belowright",
            size = 12,
            auto_close_when_success = true,
          },
        },
        cmake_runner = {
          name = "terminal",
          opts = {
            name = "CMake Run",
            prefix_name = "[CMake] ",
            split_direction = "horizontal",
            split_size = 12,
            single_terminal_per_instance = true,
            single_terminal_per_tab = true,
            keep_terminal_static_location = true,
            start_insert = false,
          },
        },
      })
    end,
  },
}
