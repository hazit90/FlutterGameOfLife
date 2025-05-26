#include <cstdint>
#include <atomic>
#include <vector>
#include <utility>

class CppThreadsComputer
{
    uint8_t *m_pGrid;
    uint8_t *m_pNewGrid;  // Pre-allocated grid for next generation
    float *m_pAliveLocs;
    int rows = 0;
    int cols = 0;
    int m_numThreads = 5;//seems to give the best performance for Apple m1 max
    double cellSize = 0;

    
private:
    void* m_pMutex;
    void* m_pThreadsList;

public:
    CppThreadsComputer(int32_t nRows, int32_t nCols, double cellSize);
    ~CppThreadsComputer();
    float* update();

private:
    void initData();
    void populateInputGridWithBools();
    int32_t countNeighbors(int x, int y);
    int32_t countNeighborsBounds(int x, int y);
    void updateChunk(int startRow, int endRow, std::atomic<int>& aliveCounter);
    void updateChunkLockFree(int startRow, int endRow, std::vector<std::pair<float, float>>& result);
};
