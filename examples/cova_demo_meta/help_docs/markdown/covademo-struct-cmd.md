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
    - `-i, --int <int (i32)>`
    - The first Integer Value for the struct-cmd.
- __str__:
    - `-s, --str <str (text)>`
    - The 'str' Option.
- __str2__:
    - `-S, --str2 <str2 (text)>`
    - The 'str2' Option.
- __flt__:
    - `-f, --flt <flt (f16)>`
    - The 'flt' Option.
- __int2__:
    - `-I, --int2 <int2 (u16)>`
    - The 'int2' Option.
- __multi-int__:
    - `-m, --multi-int <multi-int (u8)>`
    - The 'multi-int' Value.
- __multi-str__:
    - `-M, --multi-str <multi-str (text)>`
    - The 'multi-str' Value.
- __rgb-enum__:
    - `-r, --rgb-enum <rgb-enum (covademo.DemoStruct.InnerEnum)>`
    - The 'rgb-enum' Option.
- __struct-bool__:
    - `-t, --struct-bool <struct-bool (toggle)>`
    - The 'struct_bool' Option of type 'toggle'.
- __struct-str__:
    - `-T, --struct-str <struct-str (text)>`
    - The 'struct_str' Option of type 'text'.
- __struct-int__:
    - `-R, --struct-int <struct-int (i64)>`
    - The 'struct_int' Option of type 'i64'.
### Values
- __multi-int-val__ (u16)
    - The 'multi-int-val' Value.

