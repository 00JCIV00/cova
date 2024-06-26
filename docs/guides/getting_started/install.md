# Install
## Package Manager
1. Find the latest `v#.#.#` commit [here](https://github.com/00JCIV00/cova/commits/main).
2. Copy the full SHA for the commit.
3. Add the dependency to `build.zig.zon`:
```bash
zig fetch --save "https://github.com/00JCIV00/cova/archive/<GIT COMMIT SHA FROM STEP 2 HERE>.tar.gz"
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
exe.root_module.addImport("cova", cova_mod);
```

## Package Manager - Alternative
Note, this method makes Cova easier to update by simply re-running `zig fetch --save https://github.com/00JCIV00/cova/archive/[BRANCH].tar.gz`. However, it can lead to non-reproducible builds because the url will always point to the newest commit of the provided branch. Details can be found in [this discussion](https://ziggit.dev/t/feature-or-bug-w-zig-fetch-save/2565).
1. Choose a branch to stay in sync with. 
- `main` is the latest stable branch.
- The highest `v#.#.#` is the development branch.
2. Add the dependency to `build.zig.zon`:
 ```shell
 zig fetch --save https://github.com/00JCIV00/cova/archive/[BRANCH FROM STEP 1].tar.gz
 ```
3. Continue from Step 4 above.


## Build the Basic-App Demo from source
1. Use Zig v0.12 for your system. Available [here](https://ziglang.org/download/).
2. Run the following in whichever directory you'd like to install to:
```
git clone https://github.com/00JCIV00/cova.git
cd cova
zig build basic-app -Doptimize=ReleaseSafe
```
3. Try it out!
```
cd bin 
./basic-app help
```
