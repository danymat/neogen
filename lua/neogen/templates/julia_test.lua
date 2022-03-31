local i = require("neogen.types.template").item

return {
    { nil, '""" $1 """', { no_results = true, type = { "func" } } },
    { nil, '"""' },
    { nil, '$1' },
    {
        { i.Parameter, i.Type },
        "\t%s::%s: $1",
        { required = "typed_parameters", type = { "func" } },
    },
    {
         i.Parameter,
        "\t%s: $1",
        { required = "parameters", type = { "func" } },
    },

    { nil, '"""' },
}
