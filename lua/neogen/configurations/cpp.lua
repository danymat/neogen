local c_config = require("neogen.configurations.c")
local extractors = require("neogen.utilities.extractors")
local nodes_utils = require("neogen.utilities.nodes")

local cpp_config = {
    parent = {
        class = { "class_specifier", "struct_specifier" },
    },
    data = {
        class = {
            ["class_specifier|struct_specifier"] = {
                ["0"] = {
                    extract = function(node)
                        local tree = {
                            { retrieve = "first", node_type = "type_identifier", extract = true },
                        }
                        local nodes = nodes_utils:matching_nodes_from(node, tree)
                        local res = extractors:extract_from_matched(nodes)
                        return res
                    end,
                },
            },
        },
    },
    template = {

        doxygen = {
            { nil, "/**", { no_results = true, type = { "func", "file", "class" } } },
            { nil, " * @file", { no_results = true, type = { "file" } } },
            { nil, " * @brief $1", { no_results = true, type = { "func", "file", "class" } } },
            { nil, " */", { no_results = true, type = { "func", "file", "class" } } },
            { nil, "", { no_results = true, type = { "file" } } },

            { nil, "/**", { type = { "func", "class" } } },
            { "type_identifier", " * @class %s", { type = { "class" } } },
            { nil, " * @brief $1", { type = { "func", "class" } } },
            { nil, " *", { type = { "func", "class" } } },
            { "tparam", " * @tparam %s $1" },
            { "parameters", " * @param %s $1" },
            { "return_statement", " * @return $1" },
            { nil, " */", { type = { "func", "class" } } },
        },
    },
}

cpp_config = vim.tbl_deep_extend("force", c_config, cpp_config)

return cpp_config
