#include "metalComputer.hpp"

#define NS_PRIVATE_IMPLEMENTATION
#define CA_PRIVATE_IMPLEMENTATION
#define MTL_PRIVATE_IMPLEMENTATION
#include <Foundation/Foundation.hpp>
#include <Metal/Metal.hpp>
#include <QuartzCore/QuartzCore.hpp>
#include <iostream>

MetalComputer::MetalComputer(int32_t nRows, int32_t nCols, double cell_size)
:mRows(nRows), mCols(nCols), cellSize(cell_size)
{
    pPool   = (NS::AutoreleasePool*) NS::AutoreleasePool::alloc()->init();
    mDevice = (MTL::Device*) MTL::CreateSystemDefaultDevice();
    
    // Initialize input grid (moved from CppMetalComputer)
    mInputGrid = new uint8_t[mRows * mCols];
    populateWithRandomBools(mInputGrid);
    
    initWithDevice();
    initDataVars();
    
    // Populate the texture with initial data
    populateInputTexture(mInputGrid);
}

MetalComputer::~MetalComputer()
{
    delete[] mInputGrid;
    delete[] mOutPixels;
}

void MetalComputer::populateWithRandomBools(uint8_t *data)
{
    srand((uint8_t)7);
    for (int i = 0; i < mRows * mCols; ++i)
    {
        // Generate a random boolean value
        bool randomBool = rand() % 2;

        // Store 1 or 0 in inputData based on randomBool
        data[i] = randomBool ? 1 : 0;
    }
}

void MetalComputer::initWithDevice() {
    NS::Error* error;
    MTL::Device* pDevice = (MTL::Device*) mDevice;
    
    auto defaultLibrary = pDevice->newDefaultLibrary();
    
    if (!defaultLibrary) {
        std::cerr << "Failed to find the default library.\n";
        exit(-1);
    }
    
    auto functionName = NS::String::string("gameOfLifeKernel2d", NS::ASCIIStringEncoding);
    auto computeFunction = defaultLibrary->newFunction(functionName);
    
    if(!computeFunction){
        std::cerr << "Failed to find the compute function.\n";
    }
    
    mComputeFunctionPSO = pDevice->newComputePipelineState(computeFunction, &error);
    
    if (!computeFunction) {
        std::cerr << "Failed to create the pipeline state object.\n";
        exit(-1);
    }
    
    mCommandQueue = pDevice->newCommandQueue();
    
    if (!mCommandQueue) {
        std::cerr << "Failed to find command queue.\n";
        exit(-1);
    }
}
    
void MetalComputer::initDataVars() {
    MTL::Device* pDevice = (MTL::Device*) mDevice;
    
    // Allocate three buffers to hold our initial data and the result.mCommandQueue
    mInputBuffer = pDevice->newBuffer(sizeof(uint8_t) * mRows * mCols, MTL::ResourceStorageModeShared);
    mOutputBuffer = pDevice->newBuffer(sizeof(uint8_t) * mRows * mCols, MTL::ResourceStorageModeShared);
    
    MTL::TextureDescriptor* textureDescriptor = MTL::TextureDescriptor::alloc()->init();
    textureDescriptor->setPixelFormat(MTL::PixelFormatR8Uint);
    textureDescriptor->setWidth(mCols);
    textureDescriptor->setHeight(mRows);
    textureDescriptor->setDepth(1);
    textureDescriptor->setTextureType(MTL::TextureType2D);
    textureDescriptor->setStorageMode(MTL::StorageModeShared);
    textureDescriptor->setUsage(MTL::ResourceStorageModeShared);
    
    mInputTexture = pDevice->newTexture(textureDescriptor);
    mOutputTexture = pDevice->newTexture(textureDescriptor);
    
    textureDescriptor->release();
}

void MetalComputer::encodeComputeCommand(void* computeEncoder_) {
    
    MTL::ComputeCommandEncoder * computeEncoder  = (MTL::ComputeCommandEncoder*)computeEncoder_;
    
    MTL::ComputePipelineState* pComputeFunctionPSO = (MTL::ComputePipelineState*)mComputeFunctionPSO;
    
    // Encode the pipeline state object and its parameters.
    computeEncoder->setComputePipelineState(pComputeFunctionPSO);

    computeEncoder->setTexture((MTL::Texture*) mInputTexture, 0);
    computeEncoder->setTexture((MTL::Texture*) mOutputTexture, 1);
    
    long w = pComputeFunctionPSO->threadExecutionWidth();
    long h = pComputeFunctionPSO->maxTotalThreadsPerThreadgroup() / w;
    MTL::Size threadsPerThreadgroup = MTL::Size(w,h,1);
    
    MTL::Size threadsPerGrid = MTL::Size(mCols, mRows, 1);

    // Encode the compute command.
    computeEncoder->dispatchThreads(threadsPerGrid, threadsPerThreadgroup);
}

void MetalComputer::populateInputTexture(uint8_t* _inputBuffer){
    MTL::Texture* pInputTexture = (MTL::Texture*) mInputTexture;
    
    MTL::Buffer* pInputBuffer = (MTL::Buffer*) mInputBuffer;
    uint8_t* tempBuffer = (uint8_t*) pInputBuffer->contents();
    
    int k=0;
    //copy contents of _input buffer into tempBuffer. True is 1 and false is 0
    for (int i = 0; i < mRows; i++) {
        for (int j = 0; j < mCols; j++) {
            tempBuffer[k++] = _inputBuffer[i * mCols + j];
        }
    }
    
    pInputTexture->replaceRegion(MTL::Region(0, 0, 0, mCols, mRows, 1), 0, tempBuffer, mCols*sizeof(uint8_t));
}

float* MetalComputer::update(){
    sendComputeCommand();
    float* retVal = getDataPointer();
    swapInputWithOutput();
    return retVal;
}

void MetalComputer::sendComputeCommand() {
    // Create a command buffer to hold commands.
    MTL::CommandBuffer* commandBuffer = ((MTL::CommandQueue*)mCommandQueue)->commandBuffer();
    assert(commandBuffer != nullptr);
    
    // Start a compute pass.
    MTL::ComputeCommandEncoder* computeEncoder = commandBuffer->computeCommandEncoder();
    assert(computeEncoder != nullptr);
    
    encodeComputeCommand(computeEncoder);
    
    // End the compute pass.
    computeEncoder->endEncoding();
    
    // Execute the command.
    commandBuffer->commit();
    
    // Normally, you want to do other work in your app while the GPU is running,
    // but in this example, the code simply blocks until the calculation is complete.
    commandBuffer->waitUntilCompleted();

}


float* MetalComputer::getDataPointer(){
    
    MTL::Texture* pOutputTexture = (MTL::Texture*) mOutputTexture;
    
    MTL::Buffer* tempBuffer = (MTL::Buffer*) mOutputBuffer;
    
    MTL::CommandBuffer* commandBuffer = ((MTL::CommandQueue*)mCommandQueue)->commandBuffer();
    MTL::BlitCommandEncoder* blitEncoder = commandBuffer->blitCommandEncoder();
    
    blitEncoder->copyFromTexture(pOutputTexture,
                                 0,
                                 0,
                                 MTL::Origin(0, 0, 0),
                                 MTL::Size(mCols,mRows, 1),
                                 tempBuffer,
                                 0,
                                 sizeof(uint8_t)*mCols,
                                 sizeof(uint8_t)*mRows*mCols);
    
    blitEncoder->endEncoding();
    commandBuffer->commit();
    commandBuffer->waitUntilCompleted();
    
    uint8_t* tempOut = (uint8_t*) tempBuffer->contents();
    
    if(mOutPixels != nullptr)
    {
        delete [] mOutPixels;
        mOutPixels = nullptr;
    }
    if(mOutPixels == nullptr){
        mOutPixels = new float[mRows * mCols *2]();
        int k=0;
        for (int y = 0; y < mRows; y++) {
            for (int x = 0; x < mCols; x++) {
                if (tempOut[y * mCols + x] == 1) {
                    mOutPixels[k++] = x * cellSize + cellSize / 2;
                    mOutPixels[k++] = y * cellSize + cellSize / 2;
                }
            }
        }
    }
        
    return mOutPixels;
}

void MetalComputer::swapInputWithOutput(){
    //swap intput and output textures
    auto tempTexture = mInputTexture;
    mInputBuffer = mOutputTexture;
    mOutputTexture = tempTexture;
}
