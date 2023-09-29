//! Auxiliary Doc Generation for Cova-based programs
//! This is meant to be built and run as a step in `build.zig`. 

/// The Cova library is needed for the `aux_docs` module.
const cova = @import("cova");
/// This is a reference module for the program being built. Typically this is the main `.zig` file
/// in a project that has both the `main()` function and `setup_cmd` Command. 
const program = @import("program");
// This is a reference to the Build Options passed in from `build.zig`.
const aux_opts = @import("aux_opts");

pub fn main() !void {
    // Generate Manpages
    if (!aux_opts.no_manpages) {
        try cova.aux_docs.createManpage(
            @field(program, aux_opts.cmd_type_field_name), 
            @field(program, aux_opts.setup_cmd_field_name), 
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
    switch (aux_opts.tab_completion_kind) {
        .bash => {
            try cova.aux_docs.createTabCompletion(
                @field(program, aux_opts.cmd_type_field_name), 
                @field(program, aux_opts.setup_cmd_field_name), 
                .{
                    .local_filepath = "aux",
                    .include_opts = true,
                    .shell_kind = .bash,
                }
            );
        },
        .ps1 => {},
        .all => {},
        .none => {},
    }
}
