# new
__[basic-app](./basic-app.md)__ > __new__

Add a new user.

___

## Usage
```shell
USAGE:
    new-f,--first-name <first-name ([]const u8)> | -l,--last-name <last-name ([]const u8)> | -a,--age <age (u8)> | -p,--phone <phone ([]const u8)> | -A,--address <address ([]const u8)>
    new "is-admin (bool)"
    new 

```

## Examples

- `basic-app new -f Bruce -l Wayne -a 40 -p "555 555 5555" -A " 1007 Mountain Drive, Gotham" true`

## Arguments
### Options
- __first-name__:
    - `-f, --first-name <first-name ([]const u8)>`
    - User's First Name.
- __last-name__:
    - `-l, --last-name <last-name ([]const u8)>`
    - User's Last Name.
- __age__:
    - `-a, --age <age (u8)>`
    - User's Age.
- __phone__:
    - `-p, --phone <phone ([]const u8)>`
    - User's Phone #.
- __address__:
    - `-A, --address <address ([]const u8)>`
    - User's Address.
### Values
- __is-admin__ (bool)
    - Add this user as an admin?

