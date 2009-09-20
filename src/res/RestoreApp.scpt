-- see: http://lists.apple.com/archives/Applescript-users/2007/Mar/msg00265.html

-- related issues:
--   Visor launches app when returning focus (http://github.com/darwin/visor/issues#issue/8)
--   Visor crashes when trying to return focus to non-running application? (http://github.com/darwin/visor/issues#issue/12)

on appIsRunning(appName)
    tell application "System Events"
        repeat with p in processes
            set f to file of p
            try
                set u to POSIX path of f
                if u is appName then return true
            end try
        end repeat
    end tell
    return false
end appIsRunning

on restoreApp(appName)
    with timeout of 1 second
        if appIsRunning(appName) then
            tell application appName
                activate
            end tell
        end if
    end timeout
end restoreApp

restoreApp("%@")