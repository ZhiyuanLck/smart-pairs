#!/bin/env bash
nvim --headless -c "lua require('plenary.test_harness').test_directory('tests/pairs/', {minimal_init = 'tests/minimal_init.vim', keep_going = false, sequential = true})"
