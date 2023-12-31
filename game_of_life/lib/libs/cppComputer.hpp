#include <cstdint>

class CppComputer
{
    int8_t *m_pGrid;
    float *m_pAliveLocs;//i_0, j_0, i_1, j_1, ...
    int rows = 0;
    int cols = 0;
    double cellSize = 0;

public:
    CppComputer(int32_t nRows, int32_t nCols, double cellSize);
    ~CppComputer();
    float* update();

private:

    void initData();
    void populateWithBools(int8_t* data);
    int32_t countNeighbors(int x, int y);
};
