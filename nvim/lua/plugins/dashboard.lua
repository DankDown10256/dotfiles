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
            
           local date = os.date("%A")
           dashboard.section.footer.val = string.format("It's %s, code well !", date)

            dashboard.section.buttons.val = {
                dashboard.button("p", "  Open Project", ":lua require('workspace').open()<CR>"),
                dashboard.button("n", "  New Project", ":lua require('workspace').create()<CR>"),
                dashboard.button("f", "  Find Files", ":lua Snacks.picker.files({ cwd = vim.fn.getcwd() })<CR>"),
                dashboard.button("e", "  Explorer", ":lua Snacks.explorer({ cwd = vim.fn.getcwd() })<CR>"),
                dashboard.button("c", "  Config", ":lua vim.cmd('cd ' .. vim.fn.fnameescape(vim.fn.stdpath('config'))); Snacks.explorer({ cwd = vim.fn.getcwd() })<CR>"),
                dashboard.button("q", "  Quit", ":qa<CR>"),
            }

            alpha.setup(dashboard.config)
        end,
    },
}
