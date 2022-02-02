local config = {_data = {}}

config.get = function()
    return config._data
end

config.setup = function(default, user)
    local data = vim.tbl_deep_extend("keep", user or {}, default)
    setmetatable(data.languages, {
        __index = function(langs, ft)
            local ok, ft_config = pcall(require, "neogen.configurations." .. ft)
            if not ok then
                ft_config = nil
            end
            rawset(langs, ft, ft_config)
            return ft_config
        end
    })
    config._data = data
    return data
end

return config
