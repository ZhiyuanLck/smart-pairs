# Smart Deletion

## Delete Empty Line or Pre-Blanks

First, we have two cases:

- `empty_line`: the cursor is at an empty line
- `empty_pre`: there is only blanks before the cursor

In each case, option `enable_cond`, `enable_fallback`, `before_hook` and `after_hook` are support.

Then we have four subcases of each case according to whether there is a left bracket above or a
right bracket below:

- `bracket_bracket`: brackets above and below
- `bracket_text`: bracket above and text below
- `text_bracket`: text above and bracket below
- `text_text`: text above and below

Each subcase is divided to

- `multi`: config for the case that there is at least two empty lines
- `one`: config for the case that there is only one empty line
- `fallback`: fallback function when there is no empty line

Format of option `multi` is

```lua
multi = {
  strategy = string, strategy to be chosen
  fallback = fallback function if the strategy is unknow
},
```

Format of option `one` is

```lua
one = {
  strategy = string, strategy to be chosen
  trigger_indent_level = number, used by `smart` strategy
  fallback = fallback function if the strategy is unknow
}
```

### Multi-line Strategies

|Action|Description|
|------|-----------|
|`'delete_all'`|delete all blanks|
|`'leave_one_start'`|leave one empty line and set the cursor to the start of empty line|
|`'leave_one_indent'`|leave one empty line and insert the indentation according to option `'indent'`|
|`'leave_one_cur'`|leave one empty line and recover the column of the cursor at the empty line|
|`'leave_one_below'`|leave one empty line and set the cursor before the first non-blank of the first non-empty line below|
|`'leave_one_above'`|leave one empty line and set the cursor after the last non-blank of the first non-empty line above|
|`'leave_zero_below'`|delete all empty lines and set the cursor before the first non-blank of the first non-empty line below/right|
|`'leave_zero_above'`|delete all empty lines and set the cursor after the last non-blank of the first non-empty line above|

### One-line Strategies

|Action|Description|
|------|-----------|
|`'delete_all'`|delete all blanks|
|`'smart'`|if the relative indent level is greater than the value of `'trigger_indent_level'`, then `'fallback'` is called, otherwise `'delete_all'` strategy is triggered|
|`'leave_zero_below'`|delete all empty lines and set the cursor before the first non-blank of the first non-empty line below/right|
|`'leave_zero_above'`|delete all empty lines and set the cursor after the last non-blank of the first non-empty line above|

### Fallback Deletion Functions

- `require('pairs.fallback').delete`: normal deletion, the same as vanilla `<bs>`
- `require('pairs.fallback').delete_indent`: delete until an shorter indentation inferred from the lines above

## Default Deletion Setting

<details>
<summary>Default config</summary>

```lua
  delete = {
    enable_mapping  = true,
    enable_cond     = true,
    enable_fallback = fb.delete,
    empty_line = {
      enable_cond     = true,
      enable_fallback = fb.delete,
      bracket_bracket = {
        fallback = fb.delete_indent,
        multi = {
          strategy = 'leave_one_indent',
          fallback = fb.delete_indent,
        },
        one = {
          strategy = 'smart',
          trigger_indent_level = 0,
          fallback = fb.delete,
        },
      },
      bracket_text = {
        fallback = fb.delete_indent,
        multi = {
          strategy = 'leave_zero_above',
          fallback = fb.delete_indent,
        },
        one = {
          strategy = 'smart',
          trigger_indent_level = 0,
          fallback = fb.delete,
        },
      },
      text_bracket = {
        fallback = fb.delete_indent,
        multi = {
          strategy = 'leave_one_cur',
          fallback = fb.delete_indent,
        },
        one = {
          strategy = 'smart',
          trigger_indent_level = 0,
          fallback = fb.delete,
        },
      },
      text_text = {
        fallback = fb.delete_indent,
        multi = {
          strategy = 'leave_one_cur',
          fallback = fb.delete_indent,
        },
        one = {
          strategy = nil,
          trigger_indent_level = 0,
          fallback = fb.delete,
        },
      },
    },
    empty_pre = {
      enable_cond     = true,
      enable_fallback = fb.delete,
      bracket_bracket = {
        fallback = fb.delete_indent,
        multi = {
          strategy = 'leave_one_indent',
          fallback = fb.delete_indent,
        },
        one = {
          strategy = 'delete_all',
          trigger_indent_level = 0,
          fallback = fb.delete,
        },
      },
      bracket_text = {
        fallback = fb.delete_indent,
        multi = {
          strategy = 'leave_zero_below',
          fallback = fb.delete_indent,
        },
        one = {
          strategy = 'leave_zero_below',
          trigger_indent_level = 0,
          fallback = fb.delete,
        },
      },
      text_bracket = {
        fallback = fb.delete_indent,
        multi = {
          strategy = 'leave_one_indent',
          fallback = fb.delete_indent,
        },
        one = {
          strategy = 'leave_zero_above',
          trigger_indent_level = 0,
          fallback = fb.delete,
        },
      },
      text_text = {
        fallback = fb.delete_indent,
        multi = {
          strategy = 'leave_one_cur',
          fallback = fb.delete_indent,
        },
        one = {
          strategy = nil,
          trigger_indent_level = 0,
          fallback = fb.delete,
        },
      },
    },
    current_line = {
      enable_cond     = true,
      enable_fallback = fb.delete,
    }
  }
```

</details>
