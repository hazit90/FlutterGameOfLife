package main

/*
#include <stdlib.h>
*/
import "C"
import (
	"math/rand"
	"sync"
	"unsafe"
)

var (
	grid       []int8
	rows, cols int
	cellSize   float64
	aliveLocs  *C.float // Change to C allocated memory
	gridLock   sync.Mutex
	rng        *rand.Rand
)

//export initGo
func initGo(cRows C.int, cCols C.int, cCellSize C.double) {
	gridLock.Lock()
	defer gridLock.Unlock()
	rows = int(cRows)
	cols = int(cCols)
	cellSize = float64(cCellSize)
	grid = make([]int8, rows*cols)

	// Allocate C memory for alive locations
	aliveLocs = (*C.float)(C.malloc(C.size_t(rows * cols * 2 * 4))) // 4 bytes per float

	rng = rand.New(rand.NewSource(7))
	populateWithBools()
}

func populateWithBools() {
	for i := 0; i < rows*cols; i++ {
		randomBool := rng.Intn(2)
		grid[i] = int8(randomBool)
	}
}

//export updateGo
func updateGo() *C.float {
	gridLock.Lock()
	defer gridLock.Unlock()

	// Reset aliveLocs to zero using C memory access
	aliveLocsSlice := (*[1 << 30]C.float)(unsafe.Pointer(aliveLocs))[: rows*cols*2 : rows*cols*2]
	for i := 0; i < rows*cols*2; i++ {
		aliveLocsSlice[i] = 0.0
	}

	newGrid := make([]int8, rows*cols)
	k := 0

	for y := 0; y < rows; y++ {
		for x := 0; x < cols; x++ {
			neighbors := countNeighbors(x, y)
			idx := y*cols + x
			alive := grid[idx] == 1

			if alive && (neighbors < 2 || neighbors > 3) {
				newGrid[idx] = 0
			} else if !alive && neighbors == 3 {
				newGrid[idx] = 1
			} else {
				newGrid[idx] = grid[idx]
			}

			if newGrid[idx] == 1 {
				aliveLocsSlice[k] = C.float(float64(x)*cellSize + cellSize/2)
				aliveLocsSlice[k+1] = C.float(float64(y)*cellSize + cellSize/2)
				k += 2
			}
		}
	}

	// Update grid
	grid = newGrid

	return aliveLocs
}

func countNeighbors(x, y int) int {
	count := 0
	for i := -1; i <= 1; i++ {
		for j := -1; j <= 1; j++ {
			if i == 0 && j == 0 {
				continue
			}
			nx, ny := x+i, y+j
			if nx >= 0 && nx < cols && ny >= 0 && ny < rows {
				if grid[ny*cols+nx] == 1 {
					count++
				}
			}
		}
	}
	return count
}

//export destructGo
func destructGo() {
	gridLock.Lock()
	defer gridLock.Unlock()

	// Free C allocated memory
	if aliveLocs != nil {
		C.free(unsafe.Pointer(aliveLocs))
		aliveLocs = nil
	}

	grid = nil
}

func main() {}
