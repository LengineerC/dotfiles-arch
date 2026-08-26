return {
  "saghen/blink.cmp",
  opts = {
    keymap = {
      preset = "default",

      ["<Tab>"] = {
        function(cmp)
          if cmp.is_visible() then
            return cmp.accept()
          end
        end,
        "fallback",
      },
    },
  },
}
