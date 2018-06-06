
#import "liosutil.h"
#import "ejoy2dgame.h"
#import <UIKit/UIKit.h>
#import "UIAlertView+Blocks.h"

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
  const char* cancelButtonTitle = luaL_optstring(L, 3, nil);
  const char* okButtonTitle = luaL_checkstring(L, 4);
  const char* defaultText = luaL_checkstring(L,5);
  int style = (int)luaL_optinteger(L, 6, 0);
  int max_len = (int)luaL_optinteger(L, 7, 256);
  
  if(s_txt_len_limiter == nil){
    s_txt_len_limiter = [[TextLenLimiter alloc] init];
  }
  s_txt_len_limiter.maxlen = max_len;
  
  RIButtonItem *okItem = [RIButtonItem item];
  okItem.label = [NSString stringWithUTF8String:okButtonTitle];
  
  okItem.action = ^(UIAlertView * alertView)
  {
    NSString *inputText = [[alertView textFieldAtIndex:0] text];
    NSLog(@"input text:%@ for iid %d", inputText, iid);
    ejoy2d_game_message_l(L, iid, "FINISH", [inputText UTF8String], 0);
  };
  
  NSString *title = [NSString stringWithUTF8String:strTitle];
  UIAlertView *alertView = nil;
  if (cancelButtonTitle) {
    RIButtonItem *cancelItem = [RIButtonItem item];
    cancelItem.label = [NSString stringWithUTF8String:cancelButtonTitle];
    cancelItem.action = ^(UIAlertView *alertView)
    {
      NSLog(@"cancel input for iid %d", iid);
      ejoy2d_game_message_l(L, iid, "CANCEL", nil, 0);
    };
    
    alertView = [[UIAlertView alloc] initWithTitle:title message:nil cancelButtonItem:cancelItem otherButtonItems:okItem, nil];
  }else{
    alertView = [[UIAlertView alloc] initWithTitle:title message:nil cancelButtonItem:okItem otherButtonItems:nil, nil];
  }
  [alertView setAlertViewStyle:UIAlertViewStylePlainTextInput];
  [[alertView textFieldAtIndex:0] setKeyboardType:(UIKeyboardType)style];
  [[alertView textFieldAtIndex:0] setDelegate:s_txt_len_limiter];
  
  if (defaultText) {
    UITextField *textField = [alertView textFieldAtIndex:0];
    textField.text = [NSString stringWithUTF8String:defaultText];
  }
  [alertView show];
  lua_pushboolean(L, true);
  return 1;
}

int luaopen_input(lua_State* L) {
	luaL_checkversion(L);

	luaL_Reg l[] = {
    {"input", _input},
		
		{NULL, NULL}
	};

	luaL_newlib(L, l);
	return 1;
}
