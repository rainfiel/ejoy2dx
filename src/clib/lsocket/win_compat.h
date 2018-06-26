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
#define close closesocket
#ifdef errno
#undef errno
#endif
#define errno WSAGetLastError()

#define EAGAIN WSATRY_AGAIN
#define EWOULDBLOCK WSAEWOULDBLOCK
// In windows, connect returns WSAEWOULDBLOCK rather than WSAEINPROGRESS
#define EINPROGRESS WSAEWOULDBLOCK

#endif

#ifdef _WIN32
#define snprintf c99_snprintf
inline int c99_vsnprintf(char* str, size_t size, const char* format, va_list ap)
{
    int count = -1;

    if (size != 0)
        count = _vsnprintf_s(str, size, _TRUNCATE, format, ap);
    if (count == -1)
        count = _vscprintf(format, ap);

    return count;
}
inline int c99_snprintf(char* str, size_t size, const char* format, ...)
{
    int count;
    va_list ap;

    va_start(ap, format);
    count = c99_vsnprintf(str, size, format, ap);
    va_end(ap);

    return count;
}
#endif

int win_getsockopt(int sockfd, int level, int optname, void *optval, socklen_t *optlen);
int win_setsockopt(int sockfd, int level, int optname, const void *optval, socklen_t optlen);

// only support fcntl(fd, F_SETFL, O_NONBLOCK)
#define F_SETFL 0
#define O_NONBLOCK 0
int fcntl(int fd, int cmd, int value);
const char *inet_ntop(int af, const void *src, char *dst, socklen_t size);

typedef u_short sa_family_t;

// Windows doesn'y support AF_UNIX, this structure is only for avoiding compile error
#define UNIX_PATH_MAX    108

struct sockaddr_un {
   sa_family_t sun_family;	/* AF_UNIX */
   char sun_path[UNIX_PATH_MAX];	/* pathname */
};

#define SOCKADDR_BUFSIZ (sizeof(struct sockaddr_un) + UNIX_PATH_MAX + 1)

void init_socketlib(lua_State *L);
int win_getinterfaces(lua_State *L);

#endif
