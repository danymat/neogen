local ts_utils = require("nvim-treesitter.ts_utils")

neogen.utility = {
    --- Return a function to extract content of required children from a node
    --- @param _ any self
    --- @param name string the children we want to extract (if multiple childrens, separate each one with "|")
    --- @return function cb function taking a node and getting the content of each children we want from name
    extract_children = function(_, name)
        return function(node)
            local result = {}
            local split = vim.split(name, "|", true)

            for child in node:iter_children() do
                if vim.tbl_contains(split, child:type()) then
                    table.insert(result, ts_utils.get_node_text(child)[1])
                end
            end

            return result
        end
    end,

    --- Extract content from specified children from a set of nodes
    --- the nodes parameter can be a nested { [key] = value} with key being the 
    --- * key: is which children we want to extract the values from (e.g first children is 1)
    --- * value: "extract" or { [key] = value }. If value is "extract", it will extract the key child node
    --- Example (extract the first child node from the first child node of the parent node):
    --- [1] = {
    ---  [1] = "extract"
    --- }
    --- @param name string the children we want to extract (if multiple children, separate each one with "|")
    --- @param nodes table see description
    extract_children_from = function(self, name, nodes)
        return function(node)
            local result = {}

            for i, value in ipairs(nodes) do
                local child_node = node:named_child(i - 1)

                if value == "extract" then
                    return self:extract_children(name)(child_node)
                else
                    return self:extract_children_from(name, value)(node)
                end
            end

            return result
        end
    end,
}
