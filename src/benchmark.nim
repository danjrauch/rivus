import os, times, random, sequtils, strformat, strutils, streams
import psutil
import files

template benchmark(benchmarkName: string, code: untyped) =
    block:
        let t0 = epochTime()
        code
        let elapsed = epochTime() - t0
        let elapsedStr = elapsed.formatFloat(format = ffDecimal, precision = 3)
        echo "CPU Time [", benchmarkName, "] ", elapsedStr, "s"

type 
    Datum = object
        a: float64
        b: int32
        c: string

var sequence = newSeq[Datum]()
randomize()
for _ in 1..1000000:
    let a = rand(10000.00)
    let b = rand(2000).int32
    let c = 32.newSeqWith((97..122).rand.chr).join
    sequence.add(Datum(a: a, b: b, c: c))

echo cpu_count().int32, " CPUs"
echo &"{(virtual_memory().total / 1e9.int):0.2f}", " GB RAM"

benchmark "object freezing":
    let s = newFileStream("benchmark.bin", fmReadWrite)
    for dat in sequence:
        s.freeze(dat)
    s.close()

benchmark "object thawing":
    let s = newFileStream("benchmark.bin", fmReadWriteExisting)
    for dat in sequence:
        let candidate = s.thaw(Datum)
        for v1, v2 in fields(dat, candidate):
            assert(v1 == v2, "Field on thawed object doesn't match original")
    s.close()

removeFile("benchmark.bin")
