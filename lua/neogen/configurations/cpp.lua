local c_config = require("neogen.configurations.c")
local extractors = require("neogen.utilities.extractors")
local nodes_utils = require("neogen.utilities.nodes")
local i = require("neogen.types.template").item

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
                            { retrieve = "first", node_type = "type_identifier", extract = true, as = i.ClassName },
                        }
                        local nodes = nodes_utils:matching_nodes_from(node, tree)
                        local res = extractors:extract_from_matched(nodes)
                        return res
                    end,
                },
            },
        },
    },
}

cpp_config = vim.tbl_deep_extend("force", c_config, cpp_config)

return cpp_config
