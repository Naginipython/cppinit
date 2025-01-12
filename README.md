# cppinit
My general base for a c++ project

This is the best template for a C++ project that I have used thus far, after struggling with CMake, Meson, and the GNU compile while trying to build multi-platform. Zig is configured to find everything within the `src/` and `tests/` directories, and compile them without hassle. Just run `zig build run` or `zig build test` to run or test the C++ code, or just `zig build` to get a executable in `zig-out/bin/`

In the Branch 'SDL', there is an example with SDL2 for both Windows and Linux
To add packages to `build.zig.zon`, I basically found the github repo of the library wanted. I then checked the commits, copied the SHA, and typed into console `zig fetch --save https://github.com/[user]/[repo]/archive/[SHA].tar.gz`. SDL Example shows how to add to project. 

TODO:
- [x] Windows build with package management
- [x] Windows build with lib
- [x] Windows build with dll
- [x] Program name global variable
- [x] Optional `tests/` directory
- [x] `main.cpp` optionally can be program name?
- [x] Explain how to add packages, with windows
- [ ] Hot Reload example/ready code

---- 
### For the template:

# \[Project name\]
To run the project, you will need to install [Zig](https://ziglang.org/download/)\
Or you can run a custom build of your choice, but if you install Zig, here's how to run the program:

`zig build run` to build, and then run\
`zig build` and run the executable in `./zig-out/bin/[program]`

\[Other notes\]