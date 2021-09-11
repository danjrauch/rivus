import os, times, random, sequtils, strformat, strutils, streams, psutil
import cryo
import traceFiles
import types

template benchmark(benchmarkName: string, code: untyped) =
    block:
        let t0 = epochTime()
        code
        let elapsed = epochTime() - t0
        let elapsedStr = elapsed.formatFloat(format = ffDecimal, precision = 3)
        echo "CPU Time [", benchmarkName, "] ", elapsedStr, "s"

echo cpu_count().int32, " CPUs"
echo &"{(virtual_memory().total / 1e9.int):0.2f}", " GB RAM"

typeDef("Datum", @["a", "b", "c"], @["float64", "int32", "string"])

# Cycle some random objects from stream
let size = 1000000
var sequence = newSeq[Datum]()
randomize()
for _ in 1..size:
    let a = rand(10000.00)
    let b = rand(2000).int32
    let c = 32.newSeqWith((97..122).rand.chr).join
    sequence.add(Datum(a: a, b: b, c: c))

benchmark "freezing " & $size & " objects":
    let s = newFileStream("benchmark.bin", fmReadWrite)
    defer: s.close()
    for dat in sequence:
        s.freeze(dat)

benchmark "thawing " & $size & " objects":
    let s = newFileStream("benchmark.bin", fmReadWriteExisting)
    defer: s.close()
    for dat in sequence:
        let candidate = s.thaw(Datum)
        for v1, v2 in fields(dat, candidate):
            assert(v1 == v2, "Field on thawed object doesn't match original")

# Cycle a trace file
let fileName = "01.csv"
let traces = readTraceFile("datasets/GWA-T-13_Materna-Workload-Traces/Materna-Trace-1/" & fileName)

benchmark "freezing " & fileName & " w/ " & $traces.len & " objects":
    let s = newFileStream("benchmark.bin", fmReadWrite)
    defer: s.close()
    s.freeze(traces)

benchmark "thawing " & fileName & " w/ " & $traces.len & " objects":
    let s = newFileStream("benchmark.bin", fmReadWriteExisting)
    defer: s.close()
    for trace in traces:
        let candidate = s.thaw(Trace)
        for v1, v2 in fields(trace, candidate):
            assert(v1 == v2, "Field on thawed object doesn't match original")

removeFile("benchmark.bin")
