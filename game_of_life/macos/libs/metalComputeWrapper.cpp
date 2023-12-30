#include <cstdint>
#include "cppMetalComputer.hpp"
#define EXPORT extern "C" __attribute__((visibility("default"))) __attribute__((used))

CppMetalComputer* metalComp = nullptr;


EXPORT
void initMetal(int nRows, int nCols, double cellSize){
    metalComp = new CppMetalComputer(nRows, nCols, cellSize);
}

EXPORT
float* updateMetal(){
    auto retVal = metalComp->update();
    return retVal;
}

EXPORT
void destructMetal(){
    delete metalComp;
    metalComp = nullptr;
}
