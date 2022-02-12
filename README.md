# Smart Pairs

`smart-pairs` is written in lua and provides pairs completion, deletion and jump.

One line to setup the plugin with `packer.nvim`

```lua
use {'ZhiyuanLck/smart-pairs', event="InsertEnter", config=function() require('pairs'):setup() end}
```

***Note***: This plugin is still in develop, so most behaviors are set by default. You can request the feature of
options that can control the default behaviors.

***Note***: Only support bracket of single char.

***Note***: Lines in the examples below represent for the *whole line* not the part of line.

***Note***: Unfortunately, the plugin cannot take every corner case into consideration and take care of the taste of all
people. When the behavior of the plugin is not what you want and cannot be configured, just type the bracket with the
prefix `<c-v>` to avoid the mapping, such as `<c-v>(` to get a original `(` bracket.

## Configuration

Setup the options by

```
require('pairs'):setup(opts)
```

Default options are

```lua
local default_opts = {
  pairs = {
    ['*'] = {
      {'(', ')'},
      {'[', ']'},
      {'{', '}'},
      {"'", "'"},
      {'"', '"'},
    },
    lua = {
      {'(', ')', {ignore = {'%(', '%)', '\\(', '\\)', '%%'}}},
      {'[', ']', {ignore = {'%[', '%]', '\\[', '\\]', '%%'}}},
      {'{', '}', {ignore = {'%{', '%}', '\\{', '\\}', '%%'}}},
    },
    python = {
      {"'", "'", {triplet = true}},
      {'"', '"', {triplet = true}},
    },
    markdown = {
      {'`', '`', {triplet = true}},
    }
  },
  default_opts = {
    ['*'] = {
      ignore_pre = '\\\\', -- double backslash or [[\\]]
      ignore_after = '\\w', -- double backslash or [[\w]]
    },
    lua = {
      ignore_pre = '[%\\\\]' -- double backslash
    }
  },
  delete = {
    enable_mapping = true,
    enable_cond = true,
    enable_fallback = fb.delete,
    empty_line = {
      enable_cond      = true,
      enable_fallback  = fb.delete,
      enable_start     = true,
      enable_bracket   = true,
      enable_multiline = true,
      enable_oneline   = true,
      trigger_indent_level = {
        text = 0,
        bracket = 1,
      }
    },
    current_line = {
      enable_cond = true,
      enable_fallback  = fb.delete,
    }
  },
  space = {
    enable_mapping = true,
    enable_cond = true,
    enable_fallback = fb.space,
  },
  enter = {
    enable_mapping = true,
    enable_cond = true,
    enable_fallback = fb.enter,
  },
}
```

### Options

**`pairs`**: pairs table specified by `filetype = pairs list`. Use `['*'] = ...` to represent for
global pairs and options.

A `pair` is specified by `{ left, right, opts (optional) }`

#### pair options

**`ignore_pre`**: vim regex pattern, brackets after the pattern keep its original meaning.

**`ignore_after`**: vim regex pattern, only for unbalanced brackets, right bracket will never be
completed when left bracket is typeset before the pattern except the right bracket.

**`ignore`**: string or string list, these patterns will be removed before the current line is
parsed to make strategies.

**`triplet`**: boolean, only for balanced brackets, expand the triplet brackets, default false.

**`cross_line`**: boolean, whether the bracket can cross lines, default true for unbalanced pairs
and false for balanced pairs.

#### global options

**`default_opts`**: global default values of pair options. The default values are

```lua
  default_opts = {
    ['*'] = {
      ignore_pre = '\\\\', -- double backslash or [[\\]]
      ignore_after = '\\w', -- double backslash or [[\w]]
    },
    lua = {
      ignore_pre = '[%\\\\]' -- double backslash
    }
  },
```

**`space.enable_mapping`**: boolean or function, map `<space>` to enable smart space, if set to
`false`, `<space>` will not be mapped, default `true`.

**`space.enable_cond`**: boolean or function, condition to enable smart space, default `true`.

**`space.enable_fallback`**: function, if `space.enable_cond` is evaluated to `false`, then the
fallback function will be called, default `require('pairs.utils').space`.

**`space.before_hook`**: hook function which is called before smart space is triggered.

**`space.after_hook`**: hook function which is called after smart space is triggered.

**`enter.enable_mapping`**: boolean or function, map `<cr>` to enable smart enter, if set to
`false`, `<cr>` will not be mapped, default `true`.

**`enter.enable_cond`**: boolean or function, condition to enable smart enter, default `true`.

**`enter.enable_fallback`**: function, if `enter.enable_cond` is evaluated to `false`, then the
fallback function will be called, default `require('pairs.utils').enter`.

**`enter.before_hook`**: hook function which is called before smart enter is triggered.

**`enter.after_hook`**: hook function which is called after smart enter is triggered.

**`delete.enable_mapping`**: boolean or function, map `<bs>` to enable smart deletion, if set to
`false`, `<bs>` will not be mapped, default `true`.

**`delete.enable_cond`**: boolean or function, condition to enable smart deletion, default `true`.

**`delete.enable_fallback`**: function, if `delete.enable_cond` is evaluated to `false`, then the
fallback function will be called, default `require('pairs.utils').delete`.

**`delete.before_hook`**: hook function which is called before smart deletion is triggered.

**`delete.after_hook`**: hook function which is called after smart deletion is triggered.

**`delete.empty_line.enable_cond`**: boolean or function, condition to enable smart deletion of
empty lines, default `true`.

**`delete.empty_line.enable_fallback`**: function, if `delete.empty_line.enable_cond` is evaluated
to `false`, then the fallback function will be called, default `require('pairs.utils').delete`.

**`delete.empty_line.enable_start`**: enable smart deletion of empty lines at start of file, default
`true`.

**`delete.empty_line.enable_bracket`**: enable smart deletion of blanks between brackets, default
`true`.

**`delete.empty_line.enable_multiline`**: enable smart deletion of multiple empty lines, default
`true`.

**`delete.empty_line.enable_oneline`**: enable smart deletion of one empty line, default `true`.

**`delete.empty_line.trigger_indent_level.text`**: smart deletion is triggered only when the
relative indent level is less than the option value where the first nonempty line ***is not*** ended
with a left bracket that can cross lines and/or spaces, default `0`.

**`delete.empty_line.trigger_indent_level.bracket`**: smart deletion is triggered only when the
relative indent level is less than the option value where the first nonempty line is ended with a
left bracket that can cross lines and/or spaces, default `1`.

**`delete.current_line.enable_cond`**: boolean or function, condition to enable smart deletion in
current line, default `true`.

**`delete.current_line.enable_fallback`**: function, if `delete.current_line.enable_cond` is
evaluated to `false`, then the fallback function will be called, default `require('pairs.utils').delete`.

## Work with Other Plugin

Integrate smart enter and smart bracket with `nvim-cmp`:
[workaround](https://github.com/ZhiyuanLck/smart-pairs/issues/2#issuecomment-1037232219)

## Features

### Typeset Unbalanced Pairs

Typeset left bracket

```
press (
|    --> (|)
|)   --> (|)
|a   --> (|a
|()) --> (|())
\|   --> \(|
\\|  --> \\(|)
'%|' --> '%(' in lua
```

Typeset right bracket

```
press )
|       --> |)
(|      --> (|)
(|)     --> ()|
(a|b)   --> (ab)|
|(ab)   --> |)(ab)
|(ab))  --> (ab)|)
('\(|') --> ('\(')|
('%(|') --> ('%(')| in lua
```

### Typeset Balanced Pairs

```
press "
|     --> "|"
"ab|  --> "ab|"
"a|b" --> "a"|"b"
"ab|" --> "ab"|
""|   --> """|""" in python
```

### Smart Space

```
press <space>
{|} --> {␣|␣}
```

### Smart Deletion

#### Delete in curren line

```
press <bs>
{|}     --> |
{{|}    --> {|}
{|}}    --> |}
{␣|␣}   --> {}
{␣|␣␣}  --> {␣|␣}
{␣␣|␣}  --> {␣|␣}
{␣␣|}   --> {|}
{␣␣|ab  --> {|ab
{␣␣|␣ab --> {|ab
{|␣␣␣ab --> |␣ab
```

#### Delete empty lines

Delete empty lines at start of file

```
>>> start of file
>>> empty line
>>> empty line
␣␣|
text
=================
>>> start of file
|text


>>> start of file
>>> empty line
>>> empty line
␣␣|text
=================
>>> start of file
␣␣|text
```

Delete empty lines at end of file
```
text
>>> empty line
␣␣|
>>> empty line
>>> end of file
=================
text
␣␣|
>>> end of file
```

Delete blanks between brackets

```
{
␣␣|
}
=================
{|}


{
␣␣␣␣|
}
=================
{
␣␣|
}
```

Delete blanks between text

```
text1␣␣␣
>>> empty line
>>> empty line
␣␣|
text2
=================
text1
␣␣|
text2
```

### Smart Enter

```
{|}
=================
{
␣␣|
}

'|'
=================
'
|'

>>> in python
'''|'''
=================
'''
|
'''
```

## Interfaces for Advanced Users

`require('pairs.space').type()`: smart space action

`require('pairs.enter').type()`: smart enter action

`require('pairs.delete').type()`: smart deletion action

`require('pairs.bracket').type_left(left)`: smart left bracket action

`require('pairs.bracket').type_right(right)`: smart right bracket action

`require('pairs.utils').get_cursor_lr()`: get the left and right part of the current line under the
cursor

`require('pairs.utils').feedkeys(keys, mode='n')`: feed keys to vim, default not remapped.
