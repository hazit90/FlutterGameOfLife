#include "cppThreadsComputer.hpp"
#include <thread>
#include <mutex>
#include <vector>
#include <ctime>   // For time()
#include <cstdlib> // For rand() and srand()
#include <atomic>
#include <iostream>

CppThreadsComputer::CppThreadsComputer(int32_t nRows, int32_t nCols, double cellSize)
: rows(nRows), cols(nCols), cellSize(cellSize), m_numThreads(std::thread::hardware_concurrency()*2)
{
    std::cout << "Using " << m_numThreads << " threads." << std::endl;

    //sleep 500 ms
    std::this_thread::sleep_for(std::chrono::milliseconds(500));    
    
    initData();
    m_pMutex = (void*) new std::mutex();
    m_pThreadsList = (void*) new std::vector<std::thread>(m_numThreads);
    
    // Pre-allocate grid to avoid allocation on each update
    m_pNewGrid = new uint8_t[rows * cols];
}

CppThreadsComputer::~CppThreadsComputer()
{
    delete[] m_pGrid;
    delete[] m_pNewGrid;
    delete[] m_pAliveLocs;
    delete (std::mutex*)m_pMutex;
    delete (std::vector<std::thread>*)m_pThreadsList;
}

void CppThreadsComputer::initData()
{
    m_pGrid = new uint8_t[rows * cols];
    populateInputGridWithBools();
    m_pAliveLocs = new float[rows * cols * 2];
}

void CppThreadsComputer::populateInputGridWithBools()
{
    srand((uint8_t)7);
    for (int i = 0; i < rows * cols; ++i)
    {
        bool randomBool = rand() % 2;
        m_pGrid[i] = randomBool ? 1 : 0;
    }
}

float* CppThreadsComputer::update(){
    memset(m_pAliveLocs, 0, rows * cols * 2 * sizeof(float));
    
    // Pre-allocate per-thread buffers
    std::vector<std::vector<std::pair<float, float>>> threadResults(m_numThreads);
    std::vector<std::thread>* threads = (std::vector<std::thread>*)m_pThreadsList;
    
    int chunkSize = rows / m_numThreads;

    for (int t = 0; t < m_numThreads; ++t) {
        int startRow = t * chunkSize;
        int endRow = (t == m_numThreads - 1) ? rows : startRow + chunkSize;
        
        (*threads)[t] = std::thread(&CppThreadsComputer::updateChunkLockFree, this, 
                                   startRow, endRow, std::ref(threadResults[t]));
    }

    for (auto& th : *threads) {
        th.join();
    }
    
    // Combine results without locks
    int k = 0;
    for (auto& result : threadResults) {
        for (auto& cell : result) {
            if (k + 1 < rows * cols * 2) {
                m_pAliveLocs[k++] = cell.first;
                m_pAliveLocs[k++] = cell.second;
            }
        }
    }

    std::swap(m_pGrid, m_pNewGrid);
    return m_pAliveLocs;
}

void CppThreadsComputer::updateChunkLockFree(int startRow, int endRow, 
                                            std::vector<std::pair<float, float>>& result) {
    result.clear();
    result.reserve((endRow - startRow) * cols / 4); // Estimate
    
    const float halfCell = cellSize * 0.5f;
    
    for (int y = startRow; y < endRow; y++) {
        for (int x = 0; x < cols; x++) {
            int idx = y * cols + x;
            int neighbors = (y > 0 && y < rows - 1 && x > 0 && x < cols - 1) ?
                m_pGrid[(y-1) * cols + (x-1)] + m_pGrid[(y-1) * cols + x] + m_pGrid[(y-1) * cols + (x+1)] +
                m_pGrid[y * cols + (x-1)] +                                   m_pGrid[y * cols + (x+1)] +
                m_pGrid[(y+1) * cols + (x-1)] + m_pGrid[(y+1) * cols + x] + m_pGrid[(y+1) * cols + (x+1)] :
                countNeighborsBounds(x, y);
            
            uint8_t alive = m_pGrid[idx];
            uint8_t newState = alive ? 
                ((neighbors == 2 || neighbors == 3) ? 1 : 0) : 
                ((neighbors == 3) ? 1 : 0);
            
            m_pNewGrid[idx] = newState;
            
            if (newState) {
                result.emplace_back(x * cellSize + halfCell, y * cellSize + halfCell);
            }
        }
    }
}

int32_t CppThreadsComputer::countNeighbors(int x, int y){
    int32_t count = 0;
    for (int i = -1; i <= 1; i++) {
        for (int j = -1; j <= 1; j++) {
            if (i == 0 && j == 0) continue;
            int nx = x + i, ny = y + j;
            if (nx >= 0 && nx < cols && ny >= 0 && ny < rows) {
                count += m_pGrid[ny * cols + nx] == 1 ? 1 : 0;
            }
        }
    }
    return count;
}

int32_t CppThreadsComputer::countNeighborsBounds(int x, int y) {
    int32_t count = 0;
    
    // Optimized bounds checking
    int startY = (y > 0) ? y - 1 : y;
    int endY = (y < rows - 1) ? y + 1 : y;
    int startX = (x > 0) ? x - 1 : x;
    int endX = (x < cols - 1) ? x + 1 : x;
    
    for (int ny = startY; ny <= endY; ny++) {
        for (int nx = startX; nx <= endX; nx++) {
            if (nx == x && ny == y) continue;  // Skip center cell
            count += m_pGrid[ny * cols + nx];
        }
    }
    
    return count;
}