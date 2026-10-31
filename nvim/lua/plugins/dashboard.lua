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
                dashboard.button("f", "Find file", ":Telescope find_files<CR>"),
                dashboard.button("g", "Find text", ":Telescope live_grep<CR>"),
                dashboard.button("q", "Quit", ":qa<CR>"),
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
