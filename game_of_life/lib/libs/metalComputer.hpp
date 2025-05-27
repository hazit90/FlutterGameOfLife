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
    uint8_t* mInputGrid = nullptr;  // Added from CppMetalComputer
    
private:
    void initWithDevice() ;
    void initDataVars() ;
    void encodeComputeCommand(void* computeEncoder_);
    
    void sendComputeCommand();
    float* getDataPointer();
    void swapInputWithOutput();
    void populateWithRandomBools(uint8_t* data);  // Added from CppMetalComputer
    
public:
    MetalComputer(int32_t nRows, int32_t nCols, double cellSize);
    ~MetalComputer();  // Add destructor
    void populateInputTexture(uint8_t* inputBuffer);
    float* update();
};
