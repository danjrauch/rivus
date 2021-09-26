import system, streams
import types

proc binarySize(x: number): int = 
    return sizeof(x)

proc binarySize(x: string): int =
    return x.len * sizeof(char)

proc binarySize*[T: tuple | object](x: T): int =
    for value in x.fields:
        result += binarySize(value)

proc freeze[T: number](stream: Stream, x: T) =
    var x = x # redeclare so we don't use the parameter address
    stream.writeData(x.addr, sizeof(x))

proc freeze[T: string](stream: Stream, x: T) =
    stream.write(x.len.int64)
    const bufferSize = 1000
    var buffer: array[bufferSize, char]
    var left = x.len
    while left > 0:
        let amount = (if left < bufferSize: left else: bufferSize)
        for i in 0..<amount:
            buffer[i] = x[i]
        stream.writeData(buffer.addr, amount)
        left = left - amount

proc freeze*[T: tuple | object](stream: Stream, x: T) =
    for value in x.fields:
        stream.freeze(value)

proc freeze*[T: tuple | object](stream: Stream, objects: seq[T]) =
    for obj in objects:
        stream.freeze(obj)

proc thaw(stream: Stream, x: var number) =
    discard stream.readData(x.addr, sizeof(x))

proc thaw(stream: Stream, x: var string) =
    let len = stream.readInt64()
    const bufferSize = 1000
    var buffer: array[bufferSize, char]
    x = newStringOfCap(len)
    var left = len
    while left > 0:
        let amount = (if left < bufferSize: left else: bufferSize)
        discard stream.readData(buffer.addr, amount.int)
        for i in 0..<amount:
            x.add(buffer[i])
        left = left - amount

proc thaw*[T: tuple | object](stream: Stream, x: typedesc[T]): T =
    for value in result.fields:
        stream.thaw(value)
