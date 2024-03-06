cmake_minimum_required(VERSION 3.22 FATAL_ERROR)

project(fibux CXX)

set(EXECUTABLE_NAME fibux)
if(NOT WIN32)
    find_package(PkgConfig)
    if(PKG_CONFIG_FOUND)
        pkg_check_modules(NGHTTP2 REQUIRED libnghttp2)
    endif()
endif(NOT WIN32)

find_package(fmt REQUIRED)
find_package(nlohmann_json CONFIG REQUIRED)
find_package(simdjson CONFIG REQUIRED)
find_package(spdlog CONFIG REQUIRED)
find_package(cpuinfo CONFIG REQUIRED)
find_package(cxxopts REQUIRED)
find_package(OpenSSL REQUIRED)
find_package(CURL REQUIRED)

if(PKG_CONFIG_FOUND AND NGHTTP2_FOUND)
    message("NGHTTP2_FOUND = ${NGHTTP2_FOUND} ")
    message("NGHTTP2_INCLUDE_DIR = ${NGHTTP2_INCLUDE_DIRS} ")
    message("NGHTTP2_LIBRARIES = ${NGHTTP2_LIBRARIES} ")
    message("NGHTTP2_LIBRARY_DIRS = ${NGHTTP2_LIBRARY_DIRS} ")
    message("NGHTTP2_LDFLAGS = ${NGHTTP2_LDFLAGSS} ")
    message("NGHTTP2_LINK_LIBRARIES = ${NGHTTP2_LINK_LIBRARIES} ")
endif(NGHTTP2_FOUND)




add_executable(${EXECUTABLE_NAME} 
    src/main.cpp
    src/foo.cpp
    src/bar.cpp
)


target_compile_features(${EXECUTABLE_NAME} PRIVATE cxx_std_20)



target_include_directories(${EXECUTABLE_NAME} 
    PRIVATE 
    ${CMAKE_CURRENT_SOURCE_DIR}/src/include
    ${CURL_INCLUDE_DIRS}
    )




target_link_libraries(
    ${EXECUTABLE_NAME}
    PRIVATE 
            nlohmann_json::nlohmann_json
            simdjson::simdjson
            fmt::fmt
            spdlog::spdlog
            CURL::libcurl
            OpenSSL::SSL OpenSSL::Crypto
            cpuinfo::cpuinfo
            cxxopts::cxxopts)

