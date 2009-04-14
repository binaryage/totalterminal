# Visor by [BlackTree](http://blacktree.com/)

Visor for OSX provides a systemwide terminal window accessible via a hot-key, much like the consoles found in games such as Quake.

![screenshot](http://cloud.github.com/downloads/darwin/visor/visor-screenshot-1.8.png)

## **[Download Visor 1.9 (precompiled binary)](http://cloud.github.com/downloads/darwin/visor/Visor-1.9-0b987b.zip)**
Tested on OSX 10.5.6 Leopard (Intel)

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

### Prerequisities:

  * [SIMBL](http://www.culater.net/software/SIMBL/SIMBL.php)
  * ruby + rubygems
  * XCode 3.0+
  * zip/unzip

### Installation

    git clone git://github.com/darwin/visor.git
    cd visor
    rake
    rake install

Feel free to fork and contribute.

## FAQ

#### I like the idea, but I want to use Terminal.app features. Do you plan to support tabs/unicode/whatever?
> Visor is just a light-weight wrapper of Terminal.app (SIMBL). You should be able to use all Terminal.app features with Visor.

#### My Visor menu-bar icon is dimmed out. My hot-key doesn't work and just beeps. What's wrong?
> There can be only one visor-ed terminal window in the system. If you close this terminal window (for example Control+D or typing exit in shell), Visor gets into disabled state you are describing. Just open a new terminal window and it gets visor-ed again. You can do it for example by clicking on Terminal.app icon in Dock.

#### How can I open a new terminal window the old way as a classic OSX window?
> If there is a visor-ed terminal window (Visor menu-bar icon is active) every new terminal window gets opened as a classic OSX window. In other words, open at least two terminal windows. Second one will be classic for sure.

#### How can I change a height of Visor?
> Go to Terminal.app preferences -> Window -> Rows

#### How can I stick Visor to left screen edge?
> Look for "Position" option in Visor Preferences and pick "Left-Stretch" window placement.

#### How can I change a width of Visor?
> By default Visor window does stretch to full screen width. Set some non-stretching positioning for Visor window in Visor Preferences, then Go to Terminal.app preferences -> Window -> Columns.

#### Is it possible to show Visor only on secondary monitor?
> Go to Visor Preferences -> Screen

#### Is it possible to see Visor on every space?
> Visor 1.6 does not respect spaces settings ([Issue 52](http://code.google.com/p/blacktree-visor/issues/detail?id=52)). Visor 1.7+ forces it's window to be visible on every space. You may disable it in Visor Preferences. Note: spaces configuration about Terminal.app doesn't apply to visor-ed terminal window, it is effective only for other (classic) terminal windows.

#### I want to keep different preferences for Visor and other (classic) terminal windows. What is the best way how manage it?
> Well, Terminal.app has preference sets called profiles and you can run new terminal windows with different profiles. Original version of Visor took "VisorTerminal" profile in case it was available. This was removed in latest version. Simply use Terminal.app ways how to start terminal window with preferred profile like you normally would. Visor doesn't touch your profile neither has special logic how to pick one.

## Articles about Visor

  * Featured Project in **[Rebase #13](http://github.com/blog/346-github-rebase-13)**, thanks [qrush](http://github.com/qrush)!

## History

* **v1.9** (14.04.2009)
  * [[Darwin][darwin]] Fixed bottom window is off-screen in left-stretch/right stretch mode ([Issue 60](http://code.google.com/p/blacktree-visor/issues/detail?id=60)).
  * [[Darwin][darwin]] Window size gets properly reset during switching Position in Preferences.
  * [[Darwin][darwin]] Added "Full Screen" option into Positions in Preferences ([Issue 57](http://code.google.com/p/blacktree-visor/issues/detail?id=57)).
  * [[Darwin][darwin]] Debug messages are not being logged in Release builds.
  * [[Darwin][darwin]] Visor restores focus of previous app only in case of closing with hotkey or ESC key ([Issue 67](http://code.google.com/p/blacktree-visor/issues/detail?id=67)).
  * [[Darwin][darwin]] Visor does not hang when trying to return focus to a hanging application ([Issue 64](http://code.google.com/p/blacktree-visor/issues/detail?id=64)).
  * [[Darwin][darwin]] Going to an empty space no more triggers visor terminal to appear ([Issue 58](http://code.google.com/p/blacktree-visor/issues/detail?id=58)).
  * [[Darwin][darwin]] Menu item changes title to "Hide Visor" when Visor is opened ([Issue 43](http://code.google.com/p/blacktree-visor/issues/detail?id=43)).
  * [[Darwin][darwin]] Fixed: Switching Space let Visor show and hide in an infinite loop ([Issue 61](http://code.google.com/p/blacktree-visor/issues/detail?id=61)).
  * [[Darwin][darwin]] Removed option "Main Screen" from Preferences/Screen ([Issue 59](http://code.google.com/p/blacktree-visor/issues/detail?id=59)).
  * [[Darwin][darwin]] Removed pin icon, toggle added under status menu ([Issue 56](http://code.google.com/p/blacktree-visor/issues/detail?id=56)).

* **v1.8.1** (05.03.2009)
  * [[Darwin][darwin]] Fixed "[NSUserDefaults setString:ForKey:]" crash on startup (affected upgrading users from 1.7 to 1.8). Reported by [Kleinman][kleinman], thanks.
  * [[Darwin][darwin]] Compilation from sources clears previous build folder (this could possibly make troubles for people developing Visor and then doing release [like me]).

* **v1.8** (04.03.2009)
  * [[Darwin][darwin]+[Cglee][cglee]] Visor can be positioned to other screen edges. Also non-stretching mode is possible. See Position in Visor Preferences. 
  * [[Darwin][darwin]] Visor window can be pinned, so it doesn't auto-hide (see icon in the top-right window corner).
  * [[Darwin][darwin]] Better behavior of confirmation sheets (Previously, sheet might appear on different space or might be hidden behind Visor window).
  * [[Darwin][darwin]] Custom build from sources is marked as "Custom", no need to specify version.

* **v1.7** (12.02.2009)
  * [[Darwin][darwin]] Visor appears on every space by default. You may disable it in Visor Preferences.
  * [[Darwin][darwin]] Visor is correctly hidden in fullscreen mode.
  * [[Darwin][darwin]] Visor plays nicely when screen resolution changes.
  * [[Pumpkin][pumpkin]] Fixed extra shadow under menu-bar.
  * [[Blinks][blinks]] Fixed rake install task for case there is no SIMBL plugins directory.

* **v1.6** (03.02.2009)
  * [[Darwin][darwin]] Build infrastructure.
  * [[Darwin][darwin]] It is possible to specify on which screen visor will appear - see preferences ([Issue 15](http://code.google.com/p/blacktree-visor/issues/detail?id=15)).
  * [[Darwin][darwin]] Visor exits gratefully without locking UI ([Issue 50](http://code.google.com/p/blacktree-visor/issues/detail?id=50)).
  * [[Darwin][darwin]] Visor becomes inactive when you close visor-ed terminal window or exit it's shell (fixes [Issue 10](http://code.google.com/p/blacktree-visor/issues/detail?id=10)).
  * [[Darwin][darwin]] When inactive, Visor eats next coming terminal window (right click terminal.app icon and select "new window").
  * [[Darwin][darwin]] Re-implemented window sliding animation using standard NSWindow functions, should fix weird bugs with mouse cursor state.
  * [[Darwin][darwin]] Removed support for Quartz powered backgrounds (want simpler codebase!).
  * [[Darwin][darwin]] Gentle terminal window hijacking (solves [Issue 5](http://code.google.com/p/blacktree-visor/issues/detail?id=5), [Issue 6](http://code.google.com/p/blacktree-visor/issues/detail?id=6) and related problems. What more? It properly enables [applescript automation in visor-ed terminal](http://onrails.org/articles/2007/11/28/scripting-the-leopard-terminal), which was my original motivation to get dirty with Visor internals).
  * [[Darwin][darwin]] Whenever you open Visor window, it steals focus and you may start typing without touching mouse. Visor is a good guy and returns the focus back to original app when being hidden. I said ... don't touch that mouse!
  * [[Torsten][torsten]] Fixed the "White Line Bug" ([Issue 16](http://code.google.com/p/blacktree-visor/issues/detail?id=16)).
  * [[Torsten][torsten]] Added the option to hide Visor on Escape press. Press Shift+Escape, if you need a "Escape" in the Terminal.
  * [[Torsten][torsten]] If you start Visor you get now initial focus. ([Issue 20](http://code.google.com/p/blacktree-visor/issues/detail?id=20)).

* **v1.5a1** (Nov 2007?)
  * Leopard Support

* **v1.2.1**
  * Fixed Choose File button

* **v1.2**
  * Added Animation Speed Preferences
  * Added Transition Preferences for Slide and Fade (both optional)
  * Menu Item is optional
  * Fix for users with Dock on top left or right (Visor appears above the dock)
  * Fixes animation glitches from alternate unsupported version.
  * New icon
  * No longer forked code - one version.
  
* **v1.1** (drparallax's unsupported version?)
  * Dismissing visor now 'slides up'
  * Options for animation
  * New icon

* **v1.0**
  * Initial release

## Original Visor 1.5 brought to you by [BlackTree](http://blacktree.com), kudos man!

Please see the [original website](http://code.google.com/p/blacktree-visor/) for more information, the issue tracker and so on.

## License

[Apache License 2.0](http://www.apache.org/licenses/LICENSE-2.0)

[darwin]: http://github.com/darwin
[torsten]: http://github.com/torsten
[pumpkin]: http://github.com/pumpkin
[blinks]: http://github.com/blinks
[cglee]: http://github.com/cglee
[kleinman]: http://github.com/kleinman
