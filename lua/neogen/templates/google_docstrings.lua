local i = require("neogen.types.template").item

return {
    { nil, '""" $1 """', { no_results = true, type = { "class", "func" } } },
    { nil, '"""$1', { no_results = true, type = { "file" } } },
    { nil, "", { no_results = true, type = { "file" } } },
    { nil, "$1", { no_results = true, type = { "file" } } },
    { nil, '"""', { no_results = true, type = { "file" } } },
    { nil, "", { no_results = true, type = { "file" } } },

    { nil, "# $1", { no_results = true, type = { "type" } } },

    { nil, '"""$1' },
    { i.HasParameter, "", { type = { "func" } } },
    { i.HasParameter, "Args:", { type = { "func" } } },
    { i.Parameter, "    %s ($1): $1", { type = { "func" } } },
    { { i.Parameter, i.Type }, "    %s (%s): $1", { required = "typed_parameters", type = { "func" } } },
    { i.ArbitraryArgs, "    %s: $1", { type = { "func" } } },
    { i.Kwargs, "    %s: $1", { type = { "func" } } },
    { i.ClassAttribute, "    %s: $1", { before_first_item = { "", "Attributes: " } } },
    { i.HasReturn, "", { type = { "func" } } },
    { i.HasReturn, "Returns:", { type = { "func" } } },
    { i.HasReturn, "    $1", { type = { "func" } } },
    { nil, '"""' },
}
