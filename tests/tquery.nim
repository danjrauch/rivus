import system, streams, os, sugar, std/exitprocs
import rivuspkg/types
import rivuspkg/tracedb
import rivuspkg/db
import rivuspkg/query

let fileName = "01.csv"
let traces = readTraceFile("datasets/GWA-T-13_Materna-Workload-Traces/Materna-Trace-1/" & fileName)
let traceRivus = newTraceRivus(traces)

exitprocs.addExitProc(() => removeDir(traceRivus.fileName.splitFile().dir))

let result = traceRivus.filter((e: Trace) => e.cpuUsage == 110);

for trace in result:
    assert trace.cpuUsage == 110
