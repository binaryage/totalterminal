# Visor

In a nutshell: "Visor provides a systemwide terminal window accessible via a hotkey, much like the consoles found in games such as Quake."

## fixes by Torsten

This is my fork of the project, as I wanted to have some additional features and some bugs fixed.  Currently this is what is different from the original:

* Fixed the "White Line Bug" ([Issue 16](http://code.google.com/p/blacktree-visor/issues/detail?id=16))
* Added the option to hide Visor on Escape press.
  Press Shift+Escape, if you need a "Escape" in the Terminal.
* If you start Visor you get now initial focus. ([Issue 20](http://code.google.com/p/blacktree-visor/issues/detail?id=20))

## fixes by Antonin

* Gentle terminal window hijacking (solves [Issue 5](http://code.google.com/p/blacktree-visor/issues/detail?id=5), [Issue 6](http://code.google.com/p/blacktree-visor/issues/detail?id=6) and related problems. What more? It properly enables [applescript automation in visor-ed terminal](http://onrails.org/articles/2007/11/28/scripting-the-leopard-terminal), which was my original motivation to get dirty with Visor internals)
* Whenever you open Visor window, it steals focus and you may start typing without touching mouse. Visor is a good guy and returns the focus back to original app when being hidden. I said ... don't touch that mouse!

Please see the [original website](http://code.google.com/p/blacktree-visor/) for more information, the issue tracker and so on.
