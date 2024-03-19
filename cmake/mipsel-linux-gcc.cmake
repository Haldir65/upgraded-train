set(CMAKE_SYSTEM_NAME               Linux)
set(CMAKE_SYSTEM_PROCESSOR          mipsel)

##https://github.com/dockcross/dockcross/blob/master/linux-mipsel-lts/Toolchain.cmake

set(STAGING_DIR $ENV{STAGING_DIR})

message("\n STAGING_DIR retrieve env in cmake STAGING_DIR = ${STAGING_DIR} \n $ENV{STAGING_DIR}")
set(SYS_ROOT "${STAGING_DIR}/toolchain-mipsel_24kc_gcc-7.5.0_musl")
set(tool_chin_bin_dir "${SYS_ROOT}/bin")

# Without that flag CMake is not able to pass test compilation check
# set(CMAKE_TRY_COMPILE_TARGET_TYPE   STATIC_LIBRARY)
set(CMAKE_CROSSCOMPILING TRUE)
set(CMAKE_SYSROOT              ${SYS_ROOT})
set(CMAKE_CXX_STANDARD 17 )


set(CMAKE_AR                        ${tool_chin_bin_dir}/mipsel-openwrt-linux-musl-ar${CMAKE_EXECUTABLE_SUFFIX})
set(CMAKE_ASM_COMPILER              ${tool_chin_bin_dir}/mipsel-openwrt-linux-musl-gcc${CMAKE_EXECUTABLE_SUFFIX})
set(CMAKE_C_COMPILER                ${tool_chin_bin_dir}/mipsel-openwrt-linux-musl-gcc${CMAKE_EXECUTABLE_SUFFIX})
set(CMAKE_CXX_COMPILER              ${tool_chin_bin_dir}/mipsel-openwrt-linux-musl-g++${CMAKE_EXECUTABLE_SUFFIX})
set(CMAKE_LINKER                    ${tool_chin_bin_dir}/mipsel-openwrt-linux-musl-ld${CMAKE_EXECUTABLE_SUFFIX})
set(CMAKE_OBJCOPY                   ${tool_chin_bin_dir}/mipsel-openwrt-linux-musl-objcopy${CMAKE_EXECUTABLE_SUFFIX} CACHE INTERNAL "")
set(CMAKE_RANLIB                    ${tool_chin_bin_dir}/mipsel-openwrt-linux-musl-ranlib${CMAKE_EXECUTABLE_SUFFIX} CACHE INTERNAL "")
set(CMAKE_SIZE                      ${tool_chin_bin_dir}/mipsel-openwrt-linux-musl-size${CMAKE_EXECUTABLE_SUFFIX} CACHE INTERNAL "")
set(CMAKE_STRIP                     ${tool_chin_bin_dir}/mipsel-openwrt-linux-musl-strip${CMAKE_EXECUTABLE_SUFFIX} CACHE INTERNAL "")

# set(CMAKE_C_FLAGS                   "-Wno-psabi --specs=nosys.specs -fdata-sections -ffunction-sections -Wl,--gc-sections" CACHE INTERNAL "") // 被这句--specs=nosys.specs害惨了
# set(CMAKE_CXX_FLAGS                 "${CMAKE_CXX_FLAGS} -fno-exceptions" CACHE INTERNAL "")

set(CMAKE_C_FLAGS_DEBUG             "-Os -g" CACHE INTERNAL "")
set(CMAKE_C_FLAGS_RELEASE           "-Os -DNDEBUG -W -s" CACHE INTERNAL "")
set(CMAKE_CXX_FLAGS_DEBUG           "${CMAKE_CXX_FLAGS_DEBUG}" CACHE INTERNAL "")
string(APPEND CMAKE_CXX_FLAGS_RELEASE "-Os -Wall -fPIC -Wextra -pthread -fno-exceptions -march=1004kc -mtune=1004kc -msoft-float -mfp32 -s")
# set(CMAKE_CXX_FLAGS_RELEASE         "${CMAKE_CXX_FLAGS_RELEASE} -Os -Wall -fPIC -Wextra -pthread -fno-exceptions -march=1004kc -mtune=1004kc -msoft-float -mfp32 -s" CACHE INTERNAL "") ## -s是为了strip

set(CMAKE_FIND_ROOT_PATH ${SYS_ROOT})



set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)