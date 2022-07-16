#!/usr/bin env python3

import psutil


def memissue():
    print("内存信息:")
    mem = psutil.virtual_memory()
    # 单位换算为MB
    memtotal = mem.total / 1024 / 1024
    memused = mem.used / 1024 / 1024
    mempercentage = str(mem.used / mem.total * 100) + '%'

    print("Used: %.3fMB" % memused)
    print("Total: %.3fMB" % memtotal)
    print("Percentage: %.3f" % mempercentage)


def cpuissue():
    print("cpu信息")


memissue()
cpuissue()
