#coding:utf-8

import json
import socket
import struct

MCAST_GRP = '224.0.0.224'
MCAST_PORT = 2606


def create_discover():
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM, socket.IPPROTO_UDP)
    sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    sock.setsockopt(socket.IPPROTO_IP, socket.IP_MULTICAST_TTL, 32)
    sock.setsockopt(socket.IPPROTO_IP, socket.IP_MULTICAST_LOOP, 1)

    try:
        sock.bind(('', MCAST_PORT))
    except Exception, e:
        sock.bind((MCAST_GRP, MCAST_PORT))

    mreq = struct.pack("4sl", socket.inet_aton(MCAST_GRP), socket.INADDR_ANY)
    sock.setsockopt(socket.IPPROTO_IP, socket.IP_ADD_MEMBERSHIP, mreq)
    sock.setblocking(0)
    return sock


def discover(sock):
    try:
        msg, addr = sock.recvfrom(4096)
        return json.loads(msg)
    except Exception, e:
        return None


def connect(ip, port):
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.settimeout(3)
    sock.connect((ip, port))
    sock.settimeout(0.3)
    return sock

# dict and True for alive socket, False for dead socket


def send(sock, exp):
    try:
        sock.send(exp)
    except Exception, e:
        if e != socket.timeout:
            return False
        else:
            return True

    ret = ""
    while True:
        try:
            ret += sock.recv(256)
        except Exception, e:
            # print(str(e)+str(len(ret)))
            if e == socket.error:
                return False
            if len(ret) > 0:
                break
    if ret == "":
        return True

    return json.loads(ret)

def send_file(sock, path):
    f = open(path, "r")
    exp = f.read()
    f.close()
    print("send file:"+path)
    return send(sock, exp)

def add_module(sock, path, mod_name):
    send_file(sock, path)

    return send(sock, '''add_module("%s")''' % mod_name)
