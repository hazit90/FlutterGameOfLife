#include <cstdint>
#include "cppComputer.hpp"
#define EXPORT extern "C" __attribute__((visibility("default"))) __attribute__((used))

CppComputer* cppComp = nullptr;

EXPORT
void initCpp(int nRows, int nCols, double cellSize){
    cppComp = new CppComputer(nRows, nCols, cellSize);
}

EXPORT
float* updateCpp(){
    auto retVal = cppComp->update();
    return retVal;
}

EXPORT
void destructCpp(){
    delete cppComp;
    cppComp = nullptr;
}

