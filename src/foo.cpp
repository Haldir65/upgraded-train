#include "include/foo.h"

foo::foo()
{
}

foo::~foo()
{
}

void foo::show_hard_ware_info()
{
    cpuinfo_initialize();
    fmt::print(fmt::fg(fmt::color::green), "Running on {0} CPU \n", cpuinfo_get_package(0)->name);
#if CPUINFO_ARCH_ARM || CPUINFO_ARCH_ARM64
    fmt::print(fmt::fg(fmt::color::indian_red), "running on {0}\n", " arm cpu");
    if (cpuinfo_has_arm_neon())
    {
        fmt::print(fmt::fg(fmt::color::indian_red), "cpuinfo_has_arm_neon\n");
    }
#endif

    if (cpuinfo_has_x86_avx())
    {
        fmt::print(fmt::bg(fmt::color::indian_red), "cpuinfo_has_x86_avx \n");
    }

    const size_t l1_size = cpuinfo_get_processor(0)->cache.l1d->size;
    fmt::print(fmt::fg(fmt::color::light_blue), "l1_size = {0} \n more info ,see {1}\n", l1_size, "https://github.com/pytorch/cpuinfo");
}
