
#include "cppThreadsComputer.hpp"
#include <thread>
#include <mutex>
#include <vector>
#include <ctime>   // For time()
#include <cstdlib> // For rand() and srand()

CppThreadsComputer::CppThreadsComputer(int32_t nRows, int32_t nCols, double cellSize)
: rows(nRows), cols(nCols), cellSize(cellSize)
{
    initData();
    m_pMutex = (void*) new std::mutex();
    m_pThreadsList = (void*) new std::vector<std::thread>(m_numThreads);
}

CppThreadsComputer::~CppThreadsComputer()
{
    delete[] m_pGrid;
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
        // Generate a random boolean value
        bool randomBool = rand() % 2;

        // Store 1.0f or 0.0f in inputData based on randomBool
        m_pGrid[i] = randomBool ? 1 : 0;
    }
}

float* CppThreadsComputer::update(){
    
    //reset to zero
    for(int i=0; i<rows*cols*2;i++){
        m_pAliveLocs[i] = 0.0;
    }

    // Create a new grid for the next generation
    uint8_t* newGrid = new uint8_t[rows * cols];
    
    k=0;
    std::vector<std::thread>* threads = (std::vector<std::thread>*)m_pThreadsList;
    int chunkSize = rows / m_numThreads;

    for (int t = 0; t < m_numThreads; ++t) {
        int startRow = t * chunkSize;
        int endRow = (t == m_numThreads - 1) ? rows : startRow + chunkSize;

        (*threads)[t] = std::thread(&CppThreadsComputer::updateChunk, this, newGrid, startRow, endRow);
    }

    for (auto& th : *threads) {
        th.join();
    }

    auto temp = m_pGrid;
    m_pGrid = newGrid;

    if(temp != nullptr){
        delete[] temp;
        temp = nullptr;
    }
    
    return m_pAliveLocs;
}
void CppThreadsComputer::updateChunk(uint8_t* newGrid, int startRow, int endRow) {
    for (int y = startRow; y < endRow; y++) {
        for (int x = 0; x < cols; x++) {
            // Count the number of live neighbors for the current cell
            int neighbors = countNeighbors(x, y);

            // Check if the current cell is alive
            bool alive = m_pGrid[y * cols + x] == 1.0f;

            // Apply the rules of the Game of Life
            if (alive && (neighbors < 2 || neighbors > 3)) {
                newGrid[y * cols + x] = 0.0f;
            } else if (!alive && neighbors == 3) {
                newGrid[y * cols + x] = 1.0f;
            } else {
                newGrid[y * cols + x] = m_pGrid[y * cols + x];
            }
            
            // If the cell is alive, update its location in m_pAliveLocs
            if (newGrid[y * cols + x] == 1.0f) {
                std::lock_guard<std::mutex> lock(*(std::mutex*)m_pMutex);
                m_pAliveLocs[k++] = x * cellSize + cellSize / 2;
                m_pAliveLocs[k++] = y * cellSize + cellSize / 2;                
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
                count += m_pGrid[ny * cols + nx] == 1.0f ? 1 : 0;
            }
        }
    }
    return count;
}
