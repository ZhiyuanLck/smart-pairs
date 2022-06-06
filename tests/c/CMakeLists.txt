function(new_test t)
  set(name test_${t})
  add_executable(${name} ${name}.c test.c)
  target_link_libraries(${name} parser)
  set_target_properties(${name}
    PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY test_bin
    COMPILE_DEFINITIONS "TEST"
  )
  set_property(TARGET ${name} PROPERTY C_STANDARD 11)
  add_test(
    NAME ${name}
    COMMAND test_bin/${name}
  )
endfunction()

new_test(thread_pool)
new_test(dequeue)
new_test(parser_line)
new_test(parser_multi_line)
