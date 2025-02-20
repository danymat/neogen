--- Table of contents:
---@toc
---@text

--- What is Neogen ?
---
--- # Abstract~
---
--- Neogen is an extensible and extremely configurable annotation generator for your favorite languages
---
--- Want to know what the supported languages are ?
--- Check out the up-to-date readme section: https://github.com/danymat/neogen#supported-languages
---
--- # Concept~
---
--- - Create annotations with one keybind, and jump your cursor in the inserted annotation
--- - Defaults for multiple languages and annotation conventions
--- - Extremely customizable and extensible
--- - Written in lua (and uses Tree-sitter)
---@tag neogen
---@toc_entry Neogen's purpose
-- Requires ===================================================================
local neogen = {}

local conf
local config = require("neogen.config")
local helpers = require("neogen.utilities.helpers")
local mark = require("neogen.mark")
local notify = helpers.notify

-- Module definition ==========================================================

--- Module setup
---
---@param opts table Config table (see |neogen.configuration|)
---
---@usage `require('neogen').setup({})` (replace `{}` with your `config` table)
---@toc_entry The setup function
neogen.setup = function(opts)
    conf = config.setup(neogen.configuration, opts)
    if conf.enabled then
        neogen.generate_command()
    end
end

--- Neogen Usage
---
--- Neogen will use Treesitter parsing to properly generate annotations.
---
--- The basic idea is that Neogen will generate annotation to the type you're in.
--- For example, if you have a csharp function like (note the cursor position):
---
--- >
---  public class HelloWorld
---  {
---      public static void Main(string[] args)
---      {
---          # CURSOR HERE
---          Console.WriteLine("Hello world!");
---          return true;
---      }
---
---      public int someMethod(string str, ref int nm, void* ptr) { return 1; }
---
---  }
--- <
---
--- and you call `:Neogen class`, it will generate the annotation for the upper class:
---
--- >
---  /// <summary>
---  /// ...
---  /// </summary>
---  public class HelloWorld
---  {
--- <
---
--- Currently supported types are `func`, `class`, `type`, `file`.
--- Check out the up-to-date readme section: https://github.com/danymat/neogen#supported-languages
--- To know the supported types for a certain language
---
--- NOTE: calling `:Neogen` without any type is the same as `:Neogen func`
---@tag neogen-usage
---@toc_entry Usage

--- # Basic configurations~
---
--- Neogen provides those defaults, and you can change them to suit your needs
---@eval return MiniDoc.afterlines_to_code(MiniDoc.current.eval_section)
---@text # Notes~
---
--- - to configure a language, just add your configurations in the `languages` table.
---   For example, for the `lua` lang:
--- >
---    languages = {
---      lua = { -- Configuration here }
---    }
--- <
---   Default configurations for a languages can be found in `lua/neogen/configurations/<your_language>.lua`
---   To use an existing configuration in another file type, you can do like: `cuda = require("neogen.configurations.cpp")` 
---   for your language.
---
---  - To know which snippet engines are supported, take a look at |neogen-snippet-integration|.
---    Example: `snippet_engine = "luasnip"`
---
---@toc_entry Configure the setup
---@tag neogen-configuration
neogen.configuration = {
    -- Enables Neogen capabilities
    enabled = true,

    -- Go to annotation after insertion, and change to insert mode
    input_after_comment = true,

    -- Configuration for default languages
    languages = {},

    -- Use a snippet engine to generate annotations.
    snippet_engine = nil,

    -- Enables placeholders when inserting annotation
    enable_placeholders = true,

    -- Placeholders used during annotation expansion
    placeholders_text = {
        ["description"] = "[TODO:description]",
        ["tparam"] = "[TODO:tparam]",
        ["parameter"] = "[TODO:parameter]",
        ["return"] = "[TODO:return]",
        ["class"] = "[TODO:class]",
        ["throw"] = "[TODO:throw]",
        ["varargs"] = "[TODO:varargs]",
        ["type"] = "[TODO:type]",
        ["attribute"] = "[TODO:attribute]",
        ["args"] = "[TODO:args]",
        ["kwargs"] = "[TODO:kwargs]",
    },

    -- Placeholders highlights to use. If you don't want custom highlight, pass "None"
    placeholders_hl = "DiagnosticHint",
}
--minidoc_afterlines_end

-- Basic API ===================================================================

--- The only function required to use Neogen.
---
--- It'll try to find the first parent that matches a certain type.
--- For example, if you are inside a function, and called `generate({ type = "func" })`,
--- Neogen will go until the start of the function and start annotating for you.
---
---@param opts? table Optional configs to change default behaviour of generation.
---  - {opts.type} `(string, default: "any")` Which type we are trying to use for generating annotations.
---    Currently supported: `any`, `func`, `class`, `type`, `file`
---  - {opts.annotation_convention} `(table)` convention to use for generating annotations.
---    This is language specific. For example, `generate({ annotation_convention = { python = 'numpydoc' } })`
---    If no convention is specified for a specific language, it'll use the default annotation convention for the language.
---  - {opts.return_snippet} `boolean` if true, will return 3 values from the function call.
---  This option is useful if you want to get the snippet to use with a unsupported snippet engine
---  Below are the returned values:
---  - 1: (type: `string[]`) the resulting lsp snippet
---  - 2: (type: `number`) the `row` to insert the annotations
---  - 3: (type: `number`) the `col` to insert the annotations
---@toc_entry Generate annotations
neogen.generate = function(opts)
    if not conf or not conf.enabled then
        notify("Neogen not enabled. Please enable it.", vim.log.levels.WARN)
        return
    end

    opts = opts or {}
    return require("neogen.generator")(vim.bo.filetype, opts.type, opts.return_snippet, opts.annotation_convention)
end

-- Expose more API  ============================================================

-- Expose match_commands for `:Neogen` completion
neogen.match_commands = helpers.match_commands

--- Get a template for a particular filetype
---@param filetype? string
---@return neogen.TemplateConfig?
---@private
neogen.get_template = function(filetype)
    local template
    local ft_conf = filetype and conf.languages[filetype] or conf.languages[vim.bo.filetype]
    if ft_conf and ft_conf.template then
        template = ft_conf.template
    end
    return template
end

-- Required for use with completion engine =====================================

--- Jumps to the next cursor template position
---@private
function neogen.jump_next()
    mark:jump()
end

--- Jumps to the next cursor template position
---@private
function neogen.jump_prev()
    mark:jump(true)
end

--- Checks if the cursor can jump backwards or forwards
--- @param reverse number? if `-1` or true, will try to see if can be jumped backwards
---@private
function neogen.jumpable(reverse)
    return mark:jumpable(reverse == -1 or reverse == true)
end

-- Command and autocommands ====================================================

--- Generates the `:Neogen` command, which calls `neogen.generate()`
---@private
function neogen.generate_command()
    vim.cmd([[
        command! -nargs=? -complete=customlist,v:lua.require'neogen'.match_commands -range -bar Neogen lua require("neogen").generate({ type = <q-args>})
    ]])
end

--- Contribute to Neogen
---
--- *   Want to add a new language?
---     1.  Using the defaults to generate a new language support:
---         https://github.com/danymat/neogen/blob/main/docs/adding-languages.md
---     2.  (advanced) Only if the defaults aren't enough, please see here:
---         https://github.com/danymat/neogen/blob/main/docs/advanced-integration.md
--- *   Want to contribute to an existing language?
---     I guess you can still read the previous links, as they have some valuable knowledge inside.
---     You can go and directly open/edit the configuration file relative to the language you want to contribute to.
---
--- Feel free to submit a PR, I will be happy to help you !
---@tag neogen-develop
---@toc_entry Contributing

--- We use semantic versioning ! (https://semver.org)
--- Here is the current Neogen version:
---@eval return MiniDoc.afterlines_to_code(MiniDoc.current.eval_section)
---@text # Changelog~
---
--- Note: We will only document `major` and `minor` versions, not `patch` ones. (only X and Y in X.Y.z)
---
--- ## 2.20.0~
---   - Add support for `mini` snippet engine  ! (see |neogen-snippet-integration|)
--- ## 2.19.0~
---   - Add support for julia (`julia`) ! (#185)
--- ## 2.18.0~
---   - Add tests cases to tests/ for annotation generation with basic support for python (#174)
--- ## 2.17.1~
---   - Python raises now supports `raise foo.Bar()` syntax
--- ## 2.17.0~
---   - Python now supports dataclass attributes (#126)
--- ## 2.16.0~
---   - Add support for `nvim` snippet engine (default nvim snippet engine) ! (see |neogen-snippet-integration|)
--- ## 2.15.0~
---   - Google docstrings now include "Yields:", whenever possible
--- ## 2.14.0~
---   - Google docstrings now include "Raises:", whenever possible
--- ## 2.13.0~
---   - Improve google docstrings template (#124)
---   - Fix minor python retriever issues (#124)
--- ## 2.12.0~
---   - Fetch singleton methods in ruby (#121)
--- ## 2.11.0~
---   - Calling `:Neogen` will try to find the best type used to generate annotations (#116)
---     It'll recursively go up the syntax tree from the cursor position.
---     For example, if a function is defined inside class and the cursor is inside the function,
---     the annotation will be generated for the function.
--- ## 2.10.0~
---   - Add support for Throw statements in python
---     Note: only active for reST template as of right now (please open an issue request for more templates)
--- ## 2.9.0~
---   - Add support for `vsnip` snippet engine ! (see |neogen-snippet-integration|)
--- ## 2.8.0~
---   - Specify annotation convention on `generate()` method (see |neogen.generate()|)
--- ## 2.7.0~
---   - Add support for `snippy` snippet engine ! (see |neogen-snippet-integration|)
--- ## 2.6.0~
---   - Add support for placeholders in snippet insertion !
---     None: placeholders are automatically set when using a bundled snippet engine.
---     - Add `enable_placeholders` option (see |neogen-configuration|)
---     - Add `placeholders_text` option (see |neogen-configuration|)
---     - Add `placeholders_hl` option (see |neogen-configuration|)
---
---   Example placeholders:
--- >
---  --- [TODO:description]
---  ---@param param1 [TODO:parameter] [TODO:description]
---  function test(param1) end
--- <
--- ## 2.5.0~
---   - Ruby: Add support for `tomdoc` (http://tomdoc.org)
--- ## 2.4.0~
---   - Improve godoc template (#75)
--- ## 2.3.0~
---   - Added bundled support with snippet engines !
---     Check out |neogen-snippet-integration| for basic setup
--- ## 2.2.0~
---   ### Python~
---     - Add support for `*args` and `**kwargs`
---     - Fix python return annotations being inconsistent in numpydoc template
--- ## 2.1.0~
---   - Add basic support for `kotlin` (`kdoc`).
--- ## 2.0.0~
---   - We made the template API private, only for initial template configuration.
---     If you want to make a change to a template, please see:
---     |neogen-template-configuration| and |neogen-annotation|
--- ## 1.0.0~
---   - Neogen is officially out ! We support 16 languages as of right now,
---     with multiple annotation conventions.
---@tag neogen-changelog
---@toc_entry Changes in neogen plugin
neogen.version = "2.20.0"
--minidoc_afterlines_end

return neogen
