--- Uses the specified annotation convention in template, an will use the default generator
return function(parent, data, template)
    -- Uses emmylua template by default
    if template.annotation_convention == nil then
        template = template["emmylua"]
    end

    -- Uses the template annotation convention specified in config
    template = template[template.annotation_convention]
    if template ~= nil then
        return neogen.default_generator(parent, data, template)
    end
end
