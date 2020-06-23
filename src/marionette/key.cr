module Marionette
  enum Key
    Null        = 0xE000
    Cancel      = 0xE001 # ^break
    Help        = 0xE002
    Back_space  = 0xE003
    Tab         = 0xE004
    Clear       = 0xE005
    Return      = 0xE006
    Enter       = 0xE007
    Shift       = 0xE008
    LeftShift   = 0xE008 # alias
    Control     = 0xE009
    LeftControl = 0xE009 # alias
    Alt         = 0xE00a
    LeftAlt     = 0xE00a # alias
    Pause       = 0xE00b
    Escape      = 0xE00c
    Space       = 0xE00d
    PageUp      = 0xE00e
    PageDown    = 0xE00f
    End         = 0xE010
    Home        = 0xE011
    Left        = 0xE012
    ArrowLeft   = 0xE012 # alias
    Up          = 0xE013
    ArrowUp     = 0xE013 # alias
    Right       = 0xE014
    ArrowRight  = 0xE014 # alias
    Down        = 0xE015
    ArrowDown   = 0xE015 # alias
    Insert      = 0xE016
    Delete      = 0xE017
    Semicolon   = 0xE018
    Equals      = 0xE019

    Numpad0   = 0xE01a # number pad  keys
    Numpad1   = 0xE01b
    Numpad2   = 0xE01c
    Numpad3   = 0xE01d
    Numpad4   = 0xE01e
    Numpad5   = 0xE01f
    Numpad6   = 0xE020
    Numpad7   = 0xE021
    Numpad8   = 0xE022
    Numpad9   = 0xE023
    Multiply  = 0xE024
    Add       = 0xE025
    Separator = 0xE026
    Subtract  = 0xE027
    Decimal   = 0xE028
    Divide    = 0xE029

    F1  = 0xE031 # function  keys
    F2  = 0xE032
    F3  = 0xE033
    F4  = 0xE034
    F5  = 0xE035
    F6  = 0xE036
    F7  = 0xE037
    F8  = 0xE038
    F9  = 0xE039
    F10 = 0xE03a
    F11 = 0xE03b
    F12 = 0xE03c

    Meta    = 0xE03d
    Command = 0xE03d
  end
end
