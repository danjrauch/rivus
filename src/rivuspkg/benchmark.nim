import os, times, random, sequtils, strformat, strutils, streams, sugar, terminal
import psutil
import cryo
import traceFiles
import types
import db
import query

template benchmark(benchmarkName: string, target: float, code: untyped) =
    block:
        let t0 = epochTime()
        code
        let elapsed = epochTime() - t0
        let elapsedStr = formatFloat(elapsed, ffDecimal, 3)
        let result = (if elapsed <= target: "PASS " else: "FAIL ") & formatFloat(target, ffDecimal, 3)
        let resultClr = (if elapsed <= target: fgGreen else: fgRed)
        styledEcho "[", fgBlue, benchmarkName, resetStyle, "]"
        styledEcho "Ran in ".indent(4), styleBright, elapsedStr, "s ", resultClr, result, resetStyle

echo cpu_count().int32, " CPUs"
echo &"{(virtual_memory().total / 1e9.int):0.2f}", " GB RAM"

type Datum = object
    a: float64
    b: int32
    c: string

# Cycle some random objects from stream
let size = 1000000
var sequence = newSeq[Datum]()
randomize()
for _ in 1..size:
    let a = rand(10000.00)
    let b = rand(2000).int32
    let c = 32.newSeqWith((97..122).rand.chr).join
    sequence.add(Datum(a: a, b: b, c: c))

benchmark "freezing " & $size & " objects", 1.00:
    let s = newFileStream("benchmark.bin", fmReadWrite)
    defer: s.close()
    for dat in sequence:
        s.freeze(dat)

benchmark "thawing " & $size & " objects", 1.00:
    let s = newFileStream("benchmark.bin", fmReadWriteExisting)
    defer: s.close()
    for dat in sequence:
        let candidate = s.thaw(Datum)
        for v1, v2 in fields(dat, candidate):
            assert(v1 == v2, "Field on thawed object doesn't match original")

# Cycle a trace file
let fileName = "01.csv"
let traces = readTraceFile("datasets/GWA-T-13_Materna-Workload-Traces/Materna-Trace-1/" & fileName)

let dbName = "test"
let dbDir = "." & DirSep & "dbs"
let dbFileName = dbDir & DirSep & dbName & DirSep & "db.bin"
if not dirExists(dbFileName.splitFile().dir):
    createDir(dbFileName.splitFile().dir)

var traceDB = newRivus[Trace](dbName, dbFileName)

for trace in traces:
    traceDB.addItem(trace)

traceDB.flush()

benchmark "freezing " & fileName & " w/ " & $traces.len & " objects", 0.05:
    let s = newFileStream("benchmark.bin", fmReadWrite)
    defer: s.close()
    s.freeze(traces)

benchmark "thawing " & fileName & " w/ " & $traces.len & " objects", 0.05:
    let s = newFileStream("benchmark.bin", fmReadWriteExisting)
    defer: s.close()
    for trace in traces:
        let candidate = s.thaw(Trace)
        for v1, v2 in fields(trace, candidate):
            assert(v1 == v2, "Field on thawed object doesn't match original")

benchmark "querying db " & dbName & " w/ " & $traces.len & " objects", 0.05:
    let result = traceDB.filter((e: Trace) => e.cpuUsage == 110);

    for trace in result:
        assert trace.cpuUsage == 110

removeFile("benchmark.bin")
removeDir(dbDir)
