# cppinit
My general base for a c++ project

This is the best template for a C++ project that I have used thus far, after struggling with CMake, Meson, and the GNU compile while trying to build multi-platform. Zig is configured to find everything within the `src/` and `tests/` directories, and compile them without hassle. Just run `zig build run` or `zig build test` to run or test the C++ code, or just `zig build` to get a executable in `zig-out/bin/`

TODO:
- [ ] Windows build with package management
- [ ] Program name global variable
- [ ] Optional `tests/` directory
- [ ] `main.cpp` optionally can be program name?
- [ ] Explain how to add packages, with windows
