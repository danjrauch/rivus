import math, os, sugar, terminal, std/exitprocs
import cryo
import db
import query
import tracedb
import types

let fileName = "01.csv"
let traces = readTraceFile("datasets/GWA-T-13_Materna-Workload-Traces/Materna-Trace-1/" & fileName)
let traceRivus = newTraceRivus(traces)

exitprocs.addExitProc(() => removeDir(traceRivus.fileName.splitFile().dir))

# Size of the rivus
let file = open(traceRivus.fileName, fmReadWriteExisting)
assert file.getFileSize() == DB_MAX_SIZE

# Number of traces per pool
let pool1 = traceRivus.melt(0, Trace)
let expectedTracesInPool = floor((DB_POOL_SIZE - DB_MAX_DECK_SIZE) / binarySize(traces[0])).int
assert pool1.header.numItems == expectedTracesInPool, 
    $pool1.header.numItems & " != " & $expectedTracesInPool

# Number of pools written in rivus
let expectedPools = ceil(traces.len / expectedTracesInPool).int
assert traceRivus.deck.numItems == expectedPools,
    $traceRivus.deck.numItems & " != " & $expectedPools

# Found all traces for universal query
let badFilter = traceRivus.filter((e: Trace) => e.cpuCores > 0)
assert traces.len == badFilter.len,
    $traces.len & " != " & $badFilter.len
    
styledEcho styleBright, fgGreen, "   Success: ", resetStyle, "All diagnostics passed"
