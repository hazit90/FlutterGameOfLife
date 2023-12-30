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
