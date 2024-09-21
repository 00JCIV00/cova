# struct-cmd
__[covademo](./covademo.md)__ > __struct-cmd__

A demo sub command made from a struct.

___

## Usage
```shell
USAGE
    struct-cmd [ --int |  --str |  --str2 |  --flt |  --int2 |  --multi-int |  --multi-str |  --rgb-enum |  --struct-bool |  --struct-str |  --struct-int ]
    struct-cmd [ inner-cmd ]
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
    - The 'str' Option of type 'text'.
- __str2__:
    - `​​--str2 <str2 (text)>`
    - The 'str2' Option of type 'text'.
- __flt__:
    - `​​--flt <flt (f16)>`
    - The 'flt' Option of type 'f16'.
- __int2__:
    - `​​--int2 <int2 (u16)>`
    - The 'int2' Option of type 'u16'.
- __multi-int__:
    - `​​--multi-int <multi-int (u8)>`
    - The 'multi_int' Option of type 'u8'.
- __multi-str__:
    - `​​--multi-str <multi-str (text)>`
    - The 'multi_str' Option of type 'text'.
- __rgb-enum__:
    - `​​--rgb-enum <rgb-enum (covademo.DemoStruct.InnerEnum)>`
    - The 'rgb_enum' Option of type 'covademo.DemoStruct.InnerEnum'.
- __struct-bool__:
    - `​​--struct-bool <struct-bool (toggle)>`
    - The 'struct_bool' Option of type 'toggle'.
- __struct-str__:
    - `​​--struct-str <struct-str (text)>`
    - The 'struct_str' Option of type 'text'.
- __struct-int__:
    - `​​--struct-int <struct-int (i64)>`
    - The 'struct_int' Option of type 'i64'.
### Values
- __multi-int-val__ (u16)
    - The 'multi-int-val' Value of Type '[2]u16'.

