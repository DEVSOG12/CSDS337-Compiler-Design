CC = clang
CFLAGS = -Wall -Wextra -Werror
TARGET_ARCH = x86_64-apple-macosx

.PHONY: all clean

run: run.sh
	bash run.sh main

clean: # Remove all file that is not makefile, run.sh and a.c
	rm -f $(filter-out makefile run.sh a.c analysis.ipynb as.py, $(wildcard *))