#include "include/bar.h"
#include <openssl/opensslv.h>
#include <iostream>
#include <curl/curl.h>
#include <nlohmann/json.hpp>

bar::bar()
{
}

bar::~bar()
{
}

void bar::do_fmt_lib_test() const
{
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
}

void bar::show_libs_version() const
{

    fmt::print(fmt::fg(fmt::color::light_green), "curl version =  {0}\n OPENSSL_VERSION_STR = {1}\n", curl_version(), OPENSSL_VERSION_STR);
}

// 回调函数，用于处理接收到的数据
size_t write_callback(char *ptr, size_t size, size_t nmemb, std::string *data)
{
    data->append(ptr, size * nmemb);
    return size * nmemb;
}

void bar::performing_curl_test()
{

    CURL *curl;
    CURLcode res;
    long http_version;
    std::string url = "https://jsonplaceholder.typicode.com/posts";
    std::string response;

    curl_global_init(CURL_GLOBAL_ALL);
    curl = curl_easy_init();

    if (curl)
    {
        curl_easy_setopt(curl, CURLOPT_URL, url.c_str());
        curl_easy_setopt(curl, CURLOPT_HTTP_VERSION, CURL_HTTP_VERSION_2_0);
        curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, write_callback);
        curl_easy_setopt(curl, CURLOPT_WRITEDATA, &response);

        res = curl_easy_perform(curl);

        if (res != CURLE_OK)
        {
            std::cerr << "Failed to perform HTTP/2 request: " << curl_easy_strerror(res) << std::endl;
        }
        else
        {
            // 获取当前连接使用的HTTP协议版本
            curl_easy_getinfo(curl, CURLINFO_HTTP_VERSION, &http_version);
            if (http_version == CURL_HTTP_VERSION_2_0)
            {
                std::cout << "The connection is using HTTP/2 protocol." << std::endl;
            }
            else
            {
                std::cout << "The connection is not using HTTP/2 protocol." << std::endl;
            }

            // 解析返回的JSON数据
            nlohmann::json json_data = nlohmann::json::parse(response);
            // 输出解析后的JSON数据
            fmt::print(fmt::fg(fmt::color::light_green), "json_data {0}\n", json_data.dump(4));
        }

        curl_easy_cleanup(curl);
    }

    curl_global_cleanup();
}
