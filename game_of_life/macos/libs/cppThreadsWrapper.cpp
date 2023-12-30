#include <cstdint>
#include "cppThreadsComputer.hpp"
#define EXPORT extern "C" __attribute__((visibility("default"))) __attribute__((used))

CppThreadsComputer* cppThreadsComp = nullptr;

EXPORT
void initCppThreads(int nRows, int nCols, double cellSize){
    cppThreadsComp = new CppThreadsComputer(nRows, nCols, cellSize);
}

EXPORT
float* updateCppThreads(){
    auto retVal = cppThreadsComp->update();
    return retVal;
}

EXPORT
void destructCppThreads(){
    delete cppThreadsComp;
    cppThreadsComp = nullptr;
}

