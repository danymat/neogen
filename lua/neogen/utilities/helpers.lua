return {
    notify = function(msg, log_level)
        vim.notify(msg, log_level, { title = "Neogen" })
    end,

    --- Generates a list of possible types in the current language
    ---@private
    match_commands = function()
        if vim.bo.filetype == "" then
            return {}
        end

        local language = neogen.configuration.languages[vim.bo.filetype]

        if not language or not language.parent then
            return {}
        end

        return vim.tbl_keys(language.parent)
    end,

    switch_language = function()
        local filetype = vim.bo.filetype
        local ok, ft_configuration = pcall(require, "neogen.configurations." .. filetype)

        if not ok then
            return
        end

        neogen.configuration.languages[filetype] = vim.tbl_deep_extend(
            "keep",
            neogen.user_configuration.languages and neogen.user_configuration.languages[filetype] or {},
            ft_configuration
        )
    end,
}
