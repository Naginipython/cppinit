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
    if (target.query.isNativeOs() and target.result.os.tag == .windows) {
        // Solution 1
        // const sdl_dep = b.dependency("SDL", .{ // Add libs as needed
        //     .target = target,
        // });
        // exe.linkLibrary(sdl_dep.artifact("SDL2"));

        // Solution 2 (make sure you place all files in the directory, not just the lib files (unless you know what you're doing))
        // exe.addLibraryPath(b.path("lib/SDL3-3.1.6/lib/x64/"));
        // exe.linkSystemLibrary("SDL3");
        // b.installBinFile("lib/SDL3-3.1.6/lib/x64/SDL3.dll", "SDL3.dll");

        // Solution 3: Dynamic Library? -WIP-
        // b.installBinFile("lib/SDL3-3.1.6/lib/x64/SDL3.dll", "SDL3.dll");
    } else {
        // exe.linkSystemLibrary("SDL2"); // Add libs as needed
    }
}

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});

    const files = try findFiles("src", &[_][]const u8{});
    std.debug.print("Files built:\n{s}\n", .{files});

    const exe = b.addExecutable(.{ .name = PROGRAM_NAME, .target = target });
    linker(exe, files, b, target);

    b.installArtifact(exe);

    // ------ Run ------
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    // ------ Tests ------
    if (try testDirExists()) {
        const test_files1 = try findFiles("tests", &[_][]const u8{});
        const test_files2 = try findFiles("src", &[_][]const u8{"main.cpp"});

        // Combine the test files with the src files
        const test_files = try combineArrays(test_files1, test_files2);
        std.debug.print("Test Files built:\n{s}\n", .{test_files});

        // combine with `files`, except src/main.c or src/main.cpp
        const tests_name = PROGRAM_NAME ++ "_tests";
        const tests_exe = b.addExecutable(.{ .name = tests_name, .target = target });

        linker(tests_exe, test_files, b, target);
        const googletest_dep = b.dependency("googletest", .{
            .target = target,
            // .optimize = b.standardOptimizeOption(.{}),
        });
        tests_exe.linkLibrary(googletest_dep.artifact("gtest"));

        b.installArtifact(tests_exe);

        const run_tests_exe = b.addRunArtifact(tests_exe);
        run_tests_exe.step.dependOn(b.getInstallStep());

        const test_step = b.step("test", "Run unit tests");
        test_step.dependOn(&run_tests_exe.step);
    }

    // ------ Clean ------
    const clean_step = b.step("clean", "Clean the directory");
    // Windows (doesn't work without admin permission)
    // clean_step.dependOn(&b.addRemoveDirTree(b.path("zig-out")).step);
    // clean_step.dependOn(&b.addRemoveDirTree(b.path(".zig-cache")).step);
    // Linux
    clean_step.dependOn(&b.addRemoveDirTree(b.install_path).step);
    clean_step.dependOn(&b.addRemoveDirTree(b.pathFromRoot(".zig-cache")).step);
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

fn combineArrays(arr1: []const []const u8, arr2: []const []const u8) ![]const []const u8 {
    var combined = std.ArrayList([]const u8).init(std.heap.page_allocator);
    defer combined.deinit();
    for (arr1) |item|
        try combined.append(item);
    for (arr2) |item|
        try combined.append(item);
    return try combined.toOwnedSlice();
}

fn findFiles(src: []const u8, ignore_list: []const []const u8) ![]const []const u8 {
    var result = std.ArrayList([]const u8).init(std.heap.page_allocator);
    defer result.deinit();
    var root = try std.fs.cwd().openDir(src, .{ .iterate = true });
    defer root.close();

    var iter = root.iterate();
    main: while (try iter.next()) |entry| {
        // ignore if on ignore list
        for (ignore_list) |item|
            if (std.mem.indexOf(u8, entry.name, item) != null)
                continue :main;

        // Create item
        var item = std.ArrayList(u8).init(std.heap.page_allocator);
        defer item.deinit();
        try item.appendSlice(src);
        try item.append('/');
        try item.appendSlice(entry.name);
        if (entry.kind == .file) {
            const check_cpp = entry.name[entry.name.len - 4 ..];
            const check_c = entry.name[entry.name.len - 2 ..];
            if (std.mem.eql(u8, check_cpp, ".cpp") or std.mem.eql(u8, check_c, ".c")) {
                const path_u8 = try item.toOwnedSlice();
                try result.append(path_u8);
            }
        }
        // Recusively search for files in directories
        if (entry.kind == .directory) {
            const dir_u8 = try item.toOwnedSlice();
            const files = try findFiles(dir_u8, ignore_list);
            for (files) |f|
                try result.append(f);
        }
    }
    return try result.toOwnedSlice();
}