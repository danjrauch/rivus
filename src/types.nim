import macros, sequtils

type number* = int | int8 | int16 | int32 | int64 | float | float32 | float64

# dumpTree:
#     type
#         bar = proc(a: string): string

# macro typeDef1(): untyped =
#     var parameters: seq[NimNode]
#     parameters = @[]
#     parameters.add(ident("string"))
#     parameters.add(newIdentDefs(ident("a"), ident("string"), newEmptyNode()))
#     result = #nnkStmtList.newTree(
#         nnkProcTy.newTree(
#             nnkFormalParams.newTree(
#                 ident("string"),
#                 nnkIdentDefs.newTree(
#                     ident("a"),
#                     ident("string"),
#                     newEmptyNode()
#                 )
#             ),
#             newEmptyNode()
#         )
#     #)
#     echo result.treeRepr

# type foo = typeDef1()

# type <name> = object
#     <key1>: <type1>
#     <key2>: <type2>
#     ...
macro typeDef*(name: static[string], keys, types: static[seq[string]]): untyped = 
    var props = newNimNode(nnkRecList)
    for key, val in items(zip(keys, types)):
        props.add(nnkIdentDefs.newTree(
            ident(key),
            ident(val),
            newEmptyNode()
        ))
    result = nnkStmtList.newTree(
        nnkTypeSection.newTree(
            nnkTypeDef.newTree(
                ident(name),
                newEmptyNode(),
                nnkObjectTy.newTree(
                    newEmptyNode(),
                    newEmptyNode(),
                    props
                )
            )
        )
    )
