# covademo
A demo of the Cova command line argument parser.

__Version:__ 0.10.1<br>
__Date:__ 27 AUG 2024<br>
__Author:__ 00JCIV00<br>
__Copyright:__ MIT License<br>
___

## Usage
```shell
USAGE
    covademo [ --string |  --int |  --float |  --file |  --ordinal |  --cardinal |  --toggle |  --bool |  --verbosity ]
    covademo [ sub-cmd |  basic |  nest-1 |  struct-cmd |  union-cmd |  fn-cmd |  add-user ]
```

## Examples

- `covademo -b --string "Optional String"`
- `covademo -i 0 -i=1 -i2 -i=3,4,5 -i6,7 --int 8 --int=9`
- `covademo --file "/some/file"`

## Arguments
### Commands
- [__sub-cmd__](./covademo-sub-cmd.md): A demo sub command.
- [__basic__](./covademo-basic.md): The most basic Command.
- [__nest-1__](./covademo-nest-1.md): Nested Level 1.
- [__struct-cmd__](./covademo-struct-cmd.md): A demo sub command made from a struct.
- [__union-cmd__](./covademo-union-cmd.md): A demo sub command made from a union.
- [__fn-cmd__](./covademo-fn-cmd.md): A demo sub command made from a function.
- [__add-user__](./covademo-add-user.md): A demo sub command for adding a user.
### Options
- __string_opt__:
    - `-s, --string, --text <string_val (string)>`
    - A string option. (Can be given up to 4 times.)
- __int_opt__:
    - `-i, --int <int_val (i16)>`
    - An integer option. (Can be given up to 10 times.)
- __float_opt__:
    - `-f, --float <float_val (f16)>`
    - An float option. (Can be given up to 10 times.)
- __file_opt__:
    - `-F, --file <filepath (filepath)>`
    - A filepath option.
- __ordinal_opt__:
    - `-o, --ordinal <ordinal_val (text)>`
    - An ordinal number option.
- __cardinal_opt__:
    - `-c, --cardinal <cardinal_val (u8)>`
    - A cardinal number option.
- __toggle_opt__:
    - `-t, --toggle, --switch <toggle_val (toggle)>`
    - A toggle/boolean option.
- __bool_opt__:
    - `-b, --bool <bool_val (toggle)>`
    - A toggle/boolean option.
- __verbosity_opt__:
    - `-v, --verbosity <verbosity_level (u4)>`
    - Set the CovaDemo verbosity level. (WIP)
### Values
- __cmd_str__ (text)
    - A string value for the command.
- __cmd_bool__ (toggle)
    - A boolean value for the command.
- __cmd_u64__ (u64)
    - A u64 value for the command.

