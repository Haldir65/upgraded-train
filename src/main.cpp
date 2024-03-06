#include "include/foo.h"
#include "include/bar.h"

int main()
{

   

    foo f{};
    f.show_hard_ware_info();
    bar b{};
    b.do_fmt_lib_test();
    b.show_libs_version();
    b.performing_curl_test();

    
    return 0;
}