#pragma once
#include <fmt/core.h>
#include <fmt/color.h>
#include <fmt/ranges.h>
#include <fmt/chrono.h>
#include <fmt/std.h>
#include <string>
#include <vector>
#include <iostream>
#include <fstream>
#include <filesystem>
#include <map>
#include <vector>
#include <atomic>
#include <algorithm>
#include <sstream>
#include <curl/curl.h>
#include <memory>
// #include <stdatomic.h>
// <stdatomic.h> is not part of the C++ standard.
#include <stdio.h>
#include <thread>

class bar
{
private:
    int data{0};

public:
    bar();
    ~bar();
    void show_libs_version() const;
    void do_fmt_lib_test() const;
    void performing_curl_test();
};

