# Visor

Visor for OSX provides a systemwide terminal window accessible via a hot-key, much like the consoles found in games such as Quake.

![screenshot](http://github.com/darwin/visor/blob/master/support/screenshot.png?raw=true)

## Latest release

**[Visor 1.6](TODO link)**

Tested on OSX 10.5.6 Leopard.

## Installation

  * [Install SIMBL](http://www.culater.net/software/SIMBL/SIMBL.php)
  * Place Visor.bundle in ~/Library/Application Support/SIMBL/Plugins
  * (Re)launch Terminal.app - You should now see the Visor menu item ![icon](http://github.com/darwin/visor/blob/master/src/VisorActive.png?raw=true)
  * Configure your keyboard trigger by selecting the Visor menu item -> preferences and editing your keyboard hot-key

You can now trigger Visor with your hotkey from any application to get an instant terminal session. 

To hide Visor, you can either:

  * re-trigger with your key-combo
  * optionally you can click off of the Visor window
  * or you can also enable "Visor hiding on Esc" in preferences
  * use the logout key-combo (control+d) to close the Visor window
  * type "exit" in running shell to close it

## Installation from sources

Prerequisities:

  * ruby + rubygems
  * XCode 3.0
  * zip/unzip

### Installation

    git clone git://github.com/darwin/visor.git
    cd visor
    rake release version=1.6
    rake install

### Publishing
    
    cd visor
    git tag -a v1.6 -m "Release 1.6"
    git push --tags
    rake release version=1.6
    rake publish

# History

* v1.6 (03.02.2009)
  * first GitHub release == packaged pending changes from GitHub forks

## original Visor 1.5 brought to you by [BlackTree](http://blacktree.com), kudos man!

Please see the [original website](http://code.google.com/p/blacktree-visor/) for more information, the issue tracker and so on.

## additional fixes by Torsten

* Fixed the "White Line Bug" ([Issue 16](http://code.google.com/p/blacktree-visor/issues/detail?id=16))
* Added the option to hide Visor on Escape press.
  Press Shift+Escape, if you need a "Escape" in the Terminal.
* If you start Visor you get now initial focus. ([Issue 20](http://code.google.com/p/blacktree-visor/issues/detail?id=20))

## additional fixes by Darwin

* Build infrastructure
* It is possible to specify on which screen visor will appear - see preferences ([Issue 15](http://code.google.com/p/blacktree-visor/issues/detail?id=15))
* Visor exits gratefully without locking UI ([Issue 50](http://code.google.com/p/blacktree-visor/issues/detail?id=50))
* Visor becomes inactive when you close visor-ed terminal window or exit it's shell (fixes [Issue 10](http://code.google.com/p/blacktree-visor/issues/detail?id=10))
* When inactive, Visor eats next coming terminal window (right click terminal.app icon and select "new window")
* Re-implemented window sliding animation using standard NSWindow functions, should fix weird bugs with mouse cursor state
* Removed support for Quartz powered backgrounds (want simpler codebase!)
* Gentle terminal window hijacking (solves [Issue 5](http://code.google.com/p/blacktree-visor/issues/detail?id=5), [Issue 6](http://code.google.com/p/blacktree-visor/issues/detail?id=6) and related problems. What more? It properly enables [applescript automation in visor-ed terminal](http://onrails.org/articles/2007/11/28/scripting-the-leopard-terminal), which was my original motivation to get dirty with Visor internals)
* Whenever you open Visor window, it steals focus and you may start typing without touching mouse. Visor is a good guy and returns the focus back to original app when being hidden. I said ... don't touch that mouse!