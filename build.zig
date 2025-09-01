const std = @import("std");

const PROGRAM_NAME: []const u8 = "main";

fn linker(exe: *std.Build.Step.Compile, files: []const []const u8, b: *std.Build, target: std.Build.ResolvedTarget) void {
    exe.addCSourceFiles(.{
        .files = files,
        .flags = &[_][]const u8{},
    });
    exe.addIncludePath(b.path("include"));
    exe.linkLibC();
    exe.linkLibCpp();

    // Libs
    const sdl_dep = b.dependency("raylib_zig", .{
        .target = target,
    });
    exe.linkLibrary(sdl_dep.artifact("raylib"));

    // Other lib solutions
    // if (target.query.isNativeOs() and target.result.os.tag == .windows) {
        // Solution 2 (make sure you place all files in the directory, not just the lib files (unless you know what you're doing))
        // exe.addLibraryPath(b.path("lib/SDL3-3.1.6/lib/x64/"));
        // exe.linkSystemLibrary("SDL3");
        // b.installBinFile("lib/SDL3-3.1.6/lib/x64/SDL3.dll", "SDL3.dll");

        // Solution 3: Dynamic Library? -WIP-
        // b.installBinFile("lib/SDL3-3.1.6/lib/x64/SDL3.dll", "SDL3.dll");
    
}

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    defer arena.deinit();

    const files = try findFiles("src", &.{}, &arena);
    std.debug.print("Files to build: [\n", .{});
    for (files) |f| {
        std.debug.print("\t{s}\n", .{f}); // f is []const u8, this is correct
    }
    std.debug.print("]\n", .{});
    
    const exe = b.addExecutable(.{
        .name = PROGRAM_NAME,
        .root_module = b.createModule(.{
            .target = target,
        }),
    });
    linker(exe, files, b, target);

    b.installArtifact(exe);

    // ------ Run ------
    const run_step = b.step("run", "Run the app");

    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    // ------ Tests ------
    // if (try testDirExists()) {
    //     const test_files1 = try findFiles("tests", &[_][]const u8{}, &arena);
    //     const test_files2 = try findFiles("src", &[_][]const u8{"main.cpp"}, &arena);

    //     // Combine the test files with the src files
    //     const test_files = try combineArrays(test_files1, test_files2, &arena);
    //     std.debug.print("Test files to build: [\n", .{});
    //     for (test_files) |f| {
    //         std.debug.print("\t{s}\n", .{f}); // f is []const u8, this is correct
    //     }
    //     std.debug.print("]\n", .{});

    //     // combine with `files`, except src/main.c or src/main.cpp
    //     const tests_name = PROGRAM_NAME ++ "_tests";
    //     const tests_exe = b.addExecutable(.{ .name = tests_name, .root_module = b.createModule(.{ .target = target }) });

    //     linker(tests_exe, test_files, b, target);
    //     const googletest_dep = b.dependency("googletest", .{
    //         .target = target,
    //         // .optimize = b.standardOptimizeOption(.{}),
    //     });
    //     tests_exe.linkLibrary(googletest_dep.artifact("gtest"));

    //     b.installArtifact(tests_exe);

    //     const run_tests_exe = b.addRunArtifact(tests_exe);
    //     run_tests_exe.step.dependOn(b.getInstallStep());

    //     const test_step = b.step("test", "Run unit tests");
    //     test_step.dependOn(&run_tests_exe.step);
    // }
}

fn testDirExists() !bool {
    const checkDirs = try std.fs.cwd().openDir(".", .{ .iterate = true });
    var iter = checkDirs.iterate();
    while (try iter.next()) |entry| {
        if (std.mem.eql(u8, entry.name,"tests") and entry.kind == .directory) {
            return true;
        }
    }
    return false;
}

fn combineArrays(arr1: []const []const u8, arr2: []const []const u8, arena: *std.heap.ArenaAllocator) ![]const []const u8 {
    const alloc = arena.allocator();
    var combined: std.ArrayList([]const u8) = .empty;
    defer combined.deinit(alloc);
    for (arr1) |item|
        try combined.append(alloc, item);
    for (arr2) |item|
        try combined.append(alloc, item);
    return try combined.toOwnedSlice(alloc);
}

fn findFiles(src: []const u8, ignore_list: []const []const u8, arena: *std.heap.ArenaAllocator) ![]const []const u8 {
    const alloc = arena.allocator();

    var result: std.ArrayList([]const u8) = .empty;
    defer result.deinit(alloc);

    var root = try std.fs.cwd().openDir(src, .{ .iterate = true });
    defer root.close();

    var iter = root.iterate();
    main: while (try iter.next()) |entry| {
        // ignore if on ignore list (partial matching)
        for (ignore_list) |item|
            if (std.mem.indexOf(u8, entry.name, item) != null)
                continue :main;

        if (entry.kind == .file) {
            if (std.mem.endsWith(u8, entry.name, ".c") or
                std.mem.endsWith(u8, entry.name, ".cpp"))
            {
                const path_u8 = try std.fmt.allocPrint(alloc, "{s}/{s}", .{src, entry.name});
                try result.append(alloc, path_u8);
            }
        }
        // Recusively search for files in directories TODO
        else if (entry.kind == .directory) {
            const dir_u8 = try std.fmt.allocPrint(alloc, "{s}/{s}", .{src, entry.name});
            const files = try findFiles(dir_u8, ignore_list, arena);
            try result.appendSlice(alloc, files);
        }
    }
    return try result.toOwnedSlice(alloc);
}