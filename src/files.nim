import system, streams

type number = int | int8 | int16 | int32 | int64 | float | float32 | float64

proc freeze[T: number](stream: Stream, x: T) =
    var x = x # redeclare so we don't use the parameter address
    stream.writeData(x.addr, sizeof(x))

proc freeze[T: string](stream: Stream, x: T) =
    stream.write(x.len.int64)
    var buffer: array[100, char]
    var left = x.len
    while left > 0:
        let amount = (if left < 100: left else: 100)
        for i in 0..<amount:
            buffer[i] = x[i]
        stream.writeData(buffer.addr, amount)
        left = left - amount

proc freeze*[T: tuple | object](stream: Stream, x: T) =
    for value in x.fields:
        stream.freeze(value)

proc thaw(stream: Stream, x: var number) =
    discard stream.readData(x.addr, sizeof(x))

proc thaw(stream: Stream, x: var string) =
    let len = stream.readInt64().int
    var buffer: array[100, char]
    x = newStringOfCap(len)
    var left = len
    while left > 0:
        let amount = (if left < 100: left else: 100)
        discard stream.readData(buffer.addr, amount)
        for i in 0..<amount:
            x.add(buffer[i])
        left = left - amount

proc thaw*[T: tuple | object](stream: Stream, x: typedesc[T]): T =
    for value in result.fields:
        stream.thaw(value)
