local ts_utils = require("nvim-treesitter.ts_utils")

neogen.utilities.extractors = {
    --- Extract the content from each node from data
    --- @param _ any self
    --- @param data table a list of k,v values where k is the node_type and v a table of nodes
    --- @return any result the same table as data but with node texts instead
    extract_from_matched = function(_, data)
        local result = {}
        for k, v in pairs(data) do
            local get_text = function(node)
                return ts_utils.get_node_text(node)[1]
            end
            result[k] = vim.tbl_map(get_text, v)
        end
        return result
    end,
}
