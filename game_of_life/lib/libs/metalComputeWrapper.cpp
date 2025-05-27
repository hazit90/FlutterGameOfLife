#include <cstdint>
#include "metalComputer.hpp"  // Changed from cppMetalComputer.hpp
#define EXPORT extern "C" __attribute__((visibility("default"))) __attribute__((used))

MetalComputer* metalComp = nullptr;  // Changed type

EXPORT
void initMetal(int nRows, int nCols, double cellSize){
    metalComp = new MetalComputer(nRows, nCols, cellSize);  // Direct instantiation
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
