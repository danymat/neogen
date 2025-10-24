local template = require("neogen.template")

local function noop(_)
    return {}
end

return {
    -- Search for these nodes
    parent = {
        func = { "function_declaration" },
        type = { "variable_declaration", "container_field" },
        file = { "source_file" },
        container = { "struct_declaration" },
    },

    data = {
        func = {
            -- When the function is in the root tree
            ["function_declaration"] = {
                ["0"] = {
                    extract = noop,
                },
            },
        },
        type = {
            ["variable_declaration|container_field"] = {
                ["0"] = {
                    extract = noop,
                },
            },
        },
        file = {
            ["source_file"] = {
                ["0"] = {
                    extract = function() return { _ } end,
                },
            },
        },
        container = {
            ["struct_declaration"] = {
                ["0"] = {
                    extract = function() return { _ } end,
                },
            },
        },
    },

  template = template:config({
      use_default_comment = true,

      append = {
          position = "after",
          disabled = { "func", "type", "file", },
      }
  }):add_default_annotation("zig"),
}
