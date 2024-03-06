#include "include/foo.h"
#include "include/bar.h"

int main()
{

    bar b{};
    b.show_libs_version();

    foo f{};
    f.show_hard_ware_info();
    fmt::print("Elapsed time: {0:.2f} seconds \n",
               fmt::styled(1.23, fmt::fg(fmt::color::green) |
                                     fmt::bg(fmt::color::blue)));
    std::time_t t = std::time(nullptr);

    // Prints "The date is 2020-11-07." (with the current date):
    fmt::print(fmt::fg(fmt::color::light_green), "The date is {:%Y-%m-%d}. \n", fmt::localtime(t));

    using namespace std::literals::chrono_literals;

    // Prints "Default format: 42s 100ms":
    fmt::print(fmt::fg(fmt::color::light_green), "Default format: {} {}\n", 42s, 100ms);

    // Prints "strftime-like format: 03:15:30":
    fmt::print(fmt::fg(fmt::color::light_green), "strftime-like format: {:%H:%M:%S}\n", 3h + 15min + 30s);
    return 0;
}