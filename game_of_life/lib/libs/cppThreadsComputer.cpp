#include "cppThreadsComputer.hpp"
#include <thread>
#include <mutex>
#include <vector>
#include <ctime>   // For time()
#include <cstdlib> // For rand() and srand()
#include <atomic>

CppThreadsComputer::CppThreadsComputer(int32_t nRows, int32_t nCols, double cellSize)
: rows(nRows), cols(nCols), cellSize(cellSize)
{
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
    
    // Reset to zero
    for(int i = 0; i < rows * cols * 2; i++){
        m_pAliveLocs[i] = 0.0;
    }
    
    // Use atomic counter for thread-safe indexing
    std::atomic<int> aliveCounter{0};
    
    std::vector<std::thread>* threads = (std::vector<std::thread>*)m_pThreadsList;
    int chunkSize = rows / m_numThreads;

    for (int t = 0; t < m_numThreads; ++t) {
        int startRow = t * chunkSize;
        int endRow = (t == m_numThreads - 1) ? rows : startRow + chunkSize;

        (*threads)[t] = std::thread(&CppThreadsComputer::updateChunk, this, startRow, endRow, std::ref(aliveCounter));
    }

    for (auto& th : *threads) {
        th.join();
    }

    // Swap grids
    std::swap(m_pGrid, m_pNewGrid);
    
    return m_pAliveLocs;
}

void CppThreadsComputer::updateChunk(int startRow, int endRow, std::atomic<int>& aliveCounter) {
    // Local buffer for alive cells to minimize mutex contention
    std::vector<std::pair<float, float>> localAliveCells;
    localAliveCells.reserve((endRow - startRow) * cols); // Reserve space
    
    for (int y = startRow; y < endRow; y++) {
        for (int x = 0; x < cols; x++) {
            int neighbors = countNeighbors(x, y);
            bool alive = m_pGrid[y * cols + x] == 1;

            // Apply Game of Life rules
            if (alive && (neighbors < 2 || neighbors > 3)) {
                m_pNewGrid[y * cols + x] = 0;
            } else if (!alive && neighbors == 3) {
                m_pNewGrid[y * cols + x] = 1;
            } else {
                m_pNewGrid[y * cols + x] = m_pGrid[y * cols + x];
            }
            
            // Collect alive cells locally
            if (m_pNewGrid[y * cols + x] == 1) {
                float cellX = x * cellSize + cellSize / 2;
                float cellY = y * cellSize + cellSize / 2;
                localAliveCells.emplace_back(cellX, cellY);
            }
        }
    }
    
    // Single mutex lock to copy all alive cells
    if (!localAliveCells.empty()) {
        std::lock_guard<std::mutex> lock(*(std::mutex*)m_pMutex);
        int startIdx = aliveCounter.fetch_add(localAliveCells.size() * 2);
        
        for (size_t i = 0; i < localAliveCells.size() && startIdx + i * 2 + 1 < rows * cols * 2; ++i) {
            m_pAliveLocs[startIdx + i * 2] = localAliveCells[i].first;
            m_pAliveLocs[startIdx + i * 2 + 1] = localAliveCells[i].second;
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