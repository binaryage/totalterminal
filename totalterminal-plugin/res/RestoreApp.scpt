-- see: http://lists.apple.com/archives/Applescript-users/2007/Mar/msg00265.html

-- related issues:
--   Visor launches app when returning focus (http://github.com/darwin/visor/issues#issue/8)
--   Visor crashes when trying to return focus to non-running application? (http://github.com/darwin/visor/issues#issue/12)

on restoreApp(appName)
    with timeout of 1 second
        tell application appName
            activate
        end tell
    end timeout
end restoreApp

restoreApp("%@")