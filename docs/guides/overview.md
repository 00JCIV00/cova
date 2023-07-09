# Overview

Commands, Options, Values, Arguments. A simple yet robust command line argument parsing library for Zig.

Cova is based on the idea that Arguments will fall into one of three types: Commands, Options, or Values. These types are assembled into a single Command struct which is then used to parse argument tokens.

This guide is a Work in Progress, but is intended to cover everything from how to install the cova libary into a project, to basic setup and many of the library's advanced features. For a more direct look at the library in action, checkout `examples/covademo.zig` and the tests in `src/cova.zig` where many of the examples are lifted directly from.
