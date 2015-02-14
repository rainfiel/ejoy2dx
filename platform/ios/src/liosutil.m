
#import "liosutil.h"

static int
_exists(lua_State* L) {
  const char* path = luaL_checkstring(L, 1);
  NSString* nsPath = [NSString stringWithUTF8String:path];
  NSFileManager* fm = [NSFileManager defaultManager];
  lua_pushboolean(L, ([fm fileExistsAtPath:nsPath] == YES));
  return 1;
}

static int
_read_file(lua_State* L) {
  const char* path = luaL_checkstring(L, 1);
  NSString* nsPath = [NSString stringWithUTF8String:path];
  NSFileManager* fm = [NSFileManager defaultManager];
  if([fm fileExistsAtPath:nsPath] == NO) {
    return luaL_error(L, "file not found!!!!!!!!!! %s", path);
  }
	
  NSFileHandle* fh = [NSFileHandle fileHandleForReadingAtPath:nsPath];
  if(fh == nil) {
    return luaL_error(L, "file not exist!!!!!!!!!! %s", path);
  }
	
  NSData* data = [fh readDataToEndOfFile];
  [fh closeFile];
	
  lua_pushlstring(L, data.bytes, data.length);
  return 1;
}


static int
_write_file(lua_State* L) {
  const char* path = luaL_checkstring(L, 1);
  size_t data_len;
  const char* data = luaL_checklstring(L, 2, &data_len);
	
  NSString* nsPath = [NSString stringWithUTF8String:path];
  NSFileManager* fm = [NSFileManager defaultManager];
  if([fm fileExistsAtPath:nsPath] == NO) {
    if([fm createFileAtPath:nsPath contents:nil attributes:nil] == NO) {
      return luaL_error(L, "write_file failed: %s", errno);
    }
  }
	
  NSData* nsData = [NSData dataWithBytes:data length:data_len];
  NSFileHandle* fh = [NSFileHandle fileHandleForWritingAtPath:nsPath];
  [fh truncateFileAtOffset:0];
  [fh writeData:nsData];
  [fh closeFile];
  return 0;
}

static int
_delete_file(lua_State* L) {
  const char* path = luaL_checkstring(L, 1);
  NSString* nsPath = [NSString stringWithUTF8String:path];
  NSFileManager* fm = [NSFileManager defaultManager];
  if([fm fileExistsAtPath:nsPath] == NO) {
    return 0;
  }
	
  NSError* error;
  if([fm removeItemAtPath:nsPath error:&error] != YES) {
    return luaL_error(L, "unable to delete file: %s", [[error localizedDescription] UTF8String]);
  }
  return 0;
}


int luaopen_osutil(lua_State* L) {
	luaL_checkversion(L);

	luaL_Reg l[] = {
		{"exists", _exists},
		{"read_file", _read_file},
		{"write_file", _write_file},
		{"delete_file", _delete_file},
		
		{NULL, NULL}
	};

	luaL_newlib(L, l);
	return 1;
}
