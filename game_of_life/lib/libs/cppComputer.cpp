#include "cppComputer.hpp"
#include <ctime>   // For time()
#include <cstdlib> // For rand() and srand()
#include <cstring> // For memset

CppComputer::CppComputer(int32_t nRows, int32_t nCols, double cellSize)
: rows(nRows), cols(nCols), cellSize(cellSize)
{
    initData();
}

CppComputer::~CppComputer()
{
    delete[] m_pGrid;
    delete[] m_pNewGrid;
    delete[] m_pAliveLocs;
}

void CppComputer::initData()
{
    m_pGrid = new uint8_t[rows * cols];
    m_pNewGrid = new uint8_t[rows * cols];  // Pre-allocate second grid
    populateWithBools();
    m_pAliveLocs = new float[rows * cols * 2];
}

void CppComputer::populateWithBools()
{
    srand(7);  // Use consistent seed, no cast needed
    for (int i = 0; i < rows * cols; ++i)
    {
        m_pGrid[i] = rand() % 2;  // Direct assignment, no ternary needed
    }
}

float* CppComputer::update(){
    // Reset alive locations to zero using memset (faster)
    memset(m_pAliveLocs, 0, rows * cols * 2 * sizeof(float));

    // Index for tracking the alive cells
    int k = 0;

    // Loop through each cell in the grid
    for (int y = 0; y < rows; y++) {
        for (int x = 0; x < cols; x++) {
            int idx = y * cols + x;
            
            // Count neighbors for current cell
            int neighbors = countNeighbors(x, y);
            
            // Current cell state
            uint8_t currentCell = m_pGrid[idx];
            
            // Apply Game of Life rules with simplified logic
            uint8_t newState;
            if (currentCell) {
                // Alive cell: survives if 2 or 3 neighbors
                newState = (neighbors == 2 || neighbors == 3) ? 1 : 0;
            } else {
                // Dead cell: becomes alive if exactly 3 neighbors
                newState = (neighbors == 3) ? 1 : 0;
            }
            
            m_pNewGrid[idx] = newState;
            
            // If cell is alive, add to alive locations
            if (newState) {
                m_pAliveLocs[k++] = x * cellSize + cellSize * 0.5f;
                m_pAliveLocs[k++] = y * cellSize + cellSize * 0.5f;
            }
        }
    }
    
    // Swap grids (much faster than delete/new)
    uint8_t* temp = m_pGrid;
    m_pGrid = m_pNewGrid;
    m_pNewGrid = temp;
    
    return m_pAliveLocs;
}

int32_t CppComputer::countNeighbors(int x, int y){
    int32_t count = 0;
    
    // Optimized neighbor counting with bounds checking
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
