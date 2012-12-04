# TotalTerminal for OS X (previously known as Visor)

[TotalTerminal for OS X](http://totalterminal.binaryage.com) provides a system-wide terminal window accessible via a hot-key, much like the console in Quake.

<img src="http://totalterminal.binaryage.com/shared/img/visor-mainshot.png">

## Build a debug version

    git clone --recursive git@github.com:binaryage/totalterminal.git
    cd totalterminal
    xcodebuild -workspace TotalTerminal.xcworkspace -scheme "TotalTerminal Package" -configuration Debug

When successfull. The TotalTerminal.osax is placed into `~/Library/ScriptingAdditions/TotalTerminal.osax`.

To inject it into running Terminal.app use `st` alias (or `rt` alias is more convenient):

    # put these into your bash profile: ~/.profile
    alias kt='killall Terminal'
    alias qt='osascript -e "tell application \"Terminal\" to quit" && killall -SIGINT TotalTerminalCrashWatcher'
    alias st='osascript -e "tell application \"Terminal\" to «event BATTinit»"'
    alias rt='qt ; sleep 1 ; st'

Alternatively you may use `rake open` to open Xcode workspace. Switch to "TotalTerminal Package" scheme and build from within the IDE.