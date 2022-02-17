# Smart Pairs

`smart-pairs` is written in lua and provides pairs completion, deletion and jump.

One line to setup the plugin with `packer.nvim`

```lua
use {'ZhiyuanLck/smart-pairs', event = 'InsertEnter', config = function() require('pairs'):setup() end}
```

***Note***: If you find some annoying behaviors, please create an issue with the example and the
reason to let me know. I will try to find if there is a better solution and if not I will make it
configurable.

***Note***: Only support bracket of single char (of multibyte). For multi-char pairs, see snippet
plugins.

***Note***: Lines in the examples below represent for the *whole line* not the part of line.

## Configuration

Setup the options by

```
require('pairs'):setup(opts)
```

<details>
<summary><b>Default options</b></summary>

```lua
local fb = require('pairs.fallback')
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
      {'(', ')', {ignore = {'%(', '%)', '%%'}}},
      {'[', ']', {ignore = {'%[', '%]', '%%'}}},
      {'{', '}', {ignore = {'%{', '%}', '%%'}}},
    },
    python = {
      {"'", "'", {triplet = true}},
      {'"', '"', {triplet = true}},
    },
    markdown = {
      {'`', '`', {triplet = true}},
    },
    tex = {
      {'$', '$', {cross_line = true}},
      -- Chinese pairs
      {'（', '）'},
      {'【', '】'},
      {'‘', '’'},
      {'“', '”'},
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
    enable_mapping  = true,
    enable_cond     = true,
    enable_fallback = fb.delete,
    empty_line = {
      enable_cond      = true,
      enable_fallback  = fb.delete,
      enable_sub = {
        start                      = true,
        inside_brackets            = true,
        left_bracket               = true,
        text_multi_line            = true,
        text_delete_to_prev_indent = true,
      },
      trigger_indent_level = 1,
    },
    current_line = {
      enable_cond     = true,
      enable_fallback = fb.delete,
    }
  },
  space = {
    enable_mapping  = true,
    enable_cond     = true,
    enable_fallback = fb.space,
  },
  enter = {
    enable_mapping  = true,
    enable_cond     = true,
    enable_fallback = fb.enter,
    indent = {
      ['*'] = 1,
      python = 2,
    }
  },
  autojump_strategy = {
    unbalanced = 'right', -- all, right, loose_right, none
  },
  mapping = {
    jump_left_in_any   = '<m-[>',
    jump_right_out_any = '<m-]>',
    jump_left_out_any  = '<m-{>',
    jump_right_in_any  = '<m-}>',
  },
  max_search_lines = 100,
}
```

</details>

### Options

**`pairs`**: pairs table specified by `filetype = pairs list`. Use `['*'] = ...` to represent for
global pairs and options.

A `pair` is specified by `{ left, right, opts (optional) }`

<details>
<summary><b>pair options</b></summary>

**`ignore_pre`**: vim regex pattern, brackets after the pattern keep its original meaning.

**`ignore_after`**: vim regex pattern, only for unbalanced brackets, right bracket will never be
completed when left bracket is typeset before the pattern except the right bracket.

**`ignore`**: string or string list, these patterns will be removed before the current line is
parsed to make strategies. Note that escaped pair has been removed by default.

**`triplet`**: boolean, only for balanced brackets, expand the triplet brackets, default false.

**`cross_line`**: boolean, whether the bracket can cross lines, default true for unbalanced pairs
and false for balanced pairs.

**`enable_smart_space`**: boolean, whether to enable smart space, default true for unbalanced pairs
and false for balanced pairs.

</details>

<details>
<summary><b>global options</b></summary>

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

**`enter.indent`**: indent table, when smart enter is enabled, extra indent will be added according
the value of this option.

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

**`delete.empty_line.enable_sub.start`**: enable smart deletion of empty lines at start of file,
default `true`.

```
_ denotes <space>

>>> start of file
>>> empty line
>>> empty line
__|
text
=================
>>> start of file
|text


>>> start of file
>>> empty line
>>> empty line
__|text
=================
>>> start of file
__|text
```

**`delete.empty_line.enable_sub.inside_brackets`**: enable smart deletion of blanks between
brackets, default `true`.

```
_ denotes <space>

First deletion will delete all but current empty line
=================
{

____|
}

Second deletion will delete a tab
=================
{
____|
}
=================
{
__|
}

Now the relative indent level is 1, smart deletion is triggered
=================
{|}
```

**`delete.empty_line.enable_sub.left_bracket`**: enable smart deletion of empty lines when only a
left bracket is detected, default `true`.

```
{

  |text
=================
{
  |text
=================
{|text
```

**`delete.empty_line.enable_sub.text_multi_line`**: enable smart deletion of multiple empty lines
between text, default `true`.

```
text1


  |text2
=================
text1

  |text2

-----------------

text1


  |
  text2
=================
text1
  |
  text2
```

**`delete.empty_line.enable_sub.text_delete_to_prev_indent`**: enable smart deletion when there is
one empty line or zero empty line but there are blanks before the cursor, then it will delete to the
previsous indentation, default `true`.

```
text1
  text2
          |
    text3
=================
text1
  text2
  |
    text3
```

**`delete.empty_line.trigger_indent_level`**: smart deletion is triggered only when the relative
indent level is less than the option value where the first nonempty line is ended with a left
bracket that can cross lines and/or spaces, default `1`.

**`delete.current_line.enable_cond`**: boolean or function, condition to enable smart deletion in
current line, default `true`.

**`delete.current_line.enable_fallback`**: function, if `delete.current_line.enable_cond` is
evaluated to `false`, then the fallback function will be called, default `require('pairs.utils').delete`.

**`autojump_strategy.unbalanced`**: string, strategy applied to autojump, default `'right'`. All
values are

- `'all'`: always enable smart jump when you type a right bracket, but it may be not ideal when
  there is a cross-line pair.
- `'right'`: enable smart jump only when there is a right bracket next to the cursor, such as `(|)`.
- `'loose_right'`: enable smart jump only when there is a right bracket (with prefix spaces) next to
  the cursor, such as`(|_)`.
- `'none' or nil`: forbid smart jump, always type the right bracket rather than jump.

**`max_search_lines`**: number, max lines to search when needed, default 100.

**`mapping`**: key mappings

- `jump_left_in_any`: jump to the right side of left bracket on the left/above of the cursor,
  default `<m-[>`.
- `jump_right_out_any`: jump to the right side of right bracket on the right/below of the cursor,
  default `<m-]>`.
- `jump_right_in_any`: jump to the left side of right bracket on the right/below of the cursor,
  default `<m-}>`.
- `jump_left_out_any`: jump to the left side of left bracket on the left/above of the cursor,
  default `<m-{>`.

In fact, you can jump to any custom search key by `require('pairs.bracket').jump_left(opts)` and
`require('pairs.bracket').jump_right(opts)`, where
```lua
opts = {
  key = string, key to be searched
  out = boolean, jump to the outside or inside of the key
}
```

</details>

## Work with Other Plugin

Integrate smart enter and smart bracket with `nvim-cmp`:
[workaround](https://github.com/ZhiyuanLck/smart-pairs/issues/2#issuecomment-1037232219)

## Features

### Typeset Unbalanced Pairs

Typeset left bracket

```
press (
|    --> (|)    - type left and complete the right
|)   --> (|)    - complete left
|')' --> (|)')' - ignore strings
|a   --> (|a    - not complete the right before a word
|()) --> (|())  - respect the validity of current line
\|   --> \(|    - not complete the right after an escape char
\\|  --> \\(|)  - work well after double backslash
'%|' --> '%('   - not complete the right after '%' in lua (see pair option 'ignore_pre')
```

Typeset right bracket

```
press )
|       --> |)       - type right
|(ab)   --> |)(ab)   - type right
(|      --> (|)      - complete right
(|)     --> ()|      - jump right when 'autojump_strategy.unbalanced' is not 'none'
(| )    --> ()|      - jump right when 'autojump_strategy.unbalanced' is 'all' or 'loose_right'
(a|b)   --> (ab)|    - jump right when 'autojump_strategy.unbalanced' is 'all'
|(ab))  --> (ab)|)   - jump right when 'autojump_strategy.unbalanced' is 'all'
('\(|') --> ('\(')|  - jump right when 'autojump_strategy.unbalanced' is 'all'
('\(|') --> ('\()|') - type right when 'autojump_strategy.unbalanced' is not 'all'
```

### Typeset Balanced Pairs

```
press "
|     --> "|"     - type two
"ab|  --> "ab|"   - complete anoter
"a|b" --> "a"|"b" - type two in middle
"ab|" --> "ab"|   - jump right if next to the right one
'"'|  --> '"'"|"  - ignore string and type two
""|   --> """|""" - complete triplet in python
```

### Smart Space

```
press <space>, _ denotes <space>
{|} --> {_|_}
```

### Smart Deletion

```
press <bs>, _ denotes <space>
{{|}    --> {|}   - delete left
{|}     --> |     - delete two
{|}}    --> |}    - delete two
{_|__}  --> {_|_} - leave two spaces
{__|_}  --> {_|_} - leave two spaces
{_|_}   --> {}    - delete all blanks
{__|}   --> {|}   - delete all blanks
{__|ab  --> {|ab  - delete all blanks
{__|_ab --> {|ab  - delete all blanks
{|___ab --> |_ab  - delete left and leave a space
```

### Smart Enter

```
{|}
=================
{
  |
}
-----------------
{abc|}
=================
{abc
  |
}
-----------------
{ab|c}
=================
{abc
  |c}
-----------------
'|'
=================
'
|'
-----------------
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
