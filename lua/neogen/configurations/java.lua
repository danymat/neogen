return {
    parent = {
        class = { "class_declaration" },
    },

    data = {
        class = {
            ["class_declaration"] = {
                ["0"] = {
                    extract = function(node)
                        local results = {}
                        local tree = { { retrieve = "all", node_type = "identifier", extract = true } }
                        local nodes = neogen.utilities.nodes:matching_nodes_from(node, tree)
                        local res = neogen.utilities.extractors:extract_from_matched(nodes)

                        results.class_name = res.identifier
                        return results
                    end,
                },
            },
        },
    },

    template = {
        annotation_convention = "javadoc",
        use_default_comment = false,

        javadoc = {
            { nil, "/**" },
            { "class_name", " * %s $1"},
            { nil, " */" },
        },
    },
}
