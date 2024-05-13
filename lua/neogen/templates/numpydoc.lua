local i = require("neogen.types.template").item

return {
    { nil, '"""$1"""', { no_results = true, type = { "class", "func" } } },
    { nil, '"""$1', { no_results = true, type = { "file" } } },
    { nil, "", { no_results = true, type = { "file" } } },
    { nil, "$1", { no_results = true, type = { "file" } } },
    { nil, '"""', { no_results = true, type = { "file" } } },
    { nil, "", { no_results = true, type = { "file" } } },

    { nil, "# $1", { no_results = true, type = { "type" } } },

    { nil, '"""$1' },
    { i.HasParameter, "", { type = { "func" } } },
    { i.HasParameter, "Parameters", { type = { "func" } } },
    { i.HasParameter, "----------", { type = { "func" } } },
    {
        i.Parameter,
        "%s : $1",
        { after_each = "    $1", type = { "func" } },
    },
    {
        { i.Parameter, i.Type },
        "%s : %s",
        { after_each = "    $1", required = i.Tparam, type = { "func" } },
    },
    {
        i.ArbitraryArgs,
        "%s",
        { after_each = "    $1", type = { "func" } },
    },
    {
        i.Kwargs,
        "%s",
        { after_each = "    $1", type = { "func" } },
    },
    { i.ClassAttribute, "%s : $1", { before_first_item = { "", "Attributes", "----------" } } },
    { i.HasReturn, "", { type = { "func" } } },
    { i.HasReturn, "Returns", { type = { "func" } } },
    { i.HasReturn, "-------", { type = { "func" } } },
    {
        i.ReturnTypeHint,
        "%s",
        { after_each = "    $1" },
    },
    {
        i.Return,
        "$1",
        { after_each = "    $1" },
    },
    { nil, "" },
    { nil, '"""' },
}
