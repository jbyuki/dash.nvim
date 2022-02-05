dash.nvim
==================

A fast and safe script runner which outputs the result in a nicely formatted buffer.

**This is still work-in-progress.** 

Supported
---------

* :seedling: : Supports but still unstable.
* :deciduous_tree: : Stable.

| Language | Execute | Visual | Quickfix | Debugger |
|----------|:-------:|:--------:|:--------:|:--------:|
| _Lua_ | :seedling: | :seedling: | :seedling: | :seedling: |
| _Python_ | :seedling: | :seedling: | | |
| _Fennel_ | :seedling: | :seedling: | | |
| _nodejs_ | :seedling: | :seedling: | | |
| _Vimscript_ | :seedling: || :seedling: | |
| _C++ / Visual Studio_ | :seedling: || :seedling: | |
| Matlab | || | |
| _Kotlin, Java / Android_ | :seedling: || :seedling:| |
| _Latex_ | :seedling: || | |
| Go | :seedling: || | |
| GLSL / glslc | :seedling: || | |

Can be used in conjunction with [ntangle.nvim](https://github.com/jbyuki/ntangle.nvim).

**Visual**: Execution of a visual selection

**Remark**: I'm still debating if the lua debugger belongs here. But for convenience, I won't do a separate plugin for now.


Features
--------

### Diff Output 

A basic diff algorithm highlights all the newly inserted lines in the output buffer. This is useful to quickly see which lines changes compared to the previous execution.

<img src="https://i.postimg.cc/TY2GCX0S/Untitled-Project.gif" width="500">

### Infinite Loop Guard

The execution is done completely is a sandboxed environnement. For lua, it spawns a new Neovim instance which will execute the script. The execution is done asynchronously and in case it prints infintely, **little-runner.nvim** will stop the execution after a certain number of lines has been reached.

This is an interesting workaround because executing a infinite loop through `luafile` will freeze the client normally. Lua plugins developer are most likely familar with it. Although **little-runner.nvim** sandboxed execution is interesting, it can't be applied to plugin development.

<img src="https://i.postimg.cc/Qdkg0Wqg/Untitled-Project.gif" width="500">

### Fill Quickfix 

You can navigate instantly to the error line.

<img src="https://i.postimg.cc/QN5pTptH/Capture.png" width="500">

### Multi Language Support

It supports multiple languages out of the box. More support will be added as the plugin is evolving.

<img src="https://i.postimg.cc/x1ZyCnqb/Untitled-Project.gif" width="500">

### Debugger

Vimscript has some good debugging support but lua has only `debug.debug()` which is insufficient in my opinion. This still breaks often and lacks features but offers some support for debugging. It's a prototype for more to come.

<img src="https://i.postimg.cc/qvfrwzY0/Untitled-Project.gif" width="500">

Start the debugger with `:DashDebug`.

* Place breakpoint: `require"dash".toggle_breakpoint()`
* Step: `require"dash".step()`
* Continue: `require"dash".continue()`
* Inspect variable: `require"dash".inspect()`
* Inspect variable (visual): `require"dash".vinspect()`

Installation
------------

Install using your favorite plugin manager. For example using [vim-plug](https://github.com/junegunn/vim-plug).

```vim
Plug 'jbyuki/dash.nvim'
```

Usage
-----

```vim
:DashRun
```

Design
------

Guidelines which should guide the development of this plugin.

* The plugin should be functionnal with minimal configuration

Help
----

* If you encounter any problem, please don't hesitate to open an [Issue](https://github.com/jbyuki/dash.nvim/issues).
* All contributions are welcome.

Extra
-----

For the curious out there: Try to copy-paste a brainf\*ck program and execute it using `DashRun`. Set the filetype to bf using `set ft=bf`. Admire the computation done live in front of your eyes.
