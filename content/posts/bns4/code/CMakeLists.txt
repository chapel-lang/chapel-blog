cmake_minimum_required(VERSION 3.1...3.24)
project(
  nsStep11
  VERSION 1.0
  LANGUAGES CXX
)
set(CMAKE_CXX_STANDARD 17)

add_library(ns_utils utils.cpp utils.h)
add_executable(nsStep11 nsStep11.cpp nsStep11.h)

find_package(MPI REQUIRED)
include_directories(SYSTEM ${MPI_INCLUDE_PATH})

find_package(OpenMP)
if(OpenMP_CXX_FOUND)
    target_link_libraries(nsStep11 PUBLIC OpenMP::OpenMP_CXX ns_utils ${MPI_LIBRARIES})
else()
    target_link_libraries(nsStep11 PUBLIC ns_utils ${MPI_LIBRARIES})
endif()
