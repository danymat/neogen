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

    ---@param s string
    ---@param sep string
    ---@param plain boolean
    ---@return string[]
    split = function(s, sep, plain)
        return vim.fn.has("nvim-0.6") == 1 and vim.split(s, sep, { plain = plain }) or vim.split(s, sep, plain)
    end,

    --- Gets the text from the node
    ---@private
    ---@param node TSNode node to fetch text from
    ---@param bufnr? number originated buffer number. Defaults to 0
    ---@return table newline separated list of text
    get_node_text = function(node, bufnr)
        return vim.split(
            vim.treesitter.get_node_text and vim.treesitter.get_node_text(node, bufnr or 0)
                or vim.treesitter.query.get_node_text(node, bufnr or 0),
            "\n"
        )
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
            if type(rule) == "function" then
                copy[parameter] = rule(table)
            elseif rule == true then
                copy[parameter] = table[parameter]
            else
                vim.notify("Incorrect rule format for parameter " .. parameter, vim.log.levels.ERROR)
                return
            end
        end

        return copy
    end,
}
