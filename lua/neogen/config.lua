local config = { _data = {} }

config.get = function()
    return config._data
end

config.setup = function(default, user)
    local data = vim.tbl_deep_extend("keep", user or {}, default)
    -- fetch configs if users have configuration
    for ft, conf in pairs(data.languages) do
        local ok, ft_config = pcall(require, "neogen.configurations." .. ft)
        if ok then
            data.languages[ft] = vim.tbl_deep_extend("keep", conf, ft_config)
        end
    end

    setmetatable(data.languages, {
        __index = function(langs, ft)
            local ok, ft_config = pcall(require, "neogen.configurations." .. ft)
            if not ok then
                ft_config = nil
            end
            rawset(langs, ft, ft_config)
            return ft_config
        end,
    })
    config._data = data
    return data
end

return config
