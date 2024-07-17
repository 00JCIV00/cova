# struct-cmd
__[covademo](./covademo.md)__ > __struct-cmd__

A demo sub command made from a struct.

___

## Usage
```shell
USAGE:
    struct-cmd​​ --int <int (i32)> | ​​ --str <str (text)> | ​​ --str2 <str2 (text)> | ​​ --flt <flt (f16)> | ​​ --int2 <int2 (u16)> | ​​ --multi-int <multi-int (u8)> | ​​ --multi-str <multi-str (text)> | ​​ --rgb-enum <rgb-enum (u2)> | ​​ --struct-bool <struct-bool (bool)> | ​​ --struct-str <struct-str (text)> | ​​ --struct-int <struct-int (i64)>
    struct-cmd "multi-int-val (u16)"
    struct-cmd inner-cmd

```

## Arguments
### Commands
- [__inner-cmd__](./covademo-struct-cmd-inner-cmd.md): An inner/nested command for struct-cmd
### Options
- __int__:
    - `​​--int <int (i32)>`
    - The first Integer Value for the struct-cmd.
- __str__:
    - `​​--str <str (text)>`
    - The 'str' Option of type '?[]const u8'.
- __str2__:
    - `​​--str2 <str2 (text)>`
    - The 'str2' Option of type '?[]const u8'.
- __flt__:
    - `​​--flt <flt (f16)>`
    - The 'flt' Option of type '?f16'.
- __int2__:
    - `​​--int2 <int2 (u16)>`
    - The 'int2' Option of type '?u16'.
- __multi-int__:
    - `​​--multi-int <multi-int (u8)>`
    - The 'multi_int' Option of type '[3]?u8'.
- __multi-str__:
    - `​​--multi-str <multi-str (text)>`
    - The 'multi_str' Option of type '[5]?[]const u8'.
- __rgb-enum__:
    - `​​--rgb-enum <rgb-enum (u2)>`
    - The 'rgb_enum' Option of type '?covademo.DemoStruct.InnerEnum'.
- __struct-bool__:
    - `​​--struct-bool <struct-bool (bool)>`
    - The 'struct_bool' Option of type 'bool'.
- __struct-str__:
    - `​​--struct-str <struct-str (text)>`
    - The 'struct_str' Option of type '[]const u8'.
- __struct-int__:
    - `​​--struct-int <struct-int (i64)>`
    - The 'struct_int' Option of type 'i64'.
### Values
- __multi-int-val__ (u16)
    - The 'multi-int-val' Value of type '[2]u16'.

