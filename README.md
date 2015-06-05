            __   ______  _  __        __
            \ \ / /  _ \| | \ \      / /_ __ __ _ _ __
             \ V /| | | | |  \ \ /\ / /| '__/ _` | '_ \
              | | | |_| | |___\ V  V / | | | (_| | |_) |
              |_| |____/|_____|\_/\_/  |_|  \__,_| .__/
                                                 |_|

**YDLWrap** is a [Yorick](http://yorick.github.com/) plugin for dynamically
calling compiled functions.

The interface is *fast* -- I have measured an extra overhead of about 15
nanoseconds on my laptop (Core i7 Q820 at 1.73GHz) for a simple function
call like `sin(x)` compared to the built-in version of the same function.


EXAMPLE
=======

Here how you can call a function using the symbols compiled into the Yorick
excutable itself:
````C
// Load the plugin:
#include "dlwrap.i"

// Open the executable itself:
dll = dlopen();

// Create a function wrapper:
dll_sin = dlwrap(dll, DL_DOUBLE, "sin", DL_DOUBLE);
//                |    |          |      |
//                |    |          |      `-- argument type
//                |    |          `--------- symbol name
//                |    `-------------------- return type
//                `------------------------- dynamic module

// Call the wrapper (like a Yorick function):
a = dll_sin(1.25);
````
Of course, you can use the function wrappers as many times as you want and
open a specific dynamic library.


INSTALLATION
============

Prerequisites
-------------

You need two external libraries: one for loading dynamic modules, one for
dynamically calling compiled functions.

For loading dynamic modules, you can choose:
 - DLOPEN interface;
 - [LIBTOOL](http://www.gnu.org/software/libtool/) interface, for Debian
   users:

        sudo apt-get install libltdl-dev

- PLAY interface (this is the Portability LAYer on top of which Yorick is
   build; with this interface, unloading of modules is not possible).

For dynamically call compiled functions, you must use:
 - [FFCALL](http://www.haible.de/bruno/packages-ffcall.html), for Debian
   users:

        sudo apt-get install libffcall1-dev


Installation by editing "Makefile"
----------------------------------

Edit the file `Makefile` in the source directory as follows.

To use DLOPEN, add:
  * `-DHAVE_DLOPEN`     to macro `PKG_CFLAGS` in `Makefile`;
  * `-ldl`              to macro `PKG_DEPLIBS` in `Makefile`.

To use LIBTOOL, add:
  * `-DHAVE_LIBTOOL`    to macro `PKG_CFLAGS` in `Makefile`;
  * `-lltdl -ldl`       to macro `PKG_DEPLIBS` in `Makefile`.

To use FFCALL, add:
  * `-DHAVE_FFCALL`     to macro `PKG_CFLAGS` in `Makefile`;
  * `-lavcall`          to macro `PKG_DEPLIBS` in `Makefile`.

After having edited the `Makefile`, use Yorick to update the paths:

    yorick -batch make.i

Then compile the package (the "install" step is optional):

    make clean
    make
    make install


Installation with "configure" script
------------------------------------

The package comes with a script which can be used to configure the code for
compilation.  The script can be invoked in the source directory or from
another directory to separate sources from compiled files. This allows
building for different architectures from a single source tree.

Assuming `$SRC_DIR` and `$BUILD_DIR` are the source and build directories
(they can be the same), to configure, build and install the package do:

    mkdir -p $BUILD_DIR
    cd $BUILD_DIR
    $SRC_DIR/configure --cflags='...' --deplibs='...'
    make
    make install

The command:

    $SRC_DIR/configure --help

can be used for a short summary of the script usage.  The most important
options are `--cflags='...'` and `--deplibs='...'`.  The default values are
empty unless the corresponding macros (`PKG_CFLAGS` and `PKG_DEPLIBS`) are set
in the current Makefile.  Typically:

 * for the dynamic loader (nothing is needed if you want to stick with
   with Yorick own loader), to use DLOPEN, add:

    * `-DHAVE_DLOPEN`     to the value of option `--cflags`
    * `-ldl`              to the value of option `--deplibs`

   to use LIBTOOL, add:

     * `-DHAVE_LIBTOOL`    to the value of option `--cflags`
     * `-lltdl -ldl`       to the value of option `--deplibs`

 * you must specify how to use FFCALL for calling dynamic functions, add:

     * `-DHAVE_FFCALL`     to the value of option `--cflags`
     * `-lavcall`          to the value of option `--deplibs`

For instance, to use LIBTOOL and FFCALL:

    $SRC_DIR/configure \
       --cflags='-DHAVE_FFCALL -DHAVE_LIBTOOL' \
       --deplibs='-lavcall -lltdl -ldl'


WISH LIST
=========

-[ ] Hide structure definitions in the SYS object.

-[x] Write a (pseudo) `configure` script to edit the Makefile.

-[ ] For the moment only functions can be obtained, global variables remain inaccessible.

-[ ] Allow compilation of different plugins with different implementations.
   For instance:
     dlwrap-ffcall-play.${DLL}  for FFCALL + PLAY
     dlwrap-ffcall-dl.${DLL}    for FFCALL + system DL
     dlwrap-ffcall-ltdl.${DLL}  for FFCALL + GNU Libtool

-[ ] Try other dynamic function calling system like LIBFFI (fix the `SIGFPE`
   issue), CINVOKE, etc.

   To dynamically call compiled functions, I have tried to use
   [LIBFFI](http://sourceware.org/libffi) but `ffi_prep_cif()` raises a
   `SIGFPE` (perhaps it lefts some dirt in the floating-point registers)
   which interrupts Yorick.  I can try using the new `p_fpehandling` in
   Yorick API to temporarily ignore `SIGFPE`.  The advantage of LIBFFI
   would be that it may speedup calling functions (argument parsing can be
   done only once).

-[ ] Implement callback system for object destruction.

-[ ] Add other *types* to allow for Yorick variables definition:
   `C_INT_OUT`, `C_LONG_OUT`, *etc.* to mean that the argument is the name
   of a Yorick variable set with an int, a long, etc. on return, the called
   function takes a pointer to the corresponding type.


AUTHORS
=======
Éric Thiébaut <https://github.com/emmt>