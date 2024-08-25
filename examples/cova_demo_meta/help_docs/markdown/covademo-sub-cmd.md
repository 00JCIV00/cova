# sub-cmd
__[covademo](./covademo.md)__ > __sub-cmd__

A demo sub command.

___

## Usage
```shell
USAGE
    sub-cmd [ --i |  --nested_str ]
```

## Alias(es)
- `alias-cmd`
- `test-alias`

## Examples

- `covademo sub-cmd 3.14`

## Arguments
### Options
- __nested_int_opt__:
    - `-i <nested_int_val (u8)>`
    - A nested integer option.
- __nested_str_opt__:
    - `-s, --nested_str <nested_str_val ([]const u8)>`
    - A nested string option.
### Values
- __nested_float_val__ (f32)
    - A nested float value.

