
#include "LzmaLib.h"
#include <lua.h>
#include <lauxlib.h>
#include <assert.h>

#ifdef EJOY2D_OS
#include "array.h"
#else
#if defined(_MSC_VER)
#	include <malloc.h>
#	define ARRAY(type, name, size) type* name = (type*)_alloca((size) * sizeof(type))
#else
#	define ARRAY(type, name, size) type name[size]
#endif
#endif


#define LZMA_PROPS_SIZE 5
#define LENGTH_SIZE 4

static size_t
get_uncompress_size(const unsigned char* src) {
	return src[0] << 24 | src[1] << 16 | src[2] << 8 | src[3];
}

static int
uncompress(const unsigned char* src, size_t src_len, unsigned char* dst, size_t dst_len) {
	size_t len = src_len - LZMA_PROPS_SIZE;
	int res = LzmaUncompress(dst, &dst_len, &src[LZMA_PROPS_SIZE], &len, src, LZMA_PROPS_SIZE);
	return res;
}

static int
compress(const unsigned char* src, size_t src_len, unsigned char* dst, size_t* dst_len) {
	size_t props_len=LZMA_PROPS_SIZE;
	int res = LzmaCompress(&dst[LENGTH_SIZE+LZMA_PROPS_SIZE], dst_len, src, src_len, &dst[LENGTH_SIZE], &props_len, 
		5, 1<<16, 3, 0, 2, 32, 2);
	assert(props_len == LZMA_PROPS_SIZE);
	if (res==SZ_OK) {
		dst[0] = src_len >> 24;
		dst[1] = src_len >> 16;
		dst[2] = src_len >> 8;
		dst[3] = src_len;
	}
	return res;
}

static int
lcompress(lua_State* L) {
	const unsigned char* code = (unsigned char*)luaL_checkstring(L, 1);
	size_t len = lua_rawlen(L, 1);
	if (len <= LZMA_PROPS_SIZE)
		return luaL_error(L, "too short to compress");

	size_t dst_len = len + len/3 + 128;
	ARRAY(unsigned char, dst, LENGTH_SIZE+LZMA_PROPS_SIZE+dst_len);

	int ret = compress(code, len, dst, &dst_len);
	if (ret != SZ_OK) 
		return luaL_error(L, "Lzma compress failed:%d", ret);
	lua_pushlstring(L,(char*)dst, LENGTH_SIZE+LZMA_PROPS_SIZE + dst_len);
	return 1;
}

static int
luncompress(lua_State* L) {
	size_t len;
	const unsigned char* code = (unsigned char*)luaL_checklstring(L, 1, &len);
	if (len <= LZMA_PROPS_SIZE+LENGTH_SIZE)
		return luaL_error(L, "invalide lzma archive");

	size_t dst_len = get_uncompress_size(code);
	ARRAY(unsigned char, dst, dst_len);

	int ret = uncompress(&code[LENGTH_SIZE], len-LENGTH_SIZE, dst, dst_len);
	if (ret != SZ_OK)
		return luaL_error(L, "Lzma uncompress failed:%d", ret);
	lua_pushlstring(L, (char*)dst, dst_len);
	return 1;
}

int
luaopen_lzma(lua_State* L) {
  luaL_checkversion(L);
  luaL_Reg l[] = {
    {"compress", lcompress},
		{"uncompress", luncompress},
    {NULL, NULL},
  };

  luaL_newlib(L, l);

  return 1;
}

