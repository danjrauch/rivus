# A typical hybrid package uses this file as the main entry point of the application.

import system, os, sugar, std/exitprocs
import rivuspkg/tracedb
import rivuspkg/types
import rivuspkg/db

when isMainModule:
    let fileName = "01.csv"
    let traces = readTraceFile("datasets/GWA-T-13_Materna-Workload-Traces/Materna-Trace-1/" & fileName)
    let traceRivus = newTraceRivus(traces)

    exitprocs.addExitProc(() => (block:
        removeDir(traceRivus.fileName.splitFile().dir)
    ))

    let pool11 = traceRivus.melt(0, Trace)

    assert traces[0] == pool11.items[0]

    let pool22 = traceRivus.melt(1, Trace)

    assert traces[115] == pool22.items[0]
