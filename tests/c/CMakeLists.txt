function(new_test t)
  set(name test_${t})
  add_executable(${name} ${name}.c test.c)
  target_link_libraries(${name} parser)
  set_target_properties(${name}
    PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY test_bin
    COMPILE_DEFINITIONS "TEST"
  )
  add_test(
    NAME ${name}
    COMMAND test_bin/${name}
  )
endfunction()

new_test(dequeue)
new_test(parser_line)
