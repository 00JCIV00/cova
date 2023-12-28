# Overview

Commands, Options, Values, Arguments. A simple yet robust command line argument parsing library for Zig.

Cova is based on the idea that arguments will fall into one of three Argument Types: Commands, Options, or Values. These types are assembled into a single Command struct which is then used to parse argument tokens.

This guide is a Work in Progress, but is intended to cover everything from how to install the cova libary into a projectx, to basic setup and many of the library's advanced features. For a more direct look at the library in action, checkout `examples/covademo.zig`, `examples/basic-app.zig`, and the tests in `src/cova.zig` where many of the examples are lifted directly from.

While this guide does cover several aspects of the libary, everything that's needed to get up and running can be found in the Getting Started section.
