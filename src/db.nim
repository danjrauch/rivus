import system, os, streams, typetraits
import cryo, types, traceFiles

const DB_NUM_POOLS = 100
const DB_POOL_SIZE = 8192
const MAX_DECK_SIZE = 100

type # this needs to be less than around 100 bytes
    Deck = object
        numItems: int32

type
    Pool[T] = object
        header: Deck
        items: seq[T]

type
    Rivus = object
        name: string
        fileName: string


proc newRivus*(name: string, fileName: string): Rivus =
    if not os.fileExists(fileName):
        let stream = newFileStream(fileName, fmWrite)
        for i in 0..<DB_NUM_POOLS * DB_POOL_SIZE:
            stream.write(0'u8)
    return Rivus(name: name, fileName: fileName)

proc frostPool(stream: Stream, pool: Pool, writeAheadDir: string) = 
    assert pool.header.numItems == pool.items.len
    # buffer can be used for write-ahead later
    let buffer = newFileStream(writeAheadDir, fmWrite)
    buffer.freeze(pool.header)
    assert buffer.getPosition() < MAX_DECK_SIZE
    for item in pool.items:
        buffer.freeze(item)
    assert buffer.getPosition() < DB_POOL_SIZE
    stream.freeze(pool.header)
    stream.freeze(pool.items)

proc frost*(db: Rivus, pool: Pool, poolNum: int) = 
    assert poolNum < DB_NUM_POOLS
    let file = open(db.fileName, fmReadWriteExisting)
    assert file.getFileSize() > poolNum * DB_POOL_SIZE
    let stream = newFileStream(file)
    defer: stream.close()
    stream.setPosition(poolNum * DB_POOL_SIZE)
    stream.frostPool(pool, db.fileName.splitFile().dir & DirSep & "writeAhead.bin")

proc meltPool(stream: Stream, t: typedesc[tuple | object]): Pool[t] =
    let header = stream.thaw(Deck)
    var items = newSeq[t]()
    for i in 0..<header.numItems:
        let item = stream.thaw(t)
        items.add(item)
    return Pool[t](header: header, items: items)

proc melt*(db: Rivus, poolNum: int, t: typedesc[tuple | object]): Pool[t] =
    let file = open(db.fileName, fmRead)
    assert file.getFileSize() > poolNum * DB_POOL_SIZE
    let stream = newFileStream(file)
    defer: stream.close()
    stream.setPosition(poolNum * DB_POOL_SIZE)
    return stream.meltPool(t)


let fileName = "01.csv"
let dataset = readTraceFile("datasets/GWA-T-13_Materna-Workload-Traces/Materna-Trace-1/" & fileName)

let dbName = "test"
let dbDir = "." & DirSep & "dbs"
let dbFileName = dbDir & DirSep & dbName & DirSep & "db.bin"
if not dirExists(dbFileName.splitFile().dir):
    createDir(dbFileName.splitFile().dir)

let db = newRivus(dbName, dbFileName)
let pool1 = Pool[Trace](header: Deck(numItems: 5), items: dataset[0..<5])
let pool2 = Pool[Trace](header: Deck(numItems: 5), items: dataset[5..<10])
db.frost(pool1, 0)
db.frost(pool2, 1)
let pool11 = db.melt(0, Trace)

assert dataset[0] == pool11.items[0]

let pool22 = db.melt(1, Trace)

assert dataset[5] == pool22.items[0]

removeDir(dbDir)
