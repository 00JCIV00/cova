//! Functions to generate Help Docs, Tab Completion Scripts, and Argument Templates.

// Standard
const std = @import("std");
const fmt = std.fmt;
const fs = std.fs;
const log = std.log;
const mem = std.mem;

// Cova
const utils = @import("utils.zig");
pub const help_docs = @import("generate/help_docs.zig");
pub const HelpDocsConfig = help_docs.HelpDocsConfig;
pub const createHelpDoc = help_docs.createHelpDoc;
pub const tab_completion = @import("generate/tab_completion.zig");
pub const TabCompletionConfig = tab_completion.TabCompletionConfig;
pub const createTabCompletion = tab_completion.createTabCompletion;
pub const arg_template = @import("generate/arg_template.zig");
pub const ArgTemplateConfig = arg_template.ArgTemplateConfig;
pub const createArgTemplate = arg_template.createArgTemplate;

/// Config for setting up all Meta Docs
pub const MetaDocConfig = struct {
    /// Specify which kinds of Meta Docs should be generated.
    kinds: []const MetaDocKind = &.{.all},
    /// Help Docs Config
    help_docs_config: ?HelpDocsConfig = .{},
    /// Tab Completion Config
    tab_complete_config: ?TabCompletionConfig = .{},
    /// Argument Template Config
    arg_template_config: ?ArgTemplateConfig = .{},
    /// Command Type Name.
    /// This is the name of the Command Type declaration in the main source file.
    cmd_type_name: []const u8 = "CommandT",
    /// Setup Command Name.
    /// This is the name of the comptime Setup Command in the main source file.
    setup_cmd_name: []const u8 = "setup_cmd",

    /// Name of the program.
    /// Note, if this is left null, the provided CommandT's name will be used.
    name: ?[]const u8 = null,
    /// Description of the program.
    /// Note, if this is left null, the provided CommandT's description will be used.
    description: ?[]const u8 = null,
    /// Version of the program.
    version: ?[]const u8 = null,
    /// Date of the program version.
    ver_date: ?[]const u8 = null,
    /// Author of the program.
    author: ?[]const u8 = null,
    /// Copyright info.
    copyright: ?[]const u8 = null,

    /// Different Kinds of Meta Documents (Help Docs, Tab Completions, and Arg Templates) available.
    pub const MetaDocKind = enum {
        /// This is the same as adding All of the MetaDocKinds.
        all,
        /// Generate Manpages Help Docs.
        manpages,
        /// Generate Markdown Help Docs.
        markdown,
        /// Generate a Bash Tab Completion Script.
        bash,
        /// Generate a Zsh Tab Completion Script.
        zsh,
        /// Generate a PowerShell Tab Completion Script.
        ps1,
        /// Generate a JSON Argument Template.
        /// This is useful for parsing the main Command using external tools.
        json,
        /// Generate a KDL Argument Template for use with the [`usage`](https://github.com/jdx/usage) tool.
        kdl,
    };
};
