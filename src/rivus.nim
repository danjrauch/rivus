# A typical hybrid package uses this file as the main entry point of the application.

import system, os
import rivuspkg/traceFiles
import rivuspkg/types
import rivuspkg/db

when isMainModule:
    let fileName = "01.csv"
    let dataset = readTraceFile("datasets/GWA-T-13_Materna-Workload-Traces/Materna-Trace-1/" & fileName)

    let dbName = "test"
    let dbDir = "." & DirSep & "dbs"
    let dbFileName = dbDir & DirSep & dbName & DirSep & "db.bin"
    if not dirExists(dbFileName.splitFile().dir):
        createDir(dbFileName.splitFile().dir)

    var traceDB = newRivus[Trace](dbName, dbFileName)
    
    # let pool1 = Pool[Trace](header: Deck(numItems: 5), items: dataset[0..<5])
    # let pool2 = Pool[Trace](header: Deck(numItems: 5), items: dataset[5..<10])
    # traceDB.frost(pool1, 0)
    # traceDB.frost(pool2, 1)

    for trace in dataset:
        traceDB.addItem(trace)

    let pool11 = traceDB.melt(0, Trace)

    assert dataset[0] == pool11.items[0]

    let pool22 = traceDB.melt(1, Trace)

    assert dataset[115] == pool22.items[0]

    removeDir(dbDir)
