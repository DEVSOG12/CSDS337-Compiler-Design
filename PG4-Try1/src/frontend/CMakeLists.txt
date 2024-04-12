cmake_minimum_required(VERSION 3.27)
project(frontend C)

set(LLVM_PATH "/opt/homebrew/opt/llvm")

# Find LLVM package
find_package(LLVM REQUIRED CONFIG)

# Add LLVM include directories
include_directories(${LLVM_INCLUDE_DIRS})

# Add LLVM definitions
add_definitions(${LLVM_DEFINITIONS})

# Add LLVM library directories
link_directories(${LLVM_LIBRARY_DIRS})

# Set LLVM_LINK_COMPONENTS to the components you need
llvm_map_components_to_libnames(LLVM_LIBS core support)

# Bison and Flex targets
find_package(BISON REQUIRED)
find_package(FLEX REQUIRED)

# Set the output language to C for Bison and Flex
set_source_files_properties(${CMAKE_CURRENT_BINARY_DIR}/parser.tab.cc PROPERTIES LANGUAGE C)
set_source_files_properties(${CMAKE_CURRENT_BINARY_DIR}/lex.yy.cc PROPERTIES LANGUAGE C)

bison_target(MyParser parser.y ${CMAKE_CURRENT_BINARY_DIR}/parser.tab.cc COMPILE_FLAGS "-d" VERBOSE)
flex_target(MyLexer lexer.l ${CMAKE_CURRENT_BINARY_DIR}/lex.yy.cc)

# Executable
add_executable(parser ${BISON_MyParser_OUTPUTS} ${FLEX_MyLexer_OUTPUTS})
target_link_libraries(parser ${LLVM_LIBS})

# Test target
add_custom_target(test
        COMMAND $<TARGET_FILE:parser> < ${CMAKE_CURRENT_SOURCE_DIR}/test.c
        DEPENDS parser
        WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
        COMMENT "Running parser on test.c"
)

# Clean target
add_custom_target(clean_all
        COMMAND ${CMAKE_COMMAND} -P ${CMAKE_SOURCE_DIR}/clean.cmake
)
