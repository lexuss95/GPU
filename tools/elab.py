#!/usr/bin/env python3
"""Strict elaboration of the RTL with slang (via pyslang).

Usage: elab.py [slang options...]   e.g. elab.py -f rtl/files.f --top gpu_top

Accepts the same options as the slang command-line tool. Prints slang's
diagnostics and exits non-zero if there is any error (warnings are errors too).
"""
import sys

from pyslang.driver import CommandLineOptions, Driver


def main() -> int:
    driver = Driver()
    driver.addStandardArgs()
    cmdline = " ".join(["slang", "--error-limit=50", "-Werror"] + sys.argv[1:])
    if not driver.parseCommandLine(cmdline, CommandLineOptions()):
        return 2
    if not driver.processOptions():
        return 2
    if not driver.parseAllSources():
        return 1
    compilation = driver.createCompilation()
    driver.reportCompilation(compilation, False)
    ok = driver.reportDiagnostics(False)
    print("elab: PASS" if ok else "elab: FAIL")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
