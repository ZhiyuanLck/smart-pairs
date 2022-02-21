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

## Configuration

Setup the options by

```
require('pairs'):setup(opts)
```

All default options are set in [init.lua](lua/pairs/init.lua).


### Quick Start For Custom Pairs

All pairs are grouped by file types, and `'*'` contain the global pair list. Every pair is a table
list, whose first element is the left bracket, second element is the right bracket, and the last is
the optional pair options, i.e. a `pair` is specified by `{ left, right, opts (optional) }`. At
last, all types of pairs are saved in top-level option `pairs`.

<details>
<summary><b>Default pairs</b></summary>

```lua
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
  }
```

</details>

|Options|Description|Default|
|-------|-----------|-------|
|`ignore_pre`|vim regex pattern, brackets after the pattern keep its original meaning|`'\\\\'`|
|`ignore_after`|vim regex pattern, only for unbalanced brackets, forbid right bracket completion with the post pattern|`'\\w'`|
|`ignore`|string or list, patterns to ignore when counting the number of brackets|escaped brackets|
|`triplet`|boolean, only for balanced brackets, expand the triplet brackets|`false`|
|`cross_line`|boolean, whether the bracket can cross lines|`true` for unbalanced pairs, `false` for balanced pairs|
|`enable_smart_space`|boolean, whether to enable smart space|`true` for unbalanced pairs, `false` for balanced pairs|

Sometimes, it is convenient to use option `default_opts` to set the default value of the option of
each pair which belongs to the same file type to avoid repeated settings.

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

### Mapping Config

Option that controls whether to map the specified key is `<key>.enable_mapping`, where the value of
`<key>` is one of the `space`, `enter` and `delete`, which represent for `<space>`, `<cr>` and
`<bs>` that will be mapped indivisually. You can set it to a boolean value or a function that
returns a boolean value.

***Note***: The value of `<key>` below can also be `delete.empty_line`, `delete.empty_pre` and
`delete.current_line`.

Option `<key>.enable_cond` (boolean or function) define the condition to decide when to perform the
smart action, and if the test fails, function `<key>.enable_fallback` is called.

Option `<key>.before_hook` and `<key>.after_hook` define the hook funtion that will run before and
after the smart actions.

Option `mapping` is used to define other key mappings

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

### Advanced Options

[Control the behavior of smart deletion](doc/delete.md)

### Other Options

**`indent`**: indent table, insert correct indentation according to this option if needed

```lua
  indent = {
    ['*'] = 1,
    python = 2,
  }
```

**`autojump_strategy.unbalanced`**: string, strategy applied to autojump, default `'right'`. All
values are

- `'all'`: always enable smart jump when you type a right bracket, but it may be not ideal when
  there is a cross-line pair.
- `'right'`: enable smart jump only when there is a right bracket next to the cursor, such as `(|)`.
- `other value`: forbid smart jump, always type the right bracket rather than jump.

**`max_search_lines`**: number, max lines to search when needed, default 500.

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
|       --> )|       - type right
|(ab)   --> )|(ab)   - type right
(|      --> ()|      - complete right
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
