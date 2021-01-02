import sets, tables, intsets,  times, os, math, strutils, sequtils

## Each point is represented as a triple:
## (x, y, sym)
## where x, y are the nonsymmetric dimensions and sym are the rest d-2 symmetric ones.
## These symmetric components are represented as a 7-tuple,
## each position storing the amount of 0s, 1s, ..., 6s in the coordinate.
## So, every point is represented by 9 values, these are further packed into a single int64.
## 
## Troughout the calculation, we only track which cosets are active.
## In the end, we weight each active cosets by its size.

const ROUNDS = 6
const CROP_SYM = 0b11111111111111111111111111111111111
var DIM, k: int

## differences in the nonsymmetric dimensions
const DXY = [-1 * (1 shl 50) - 1 * (1 shl 35),
             -1 * (1 shl 50) + 0 * (1 shl 35),
             -1 * (1 shl 50) + 1 * (1 shl 35),
              0 * (1 shl 50) - 1 * (1 shl 35),
              0 * (1 shl 50) + 0 * (1 shl 35),
              0 * (1 shl 50) + 1 * (1 shl 35),
              1 * (1 shl 50) - 1 * (1 shl 35),
              1 * (1 shl 50) + 0 * (1 shl 35),
              1 * (1 shl 50) + 1 * (1 shl 35)]

## packing/unpacking
func pack(sym: array[7, int]): int =
    for i in 0..6:
        result = (result shl 5) xor sym[6-i]

func unpack(packed:int): array[7, int] =
    var packed = packed
    for i in 0..6:
        result[i] = packed and 0b11111
        packed = packed shr 5

func pack2(x,y:int, sym:int): int =
    (((x shl 15) xor y) shl (35)) xor sym

func unpack2(packed:int): (int, int, int) =
    let sym = packed and CROP_SYM
    let y = (packed shr 35) and 0b11111
    let x = (packed shr 50)
    return (x, y, sym.int)
    
func binom2(n,k:int): int {.inline.} =
    ## Returns (n choose k) or 4 if it's unnecesarily big.
    if k > n:
        return 0
    if k == 0 or k == n:
        return 1
    if n <= 3:
        return n
    return 4
    
func neg(a:int):int {.inline.}=
    ## Returns the negative part of a number.
    min(a,0)
func pos(a:int):int {.inline.}=
    ## Returns the positive part of a number.
    max(a,0)

func getSymNeighboursWeights(x: array[7, int]): seq[int] =
    ## Generates all neigbours of given cell with weights.
    ## Does so by considering how much of each occurence of 0s,...6s increases and decreases.
    for s0 in -x[1]..x[0]:
        for s1 in -x[2]..x[1]+neg(s0):
            for s2 in -x[3]..x[2]+neg(s1):
                for s3 in -x[4]..x[3]+neg(s2):
                    for s4 in -x[5]..x[4]+neg(s3):
                        for s5 in 0..x[5]+neg(s4):
                            let newCell = [x[0] - s0,
                                    x[1] + s0 - s1,
                                    x[2] + s1 - s2,
                                    x[3] + s2 - s3,
                                    x[4] + s3 - s4,
                                    x[5] + s4 - s5,
                                    + s5]
                            var ways:int
                            # This should be optimized and calculated without iteration
                            # If it's a big number (> 4) I don't need to know how large it is
                            block slow: 
                                for R0 in pos(s0)..x[0]:
                                    let L1 = R0 - s0
                                    let m0 = 1 shl L1
                                    for R1 in pos(s1)..x[1]-L1:
                                        let L2 = R1 - s1
                                        let m1 = binom2(newCell[1], R0) * binom2(newCell[1]-R0, L2)
                                        if m1 == 0:
                                            debugEcho((x[0], s0, R0, L1, newCell[1]))
                                        for R2 in pos(s2)..x[2]-L2:
                                            let L3 = R2 - s2
                                            let m2 = binom2(newCell[2], R1) * binom2(newCell[2]-R1, L3)
                                            for R3 in pos(s3)..x[3]-L3:
                                                let L4 = R3 - s3                                                    
                                                let m3 = binom2(newCell[3], R2) * binom2(newCell[3]-R2, L4)
                                                for R4 in pos(s4)..x[4]-L4:
                                                    let L5 = R4 - s4
                                                    let m4 = binom2(newCell[4], R3) * binom2(newCell[4]-R3, L5)
                                                    let m5 = binom2(newCell[5], R4)
                                                    ways  += m0*m1*m2*m3*m4*m5
                                                    if s0 == R0-L1 and s1 == R1-L2 and s2 == R2-L3 and s3 == R3-L4 and s4 == R4-L5:
                                                        if ways >= 4:
                                                            break slow                                                          
                                            
                            result.add(newCell.pack)
                            result.add(ways)

# EVOLUTION
proc nxt(grid: seq[int]): seq[int] =
    ## Given a list of active cosets, returns a list of cosets in the next time step.
    var counting: CountTable[int] 
    for cell in grid:
        var sym = int(cell and CROP_SYM)
        let neigbours = sym.unpack.getSymNeighboursWeights
        var i = 0
        while i < neigbours.len:
            let sym2 = neigbours[i]
            let w = neigbours[i+1]
            for dxy in DXY:
                let cell2 = (cell + dxy) xor sym xor sym2
                counting.inc(cell2, 2*w)
            i += 2
        counting.inc(cell)
    for cell,val in counting:
        # active + 2 or 3 other active neigbours = active + 3 or 4 active neigbours = 0111 or 1001 = 7 or 9
        # not active + 3 other active neigbours = not active + 3 active neigbours   = 0110         = 6
        if (val == 6) or (val == 7) or (val == 9):
            result.add(cell)

proc weight(point:int):int =
    ## Returns a weight of a coset for final calculation.
    ## Weight is number of distinct permutations times 2^(number of nonzeroes).
    let sym = point.unpack2[2].unpack
    result = fac(k)
    for q in sym:
        result = result div fac(q)
    result = result shl (k-sym[0])
        
for DIM in 31..40:
    k = DIM-2

    # Loads input
    var grid = newSeq[int]()
    var row = 0
    let input = open("input.txt")
    for line in input.lines:
      for i, col in line:
        if col == '#':
            grid.add(pack2(10+i, 10+row, k))
      inc row
    input.close()


    # Run computation
    let time2 = cpuTime()
    for round in 1..ROUNDS:
        grid = nxt(grid)

    echo "Dim: ", DIM
    echo "Computation time taken: ", cpuTime() - time2
    echo "Partial: ", grid.len
    if DIM <= 20:
        echo "Result: ", grid.toSeq.map(weight).sum
discard stdin.readLine