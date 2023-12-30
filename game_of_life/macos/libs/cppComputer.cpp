
#include "cppComputer.hpp"
#include <ctime>   // For time()
#include <cstdlib> // For rand() and srand()

CppComputer::CppComputer(int32_t nRows, int32_t nCols, double cellSize)
: rows(nRows), cols(nCols), cellSize(cellSize)
{
    initData();
}

CppComputer::~CppComputer()
{
    delete[] m_pGrid;
    delete[] m_pAliveLocs;
}

void CppComputer::initData()
{
    m_pGrid = new int8_t[rows * cols];
    populateWithBools(m_pGrid);
    m_pAliveLocs = new float[rows * cols * 2];
}

void CppComputer::populateWithBools(int8_t *data)
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

float* CppComputer::update(){
    int8_t* input = m_pGrid;

    //reset to zero
    for(int i=0; i<rows*cols*2;i++){
        m_pAliveLocs[i] = 0.0;
    }

    // Create a new grid for the next generation
    int8_t* newGrid = new int8_t[rows * cols];

    // Index for tracking the alive cells in aliveCellsOutput
    int k = 0;

    // Loop through each cell in the grid
    for (int y = 0; y < rows; y++) {
        for (int x = 0; x < cols; x++) {
            // Count the number of live neighbors for the current cell
            int neighbors = countNeighbors(x, y);

            // Check if the current cell is alive
            bool alive = input[y * cols + x] == 1.0f;

            // Apply the rules of the Game of Life
            if (alive && (neighbors < 2 || neighbors > 3)) {
                newGrid[y * cols + x] = 0.0f;
            } else if (!alive && neighbors == 3) {
                newGrid[y * cols + x] = 1.0f;
            } else {
                newGrid[y * cols + x] = input[y * cols + x];
            }
            if (newGrid[y * cols + x] == 1.0f) {
                m_pAliveLocs[k++] = x * cellSize + cellSize / 2;
                m_pAliveLocs[k++] = y * cellSize + cellSize / 2;
            }
        }
    }
    
    auto temp = m_pGrid;
    m_pGrid = newGrid;

    if(temp != nullptr){
        delete[] temp;
        temp = nullptr;
    }
    
    return m_pAliveLocs;
}

int32_t CppComputer::countNeighbors(int x, int y){
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
