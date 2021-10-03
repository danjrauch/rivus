import system, os, streams
import cryo

const DB_NUM_POOLS* = 500
const DB_POOL_SIZE* = 8192
const DB_MAX_DECK_SIZE* = 100
const DB_MAX_SIZE* = DB_MAX_DECK_SIZE + DB_NUM_POOLS * DB_POOL_SIZE

type # needs to be less than MAX_DECK_SIZE when written to binary
    Deck* = object
        numItems*: int32

type
    Pool*[T] = object
        header*: Deck
        items*: seq[T]

type
    Rivus*[T] = object
        name*: string
        fileName*: string
        deck*: Deck
        writeAheadDir: string
        inMemPool: Pool[T]

proc newRivus*[T](name: string, fileName: string): Rivus[T] =
    if not os.fileExists(fileName):
        let stream = newFileStream(fileName, fmWrite)
        defer: stream.close()
        let dbDeck = Deck(numItems: 0)
        stream.freeze(dbDeck)
        for i in 0..<DB_MAX_SIZE - binarySize(dbDeck):
            stream.write(0'u8)
    let stream = newFileStream(fileName, fmRead)
    defer: stream.close()
    let dbDeck = stream.thaw(Deck)
    return Rivus[T](name: name, 
        fileName: fileName,
        writeAheadDir: fileName.splitFile().dir & DirSep & "writeAhead.bin",
        deck: dbDeck)

proc deleteRivus*(fileName: string): void =
    removeFile(fileName)

proc flush*[T](this: var Rivus[T]): void =
    this.frost(this.inMemPool, this.deck.numItems)

proc addItem*[T](this: var Rivus[T], v: T): void =
    let vBinSize = binarySize(v)
    let inMemPoolSize = DB_MAX_DECK_SIZE + this.inMemPool.items.len * vBinSize
    if inMemPoolSize + vBinSize > DB_POOL_SIZE:
        this.flush()
        let header = Deck(numItems: 0)
        this.inMemPool = Pool[T](header: header, items: newSeq[T]())
    this.inMemPool.items.add(v)
    this.inMemPool.header.numItems += 1

proc frostPool(stream: Stream, pool: Pool, writeAheadDir: string) = 
    assert pool.header.numItems == pool.items.len
    # buffer can be used for write-ahead later
    let buffer = newFileStream(writeAheadDir, fmWrite)
    let startPosition = buffer.getPosition()
    buffer.freeze(pool.header)
    assert buffer.getPosition() - startPosition < DB_MAX_DECK_SIZE
    for item in pool.items:
        buffer.freeze(item)
    assert buffer.getPosition() - startPosition - DB_MAX_DECK_SIZE < DB_POOL_SIZE
    stream.freeze(pool.header)
    stream.freeze(pool.items)

proc frost*(db: var Rivus, pool: Pool, poolNum: int) = 
    assert poolNum < DB_NUM_POOLS
    let file = open(db.fileName, fmReadWriteExisting)
    assert file.getFileSize() == DB_MAX_SIZE
    assert file.getFileSize() >= DB_MAX_DECK_SIZE + (poolNum + 1) * DB_POOL_SIZE, 
        "The rivus has run out of space."
    let stream = newFileStream(file)
    defer: stream.close()
    if poolNum + 1 > db.deck.numItems:
        db.deck.numItems += 1
        assert binarySize(db.deck) <= DB_MAX_DECK_SIZE
        stream.freeze(db.deck)
    stream.setPosition(DB_MAX_DECK_SIZE + poolNum * DB_POOL_SIZE)
    stream.frostPool(pool, db.writeAheadDir)

proc meltPool(stream: Stream, t: typedesc[tuple | object]): Pool[t] =
    let header = stream.thaw(Deck)
    var items = newSeq[t]()
    for i in 0..<header.numItems:
        let item = stream.thaw(t)
        items.add(item)
    return Pool[t](header: header, items: items)

proc melt*(db: Rivus, poolNum: int, t: typedesc[tuple | object]): Pool[t] =
    let file = open(db.fileName, fmRead)
    assert file.getFileSize() == DB_MAX_SIZE
    assert file.getFileSize() >= DB_MAX_DECK_SIZE + (poolNum + 1) * DB_POOL_SIZE, 
        "The rivus has run out of space."
    let stream = newFileStream(file)
    defer: stream.close()
    stream.setPosition(DB_MAX_DECK_SIZE + poolNum * DB_POOL_SIZE)
    return stream.meltPool(t)
