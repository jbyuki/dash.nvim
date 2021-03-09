little_runner.nvim
==================

A script/program runner which outputs the result in a nicely formatted buffer.

**This is still work-in-progress.** 

It only supports lua currently.

Features
--------

### Diff output 

A basic diff algorithm highlights all the newly inserted lines in the output buffer. This is useful to quickly see which lines changes compared to the previous execution.

[![Untitled-Project.gif](https://i.postimg.cc/tCdtSvM0/Untitled-Project.gif)](https://postimg.cc/RNFHqdmG)

### Infinite loop guard

The execution is done completely is a sandboxed environnement. For lua, it spawns a new Neovim instance which will execute the script. The execution is done asynchronously and in case it prints infintely, **little_runner.nvim** will stop the execution after a certain number of lines has been reached.

This is an interesting workaround because executing a infinite loop through `luafile` will completely the client normally. Lua plugins developer are most likely familar with it. Although **little_runner.nvim** sandboxed execution is interesting, it can't be applied to plugin development.

[![Capture.png](https://i.postimg.cc/Y91KT3H4/Capture.png)](https://postimg.cc/PprRw1Nh)

Installation
------------

```vim
Plug 'jbyuki/little_runner.nvim'
```

Usage
-----

```vim
:LittleRun
```

Design
------

Guidelines which should guide the development of this plugin.

* The plugin should be functionnal with minimal configuration


Supported
---------

* [x] built-in lua
