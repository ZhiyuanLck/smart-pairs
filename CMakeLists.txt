cmake_minimum_required(VERSION 3.1)

project(parser C)

include_directories(c)

set(files c/parser.c c/dequeue.c)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# pthread
if(TEST_PAIR OR THREADS)
  set(THREADS_PREFER_PTHREAD_FLAG ON)
  find_package(Threads REQUIRED)
  include_directories(tests/c)
  list(APPEND files c/thread_pool.c)
endif()

# test
if(TEST_PAIR)
  set(CMAKE_BUILD_TYPE Debug)
  list(APPEND files c/msg.c)
else()
  set(CMAKE_BUILD_TYPE Release)
endif()

add_library(parser SHARED ${files})
set_property(TARGET parser PROPERTY C_STANDARD 11)
set_target_properties(parser
  PROPERTIES
    LIBRARY_OUTPUT_DIRECTORY lib
    RUNTIME_OUTPUT_DIRECTORY lib
)

if(TEST_PAIR OR THREADS)
  target_link_libraries(parser PRIVATE Threads::Threads)
endif()

if(TEST_PAIR)
  target_compile_definitions(parser PUBLIC TEST)
  enable_testing()
  add_subdirectory(tests/c)
endif()

if(THREADS)
  target_compile_definitions(parser PUBLIC THREADS)
endif()
