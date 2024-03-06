#include "include/bar.h"
#include <openssl/opensslv.h>

bar::bar()
{
}

bar::~bar()
{
}

void bar::show_libs_version() const
{

    fmt::print(fmt::fg(fmt::color::light_green), "curl version =  {0}\n OPENSSL_VERSION_STR = {1}\n", curl_version(), OPENSSL_VERSION_STR);
}