cmake_minimum_required(VERSION 3.4.1)

file(GLOB_RECURSE cppPaths "../ios/Arasan/src/*.cpp")
add_library(
  arasan
  SHARED
  ../ios/FlutterArasan/ffi.cpp
  ${cppPaths}
)

