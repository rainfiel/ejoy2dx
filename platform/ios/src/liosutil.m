
#import "liosutil.h"
#import "ejoy2dgame.h"
#import <UIKit/UIKit.h>

static UIViewController *controller=NULL;
void set_view_controller(void *p) {
    controller  = (__bridge UIViewController*)p;
}

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

@interface TextLenLimiter : UITextField<UITextFieldDelegate>
@property
  int  maxlen;
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string;
@end

@implementation TextLenLimiter

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
  NSString *newString = [textField.text stringByReplacingCharactersInRange:range withString:string];
  
  if (newString.length > self.maxlen)
  {
    return NO;
  }
  
  return YES;
}
@end

static TextLenLimiter *s_txt_len_limiter = nil;

static int
_input(lua_State* L) {
    const char* strTitle = luaL_checkstring(L,1);
    int iid = (int)luaL_checkinteger(L, 2);
    const char* cancelButtonTitle = luaL_optstring(L,3, nil);
    const char* okButtonTitle = luaL_checkstring(L, 4);
    const char* defaultText = luaL_optstring(L,5, nil);
  
    int style = (int)luaL_optinteger(L, 6, 0);
    int max_len = (int)luaL_optinteger(L, 7, 256);
  
    if(s_txt_len_limiter == nil){
      s_txt_len_limiter = [[TextLenLimiter alloc] init];
    }
    s_txt_len_limiter.maxlen = max_len;
	
		NSString *title = [NSString stringWithUTF8String:strTitle];
		UIAlertController *alertView = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleAlert];
	
		[alertView addTextFieldWithConfigurationHandler:^(UITextField *textField)
			{
				if (defaultText) {
					textField.text = [NSString stringWithUTF8String:defaultText];
				}
				[textField setKeyboardType:(UIKeyboardType)style];
				[textField setDelegate:s_txt_len_limiter];
			}];
	
		UIAlertAction *okAction = [UIAlertAction actionWithTitle:[NSString stringWithUTF8String:okButtonTitle] style:UIAlertActionStyleDefault
																									 handler:^(UIAlertAction *action)
														 {
															 UITextField * textField = alertView.textFields.firstObject;
															 ejoy2d_game_message_l(L, iid, "FINISH", [textField.text UTF8String], 0);
                                                             [alertView.view removeFromSuperview];
														 }];
		[alertView addAction:okAction];
	
		if (cancelButtonTitle) {
			UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:[NSString stringWithUTF8String:cancelButtonTitle] style:UIAlertActionStyleDefault
																													 handler:^(UIAlertAction *action)
																		 {
																			 ejoy2d_game_message_l(L, iid, "CANCEL", nil, 0);
                                                                             [alertView.view removeFromSuperview];
																		 }];
			[alertView addAction:cancelAction];
		}
    
    bool loaded = [controller isViewLoaded];
    [controller.view addSubview:alertView.view];
    [controller presentViewController:alertView animated:YES completion:nil];
    lua_pushboolean(L, true);
    return 1;
}

// modes:
//   "d" for Documents
//   "l" for Library
//   "c" for Caches
static int
_get_path(lua_State* L) {
	const char* filename = luaL_checkstring(L, 1);
	const char* mode = luaL_checkstring(L, 2);
	NSSearchPathDirectory directory;
	if(mode[0] == 'd') {
		directory = NSDocumentDirectory;
	} else if(mode[0] == 'l') {
		directory = NSLibraryDirectory;
	} else if(mode[0] == 'c') {
		directory = NSCachesDirectory;
	} else {
		return luaL_error(L, "unknown mode '%s' for 'get_path'", mode);
	}
	
	NSArray *paths = NSSearchPathForDirectoriesInDomains(directory, NSUserDomainMask, YES);
	if([paths count] == 0) {
		return luaL_error(L, "NSSearchPathForDirectoriesInDomains returns nothing!");
	}
	
	NSString* nsFilename = [NSString stringWithUTF8String:filename];
	NSString* path = [[paths objectAtIndex:0] stringByAppendingPathComponent:nsFilename];
	lua_pushstring(L, [path UTF8String]);
	return 1;
}

static int
_create_directory(lua_State* L){
  const char* dir_path = luaL_checkstring(L, 1);
  int b = [[NSFileManager defaultManager] createDirectoryAtPath:[NSString stringWithUTF8String:dir_path]
                                    withIntermediateDirectories:NO
                                                     attributes:nil
                                                          error:nil];
  lua_pushboolean(L, b);
  return 1;
}

int luaopen_osutil(lua_State* L) {
	luaL_checkversion(L);

	luaL_Reg l[] = {
		{"exists", _exists},
		{"read_file", _read_file},
		{"write_file", _write_file},
		{"delete_file", _delete_file},
		{"get_path", _get_path},
		{"create_directory", _create_directory},
		
		{NULL, NULL}
	};

	luaL_newlib(L, l);
	return 1;
}
