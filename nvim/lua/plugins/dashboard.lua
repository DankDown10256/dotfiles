return {
    {
        "goolord/alpha-nvim",
        dependencies = {
            "nvim-tree/nvim-web-devicons",
        },
        config = function()
            local alpha = require("alpha")
            local dashboard = require("alpha.themes.dashboard")
            
           dashboard.section.header.val = {
            "  ⡑⡁     ⠁            ⡀⡀⡀⡀⡀⣀⣀⡀",
            " ⠁⠁⠁      ⣴⣴⡄     ⣀⣀⣴⣿⣿⣿⣿⣿⣿⣿⣷⣷⣄⡀",
            "   ⣴⣴⡄    ⠙⠟⠗  ⢀⣴⣴⣿⣿⣿⣿⣟⡿⡟⠛⠙⠙⠛⠟⣿⣿⣿⣿⣷⡄",
            "   ⠙⠛⠁        ⣴⣿⣿⣿⣟⡟⠙⠛⠟⡗⠁  ⡄   ⠙⡟⡝⠙⣿⣷⡄",
            "           ⣕⣵⣿⣿⣟⡟⠛⠛⠁        ⠁   ⠑⠕⣕⣵⣝⡕",
            "         ⣴⣿⣿⣿⡟⠟⠟⠁⠁⠁             ⠁⡑⠙⠙⠟⣿⣷⡄",
            "        ⣀⣿⣿⡟⠁⠁                   ⠁  ⠁⠙⣿⣷⡄",
            "     ⠁⠁⢑⣿⣿⣿⡁                          ⠁⠙⠁",
            "       ⢹⣿⣿⣿⡅⡕⠁ ⣴⠁                   ⠁⠑⠁",
            "       ⠁⣽⣿⣿⣿⡇⡀ ⠁                        ⠑⡕⡀",
            "      ⢀⣿⣟⣝⡝⣿⣿⣷⡄⣄⡄                        ⠝⡕⡁",
            "⠁     ⣹⣿⣿⣿⡅⣽⣿⣿⣿⣿⡟⡕⠁⠁⠁⠁⠁⡁⡀      ⣀⡄      ⠁ ⠐⣿⣷⡅       ⣀⡀",
            "⠁     ⠁⠙⠙⠉⠁⠙⣿⣿⣟⡟⠁⠁  ⠁⡁⡕⡕⡁    ⠁⣕⣟⠟⠁        ⠙⣿⣷⣅⡀     ⠙⠁",
            "⠁⠁⠁⠁        ⠉⠙⣿⡅⡀⡀⡁ ⡑⡕⡕⠑⠁⠁    ⠉⠁      ⠁    ⠙⡿⣿⡗⠅",
            "⠁⠁⠁⠁⠁        ⠐⣿⡕⡕⡑⡁⡑⡕⡁⠁⠁⠁⡁⡁⠁⠁⠁ ⡑⠁         ⡅⠁⡑⠁⠁⠁⠁⠁⠁⠁",
            "⠁⠁⠁⠁⠁⠁⠁⠁⠁⠁⠁⠁⠁⣑⣿⡗⡁⠁⠁⡑⡕⡁⡁⡁⡁⠁⡑⡑⠁⠁ ⠐⡕⡁       ⡑⡕⡅⡑⡁⠁⡁⡁⡁⡁⠁⠁⠁",
            "⠁⠁⠁⠁⠁⠁⠁⠁⠁⠁⠁⠁⠁⠙⠟⠁⣵⣕⡕⡑⠑⡑⡑⡁⡑⡑⠑⠁⠁  ⡑⡕⡁⠁ ⠁⠁   ⡅⠁⠑⠑⡕⣕⡕⣕⣕⡕⡁⡁⡁",
            "⠁⠁⠁⠁⠁⠁⠁⠁⠁⠁⠁⠁⠁⡁⠁⡁⠙⣿⣷⡅⠁⡁⠁⠁⠁⠁⠁⠁   ⣕⣕⡅⠁  ⠁⡁⡁⡁⠁   ⠁⠁⠁⠁⠙⠙⠑⠙⡿",
            "⣕⡅⡁⡁⡁⡁⠁⠁⠁⡁⡁⠁⠁⠁⠁⠁⡁⡙⡟⣵⣵⣕⡁⠁⠁⠁⢀⣀⡀⡐⡕⣝⣟⡕⠁  ⡁⡁⠁⠁",
            "⡟⡕⡕⡕⡑⡁⡁⡁⡕⣕⡕⣅⣅⣅⡅⣕⣿⣿⡟⠟⠟⠟⠁   ⠈⠛⠟⡕⡑⣝⣟⡅  ⠁⠁⠁",
            "⡑⣝⣝⣕⣕⣕⣕⡕⡝⠙⠁⠙⠙⠁⠁⠉⠉⠁           ⠁⠙⣝⣟⡅",
            "⣕⣿⣿⣿⡟⠉⠁⠁⠁                      ⠁⠉⠁",
            "⡿⡟⠛⠉⠁⠁",
           } 

            dashboard.section.buttons.val = {
                dashboard.button(
                    "p",
                    "  Open Project",
                    ":lua require('workspace').open()<CR>"
                ),
                dashboard.button("f", "  Find Files", ":lua Snacks.picker.files({ cwd = vim.fn.getcwd() })<CR>"),
                dashboard.button("e", "  Explorer", ":lua Snacks.explorer({ cwd = vim.fn.getcwd() })<CR>"),
                dashboard.button("q", "  Quit", ":qa<CR>"),
            }
            
            local date = os.date("%A")
            dashboard.section.footer.val = string.format("Hi, today is %s", date)
            local graph, highlights = require("github_graph").get()

            dashboard.section.footer.val = graph
            dashboard.section.footer.opts.hl = highlights

            alpha.setup(dashboard.config)
        end,
    },
}
