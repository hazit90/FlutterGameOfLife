#include <metal_stdlib>
using namespace metal;

kernel void gameOfLifeKernel(texture2d<float, access::read> inputGrid [[texture(0)]],
                             texture2d<float, access::write> outputGrid [[texture(1)]],
                             uint2 gid [[thread_position_in_grid]]) {
    // Get the dimensions of the texture.
    const uint width = inputGrid.get_width();
    const uint height = inputGrid.get_height();

    // Count the number of live neighbors.
    int liveNeighbors = 0;
    for (int y = -1; y <= 1; y++) {
        for (int x = -1; x <= 1; x++) {
            if (x == 0 && y == 0) continue; // Skip the cell itself.

            // Calculate neighbor position with wrapping.
            int nx = (gid.x + x + width) % width;
            int ny = (gid.y + y + height) % height;

            // Read the state of the neighbor and update the count.
            float4 neighborState = inputGrid.read(uint2(nx, ny));
            liveNeighbors += neighborState.r > 0.5 ? 1 : 0; // Assuming live cells are represented with values > 0.5.
        }
    }

    // Read the current state of the cell.
    float4 currentState = inputGrid.read(gid);

    // Apply the Game of Life rules.
    bool isAlive = currentState.r > 0.5;
    bool nextState = false;
    if (isAlive && (liveNeighbors < 2 || liveNeighbors > 3)) {
        nextState = false; // Dies due to underpopulation or overpopulation.
    } else if (!isAlive && liveNeighbors == 3) {
        nextState = true; // Becomes alive due to reproduction.
    } else {
        nextState = isAlive; // Remains in the current state.
    }

    // Write the new state to the output grid.
    outputGrid.write(nextState ? 1.0 : 0.0, gid);

}

kernel void gameOfLifeKernel2d(texture2d<uint, access::read> inputGrid [[texture(0)]],
                               texture2d<uint, access::write> outputGrid [[texture(1)]],
                               uint2 gid [[thread_position_in_grid]]) {
    // Get the dimensions of the texture.
    const uint width = inputGrid.get_width();
    const uint height = inputGrid.get_height();

    // Count the number of live neighbors.
    int liveNeighbors = 0;
    for (int y = -1; y <= 1; y++) {
        for (int x = -1; x <= 1; x++) {
            if (x == 0 && y == 0) continue; // Skip the cell itself.

            // Calculate neighbor position with wrapping.
            int nx = (gid.x + x + width) % width;
            int ny = (gid.y + y + height) % height;

            // Read the state of the neighbor and update the count.
            uint neighborState = inputGrid.read(uint2(nx, ny)).r;
            liveNeighbors += neighborState > 0 ? 1 : 0; // Assuming live cells are represented with non-zero values.
        }
    }

    // Read the current state of the cell.
    uint currentState = inputGrid.read(gid).r;

    // Apply the Game of Life rules.
    bool isAlive = currentState > 0;
    bool nextState = false;
    if (isAlive && (liveNeighbors < 2 || liveNeighbors > 3)) {
        nextState = false; // Dies due to underpopulation or overpopulation.
    } else if (!isAlive && liveNeighbors == 3) {
        nextState = true; // Becomes alive due to reproduction.
    } else {
        nextState = isAlive; // Remains in the current state.
    }

    // Write the new state to the output grid.
    outputGrid.write(nextState ? 1u : 0u, gid);
}

kernel void gameOfLifeKernelOptimized(texture2d<uint, access::read> inputGrid [[texture(0)]],
                                      texture2d<uint, access::write> outputGrid [[texture(1)]],
                                      uint2 gid [[thread_position_in_grid]]) {
    // Get dimensions once
    const uint2 dimensions = uint2(inputGrid.get_width(), inputGrid.get_height());
    
    // Early exit for out-of-bounds threads
    if (gid.x >= dimensions.x || gid.y >= dimensions.y) return;
    
    // Precompute wrapped coordinates (avoid modulo in loop)
    const int2 pos = int2(gid);
    const int2 dim = int2(dimensions);
    
    // Count neighbors with unrolled loop for better performance
    uint liveNeighbors = 0;
    
    // Unroll the 3x3 neighborhood loop with inline wrapping
    liveNeighbors += inputGrid.read(uint2((pos.x - 1 + dim.x) % dim.x, (pos.y - 1 + dim.y) % dim.y)).r;
    liveNeighbors += inputGrid.read(uint2((pos.x     + dim.x) % dim.x, (pos.y - 1 + dim.y) % dim.y)).r;
    liveNeighbors += inputGrid.read(uint2((pos.x + 1 + dim.x) % dim.x, (pos.y - 1 + dim.y) % dim.y)).r;
    liveNeighbors += inputGrid.read(uint2((pos.x - 1 + dim.x) % dim.x, (pos.y     + dim.y) % dim.y)).r;
    // Skip center cell
    liveNeighbors += inputGrid.read(uint2((pos.x + 1 + dim.x) % dim.x, (pos.y     + dim.y) % dim.y)).r;
    liveNeighbors += inputGrid.read(uint2((pos.x - 1 + dim.x) % dim.x, (pos.y + 1 + dim.y) % dim.y)).r;
    liveNeighbors += inputGrid.read(uint2((pos.x     + dim.x) % dim.x, (pos.y + 1 + dim.y) % dim.y)).r;
    liveNeighbors += inputGrid.read(uint2((pos.x + 1 + dim.x) % dim.x, (pos.y + 1 + dim.y) % dim.y)).r;
    
    // Read current state
    uint currentState = inputGrid.read(gid).r;
    
    // Optimized Game of Life rules using bitwise operations
    // Rule: alive if (alive && neighbors == 2) || neighbors == 3
    uint nextState = ((currentState & (liveNeighbors == 2)) | (liveNeighbors == 3)) ? 1u : 0u;
    
    outputGrid.write(nextState, gid);
}

// Even more optimized version using shared memory (if supported)
kernel void gameOfLifeKernelShared(texture2d<uint, access::read> inputGrid [[texture(0)]],
                                   texture2d<uint, access::write> outputGrid [[texture(1)]],
                                   uint2 gid [[thread_position_in_grid]],
                                   uint2 tid [[thread_position_in_threadgroup]],
                                   uint2 groupId [[threadgroup_position_in_grid]]) {
    
    // Use threadgroup memory to cache a tile of the grid
    threadgroup uint sharedTile[18][18]; // 16x16 + 1-pixel border
    
    const uint2 dimensions = uint2(inputGrid.get_width(), inputGrid.get_height());
    const uint2 groupStart = groupId * 16;
    
    // Load data into shared memory (including borders)
    for (uint i = tid.y; i < 18; i += 16) {
        for (uint j = tid.x; j < 18; j += 16) {
            uint2 globalPos = uint2((groupStart.x + j - 1 + dimensions.x) % dimensions.x,
                                   (groupStart.y + i - 1 + dimensions.y) % dimensions.y);
            sharedTile[i][j] = inputGrid.read(globalPos).r;
        }
    }
    
    threadgroup_barrier(mem_flags::mem_threadgroup);
    
    if (gid.x >= dimensions.x || gid.y >= dimensions.y) return;
    
    // Count neighbors from shared memory
    uint2 localPos = tid + 1; // Account for border
    uint liveNeighbors = sharedTile[localPos.y-1][localPos.x-1] +
                        sharedTile[localPos.y-1][localPos.x] +
                        sharedTile[localPos.y-1][localPos.x+1] +
                        sharedTile[localPos.y][localPos.x-1] +
                        sharedTile[localPos.y][localPos.x+1] +
                        sharedTile[localPos.y+1][localPos.x-1] +
                        sharedTile[localPos.y+1][localPos.x] +
                        sharedTile[localPos.y+1][localPos.x+1];
    
    uint currentState = sharedTile[localPos.y][localPos.x];
    uint nextState = ((currentState & (liveNeighbors == 2)) | (liveNeighbors == 3)) ? 1u : 0u;
    
    outputGrid.write(nextState, gid);
}
