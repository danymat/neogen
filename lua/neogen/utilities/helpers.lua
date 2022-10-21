local config = require("neogen.config")
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

        local language = config.get().languages[vim.bo.filetype]

        if not language or not language.parent then
            return {}
        end

        return vim.tbl_keys(language.parent)
    end,

    split = function(s, sep, plain)
        return vim.fn.has("nvim-0.6") == 1 and vim.split(s, sep, { plain = plain }) or vim.split(s, sep, plain)
    end,

    --- Gets the text from the node
    ---@private
    ---@param node userdata node to fetch text from
    ---@param bufnr? number originated buffer number. Defaults to 0
    ---@return table newline separated list of text
    get_node_text = function(node, bufnr)
        return vim.split(vim.treesitter.query.get_node_text(node, bufnr or 0), "\n")
    end,

    --- Copies a table to another table depending of the parameters that we want to expose
    ---TODO: create a doc for the table structure
    ---@param rules table the rules that we want to execute
    ---@param table table the table to copy
    ---@return table?
    ---@private
    copy = function(rules, table)
        local copy = {}

        for parameter, rule in pairs(rules) do
            local parameter_value = table[parameter]

            if parameter_value then
                if type(rule) == "function" then
                    copy[parameter] = vim.tbl_deep_extend("error", rule(table), copy[parameter] or {})
                elseif rule == true and parameter_value ~= nil then
                    copy[parameter] = parameter_value
                else
                    vim.notify("Incorrect rule format for parameter " .. parameter, vim.log.levels.ERROR)
                    return
                end
            end
        end

        return copy
    end,
}
