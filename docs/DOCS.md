# Abstract

Neogen is an extensible and extremely configurable annotation generator for your favorite languages

Want to know what the supported languages are ?
Check out the up-to-date readme section: https://github.com/danymat/neogen#supported-languages

# Concept

- Create annotations with one keybind, and jump your cursor in the inserted annotation
- Defaults for multiple languages and annotation conventions
- Extremely customizable and extensible
- Written in lua (and uses Tree-sitter)

# Usage

Neogen will use tree-sitter parsing to properly generate annotations.

The basic idea is that Neogen will generate annotation to the type you're in.
For example, if you have a csharp function like (note the cursor position):

```cs
public class HelloWorld
{
    public static void Main(string[] args)
    {
        # CURSOR HERE
        Console.WriteLine("Hello world!");
        return true;
    }

    public int someMethod(string str, ref int nm, void* ptr) { return 1; }

}
```

and you call `:Neogen class`, it will generate the annotation for the upper class:

```cs
/// <summary>
/// ...
/// </summary>
public class HelloWorld
{
```

Currently supported types are `func`, `class`, `type`, `file`.
Check out the up-to-date readme section: https://github.com/danymat/neogen#supported-languages
To know the supported types for a certain language

NOTE: calling `:Neogen` without any type is the same as `:Neogen func`

# Basic configurations

Every configuration here is to put inside your `require('neogen').setup {...}` table.

- `enabled` (defaults: `false`)
  Enable Neogen.

- `input_after_comment` (defaults: `true`)
  Go to annotation after insertion, and change to insert mode

# Advanced configurations

To customize a language, you can provide a custom table like this:
The defaults are provided here: https://github.com/danymat/neogen/tree/main/lua/neogen/configurations

```lua
require('neogen').setup {
    languages = {
        csharp = {
            -- Configuration here
        }
    }
}
```

- `template.annotation_convention` (default: check the language default configurations)
  Change the annotation convention to use with the language.
- `template.use_default_comment` (default: `true`)
  Prepend any template line with the default comment for the filetype
- `template.position` (`fun(node: userdata, type: string):(number,number)?`)
  Provide an absolute position for the annotation.
  If return values are `nil`, use default position
- `template.append`
  If you want to customize the position of the annotation
- `template.append.child_name`
  What child node to use for appending the annotation
- `template.append.position` (`before/after`)
  Relative positioning with `child_name`
- `template.<convention_name>` (replace `<convention_name>` with an annotation convention)
  Template for an annotation convention.
  To know more about how to create your own template, go here:
  https://github.com/danymat/neogen/blob/main/docs/adding-languages.md#default-generator

For example, changing the default annotation convention is as simple as this:

```lua
require('neogen').setup {
    languages = {
        csharp = {
            template = { annotation_convention = "..." }
        }
    }
}
```

# Develop

- Want to add a new language?

  1. Using the defaults to generate a new language support:
     https://github.com/danymat/neogen/blob/main/docs/adding-languages.md
  2. (advanced) Only if the defaults aren't enough, please see here:
     https://github.com/danymat/neogen/blob/main/docs/advanced-integration.md

- Want to contribute to an existing language?
  I guess you can still read the previous links, as they have some valuable knowledge inside.
  You can go and directly open/edit the configuration file relative to the language you want to contribute to.

  Feel free to submit a PR, I will be happy to help you !

## Developer API

TODO: update doc

# FAQ

Seems too calm here...
