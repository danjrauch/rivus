# Package

version       = "0.1.0"
author        = "Dan Rauch"
description   = "A small time series database"
license       = "MIT"
srcDir        = "src"
installExt    = @["nim"]
binDir        = "bin"
bin           = @["rivus"]


# Dependencies

requires "nim >= 1.5.1"
#requires "compiler >= 1.5.1"


# Tasks

task benchmark, "run the rivus benchmarks":
    exec "nim c -o:./bin/program -d:release -r src/rivuspkg/benchmark.nim && rm -R ./bin"