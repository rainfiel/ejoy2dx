#ifndef WINDOWS_COMPAT_H
#define WINDOWS_COMPAT_H

#include <WinSock2.h>
#include <ws2tcpip.h>
#include <stdint.h>
#include <lua.h>
#include <lauxlib.h>

#define SO_NOSIGPIPE 0		// ignore it, don't support

#ifndef WIN_COMPAT_IMPL

#define getsockopt win_getsockopt
#define setsockopt win_setsockopt

#endif

int win_getsockopt(int sockfd, int level, int optname, void *optval, socklen_t *optlen);
int win_setsockopt(int sockfd, int level, int optname, const void *optval, socklen_t optlen);

const char *inet_ntop(int af, const void *src, char *dst, socklen_t size);

#endif
