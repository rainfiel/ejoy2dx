
local sprite = require "ejoy2d.sprite"
local fw = require "ejoy2d.framework"

local ejoy2dx = {}

ejoy2dx.texture = require("ejoy2dx.texture")
ejoy2dx.texture:init()

ejoy2dx.package = require("ejoy2dx.package")
function ejoy2dx.sprite(package, name)
	ejoy2dx.package:prepare_package(package)
	return sprite.new(package, name)
end

ejoy2dx.render = require("ejoy2dx.render")
ejoy2dx.render:init(fw.GameInfo.width, fw.GameInfo.height)

ejoy2dx.animation = require("ejoy2dx.animation")
ejoy2dx.animation:init(fw.GameInfo.logic_frame)

ejoy2dx.game_stat = require("ejoy2dx.game_stat")

  --gesture states, defined in winfw.h
ejoy2dx.STATE_POSSIBLE = 0
ejoy2dx.STATE_BEGAN = 1
ejoy2dx.STATE_CHANGED = 2
ejoy2dx.STATE_ENDED = 3
ejoy2dx.STATE_CANCELLED = 4
ejoy2dx.STATE_FAILED = 5

 --input style
 ejoy2dx.INPUT_STYLE_DEFAULT = 0
 ejoy2dx.INPUT_STYLE_NUMBER = 4
-- UIKeyboardTypeDefault,                // Default type for the current input method.
-- UIKeyboardTypeASCIICapable,           // Displays a keyboard which can enter ASCII characters, non-ASCII keyboards remain active
-- UIKeyboardTypeNumbersAndPunctuation,  // Numbers and assorted punctuation.
-- UIKeyboardTypeURL,                    // A type optimized for URL entry (shows . / .com prominently).
-- UIKeyboardTypeNumberPad,              // A number pad (0-9). Suitable for PIN entry.
-- UIKeyboardTypePhonePad,               // A phone pad (1-9, *, 0, #, with letters under the numbers).
-- UIKeyboardTypeNamePhonePad,           // A type optimized for entering a person's name or phone number.
-- UIKeyboardTypeEmailAddress,           // A type optimized for multiple email address entry (shows space @ . prominently).
-- UIKeyboardTypeDecimalPad NS_ENUM_AVAILABLE_IOS(4_1),   // A number pad with a decimal point.
-- UIKeyboardTypeTwitter NS_ENUM_AVAILABLE_IOS(5_0),      // A type optimized for twitter text entry (easy access to @ #)
-- UIKeyboardTypeWebSearch NS_ENUM_AVAILABLE_IOS(7_0),    // A default keyboard type with URL-oriented addition (shows space . prominently).

return ejoy2dx
