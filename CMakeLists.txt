cmake_minimum_required(VERSION 3.1)

project(parser C)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(THREADS_PREFER_PTHREAD_FLAG ON)
find_package(Threads REQUIRED)
include_directories(c tests/c)

if(TEST_PAIR)
  add_library(parser SHARED c/parser.c c/dequeue.c c/msg.c)
  target_compile_definitions(parser PUBLIC TEST)
else()
  add_library(parser SHARED c/parser.c c/dequeue.c)
endif()

target_link_libraries(parser PRIVATE Threads::Threads)
set_property(TARGET parser PROPERTY C_STANDARD 99)

set_target_properties(parser
  PROPERTIES
    LIBRARY_OUTPUT_DIRECTORY lib
    RUNTIME_OUTPUT_DIRECTORY lib
)

enable_testing()
add_subdirectory(tests/c)
