return {
    { nil, " $1", { no_results = true } },
    { "func_name", " %s $1", { type = { "func" } } },
    { "type_name", " %s $1", { type = { "type" } } },
    { "package_name", " Package %s $1", { type = { "file" } } },
}
