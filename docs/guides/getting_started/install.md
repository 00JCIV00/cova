# Install
## Package Manager
1. Find the latest `v#.#.#` commit [here](https://github.com/00JCIV00/cova/commits/main).
2. Copy the full SHA for the commit.
3. Add the dependency to `build.zig.zon`:
```zig 
.dependencies = .{
    .cova = .{
        .url = "https://github.com/00JCIV00/cova/archive/<GIT COMMIT SHA FROM STEP 2 HERE>.tar.gz",
    },
},
```
4. Add the dependency and module to `build.zig`:
```zig
// Cova Dependency
const cova_dep = b.dependency("cova", .{ .target = target });
// Cova Module
const cova_mod = cova_dep.module("cova");
// Executable
const exe = b.addExecutable(.{
    .name = "cova_example",
    .root_source_file = .{ .path = "src/main.zig" },
    .target = target,
    .optimize = optimize,
});
// Add the Cova Module to the Executable
exe.addModule("cova", cova_mod);
```
5. Run `zig build <PROJECT BUILD STEP IF APPLICABLE>` to get the hash.
6. Insert the hash into `build.zig.zon`:
```bash 
.dependencies = .{
    .cova = .{
        .url = "https://github.com/00JCIV00/cova/archive/<GIT COMMIT SHA FROM STEP 2 HERE>.tar.gz",
	    .hash = "HASH FROM STEP 5 HERE",
    },
},
```

## Build the Demo from source
1. Use Zig v0.11 for your system. Available [here](https://ziglang.org/download/).
2. Run the following in whichever directory you'd like to install to:
```
git clone https://github.com/00JCIV00/cova.git
cd cova
zig build demo
```
3. Try it out!
```
cd bin 
./covademo help
```
