import system, streams, os, sequtils, sugar, std/exitprocs
import rivuspkg/types
import rivuspkg/tracedb
import rivuspkg/cryo

let traces = readTraceFile("datasets/GWA-T-13_Materna-Workload-Traces/Materna-Trace-1/01.csv")
let streamToFreeze = newFileStream("stress.bin", fmWrite)

exitprocs.addExitProc(() => removeFile("stress.bin"))

streamToFreeze.freeze(traces)
streamToFreeze.close()

let streamToThaw = newFileStream("stress.bin", fmRead)
var thawedTraces = newSeq[Trace]()
for i in [0..<traces.len]:
    thawedTraces.add(streamToThaw.thaw(Trace))
streamToThaw.close()

for (t, tt) in zip(traces, thawedTraces):
    for v1, v2 in fields(t, tt):
        assert(v1 == v2, "Field on thawed object doesn't match original")
