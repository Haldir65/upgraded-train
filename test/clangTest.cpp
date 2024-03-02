#include <iostream>
#include <map>
#include <vector>
#include <atomic>
#include <algorithm>
#include <sstream>
// #include <stdatomic.h>
// <stdatomic.h> is not part of the C++ standard.
#include <stdio.h>
#include <thread>
// #include <threads.h>

std::atomic_int acnt;
int cnt;

int f(void *thr_data)
{
    for (int n = 0; n < 10000; ++n)
    {
        ++cnt;
        ++acnt;
    }
    return 0;
}

void testing_thread_realiablity()
{
    /* Exercise thrd_create from -pthread,
     * which is not present in glibc 2.27 in Ubuntu 18.04.
     * https://stackoverflow.com/questions/56810/how-do-i-start-threads-in-plain-c/52453291#52453291 */
    {
        std::vector<std::thread> pool;
        for (int n = 0; n < 10; ++n)
        {
            pool.push_back(std::thread([&]()
                                       { f(&n); }));
        }

        std::for_each(pool.begin(), pool.end(), [](std::thread &t)
                      { t.join(); });
    }
    printf("The atomic counter is %u\n", acnt.load());
    printf("The non-atomic counter is %u\n", cnt);
}

void current_standard()
{
    //https://gcc.gnu.org/onlinedocs/cpp/Standard-Predefined-Macros.html    //这个是gnu的
    // https://en.cppreference.com/w/cpp/preprocessor/replace#Predefined_macros  这个才是标准
    if (__cplusplus > 202302L )
        std::cout << "an unspecified value strictly larger than 202302L for the experimental languages enabled by -std=c++26 and -std=gnu++26.";
    else if (__cplusplus >  202002L || __cplusplus == 202302L)
        std::cout << "C++23";
    else if (__cplusplus == 202002L)
        std::cout << "C++20";
    else if (__cplusplus == 201703L)
        std::cout << "C++17";
    else if (__cplusplus == 201402L)
        std::cout << "C++14";
    else if (__cplusplus == 201103L)
        std::cout << "C++11";
    else if (__cplusplus == 199711L)
        std::cout << "C++98";
    else
        std::cout << "pre-standard C++." << __cplusplus;
    std::cout << "\n";

// check compiler version
#if defined(__clang__)
    std::cout << "__clang__"
              << "\n __clang_major__ = " << __clang_major__ << "\n __clang_patchlevel__ = " << __clang_patchlevel__ << std::endl;
    ;
#elif defined(__GNUC__) || defined(__GNUG__)
    std::cout << "__GNUC__" << __GNUC_MINOR__ << __GNUC_PATCHLEVEL__ << std::endl;
    // printf("gnu_get_libc_version() = %s\n", gnu_get_libc_version());
#elif defined(_MSC_VER)
    std::cout << "_MSC_VER";
#endif

    std::string true_cxx =
#ifdef __clang__
        "clang++";
#else
        "g++";
#endif

    auto constexpr ver_string = [](int a, int b, int c) -> std::string
    {
        std::ostringstream ss;
        ss << a << '.' << b << '.' << c;
        return ss.str();
    };

    std::string true_cxx_ver =
#ifdef __clang__
        ver_string(__clang_major__, __clang_minor__, __clang_patchlevel__);
#else
        ver_string(__GNUC__, __GNUC_MINOR__, __GNUC_PATCHLEVEL__);
#endif

    std::cout << "[compiler]: " << true_cxx << " version: " << true_cxx_ver << std::endl;
}

int funcThrow(void)
{
    throw std::runtime_error("some error happens");
    return 0;
}

int main(int argc, char const *argv[])
{
    std::cout << "this works , right ?" << std::endl;
    current_standard();
    // Map
    std::map<int, char> M = {{1, 'a'},
                             {2, 'b'}};
    try
    {
        funcThrow();
    }
    catch (const std::exception &e)
    {
        std::cerr << e.what() << '\n';
    }

#if defined(__clang__)
    // Check if M has key 2
    if (M.contains(2)) // c++20 feature
    {
        std::cout << "Found\n";
    }
    else
    {
        std::cout << "Not found\n";
    }
#endif
    testing_thread_realiablity();
    return 0;
}
