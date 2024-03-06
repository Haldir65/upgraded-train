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
// #include <stdatomic.h>
// <stdatomic.h> is not part of the C++ standard.
#include <stdio.h>
#include <thread>

#include <string>
#include <filesystem>
#include <vector>
#include <algorithm>
#include <map>
#include <unordered_map>
#include <unordered_set>
#include <algorithm>
#include <cassert>
#include <vector>
#include <fmt/ranges.h>
#include <fmt/color.h>
#include <fmt/core.h>

#include <cpuinfo.h>


class foo
{
private:
    uint8_t cost{100};

public:
    foo();
    ~foo();
    void show_hard_ware_info();

};


