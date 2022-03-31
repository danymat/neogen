local i = require("neogen.types.template").item

return {
    { nil, '""" $1 """', { no_results = true, type = { "func" } } },
    { nil, '"""' },
    { nil, 'Overview:' },
    { nil, '\t$1' },
    { nil, 'Where:' },
    {
        { i.Parameter, i.Type },
        "\t%s::%s is $1",
        { required = "typed_parameters", type = { "func" } },
    },
    {
         i.Parameter,
        "\t%s is $1",
        { required = "parameters", type = { "func" } },
    },

    { nil, '"""' },
}
