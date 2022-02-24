---
name: Bug report
about: Create a report to help us improve
title: ''
labels: bug
assignees: ''

---

**Describe the bug**
A clear and concise description of what the bug is. For example, right bracket is not jumped as expected.

**To Reproduce**
For example, initial cursor position is at `(|)`. Then press `)`.

<!---
Expected behavior
A clear and concise description of what you expected to happen.
--->
We should get `()|`, but get `()|)` instead.

<!---
**Error messages**
You can take a screenshort.
--->

<!--- 
**Screenshots**
Other screenshots or gifs to help show the issue.
--->

**Packer config and plugin config**
For example

<details>
<summary>Config</summary>

```lua
    use {'ZhiyuanLck/smart-pairs', event = "InsertEnter",
      config = function()
        require('pairs'):setup{
          pairs = {
            html = {
              {'<', '>'}
            }
          }
        }
      end
    }
```

</details>


**Other information**
 - Distribution: [e.g. Ubuntu, Windows 11]
 - Nvim version: [first line of the output of `nvim -v`, e.g. NVIM v0.7.0-dev+922-g1b6ae2dbb]
