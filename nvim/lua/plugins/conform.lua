return {
    {
        'stevearc/conform.nvim',
        opts = {},
        format_on_save = nil,
        vim.api.nvim_create_user_command("Format", function()
        
        require("conform").format({
        async = true,
        lsp_format = "fallback",
        })
        end, { desc = "Format current file" })
    }
}
