import system, os, streams, strutils, times
import db
import types

proc readTraceFile*(fileName: string): seq[Trace] = 
    assert fileExists(fileName), "The trace file doesn't exist."
    let s = newFileStream(fileName, fmRead)
    defer: s.close()
    discard s.readLine()
    var line = ""
    while s.readLine(line):
        let parts = line.split(';')
        let timestamp = parseTime(parts[0][1..^2], "dd'.'MM'.'yyyy HH:mm:ss", utc()).toUnix()
        let cpuCores = parts[1][1..^2].parseBiggestInt().int16
        let cpuCapacityProvisioned = parts[2][1..^2].parseBiggestInt().int32
        let cpuUsage = parts[3][1..^2].parseBiggestInt().int32
        let cpuUsagePercent = parts[4][1..^2].replace(',', '.').parseFloat()
        let memCapacityProvisioned = parts[5][1..^2].parseBiggestInt().int64
        let memUsage = parts[6][1..^2].parseBiggestInt().int64
        let memUsagePercent = parts[7][1..^2].replace(',', '.').parseFloat()
        let diskReadThroughput = parts[8][1..^2].parseBiggestInt().int32
        let diskWriteThroughput = parts[9][1..^2].parseBiggestInt().int32
        let diskSize = parts[10][1..^2].parseBiggestInt().int32
        let networkReceivedThroughput = parts[11][1..^2].parseBiggestInt().int32
        let networkTransmittedThroughput = parts[12][1..^2].parseBiggestInt().int32

        result.add(Trace(
            timestamp: timestamp, 
            cpuCores: cpuCores, 
            cpuCapacityProvisioned: cpuCapacityProvisioned, 
            cpuUsage: cpuUsage, 
            cpuUsagePercent: cpuUsagePercent, 
            memCapacityProvisioned: memCapacityProvisioned, 
            memUsage: memUsage, 
            memUsagePercent: memUsagePercent, 
            diskReadThroughput: diskReadThroughput, 
            diskWriteThroughput: diskWriteThroughput, 
            diskSize: diskSize, 
            networkReceivedThroughput: networkReceivedThroughput, 
            networkTransmittedThroughput: networkTransmittedThroughput))

proc newTraceRivus*(traces: seq[Trace]): Rivus[Trace] =
    let dbName = "test"
    let dbDir = "." & DirSep & "dbs"
    let dbFileName = dbDir & DirSep & "db.bin"
    if not dirExists(dbFileName.splitFile().dir):
        createDir(dbFileName.splitFile().dir)

    result = newRivus[Trace](dbName, dbFileName)

    for trace in traces:
        result.addItem(trace)

    result.flush()
