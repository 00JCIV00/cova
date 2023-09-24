//! Auxiliary Doc Generation for Cova-based programs
//! This is meant to be built and run as a step in `build.zig`.

/// The Cova library is needed for the `aux_docs` module.
const cova = @import("cova");
const program = @import("program");
const aux_opts = @import("aux_opts");

pub fn main() !void {
    // Generate Manpages
    if (!aux_opts.no_manpages) {
        try cova.aux_docs.createManpage(program.CommandT, program.setup_cmd, .{
            .local_filepath = "aux",
            .author = "00JCIV00",
            .copyright = "Free to use.",
        });
    }
    // Generate Tab Completion
    // TODO: This
    switch (aux_opts.tab_completion_kind) {
        .bash => {},
        .ps1 => {},
        .all => {},
        .none => {},
    }
}
