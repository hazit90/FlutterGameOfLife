#include <cstdint>
#include <vector>
#include <mutex>
#include "metalComputer.hpp"

class CppMetalComputer
{
    uint8_t *m_pInputGrid;
    float *m_pAliveLocs;//i_0, j_0, i_1, j_1, ...ve
    int rows = 0;
    int cols = 0;

    
private:
    int k=0;
    double cellSize = 0;
    MetalComputer* computer;


public:
    CppMetalComputer(int32_t nRows, int32_t nCols, double cellSize);
    ~CppMetalComputer();
    float* update();
    
private:

    void initData();
    void populateWithRandomBools(uint8_t* data);
    int32_t countNeighbors(int x, int y);
};
