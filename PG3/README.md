# An Intro To LLVM
LLVM is a powerful framework that allows you to generate and even execute code. In this assignment, we will look at the basics of programming with LLVM. This is by no means a complete guide, but our hope is that you get an understanding on how LLVM works and can use this as a base for future LLVM-related projects.

## Assignment
Your assignment is to modify `src/main.cpp` to generate code for 6 optimized functions. Each stage of the assignment will get progressively harder (though sometimes getting started can be the hardest). Please see the guide section of this README first for a quick guide about LLVM and for common FAQs. WINDOWS_SETUP instructions are provided, though the VM will have all the packages needed by default. A `runDocker.sh` script is provided for building with docker if that is preferred. You may need to `chmod +x run.sh` and other scripts first before running them with `./run.sh`.

### Running The Project
This assignment is designed in such a way that you get to measure your progress along the way :} The `run.sh` script will run the `main.cpp` file, and the `testGenerations.sh` will execute the tests in `testGenerations.cpp` (it will also run `run.sh` first). If an assertion fails, that means the function does not return the expected value. If you get a linker error, that means a function was not defined in your bitcode file. You can comment out assertions that cause linker errors temporarily if you have not gotten to them yet. Ex: Commenting out the `assert(addIntFloat(4, 32.4f) == 36.4f);` line in `testGenerations.cpp` since you did not implement `addIntFloat` yet. If all tests pass, that doesn't guarantee a perfect grade.

### Part 1 - Setup The Module
Before we can do anything, an LLVM context and module needs to be establed. This module should be called `sampleMod`. Have this module be printed (printing will print LLVM assembly) to `sampleMod.ll` and have its bitcode be written to `sampleMod.bc`. Note that the printed `.ll` file is text, and will show you the exact code you are generating.

### Part 2 - A Simple Function
Create a function named `simple`. It takes no parameters, and returns a 32-bit integer. Have it return 0. Use `llvm::verifyFunction(*FUNC_HERE);` after you are done building a function to check for errors.

### Part 3 - Addition Function
Create a function named `add` that takes two 32-bit integers and returns the sum of them (a 32-bit integer).

### Part 4 - Addition Function: With A Twist!
Create a function named `addIntFloat` that has the first parameter be a 32-bit integer and the second parameter be a float. The function should return a float. Note that there are different types of casts to float, you can assume the input integer is signed.

### Part 5 - Branching, Stack Variables, And Booleans Oh My!
Adding things together in a linear fashion is fun, but what about temporary variables and control flow? Create a function called `conditional`, it will take a boolean input (1-bit integer) and output a 32-bit integer. Allocate a mutable variable stored on the stack in the entry block. If the input parameter is true, store a `3` to the variable, else store a `5`. Using only one add instruction in the entire function, return the value of the stored variable added with `11`. The function should return `14` if the parameter is true or `16` if it is false. **DO NOT OPTIMIZE THIS FUNCTION YOURSELF.** The point of this part is to make sure you understand control flow and mutable stack variables.

### Part 6 - Time To Count To Phi
Do the last part again, except name the function `oneTwoPhi` and do it with phi nodes instead.

### Part 7 - Select Again?
Do the last part again, except name the function `selection` and do it with the `select` instruction instead.

### Part 8 - Optimization
Add an LLVM legacy function pass manager `llvm::legacy::FunctionPassManager`. Add the `llvm::createPromoteMemoryToRegisterPass()`, `llvm::createReassociatePass()`, `llvm::createGVNPass()`, and `llvm::createCFGSimplificationPass()` passes and run it on the 6 functions you created earlier. What was the effect of these passes on each of the 6 functions?

### Part 9 - What's Next
By now, you should have a decent base knowledge of generating code with LLVM. Note that the below items are completely optional, but they can give you ideas on what you can do:
* Make hello world in LLVM.
* Make a function's arguments mutable local to the function by storing them into stack variables.
* Declare the `malloc` and `free` functions and call them in different functions to play with heap memory.
* Make a while or for loop with LLVM.
* Play around with struct types.
* Create a basic calculator interpreter program.

## LLVM 101
Before the days of high-level programming, programmers used machine instructions directly (assembly).
This assembly language is specific to whatever processor is present in the machine being programmed for.
Higher-level languages such as C abstract these low-level assembly instructions to be processor-agnostic (I know C is low-level, but it's higher than assembly).
This C can then be compiled back into machine instructions depending on the target processor.
LLVM is a compiler framework that allows you to make processor-agnostic code.
But how does it do this? Picking a base such as C would be choosing favorites (C is very different than Basic or Rust).
LLVM thus utilizes an assembly-like language to accomplish this.

### The LLVM Language
LLVM isn't quite assembly, there are some differences.
* There is a dedicated type system. It supports integers, floating-point numbers, structures, pointers, etc.
* Functions exist and have formal listings of arguments and return types.
* While most processors have a limited set of registers, LLVM has INFINITE registers. Sounds crazy, but the next point really mellows this out.
* LLVM uses Single State Assignment (SSA). That means that once a register is assigned a value, its value can never be assigned again (read-only). A register must also be declared before being used, see [this GeeksForGeeks post](https://www.geeksforgeeks.org/static-single-assignment-with-relevant-examples/).
* Please see [the language reference manual](https://llvm.org/docs/LangRef.html). It is an invaluable resource that describes the usage of LLVM instructions to create with an instruction builder.
* LLVM can output bitcode in a hexfile or print assembly in text. LLVM bitcode files can be compiled with clang to an object file or executable, and even linked with functions in other languages like C!

### How An LLVM Program Is Structured
We don't type out raw LLVM assembly, that's lame. Instead we use the LLVM API to generate the assembly for us. A typical program has these components:
* Context - Way of interacting with the divine kingdom of LLVM.
* Module - A compilation unit containing functions. Think of a compilation unit as a single source code file (.c or .cpp file as an example).
* Function - Code that takes in input values and returns a value as a result (void counts as an output value). A function is declared if it has no body (no basic blocks to it). A function is defined if it has at least one basic block to it. A declaration is a pinky-promise to the compiler that if you use the function, its implementation exists somewhere (it is the job of the linker to see if you're an honest person). A declaration means you are defining what the function does (and therefore a defined function always has an implementation so the linker can't bother you unless you define the same function twice).
* Basic Block - Parts that make up a function. The first block of a function is called the `entry` block and is where the code of the function starts. **IMPORTANT:** Every basic block must have *one* branch or return instruction at the end of the block!
* Builder - Can be placed at basic blocks and insert instructions to them.

### Control Flow With LLVM
LLVM does not provide fancy tools such as loops, if statements, etc. so how does control flow work?
LLVM can do function calls built in luckily, but for control flow it relies on branching (kinda like goto).
Loops and if statements get desugared to this branching method.

If example:
```cpp
// Normal.
if (condition)
    doThing();
else
    doOtherThing();
return doFinalThing();

// Desugared.
entry:
    if condition goto doThen else goto doElse; // LLVM has conditional branches to mimic this functionality.

doThen:
    doThing();
    goto doContinue;

doElse:
    doOtherThing();
    goto doContinue;

doContinue:
    return doFinalThing();
```

While loop example:
```cpp
// Normal.
int i = 0;
while (i < 7)
{
    doThing();
    i++;
}

// Desugared.
int i = 0;
goto whileCond;

whileCond:
    if (i < 7) goto whileBody else goto whileEnd;

whileBody:
    doThing();
    i++;
    goto whileCond;

whileEnd:
```

With some imagination, any other type of control flow can be desugared to this form. Keep this in mind for the next assignment :}

### Heap Memory
In LLVM, you don't have heap memory provided by the API. You only get stack memory. Heap memory functions such as `malloc` are platform-dependent as implemented by the C standard library. You could declare the `malloc` function, and clang will link it for you when you try and compile the bitcode to object code. You can use heap memory as normal, just note that it's nothing built in.

### Stack Memory
If you can only write to a register once, how do you have mutable variables such as:

```cpp
int a = 3;
a = 5;
return a;
```

The rule is we can write to a register once, but there's a trick. What if we allocate stack memory for a variable, then give a pointer its register value? Technically this follows SSA form, and that's how we have mutable variables in LLVM. We allocate stack memory and get a pointer to it by using the `alloca` [instruction](https://llvm.org/docs/LangRef.html#alloca-instruction). If our generated LLVM code looked liked C++, it would look something like this:

```cpp
int* a = alloca(sizeof(int));
*a = 3;
*a = 5;
return *a;
```

Note that we are never changing the value of `a`, we are changing the value stored at it. We can use LLVM's load and store instructions for this purpose.

Stack memory is not as efficient as using registers though. Luckily, there is an optimization pass (mem2reg) that takes care of this for it, so we can use all the stack memory we want (as long as it is allocated in the first block of the function). Alternatively, we can use phi nodes.

### Phi Nodes
Given the nature of SSA form, it is impossible to assign to the same register twice. However, say we have a situation like this:

```cpp
int a;

if (x < y) a = 3;
else if (x > y) a = 5;
else a = 7;
```

A phi node would look something like this:

```cpp
// INSERT BRANCH LOGIC HERE!

xLessThanY:
    goto collect;

xGreaterThanY:
    goto collect;

xEqualToY:
    goto collect;

collect:
    a = phi({{ xLessThanY, 3 }, { xGreaterThanY, 5 }, { xEqualToY, 7 }});
```

A phi node has to be the first instruction of a basic block (if there is a phi node).
A phi node is able to assign a value to a register depending on what was the previous basic block before it.

### LLVM Gotchya's
Below are some common mistakes using LLVM.
* Any operation (such as addition) must operate on the *same* types. Ex: You can only add two 32-bit integers or two 64-bit floats, not a 32-bit int and a 64-bit int.
* A FPCast is not the same SIToFP or UIToFP. Please make sure to look at the [language reference](https://llvm.org/docs/LangRef.html#alloca-instruction) to understand the different types of casts.
* A basic block must always have a single ending (as in you have to either return a value or branch to another block). This means a block will either end with a `br`, conditional `br`, or `ret`. If you do not have exactly one of those options, bad things can happen.
* Be careful of the order of arguments to LLVM's load and store instructions! For loads you give the type to retrieve then the pointer to stack memory, and for stores you give the value to store *then* the pointer to stack memory.
* Any stack allocations should be done in the entry block. The optimizer will not promote inefficient stack memory usage to registers if done in a different block.
* LLVM does NOT have name mangling. This means that two functions with the same name but different signature can be confused to be the same function. If you try to make a function with the same name to your module, LLVM makes it unique (which is probably not what you want). Function overloading is a complex topic, to learn more about its rules read a C++ specification. In order to prevent name conflicts with functions of different signatures in high level languages, a mangling scheme is used to change the name of a function. The [CodeWarrior Mangling Scheme](https://github.com/bfbbdecomp/bfbb/blob/master/docs/WalkthroughAndTips.md#name-mangling-translation) is a more simple example of one.

### FAQ
Below you can find some frequent questions with answers.

#### All This LLVM Theory Stuff Is Cool, But Where Can I See Some Sample Code?
The [LLVM Kaleidoscope Tutorial](https://llvm.org/docs/tutorial/index.html) has sample code available. Sections 3+ should have areas of interest.

#### I'm Still Confused, Give Me Some Code
Here's some helpful LLVM calls:
```cpp
// Create an LLVM module with a given name. context is type llvm::LLVMContext.
llvm::Module mod("MODULE_NAME", context);

// Write a bitcode file to an output stream. outBc is type llvm::raw_fd_ostream.
llvm::WriteBitcodeToFile(mod, outBc);

// Create an instruction builder. This can be positioned at basic blocks and insert instructions as well. This can be reused throughout every function in the assignment.
llvm::IRBuilder<> builder(context);

// Sample way of creating a function. This function returns a 32-bit integer, and takes a 64-bit integer and floating point number as a parameter. The false means that it's not variadic, meaning it doesn't take infinite extra arguments.
llvm::Function* myFunc = llvm::Function::Create(
    llvm::FunctionType::get(llvm::Type::getInt32Ty(context), {llvm::Type::getInt64Ty(context), llvm::Type::getFloatTy(context)}, false),
    llvm::GlobalValue::LinkageTypes::ExternalLinkage,               // Really any linkage that just shows up in the bitcode works.
    "myFuncName",                                                   // Name of our function in the bitcode.
    &mod                                                            // Pointer to module to create the function in.
);

// Adding a basic block to a function. The first one should be entry.
llvm::BasicBlock* myFuncBlock = llvm::BasicBlock::Create(context, "entry", myFunc);

// Positioning a builder at a block.
builder.SetInsertPoint(myFuncBlock);

// Return the first argument minus the second argument. The CreateSub function expects the arguments to have the same type.
builder.CreateRet(builder.CreateSub(subFunc->getArg(0), subFunc->getArg(1)));

// Get a constant 32-bit integer of value 7.
llvm::Value* val7 = llvm::ConstantInt::get(llvm::Type::getInt32Ty(context), 7);
```