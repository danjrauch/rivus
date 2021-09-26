# import strutils, streams, compiler/[nimeval, llstream]

type number* = int | int8 | int16 | int32 | int64 | float | float32 | float64

type Rock* = object
    id: int
    msmt: float
    ts: float

type 
    Trace* = object
        timestamp*: int64
        cpuCores*: int16
        cpuCapacityProvisioned*: int32
        cpuUsage*: int32
        cpuUsagePercent*: float64
        memCapacityProvisioned*: int64
        memUsage*: int64
        memUsagePercent*: float64
        diskReadThroughput*: int32
        diskWriteThroughput*: int32
        diskSize*: int32
        networkReceivedThroughput*: int32
        networkTransmittedThroughput*: int32

#[
type Field = object
    name: string
    typ: string

type RivusType = object
    name: string
    fields: seq[Field]

proc readTypeFile(fileName: string): RivusType =
    let strm = newFileStream(fileName, fmRead)
    var line = ""
    defer: strm.close()
    discard strm.readLine(result.name)
    if not isNil(strm):
        while strm.readLine(line):
            let prop = line.split(" ")
            let field = Field(name: prop[0], typ: prop[1])
            result.fields.add(field)

proc evalScript(code: string, moduleName = "script.nim") =
    let stream = llStreamOpen(code)
    let std = findNimStdLibCompileTime()
    var intr = createInterpreter(moduleName, [std])
    intr.evalScript(stream)
    destroyInterpreter(intr)
    llStreamClose(stream)

proc assembleTypeSection(name: string, fields: seq[Field]): NimNode =
    var props = newNimNode(nnkRecList)
    for field in fields:
        props.add(newIdentDefs(
            ident(field.name),
            ident(field.typ)
        ))
    result = newNimNode(nnkStmtList).add(
        newNimNode(nnkTypeSection).add(
            newNimNode(nnkTypeDef).add(
                ident(name),
                newEmptyNode(),
                newNimNode(nnkObjectTy).add(
                    newEmptyNode(),
                    newEmptyNode(),
                    props
                )
            )
        )
    )

# type <name> = object
#     <key1>: <type1>
#     <key2>: <type2>
#     ...
macro genType*(fileName: string): untyped = 
    let res = readTypeFile(fileName.strVal)
    echo res
    let def = assembleTypeSection(res.name, res.fields)
    echo def.treeRepr
    return def
]#