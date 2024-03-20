cmake_minimum_required(VERSION 3.13.4)
project(LLVM-Lab)

set(CMAKE_CXX_STANDARD 17)
set(LLVM_PATH "/opt/homebrew/opt/llvm")

# Set binary output destination.
set(BINARY_OUTPUT_DIR ${CMAKE_CURRENT_SOURCE_DIR}/bin)
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${BINARY_OUTPUT_DIR})
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${BINARY_OUTPUT_DIR})
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${BINARY_OUTPUT_DIR})

# Include project sources.
include_directories("src")
file(GLOB_RECURSE SOURCES RELATIVE ${CMAKE_SOURCE_DIR} "src/*.cpp" "src/*.c")

# Get LLVM linker flags.
execute_process(COMMAND llvm-config --ldflags --system-libs --libs all OUTPUT_VARIABLE LLVM_FLAGS)

# Get rid of whitespace and replace newlines with spaces.
string(STRIP "${LLVM_FLAGS}" LLVM_FLAGS)
string(REPLACE "\n" " " LLVM_FLAGS  "${LLVM_FLAGS}")

link_directories(${LLVM_PATH}/lib)
include_directories(${LLVM_PATH}/include)

add_definitions(
        -D__STDC_LIMIT_MACROS
        -D__STDC_CONSTANT_MACROS
)

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fno-rtti -std=c++11")

# Append LLVM linker flags to CMAKE_EXE_LINKER_FLAGS
set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} ${LLVM_FLAGS}")

add_executable(LLVM-Lab ${SOURCES})