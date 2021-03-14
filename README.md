little-runner.nvim
==================

A script/program runner which outputs the result in a nicely formatted buffer.

**This is still work-in-progress.** 

Supported
---------

* :seedling: : Supports but still unstable.
* :deciduous_tree: : Stable.

| Language | Execute | Quickfix |
|----------|:-------:|:--------:|
| _Lua_ | :seedling: | :seedling: |
| _Python_ | :seedling: | |

Can be used in conjunction with [ntangle.nvim](https://github.com/jbyuki/ntangle.nvim).

Features
--------

### Diff output 

A basic diff algorithm highlights all the newly inserted lines in the output buffer. This is useful to quickly see which lines changes compared to the previous execution.

<img src="https://i.postimg.cc/tCdtSvM0/Untitled-Project.gif" width="300">

### Infinite loop guard

The execution is done completely is a sandboxed environnement. For lua, it spawns a new Neovim instance which will execute the script. The execution is done asynchronously and in case it prints infintely, **little-runner.nvim** will stop the execution after a certain number of lines has been reached.

This is an interesting workaround because executing a infinite loop through `luafile` will freeze the client normally. Lua plugins developer are most likely familar with it. Although **little-runner.nvim** sandboxed execution is interesting, it can't be applied to plugin development.

<img src="https://i.postimg.cc/Y91KT3H4/Capture.png" width="300">

### Fill Quickfix 

You can navigate instantly to the error line.

<img src="https://i.postimg.cc/QN5pTptH/Capture.png" width="300">

Installation
------------

Install using your favorite plugin manager. For example using [vim-plug](https://github.com/junegunn/vim-plug).

```vim
Plug 'jbyuki/little-runner.nvim'
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

Help
----

* If you encounter any problem, please don't hesitate to open an [Issue](https://github.com/jbyuki/little-runner.nvim/issues).
* All contributions are welcome.
