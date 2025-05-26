package main

/*
#include <stdlib.h>
*/
import "C"
import (
	"math/rand"
	"runtime"
	"sync"
	"unsafe"
)

var (
	grid       []int8
	rows, cols int
	cellSize   float64
	aliveLocs  *C.float
	gridLock   sync.Mutex
	rng        *rand.Rand
	numWorkers int
)

// Worker task structure
type workerTask struct {
	startRow   int
	endRow     int
	newGrid    []int8
	aliveCells []aliveCell
}

type aliveCell struct {
	x, y float32
}

//export initGo
func initGo(cRows C.int, cCols C.int, cCellSize C.double) {
	gridLock.Lock()
	defer gridLock.Unlock()
	rows = int(cRows)
	cols = int(cCols)
	cellSize = float64(cCellSize)
	grid = make([]int8, rows*cols)

	// Set number of workers based on CPU cores
	numWorkers = runtime.NumCPU()
	if numWorkers > rows {
		numWorkers = rows
	}

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

	// Reset aliveLocs to zero
	aliveLocsSlice := (*[1 << 30]C.float)(unsafe.Pointer(aliveLocs))[: rows*cols*2 : rows*cols*2]
	for i := 0; i < rows*cols*2; i++ {
		aliveLocsSlice[i] = 0.0
	}

	newGrid := make([]int8, rows*cols)

	// Calculate rows per worker
	rowsPerWorker := rows / numWorkers
	remainder := rows % numWorkers

	// Create channels for communication
	tasks := make(chan workerTask, numWorkers)
	results := make(chan workerTask, numWorkers)

	// Start workers
	var wg sync.WaitGroup
	for i := 0; i < numWorkers; i++ {
		wg.Add(1)
		go worker(tasks, results, &wg)
	}

	// Distribute work
	startRow := 0
	for i := 0; i < numWorkers; i++ {
		endRow := startRow + rowsPerWorker
		if i < remainder {
			endRow++
		}

		task := workerTask{
			startRow:   startRow,
			endRow:     endRow,
			newGrid:    make([]int8, cols*(endRow-startRow)),
			aliveCells: make([]aliveCell, 0),
		}

		tasks <- task
		startRow = endRow
	}
	close(tasks)

	// Wait for all workers to complete
	go func() {
		wg.Wait()
		close(results)
	}()

	// Collect results
	k := 0
	for result := range results {
		// Copy the computed grid section back to newGrid
		for localRow := 0; localRow < result.endRow-result.startRow; localRow++ {
			globalRow := result.startRow + localRow
			copy(newGrid[globalRow*cols:(globalRow+1)*cols],
				result.newGrid[localRow*cols:(localRow+1)*cols])
		}

		// Add alive cells to output
		for _, cell := range result.aliveCells {
			if k < rows*cols*2-1 {
				aliveLocsSlice[k] = C.float(cell.x)
				aliveLocsSlice[k+1] = C.float(cell.y)
				k += 2
			}
		}
	}

	// Update grid
	grid = newGrid

	return aliveLocs
}

// Worker function that processes a range of rows
func worker(tasks <-chan workerTask, results chan<- workerTask, wg *sync.WaitGroup) {
	defer wg.Done()

	for task := range tasks {
		// Process each row in this worker's range
		for y := task.startRow; y < task.endRow; y++ {
			for x := 0; x < cols; x++ {
				neighbors := countNeighbors(x, y)
				idx := y*cols + x
				localIdx := (y-task.startRow)*cols + x
				alive := grid[idx] == 1

				if alive && (neighbors < 2 || neighbors > 3) {
					task.newGrid[localIdx] = 0
				} else if !alive && neighbors == 3 {
					task.newGrid[localIdx] = 1
				} else {
					task.newGrid[localIdx] = grid[idx]
				}

				if task.newGrid[localIdx] == 1 {
					cellX := float32(float64(x)*cellSize + cellSize/2)
					cellY := float32(float64(y)*cellSize + cellSize/2)
					task.aliveCells = append(task.aliveCells, aliveCell{x: cellX, y: cellY})
				}
			}
		}

		results <- task
	}
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
