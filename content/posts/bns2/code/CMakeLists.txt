
# basic project setup
cmake_minimum_required(VERSION 3.1...3.24)
project(
  nsPoisson
  VERSION 1.0
  LANGUAGES CXX
)
set(CMAKE_CXX_STANDARD 17)

# define library for shared utility code
add_library(ns_utils utils.cpp utils.h)

add_executable(nsPoisson nsPoisson.cpp nsPoisson.h)

find_package(OpenMP)
if(OpenMP_CXX_FOUND)
    message(OpenMP_CXX_FOUND="${OpenMP_CXX_FOUND}")
    target_link_libraries(nsPoisson PUBLIC OpenMP::OpenMP_CXX ns_utils)
endif()

if($ENV{TERMONTOL})
    add_compile_definitions(TERMONTOL)
endif()
