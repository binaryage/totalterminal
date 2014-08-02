# TotalTerminal for OS X

[TotalTerminal for OS X](http://totalterminal.binaryage.com) provides a system-wide terminal window accessible via a hot-key, much like the console in Quake.

<img src="http://totalterminal.binaryage.com/shared/img/visor-mainshot.png">

## TotalTerminal is no longer open-source

TotalTerminal was forked and the latest version from BinaryAge is private. You can find last published open-source version in [master branch of this repo](https://github.com/binaryage/totalterminal/tree/master). I have announced it in [this blog post](http://blog.binaryage.com/surfing-mavericks). 

## What was the reason?

I'm also developer of closed-source app called [TotalFinder](http://totalfinder.binaryage.com). Both TotalFinder and TotalTerminal are plugins into native Mac apps (SIMBL plugins) and could gain by sharing common library code. I have developed a lot of SIMBL-related reusable code in TotalFinder and I wanted to reuse it in TotalTerminal. This would help me to maintain TotalTerminal codebase more effectively. The problem was that I'm not confortable open-sourcing all that work from TotalFinder at this point. TotalFinder is a paid app and inspired [active competition](http://www.trankynam.com/xtrafinder) who implemented most TotalFinder features in their free product. Competition is good, but sharing this code would simply help them without much benefit on my side.

If you want to contribute to TotalTerminal, please [contact me](mailto:antonin@binaryage.com) and I will consider sharing access to the private repo.