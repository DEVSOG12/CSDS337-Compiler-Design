# LLVM-Lab
Guided LLVM tutorial with C subset.

## Details
More information will be provided later.

## DETAILED Setup and Build Instructions for WINDOWS
### Install WSL:
1. Open Powershell as administrator (you can do this by right-clicking *PowerShell* in your start menu, and selecting *Run as administrator*
2. Run `wsl --install` in the command line interface. This will install the Ubuntu distribution of Linux.
3. Restart your computer.
4. Open the app *Ubuntu on Windows*. You should be tasked with setting your username and password.
    > You will have to enter your password periodically when you run a `sudo` (abbreviation of "superuser do") command on linux. When you enter your password, nothing will appear on screen (this is called "blind typing" and is normal), but the machine is still reading your keystrokes.
5. You should regularly update and upgrade your packages by running the commands `sudo apt update` and `sudo apt upgrade`. Do this now.
### Install the required packages:
- Run `sudo apt install clang`. This installs the **CLANG** compilers for C and C++, which are the compilers that LLVM uses.
- Run `sudo apt install make`. This installs the **Make** utility, which is used for directing compilation of projects using "makefiles".
- Run `sudo apt install cmake`. This installs **CMake** utility, which is used to generate the build files.
    > **Build files** are files that describe targets that own the source files.
      **Source files** are files that contain source code, like .cpp or .java files.
- Run `sudo apt install llvm-dev`. This installs the **LLVM** (Low-Level Virtual Machine) package as well as its development package which includes libraries and headers for llvm source code.
- Run `sudo apt install flex`. This installs **Flex** (Fast Lexical Analyzer Generator), which is a program that generates lexical analyzers out of flex code.
- Run `sudo apt install bison`. This installs **Bison** which is a program that generates parsers using the
- Run `sudo apt install graphviz`. This installs the graph visualization software that we will use to visualize control flow and data flow of compiled programs.