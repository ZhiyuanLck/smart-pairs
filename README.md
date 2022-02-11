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
      ignore_pre = '\\\\', -- double backslash
      ignore_after = '\\S', -- double backslash
    },
    lua = {
      ignore_pre = '[%\\\\]' -- double backslash
    }
  },
}
```

### Options

`pairs`: pairs table specified by `filetype = pairs list`. Use `['*'] = ...` to represent for global pairs and options.

A `pair` is specified by

<!-- tw=100 -->
```lua
{ left, right, opts (optional) }
opts = {
  ignore_pre   = vim regex pattern, right bracket will never be completed when left bracket is
    typeset after the pattern
  ignore_after = vim regex pattern, right bracket will never be completed when left bracket is
    typeset before the pattern
  ignore       = string or string list, when checking the validity of brackets or whether to ignore
    some patterns, these strings will be ignored, default escaped pairs
  triplet      = boolean, only for balanced brackets, expand the triplet brackets, default false
  cross_line   = boolean, whether the bracket can cross lines, this option only has effect on enter
    action, default true for unbalanced pairs and false for balanced pairs
}
```

`default_opts`: global default values of pair options. The default values are

```lua
  default_opts = {
    ['*'] = {
      ignore_pre = '\\\\', -- double backslash
      ignore_after = '\\S', -- double backslash
    },
    lua = {
      ignore_pre = '[%\\\\]' -- double backslash
    }
  },
```

## Features

### Typeset Unbalanced Pairs

Typeset left bracket

```
press (
|    --> (|)
|)   --> (|)
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
>>> empty line
␣␣|
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
