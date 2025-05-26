#include "cppComputer.hpp"
#include <ctime>
#include <cstdlib>
#include <cstring>

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
    m_pNewGrid = new uint8_t[rows * cols];
    populateWithBools();
    m_pAliveLocs = new float[rows * cols * 2];
}

void CppComputer::populateWithBools()
{
    srand(7);
    for (int i = 0; i < rows * cols; ++i)
    {
        m_pGrid[i] = rand() % 2;
    }
}

float* CppComputer::update(){
    memset(m_pAliveLocs, 0, rows * cols * 2 * sizeof(float));
    
    int k = 0;
    const float halfCell = cellSize * 0.5f;

    // Process interior cells (no bounds checking needed)
    for (int y = 1; y < rows - 1; y++) {
        for (int x = 1; x < cols - 1; x++) {
            int idx = y * cols + x;
            
            // Fast neighbor count for interior cells
            int neighbors = 
                m_pGrid[(y-1) * cols + (x-1)] + m_pGrid[(y-1) * cols + x] + m_pGrid[(y-1) * cols + (x+1)] +
                m_pGrid[y * cols + (x-1)] +                                   m_pGrid[y * cols + (x+1)] +
                m_pGrid[(y+1) * cols + (x-1)] + m_pGrid[(y+1) * cols + x] + m_pGrid[(y+1) * cols + (x+1)];
            
            uint8_t currentCell = m_pGrid[idx];
            uint8_t newState = currentCell ? 
                ((neighbors == 2 || neighbors == 3) ? 1 : 0) : 
                ((neighbors == 3) ? 1 : 0);
            
            m_pNewGrid[idx] = newState;
            
            if (newState) {
                m_pAliveLocs[k++] = x * cellSize + halfCell;
                m_pAliveLocs[k++] = y * cellSize + halfCell;
            }
        }
    }
    
    // Process border cells with bounds checking
    processBorderCells(k);
    
    // Swap grids
    uint8_t* temp = m_pGrid;
    m_pGrid = m_pNewGrid;
    m_pNewGrid = temp;
    
    return m_pAliveLocs;
}

void CppComputer::processBorderCells(int& k) {
    const float halfCell = cellSize * 0.5f;
    
    // Process top and bottom rows
    for (int x = 0; x < cols; x++) {
        // Top row
        processSingleCell(x, 0, k, halfCell);
        // Bottom row
        if (rows > 1) {
            processSingleCell(x, rows - 1, k, halfCell);
        }
    }
    
    // Process left and right columns (excluding corners already processed)
    for (int y = 1; y < rows - 1; y++) {
        // Left column
        processSingleCell(0, y, k, halfCell);
        // Right column
        if (cols > 1) {
            processSingleCell(cols - 1, y, k, halfCell);
        }
    }
}

void CppComputer::processSingleCell(int x, int y, int& k, float halfCell) {
    int idx = y * cols + x;
    int neighbors = countNeighbors(x, y);
    
    uint8_t currentCell = m_pGrid[idx];
    uint8_t newState = currentCell ? 
        ((neighbors == 2 || neighbors == 3) ? 1 : 0) : 
        ((neighbors == 3) ? 1 : 0);
    
    m_pNewGrid[idx] = newState;
    
    if (newState) {
        m_pAliveLocs[k++] = x * cellSize + halfCell;
        m_pAliveLocs[k++] = y * cellSize + halfCell;
    }
}

int32_t CppComputer::countNeighbors(int x, int y){
    int32_t count = 0;
    
    for (int i = -1; i <= 1; i++) {
        for (int j = -1; j <= 1; j++) {
            if (i == 0 && j == 0) continue;
            int nx = x + i, ny = y + j;
            if (nx >= 0 && nx < cols && ny >= 0 && ny < rows) {
                count += m_pGrid[ny * cols + nx];
            }
        }
    }
    return count;
}
