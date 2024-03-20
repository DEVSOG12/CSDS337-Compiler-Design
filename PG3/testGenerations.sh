./run.sh
clang testGenerations.cpp sampleMod.bc -o testGenerations -lstdc++ -lm -lpthread -ldl -lc
./testGenerations