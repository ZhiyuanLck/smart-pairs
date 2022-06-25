#!/bin/env bash
# nvim --headless --noplugin -c "lua require('plenary.test_harness').test_directory('tests/pairs/', {minimal_init = 'tests/minimal_init.vim', keep_going = false, sequential = true})"
cmake -DTEST_PAIR=1 -DTHREADS=1 . && cmake --build . && ctest --output-on-failure
