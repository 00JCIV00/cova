# Analysis
Once initialized and parsed, a Command can be analyzed. The Command type has several functions and methods to make this easier, with methods for checking and matchingsub-Commands being the standard starting point. Addtionally, it's possible to convert the Command into a comptime-known Struct, Union, or Function Type and use the resulting Type normally. For a more direct look, one can look at all of the sub-Arguments individually.

## Checking and Matching Sub Commands
The `cova.Command.Custom.checkSubCmd`() and `cova.Command.Custom.matchSubCmd`() methods are designed to be the starting point for analysis. The check function simply returns a Boolean value based on a check of whether or not the provided Command name (`cmd_name`) is the same as the Command's active sub-Command. The match function works similarly, but will return the active sub-Command if it's matched or `null` otherwise. Chaining these methods into conditional `if/else` statements makes iterating over and analyzing all sub-Commands of each Command simple and easy, even when done recursively.

For a detailed example of these methods in action, refer to the [Basic-App](https://github.com/00JCIV00/cova/blob/main/examples/basic_app.zig) demo under the `// - Handle Parsed Commands` comment in the `main()` function.

## Conversions
### To a Struct or Union
Once a Command has been initialized and parsed to, using the `cova.Command.Custom.to`() method will convert it into a struct or union of a comptime-known Struct or Union Type. The function takes a valid comptime-known Struct or Union Type (`ToT`) and a ToConfig (`to_config`). Details for the method, including the rules for a valid Struct or Union Type, can be found under `cova.Command.Custom.to`(). Once sucessfully created, the new struct or union can be used normally throughout the rest of the project. This process looks as follows:
```zig
const DemoStruct {
    // Valid field values
    ...
};

...

pub fn main() !void {
    ...
    const main_cmd = ...;
    // Parse into the initialized Command
    ...

    // Convert to struct
    const demo_struct = main_cmd.to(DemoStruct, .{}); 

    // Use the struct normally
    some_fn(demo_struct);
}

```

The `cova.Command.Custom.ToConfig` can be used to specify how the Command will be converted to a struct.

### To a Function
Alternatively, the Command can also be called as a comptime-known function using `cova.Command.Custom.callAs`(). This method takes a function (`call_fn`), an optional self parameter for the function (`fn_self`), and the return Type of the function (`ReturnT`) to call the function using the Command's Arguments as the parameters. Example:
```zig
pub fn projectFn(some: anytype, params: []const u8) void {
    _ = some;
    _ = params;
}

...

pub fn main() !void {
    ...
    const main_cmd = ...;
    // Parse into the initialized Command
    ...

    // Call as a Function
    main_cmd.callAs(projectFn, null, void); 
}

```


## Direct Access
To directly access the sub-Argument of a Command the following fields and methods of `cova.Command.Custom` can be used: 
### Fields
- `sub_cmd`: Access the sub Command of this Command if set.
- `opts`: Access the Options of this Command if any.
- `vals`: Access the Values of this Command if any.

### Methods
- `checkFlag()`: Check if a Command or Boolean Option/Value is set for this Command.
- `getOpts()` / `getOptsAlloc`: Get a String Hashmap of all of the Options in this Command as `<Name, Option>`.
- `getVals()` / `getValsAlloc`: Get a String Hashmap of all of the Values in this Command as `<Name, Value>`.

### Examples
Check the `cova.utils.displayCmdInfo`() and `cova.utils.displayValInfo`() functions for examples of direct access.
