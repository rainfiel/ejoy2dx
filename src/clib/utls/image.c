
#include "texture.h"
#include "array.h"
#include "filesystem.h"
#include <array.h>

#include <stdint.h>
#include <stdbool.h>
#include <assert.h>
#include <string.h>

#include "lua.h"
#include "lauxlib.h"

#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"

#define STB_IMAGE_WRITE_IMPLEMENTATION
#include "stb_image_write.h"

static int
unload_texture(lua_State *L) {
	int id = (int)luaL_checkinteger(L,1);
	texture_unload(id);
	return 0;
}

static enum TEXTURE_FORMAT
comp_to_texture_format(int comp) {
	if (comp == 1) {
		return TEXTURE_A8;
	} else if (comp == 2) {
		return TEXTURE_RGBA4;
	} else if (comp == 3) {
		return TEXTURE_RGB;
	} else if (comp == 4) {
		return TEXTURE_RGBA8;
	}
	return TEXTURE_INVALID;
}

static int
loadimage_raw(lua_State *L) {
	const char * filename = luaL_checkstring(L, 1);
	int comp_req = (int)lua_tointeger(L, 2);

	struct FileHandle *handle = pf_fileopen(filename, "rb");
	if (handle == NULL){
		return luaL_error(L, "Can't open file %s", filename);
	}

	int buff_size = pf_filesize(handle);
	if (buff_size == 0){
		pf_fileclose(handle);
		return luaL_error(L, "file size is zero %s", filename);
	}
	unsigned char* buffer = (unsigned char*)malloc(buff_size);
	pf_fread(buffer, sizeof(unsigned char), buff_size, handle);
	pf_fileclose(handle);

	int x, y;
	int comp;
	unsigned char* img = stbi_load_from_memory(buffer, buff_size, &x, &y, &comp, comp_req);
	free(buffer);
	if (comp_req != 0){
		comp = comp_req;
	}

	enum TEXTURE_FORMAT type;
	if (img)
	{
		type = comp_to_texture_format(comp);
		if (type == TEXTURE_INVALID)
		{
			stbi_image_free(img);
			return luaL_error(L, "invalid texture format:%d, %s", comp, filename);
		}

		lua_pushnumber(L, x);
		lua_pushnumber(L, y);
		lua_pushnumber(L, comp);

		int size = x*y*comp*sizeof(unsigned char);
		//void* data = lua_newuserdata(L, size);
		//memcpy(data, img, size);

		lua_pushlstring(L, (char*)img, size);
		stbi_image_free(img);
	} else {
		return luaL_error(L, "stb load image failed:%s", filename);
	}

	return 4;
}

static int
do_texture_load(lua_State* L) {
	int id = (int)luaL_checkinteger(L,1);
	int x = (int)luaL_checkinteger(L, 2);
	int y = (int)luaL_checkinteger(L, 3);
	int comp = (int)luaL_checkinteger(L, 4);

	enum TEXTURE_FORMAT type = comp_to_texture_format(comp);
	if (type == TEXTURE_INVALID)
	{
		return luaL_error(L, "invalid texture format:%d", comp);
	}

	const char* img = luaL_checkstring(L, 5);
	int reduce = lua_tointeger(L, 6);

	const char* err = texture_load(id, type, x, y, (void*)img, reduce);

	if (err) {
		return luaL_error(L, "texture_load failed:%s", err);
	}
	return 0;
}

static int
loadimage(lua_State *L) {
	int id = (int)luaL_checkinteger(L,1);
	const char * filename = luaL_checkstring(L, 2);

	struct FileHandle *handle = pf_fileopen(filename, "rb");
	if (handle == NULL){
		return luaL_error(L, "Can't open file %s", filename);
	}

	int buff_size = pf_filesize(handle);
	if (buff_size == 0){
		pf_fileclose(handle);
		return luaL_error(L, "file size is zero %s", filename);
	}
	unsigned char* buffer = (unsigned char*)malloc(buff_size);
	pf_fread(buffer, sizeof(unsigned char), buff_size, handle);
	pf_fileclose(handle);

	int x, y;
	int comp;
	unsigned char* img = stbi_load_from_memory(buffer, buff_size, &x, &y, &comp, 0);
	free(buffer);

/*	for (int i = 0; i < y; i++)
	{
		for (int j = 0; j < x; j++)
		{
			int pix = i * x + j;
			for (int k = 0; k < 4; k++)
			{
				printf("%d ", (int)img[pix*4+k]);
			}
			printf(",");
		}
		printf("\n");
	}*/

	enum TEXTURE_FORMAT type;
	if (img) {
		type = comp_to_texture_format(comp);
		if (type == TEXTURE_INVALID)
		{
			stbi_image_free(img);
			return luaL_error(L, "invalid texture format:%d, %s", comp, filename);
		}
		const char* err = texture_load(id, type, x, y, img, 0);
		stbi_image_free(img);

		if (err) {
			return luaL_error(L, "texture_load failed:%s, %s", err, filename);
		}
	} else {
		return luaL_error(L, "stb load image failed:%s", filename);
	}

	lua_pushnumber(L, x);
	lua_pushnumber(L, y);
	lua_pushnumber(L, type);

	return 3;
}

static int
saveimage(lua_State *L) {
	const char * filename = luaL_checkstring(L, 1);
	int width = luaL_checkinteger(L, 2);
	int height = luaL_checkinteger(L, 3);
	int comp = luaL_checkinteger(L, 4);
	const char * buffer = luaL_checkstring(L, 5);
	int stride = luaL_checkinteger(L, 6);

	if (stbi_write_png(filename, width, height, comp, buffer, stride)==0)
		return 0;
	lua_pushboolean(L, 1);
	return 1;
}


static int
create_custom_texture(lua_State *L) {
	int id = (int)luaL_checkinteger(L,1);
	int width = (int)luaL_checkinteger(L, 2);
	int height = (int)luaL_checkinteger(L, 3);
	int comp = (int)luaL_checkinteger(L, 4);
	enum TEXTURE_FORMAT type = comp_to_texture_format(comp);

	if (type == TEXTURE_INVALID) {
		return luaL_error(L, "invalid texture comp:%d", comp);
	}

	size_t size;
	unsigned char * data = (unsigned char*)luaL_checklstring(L, 5, &size);
	if (size != width * height * comp * sizeof(unsigned char)) {
		return luaL_error(L, "invalid texture data size, %d != %dx%dx%d", size, width, height, comp);
	}

	const char *err = texture_load(id, type, width, height, data, 0);

	if (err) {
		return luaL_error(L, "custom texture_load failed:%s", err);
	}

	return 0;
}

static int
_texture_update(lua_State *L) {
	int id = (int)luaL_checkinteger(L, 1);
	int width = (int)luaL_checkinteger(L, 2);
	int height = (int)luaL_checkinteger(L, 3);
	unsigned char* data = (unsigned char*)luaL_checkstring(L, 4);
	const char* err = texture_update(id, width, height, data);

	if (err) {
		return luaL_error(L, "texture update failed:%s", err);
	}

	return 0;
}

static int
_texture_sub_update(lua_State *L) {
	int id = (int)luaL_checkinteger(L, 1);
	int x = (int)luaL_checkinteger(L, 2);
	int y = (int)luaL_checkinteger(L, 3);
	int width = (int)luaL_checkinteger(L, 4);
	int height = (int)luaL_checkinteger(L, 5);
	unsigned char* data = (unsigned char*)luaL_checkstring(L, 6);

	const char* err = texture_sub_update(id, x, y, width, height, data);
	if (err) {
		return luaL_error(L, "texture sub update failed:%s", err);
	}
	return 0;
}

static int
create_rt(lua_State* L) {
	int id = (int)luaL_checkinteger(L, 1);
	int w = (int)luaL_checkinteger(L, 2);
	int h = (int)luaL_checkinteger(L, 3);
	const char* err = texture_new_rt(id, w, h);
	if (err) {
		return luaL_error(L, "create new rt failed:%s", err);
	}
	return 0;
}

static int
delete_rt(lua_State* L) {
	int id = (int)luaL_checkinteger(L, 1);
	texture_delete_framebuffer(id);
	return 0;
}

static int
active_rt(lua_State*L ){
	int id = (int)luaL_checkinteger(L, 1);
	if (id < 0) {
		texture_reset_rt();
	} else {
		const char* err = texture_active_rt(id);
		if (err) {
			return luaL_error(L, "active rt failed:%s", err);
		}
	}
	return 0;
}

int
luaopen_image(lua_State *L) {
	//loadimage = image_rawdata + rawdata_to_texture
	luaL_Reg l[] = {
		{ "loadimage", loadimage },
		{ "image_rawdata", loadimage_raw },
		{ "rawdata_to_texture", do_texture_load },
		{ "saveimage", saveimage },
		{ "custom_texture", create_custom_texture },
		{ "texture_update", _texture_update },
		{ "texture_sub_update", _texture_sub_update },
		{ "unload_texture", unload_texture },

		{ "create_rt", create_rt }, 
		{ "delete_rt", delete_rt },
		{ "active_rt", active_rt },
		{ NULL, NULL },
	};

	luaL_newlib(L,l);

	return 1;
}
