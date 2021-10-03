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

requires "nim >= 1.4.8"
requires "psutil"


# Tasks

task diagnostic, "run the rivus diagnostic checks":
    exec "nim c --hints:off -o:./bin/program -d:release -r src/rivuspkg/diagnostic.nim && rm -R ./bin"

task benchmark, "run the rivus benchmarks":
    exec "nim c --hints:off -o:./bin/program -d:release -r src/rivuspkg/benchmark.nim && rm -R ./bin"

task ci, "run tests, diagnostics, and benchmarks":
    exec "nimble test"
    exec "nimble diagnostic --silent"
    exec "nimble benchmark --silent"
