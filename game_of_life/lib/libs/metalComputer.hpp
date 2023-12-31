#include <cstdlib>

class MetalComputer{

private:
    int32_t mRows = 100;
    int32_t mCols = 100;
    double cellSize = 0;
    
    //(NS::AutoreleasePool*)
    void* pPool = nullptr;
    
//    (MTL::Device*)
    void* mDevice = nullptr;
    
//    // The compute pipeline generated from the compute kernel in the .metal shader file.
//    (MTL::ComputePipelineState*)
    void* mComputeFunctionPSO;
    
//    // The command queue used to pass commands to the device.
//    (MTL::CommandQueue*)
    void* mCommandQueue;

    
//    (MTL::Buffer*)
    void* mInputBuffer;
    void* mOutputBuffer;//holding mOutPixels
    
//    (MTL::Texture*)
    void* mInputTexture;
    void* mOutputTexture;
    
    float* mOutPixels = nullptr;

    
private:
    void initWithDevice() ;
    void initDataVars() ;
    void encodeComputeCommand(void* computeEncoder_);
    
    void sendComputeCommand();
    float* getDataPointer();
    void swapInputWithOutput();
    
public:
    MetalComputer(int32_t nRows, int32_t nCols, double cellSize);
    void populateInputTexture(uint8_t* inputBuffer);
    float* update();
};
