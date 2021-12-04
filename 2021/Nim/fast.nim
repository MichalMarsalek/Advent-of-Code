include prelude
import times

const days = 3
const repetitions = 1000
var SOLUTIONS: array[26,proc (input:string):(string,string)]
var INPUTS: array[26,string]
var OUTPUTS: array[26,(string,string)]

for day in 1..days:
    INPUTS[day] = readFile("inputs\\day" & $day & ".in")



            

SOLUTIONS[1] = proc (input: string):(string, string) =
    type part = tuple[start: int, len: int]
    func mySplit2(text:string):seq[part] =
        var start = 0
        for i in 0..text.high:
            if text[i] == '\n':
                result.add (start, i-start)
                start = i+1
    proc lt2(a,b:part): bool =
        if a.len < b.len: return true
        if a.len > b.len: return false
        for i in 0..<a.len:
            if input[a.start + i] < input[b.start + i]: return true
            if input[a.start + i] > input[b.start + i]: return false
    var parts = input.mySplit2 # idk why but strutils.split is just so slow
    var p1,p2 = 0
    if parts[0] .lt2 parts[1]: inc p1
    if parts[1] .lt2 parts[2]: inc p1
    for i in 3..<parts.len:
        if parts[i-1] .lt2 parts[i]: inc p1
        if parts[i-3] .lt2 parts[i]: inc p2
    return ($p1, $p2)

SOLUTIONS[2] = proc (input: string):(string, string) =
    var i = 0
    var x,y,aim = 0
    while i < input.len:
        case input[i]
        of 'u': aim -= input[i+3].ord - 48; i += 5
        of 'd': aim += input[i+5].ord - 48; i += 7
        else:
            let X = input[i+8].ord - 48; x += X; y += aim*X; i += 10
    return ($(x*aim), $(x*y))

SOLUTIONS[3] = proc (input: string):(string, string) =
    func toInt(x: array[12,int]):int =
        for i in 0..11:
            result = result * 2 + x[i]
            
    #parsing
    var data: seq[array[12,int]]
    var i = 0
    while i < input.len:
        var number: array[12,int]
        for j in 0..11:
            number[j] = input[i+j].ord - 48
        i += 13
        data.add(number)
    
    #part 1
    var most: array[12,int]
    var least: array[12,int]
    
    for i in 0..11:
        var c = 0
        for n in data:
            c += n[i]
            if 2*c >= data.len: break
        most[i] = int(2*c >= data.len)
        least[i] = 1-most[i]
    
    #part 2
    var most_data, least_data = data
    
    i = 0
    while most_data.len > 1:
        var c = 0
        for n in most_data:
            c += n[i]
            if 2*c >= data.len: break
        var most_i = int(2*c >= most_data.len)
        most_data.keepItIf(it[i] == most_i)
        inc i
    i = 0
    while least_data.len > 1:
        var c = 0
        for n in least_data:
            c += n[i]
        var least_i = int(2*c < least_data.len)
        least_data.keepItIf(it[i] == least_i)
        inc i
        
    return ($(most.toInt*least.toInt), $(most_data[0].toInt*least_data[0].toInt))

SOLUTIONS[3] = proc (input: string):(string, string) =
    func toInt(x: array[12,int]):int =
        for i in 0..11:
            result = result * 2 + x[i]
            
    #parsing
    var data: seq[uint32]
    var i = 0
    while i < input.len:
        var number = 0'u32
        for j in 0..11:
            number = (number shl 1) xor (input[i+j].ord - 48).uint32
        i += 13
        data.add(number)
    
    #part 1
    var most: uint32
    
    template bit(n:uint32, i:int):uint32 = (n shr i) and 1'u32
        
    
    for i in 0..11:
        var c = 0
        for n in data:
            c += n.bit(11-i).int
            if 2*c >= data.len: break
        most = (most shl 1)
        if 2*c >= data.len:
            most = most xor 1'u32
    var least = (not most) and 0xfff'u32
    
    #part 2
    var most_data, least_data = data
    
    i = 11
    while most_data.len > 1:
        var c = 0
        for n in most_data:
            c += n.bit(i).int
            if 2*c >= most_data.len: break
        var most_i = if 2*c >= most_data.len: 1'u32 else: 0'u32
        most_data.keepItIf(it.bit(i) == most_i)
        dec i
    i = 11
    while least_data.len > 1:
        var c = 0
        for n in least_data:
            c += n.bit(i).int
            if 2*c >= least_data.len: break
        var least_i = if 2*c >= least_data.len: 0'u32 else: 1'u32
        least_data.keepItIf(it.bit(i) == least_i)        
        dec i
        
    return ($(most*least), $(most_data[0]*least_data[0]))


var total_time = 0.0
for day in 1..days:
    let start = getTime()
    for _ in 1..repetitions:
        OUTPUTS[day] = SOLUTIONS[day] INPUTS[day]       

    let finish = getTime()
    let mean_time = (finish-start).inNanoseconds.float / repetitions.float / 1000000.0
    total_time += mean_time
    
    echo "Day ", day
    echo OUTPUTS[day]
    echo mean_time, " ms"
    echo ""
echo "Total time: ", total_time, " ms"
    