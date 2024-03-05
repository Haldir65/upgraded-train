cmake_minimum_required(VERSION 3.15)

project(fibux CXX)

set(EXECUTABLE_NAME fibux)

find_package(fmt REQUIRED)
find_package(nlohmann_json CONFIG REQUIRED)
find_package(simdjson CONFIG REQUIRED)
find_package(spdlog CONFIG REQUIRED)
find_package(cpuinfo CONFIG REQUIRED)
find_package(cxxopts REQUIRED)





add_executable(${EXECUTABLE_NAME} src/main.cpp)


target_compile_features(${EXECUTABLE_NAME} PRIVATE cxx_std_20)

target_link_libraries(
    ${EXECUTABLE_NAME}
    PRIVATE 
            nlohmann_json::nlohmann_json
            simdjson::simdjson
            fmt::fmt
            spdlog::spdlog
            cpuinfo::clog 
            cpuinfo::cpuinfo
            cxxopts::cxxopts)