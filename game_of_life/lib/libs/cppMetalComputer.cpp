#include "cppMetalComputer.hpp"
#include <thread>
#include <mutex>
#include <vector>
#include <cstdlib>


CppMetalComputer::CppMetalComputer(int32_t nRows, int32_t nCols, double cellSize)
: rows(nRows), cols(nCols), cellSize(cellSize)
{
    initData();
    populateWithRandomBools(m_pInputGrid);
    computer = new MetalComputer(nRows, nCols, cellSize);
    computer->populateInputTexture(m_pInputGrid);
}

CppMetalComputer::~CppMetalComputer()
{
    delete[] m_pInputGrid;
    delete[] m_pAliveLocs;
    delete computer;

}

void CppMetalComputer::initData()
{
    m_pInputGrid = new uint8_t[rows * cols];
    m_pAliveLocs = new float[rows * cols * 2]();
}

void CppMetalComputer::populateWithRandomBools(uint8_t *data)
{
    srand((uint8_t)7);
    for (int i = 0; i < rows * cols; ++i)
    {
        // Generate a random boolean value
        bool randomBool = rand() % 2;

        // Store 1.0f or 0.0f in inputData based on randomBool
        m_pInputGrid[i] = randomBool ? 1 : 0;
    }
}

float* CppMetalComputer::update(){   
    if(computer != nullptr){
        return  computer->update();
    }
    
    return m_pAliveLocs;
}



