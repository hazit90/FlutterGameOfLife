#include <cstdint>

class CppThreadsComputer
{
    uint8_t *m_pGrid;
    float *m_pAliveLocs;//i_0, j_0, i_1, j_1, ...
    int rows = 0;
    int cols = 0;
    int m_numThreads = 32;//seems to give the best performance for Apple m1 max
    double cellSize = 0;

    
private:
    int k=0;
    
    //std::mutex*
    void* m_pMutex;
    
    //std::vector<std::thread>*
    void* m_pThreadsList;

public:
    CppThreadsComputer(int32_t nRows, int32_t nCols, double cellSize);
    ~CppThreadsComputer();
    float* update();

private:

    void initData();
    void populateInputGridWithBools();
    int32_t countNeighbors(int x, int y);
    void updateChunk(uint8_t* newGrid, int startRow, int endRow);
};
