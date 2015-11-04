#!/usr/bin/env python

# Simple hardware simulation server.
#
# Lists on a socket port and performs the appropriate exchange to implement
# hardware reading and writing.

import socket
import struct


class SocketFail(Exception):
    pass

# Ensures exactly n bytes are read from sock
def read(sock, n):
    result = ''
    while len(result) < n:
        rx = sock.recv(n - len(result))
        if not rx:
            raise SocketFail('End of input')
        result = result + rx
    return result


sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
sock.bind(('localhost', 9999))
sock.listen(0)


state = {}

def do_read(block, num, reg):
    print 'do_read', block, num, reg
    return state.setdefault((block, num, reg), 0x55555555)

def do_write(block, num, reg, value):
    print 'do_write', block, num, reg, repr(value)
    state[(block, num, reg)] = value


def run_simulation(conn):
    while True:
        command, block, num, reg = struct.unpack('cBBB', read(conn, 4))
        if command == 'R':
            tx = do_read(block, num, reg)
            conn.sendall(struct.pack('I', tx))
        elif command == 'W':
            value, = struct.unpack('I', read(conn, 4))
            do_write(block, num, reg, value)
        else:
            print 'Unexpected command', repr(command)
            raise SocketFail('Unexpected command')


(conn, addr) = sock.accept()
conn.setsockopt(socket.SOL_TCP, socket.TCP_NODELAY, 1)
try:
    run_simulation(conn)
except SocketFail:
    print 'Simulation closed'