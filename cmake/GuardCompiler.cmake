message("CMAKE_CXX_COMPILER_ID = ${CMAKE_CXX_COMPILER_ID}")

if("${CMAKE_CXX_COMPILER}" STREQUAL "")
  # this branch will be taken
  message("oops... ${CMAKE_CXX_COMPILER} empty")
  set(CMAKE_C_COMPILER "clang")
  set(CMAKE_CXX_COMPILER "clang++")
else()
  message("fine... ${CMAKE_CXX_COMPILER} ")
endif()