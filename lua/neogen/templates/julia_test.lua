local i = require("neogen.types.template").item

return {
    { nil, '""" $1 """', { no_results = true, type = { "func" } } },
    { nil, '"""$1' },
    {
        { i.Parameter, i.Type },
        "\t%s::%s,",
        { required = "typed_parameters", type = { "func" } },
    },
    {
         i.Parameter,
        "\t%s,",
        { required = "parameters", type = { "func" } },
    },

    { nil, '"""' },
}
