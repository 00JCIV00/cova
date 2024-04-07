# filter
__[basic-app](./basic-app.md)__ > __[list](./basic-app-list.md)__ > __filter__

List all current users matching the provided filter. Filters can be exactly ONE of any user field.

___

## Usage
```shell
USAGE:
    filter -i,--id <id (u16)> | -a,--admin <admin (bool)> | -A,--age <age (u8)> | -f,--first-name <first-name ([]const u8)> | -l,--last-name <last-name ([]const u8)> | -p,--phone <phone ([]const u8)> | -d,--address <address ([]const u8)>
    filter 

```

## Arguments
### Options
- __id__:
    - `-i, --id <id (u16)>`
    - The 'id' Option of type '?u16'.
- __admin__:
    - `-a, --admin <admin (bool)>`
    - The 'admin' Option of type '?bool'.
- __age__:
    - `-A, --age <age (u8)>`
    - The 'age' Option of type '?u8'.
- __first-name__:
    - `-f, --first-name <first-name ([]const u8)>`
    - The 'first_name' Option of type '?[]const u8'.
- __last-name__:
    - `-l, --last-name <last-name ([]const u8)>`
    - The 'last_name' Option of type '?[]const u8'.
- __phone__:
    - `-p, --phone <phone ([]const u8)>`
    - The 'phone' Option of type '?[]const u8'.
- __address__:
    - `-d, --address <address ([]const u8)>`
    - The 'address' Option of type '?[]const u8'.

