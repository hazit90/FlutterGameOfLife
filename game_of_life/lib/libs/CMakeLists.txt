cmake_minimum_required(VERSION 3.10)  
project(api LANGUAGES CXX C)                         
add_library(cppApi
  SHARED
  ./cppComputer.cpp
  ./cppComputeWrapper.cpp
)

add_library(cppThreadsApi
  SHARED
  ./cppThreadsComputer.cpp
  ./cppThreadsWrapper.cpp
)