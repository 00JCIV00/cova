# Analysis
Once initialized and parsed, a Command can be analyzed. The Command type has several functions and methods to make this easier. The simplest way is to convert the Command into a comptime-known Struct Type and use the resulting struct normally. For a more direct look, one can look at all of the sub Argument types individually.

## Convert to Struct
Once a Command has been initialized and parsed to, using the `to()` method will convert it into a struct of a comptime-known Struct Type. The function takes a valid comptime-known Struct Type (`T`) and a ToConfig (`to_config`). Details for the method, including the rules for a valid Struct Type, can be found under `cova.Command.Custom.to`(). Once sucessfully created, the new struct can be used normally throughout the rest of the project. This process looks as follows:
```
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

The `ToConfig` can be used to specify how the Command will be converted to a struct. Details can be found in the API documentation under `cova.Command.Custom.ToConfig`. 


## Direct Access
To directly access the sub Argument types of a Command the following fields and methods of `cova.Command.Custom` can be used: 
### Fields
- `sub_cmd`: Access the sub Command of this Command if set.
- `opts`: Access the Options of this Command if any.
- `vals`: Access the Values of this Command if any.

### Methods
- `checkFlag()`: Check if a Command or Boolean Option/Value is set for this Command.
- `getOpts()` / `getOptsAlloc`: Get a String Hashmap of all of the Options in this Command as <Name, Option>.
- `getVals()` / `getValsAlloc`: Get a String Hashmap of all of the Values in this Command as <Name, Value>.

### Examples
Check the `cova.utils.displayCmdInfo`() and `cova.utils.displayValInfo`() functions for examples of direct access.
