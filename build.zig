const std = @import("std");

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    // const tokenizer = b.addStaticLibrary(.{
    //     .name = "tokenizer",
    //     // In this case the main source file is merely a path, however, in more
    //     // complicated build scripts, this could be a generated file.
    //     .root_source_file = b.path("src/tokenizer/tokenizer.zig"),
    //     .target = target,
    //     .optimize = optimize,
    // });

    // const prettizy_dep = b.dependency("prettizy", .{
    //     .target = target,
    //     .optimize = optimize,
    // });

    const parser = b.addStaticLibrary(.{
        .name = "parser",
        // In this case the main source file is merely a path, however, in more
        // complicated build scripts, this could be a generated file.
        .root_source_file = b.path("src/parser/parser.zig"),
        .target = target,
        .optimize = optimize,
    });

    // const tokenizer = b.addModule("tokenizer", .{
    //     .root_source_file = b.path("src/tokenizer/tokenizer.zig"),
    // });

    // parser.root_module.addImport("tokenizer", tokenizer);

    // This declares intent for the library to be installed into the standard
    // location when the user invokes the "install" step (the default step when
    // running `zig build`).
    b.installArtifact(parser);

    const exe = b.addExecutable(.{
        .name = "parse-lisp-perhaps",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    // exe.root_module.addImport("prettizy", prettizy_dep.module("prettizy"));
    exe.root_module.addImport("parser", parser.root_module);

    // This declares intent for the executable to be installed into the
    // standard location when the user invokes the "install" step (the default
    // step when running `zig build`).
    b.installArtifact(exe);
}
