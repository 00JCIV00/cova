//! Meta Doc Generation for Cova-based programs
//! This is meant to be built and run as a step in `build.zig`.

/// Standard library
const std = @import("std");
const Build = std.Build;
/// The Cova library is needed for the `generate` module.
const cova = @import("cova");
/// This is a reference module for the program being built. Typically this is the main `.zig` file
/// in a project that has both the `main()` function and `setup_cmd` Command. 
const program = @import("program");
// This is a reference to the Build Options passed in from `build.zig`.
const gen_opts = @import("gen_opts");

pub fn main() !void {
    // Generate Manpages
    if (!gen_opts.no_manpages) {
        try cova.generate.createManpage(
            @field(program, gen_opts.cmd_type_field_name), 
            @field(program, gen_opts.setup_cmd_field_name), 
            .{
                .local_filepath = "aux",
                .version = "0.9.0",
                .ver_date = "25 SEP 2023",
                .man_name = "User's Manual",
                .author = "00JCIV00",
                .copyright = "Copyright info here",
            }
        );
    }
    // Generate Tab Completion
    switch (gen_opts.tab_completion_kind) {
        .bash => {
            try cova.generate.createTabCompletion(
                @field(program, gen_opts.cmd_type_field_name), 
                @field(program, gen_opts.setup_cmd_field_name), 
                .{
                    .local_filepath = "aux",
                    .include_opts = true,
                    .shell_kind = .bash,
                }
            );
        },
        .zsh => {},
        .ps1 => {},
        .json => {},
        .kdl => {},
        .all => {},
        .none => {},
    }
}

/// Different Kinds of Meta Documents (Manpages, Tab Completions, etc) available.
const MetaDocKind = enum {
    /// Generate Manpages.
    manpages,
    /// Generate a Bash Tab Completion Script.
    bash,
    /// Generate a Zsh Tab Completion Script. (WIP)
    zsh,
    /// Generate a PowerShell Tab Completion Script. (WIP)
    ps1,
    /// Generate a JSON Representation. (WIP)
    /// This is useful for parsing the main Command using external tools.
    json,
    /// Generate a KDL Representation for use with the [`usage`](https://sr.ht/~jdx/usage/) tool. (WIP)
    kdl,
    /// This is the same as adding All of the MetaDocKinds.
    all,
};

/// A Config for setting up all Meta Docs
pub const MetaDocConfig = struct{
    /// Specify which kinds of Meta Docs should be generated.
    kinds: []const MetaDocKind = &.{ .manpages, .bash },
    /// Manpages Config
    manpages_config: ?cova.generate.ManpageConfig = null,
    /// Tab Completion Config
    tab_complete_config: ?cova.generate.TabCompletionConfig = null,
    /// Main Source File Path.
    /// This should be the file with the entry `main()` function.
    main_source_file: []const u8,
    /// Command Type Name.
    /// This is the name of the Command Type declaration in the main source file.
    cmd_type_name: []const u8 = "CommandT",
    /// Setup Command Name.
    /// This is the name of the comptime Setup Command in the main source file.
    setup_cmd_name: []const u8 = "setup_cmd",
};

/// A Build Step for Generating Manpages, Tab Completion Scripts, and other Meta Documents.
pub const GeneratorStep = struct{
    md_config: MetaDocConfig = .{},
    step: Build.Step,
    
    pub fn init(b: *Build, md_config: MetaDocConfig) *@This() {
        const self = b.allocator.create(@This()) catch @panic("OOM");
        self.* = .{
            .md_config = md_config,
            .step = Build.Step.init(.{
                .id = .install_file,
                .name = "GenMetaDocs",
                .owner = b,
                //.makeFn = make,
            }),
        };
    }
    
    //fn make(step: Build.Step, _: *std.Progress.Node) !void {
    //    const b = step.owner;
    //    const self = @fieldParentPtr(@This(), "step", step);

    //    const main_mod = b.addModule("main_mod", .{
    //        .root_source_file = .{ .path = self.md_config.main_source_file },
    //    });
    //    //main_mod.import_table.
    //    

    //}

};

pub fn gen(b: *Build) !void {
    _ = b;
}
