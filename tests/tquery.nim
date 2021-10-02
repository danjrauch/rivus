import system, streams, os, sugar
import rivuspkg/types
import rivuspkg/traceFiles
import rivuspkg/db
import rivuspkg/query

let fileName = "01.csv"
let dataset = readTraceFile("datasets/GWA-T-13_Materna-Workload-Traces/Materna-Trace-1/" & fileName)

let dbName = "test"
let dbDir = "." & DirSep & "dbs"
let dbFileName = dbDir & DirSep & dbName & DirSep & "db.bin"
if not dirExists(dbFileName.splitFile().dir):
    createDir(dbFileName.splitFile().dir)

var traceDB = newRivus[Trace](dbName, dbFileName)

for trace in dataset:
    traceDB.addItem(trace)

traceDB.flush()

let result = traceDB.filter((e: Trace) => e.cpuUsage == 110);

for trace in result:
    assert trace.cpuUsage == 110

removeDir(dbDir)
