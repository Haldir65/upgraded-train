cmake_minimum_required(VERSION 3.22 FATAL_ERROR)

project(fibux CXX)

set(EXECUTABLE_NAME fibux)
find_package(fmt REQUIRED)
find_package(nlohmann_json CONFIG REQUIRED)
find_package(simdjson CONFIG REQUIRED)
find_package(spdlog CONFIG REQUIRED)
find_package(cpuinfo CONFIG REQUIRED)
find_package(cxxopts REQUIRED)
find_package(OpenSSL REQUIRED)
find_package(CURL REQUIRED)




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
            cpuinfo::clog 
            CURL::libcurl
            OpenSSL::SSL OpenSSL::Crypto
            cpuinfo::cpuinfo
            cxxopts::cxxopts)

