# CMAKE header.
cmake_minimum_required(VERSION 3.13.4)
project(LLVM-Lab)
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

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fno-rtti -std=c++11 -frtti" )

# Append LLVM linker flags to CMAKE_EXE_LINKER_FLAGS
set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} ${LLVM_FLAGS}")



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
string(REPLACE "\n" " " LLVM_FLAGS "${LLVM_FLAGS}")

# Find bison:
find_package(BISON)
BISON_TARGET(Parser "src/frontend/parser.y" "${CMAKE_CURRENT_BINARY_DIR}/parser.tab.cc" DEFINES_FILE "${CMAKE_CURRENT_BINARY_DIR}/parser.tab.hh")

# Find flex:
find_package(FLEX)
FLEX_TARGET(Lexer "src/frontend/lexer.l" "${CMAKE_CURRENT_BINARY_DIR}/lex.yy.cc")
ADD_FLEX_BISON_DEPENDENCY(Lexer Parser)

# Finally link the program with LLVM.
add_executable(${PROJECT_NAME} ${SOURCES}
        src/expressions/multiplication.cpp
        src/expressions/multiplication.h
        src/expressions/division.cpp
        src/expressions/division.h
        src/expressions/negative.cpp
        src/expressions/negative.h
        src/statements/return.cpp
        src/statements/return.h
        src/expressions/or.cpp
        src/expressions/or.h ${FLEX_Lexer_OUTPUTS} ${BISON_Parser_OUTPUTS}
        src/statements/for.cpp
        src/statements/for.h
)

