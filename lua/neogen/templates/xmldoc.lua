local i = require("neogen.types.template").item

return {
    { nil, "/// <summary>", { no_results = true } },
    { nil, "/// $1", { no_results = true } },
    { nil, "/// </summary>", { no_results = true } },

    { nil, "/// <summary>", {} },
    { nil, "/// $1", {} },
    { nil, "/// </summary>", {} },
    { i.Parameter, '/// <param name="%s">$1</param>', { type = { "func", "type" } } },
    { i.Tparam, '/// <typeparam name="%s">$1</typeparam>', { type = { "func", "class" } } },
    { i.Return, "/// <returns>$1</returns>", { type = { "func", "type" } } },
}
