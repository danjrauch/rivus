import sugar
import db

proc filter*[T](db: Rivus[T], fun: (e: T) -> bool): seq[T] =
    for poolNum in 0..<db.nWrittenPools:
        let pool = db.melt(poolNum, T)
        for rock in pool.items:
            if fun(rock):
                result.add(rock) 
