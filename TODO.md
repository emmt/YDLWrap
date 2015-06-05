 - Allow compilation of different plugins with different implementations.
   For instance:
    - `dlwrap-ffcall-play.${DLL}`  for FFCALL + PLAY;
    - `dlwrap-ffcall-dl.${DLL}`    for FFCALL + system DL;
    - `dlwrap-ffcall-ltdl.${DLL}`  for FFCALL + GNU Libtool;

 - Try other dynamic function calling system LIBFFI, CINVOKE, etc.

 - Implement callback system for object destruction.

