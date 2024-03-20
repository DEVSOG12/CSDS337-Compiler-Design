// File to make sure functions generated are working :}
#include <cassert>
#include <iostream>

// We can declare that these functions exist, and pass your bitcode file to clang along with this and the linker will magically put your implementations here. How cool is that?
extern "C"
{
    int simple();
    int add(int, int);
    float addIntFloat(int, float);
    int conditional(bool);
    int oneTwoPhi(bool);
    int selection(bool);
}

int main()
{
    assert(simple() == 0);
    assert(add(5, -7) == -2);
    assert(addIntFloat(4, 32.4f) == 36.4f);
    assert(conditional(false) == 16);
    assert(conditional(true) == 14);
    assert(oneTwoPhi(false) == 16);
    assert(oneTwoPhi(true) == 14);
    assert(selection(false) == 16);
    assert(selection(true) == 14);
    std::cout << "All Tests Passed! Good Job!" << std::endl;
    return 0;
}