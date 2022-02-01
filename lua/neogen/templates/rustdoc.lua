return {
    { nil, "! $1", { no_results = true, type = { "file" } } },
    { nil, "", { no_results = true, type = { "file" } } },

    { nil, "/ $1", { no_results = true, type = { "func", "class" } } },
    { nil, "/ $1", { type = { "func", "class" } } },
}
