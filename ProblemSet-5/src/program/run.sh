#!/bin/bash

# Function to compile C code with different optimization levels
compile_with_optimization() {
    local optimization_level=$1
    local architecture=$2

    clang -O${optimization_level} -target ${architecture} -o a_${optimization_level} a.c
}

# Function to generate LLVM IR
generate_llvm_ir() {
    time clang -S -emit-llvm a.c -o a.ll
}

# Function to run LLVM optimizations
run_llvm_optimizations() {
    local optimization_level=$1

    echo "Running LLVM optimizations for optimization level $optimization_level"
    
    { time opt -O${optimization_level} a.ll -o a_${optimization_level}.ll ;} 2> optimization_${optimization_level}_time.txt
}

# Function to convert LLVM IR back to assembly
llvm_to_assembly() {
    local optimization_level=$1

    time llc -O${optimization_level} a_${optimization_level}.ll -o a_${optimization_level}_from_ir.s
}

# Function to compare assembly files
compare_assembly_files() {
    wc -l a_baseline.s > a_baseline_lines.txt 
    for i in {0..3}; do
        echo "Diff for optimization level $i" 
        wc -l a_${i}.s > a_${i}_lines.txt
    done
}

# Function to run LLVM optimizations with multiple passes
run_llvm_optimizations_A() {
    local optimization_level=$1

    local passes=('adce' 'loop-vectorize' 'loop-unroll' 'simple-loop-unswitch' 'loop-unroll-and-jam' 'extract-blocks' 'loop-rotate' 'loop-reduce' 'lcssa' 'mergefunc' 'loop-deletion' 'licm' )

    for pass in "${passes[@]}"; do
        t1=0
        for ((i = 1; i <= 10; i++)); do
            { time opt -passes="$pass" a.ll -o a_${pass}.ll; } 2> passes_${pass}_time_${i}.txt
        done
    
        { python3 as.py passes_${pass}_time.txt; }
        { wc -l a_${pass}.ll > a_${pass}_lines.txt; }
    done
}

# Function to run tests
run_tests() {
    local size=$1
    local optimization_level=$2
    local num_tests=$3

    echo "Running tests for matrix size ${size}x${size} with optimization level ${optimization_level}"

    # Compile the C code
    compile_with_optimization $optimization_level "x86_64-apple-macosx"

    # Run tests
    total_time=0
    for ((i = 1; i <= num_tests; i++)); do
        time_taken=$({ time ./a_${optimization_level} $size; } 2>&1 | grep real | awk '{print $2}')
        total_time=$(echo "$total_time + $time_taken" | bc)
    done

    # Calculate the mean time
    mean_time=$(echo "scale=3; $total_time / $num_tests" | bc)

    # Save the mean time to a file
    echo "$mean_time" > "${size}x${size}_optimization_${optimization_level}_mean_time.txt"
}

# Main function
main() {
    architecture="x86_64-apple-macosx"

    # Compile baseline
    echo "Compiling baseline"
    clang -S -o a_baseline.s a.c  
    
    # Run baseline
    clang a_baseline.s -o a_baseline
    { time ./a_baseline 5;} 2> baseline_time.txt
    { wc -l a_baseline.s > a_baseline_lines.txt; }
   
    generate_llvm_ir 
    run_llvm_optimizations_A 0
}

# Run the main function
main
