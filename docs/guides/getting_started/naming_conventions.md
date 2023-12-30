# Naming Conventions
Cova follows Zig's naming conventions for the most part. This guide covers the few places where it deviates and certain conventions that may be peculiar in the Library and/or Guide.

## Argument Type vs Argument
The terms 'Argument Type' and 'Argument' are used throughout this guide. While the terms are related, they're not inter-changeable. 

'Argument Type' refers to the Types `cova.Command.Custom`, `cova.Option.Custom`, and `cova.Value.Custom`. These are the base Types of Cova which can be configured to apply customizations to all of their respective instances. For brevity, these are also referred to as `CommandT`, `OptionT`, and `ValueT`. 

Conversely, `Argument` refers to any instance of those Types, which can also be referenced individualy as a Command, Option, or Value.

## Callback Functions
Cova uses Callback Functions to allow the library user to overwrite or otherwise customize certain aspects of the argument parsing process. The functions are represented as fields within both the Argument Type Config Structs and Instances. They're always some variation of the Type `?*const fn()` (with varying parameters and Return Types) and end with the `_fn` suffix to distinguish them from both other fields and normal functions.

## Functions vs Methods
While Zig doesn't officially have methods, it does have 'Member Functions'. These are functions that belong to a Type and whose first parameter is an instance or pointer of that Type. They work effectively the same way as methods in other languages, so the term 'method' is used in this guide for both brevity and clarity.

## Global & Child Type Prefixes
Some fields are shared between both the Argument Type Config Structs and their Instances. These fields all share the purpose of overwriting some default property with varying levels of precedence as denoted by their prefixes:
1. No Prefix: These will always be found directly on the Argument they apply to and have the highest precedence. They apply only to that Argument.
2. `child_type_`: These are only found within Value Config Structs and have the 2nd highest precedence. They apply to any Values with the corresponding Child Type.
3. `global_`: These will always be found within a Config Struct and have lowest precedence. They apply to all Arguments of the configured Type.

## Title Case
Types and certain Key Concepts will be shown in Title Case for distinction. For Types, this includes their descriptions, such as 'Command Type', and their Type Names like in 'CommandT'.

## Users
This guide makes reference to both 'Library' and 'End' users. 'Library user' refers to the developer using the Cova library (probably you, the reader) and 'End user' refers to the user of an application or project built with the help of the Cova library.

