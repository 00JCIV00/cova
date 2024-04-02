# add-user
__[covademo](examples/meta/help_docs/markdown/covademo.md)__ > __add-user__

A demo sub command for adding a user.

___

## Usage
```shell
USAGE:
    add-user -f, --fname <fname (text)> | -l, --lname <lname (text)> | -a, --age <age (u8)> | -A, --admin <admin (bool)> | -r, --ref-ids <ref-ids (u8)>
    add-user "id (u16)"
    add-user 

```

## Arguments
### Options
- __fname__:
    - `-f, --fname <fname (text)>`
    - The 'fname' Option of type '?[]const u8'.
- __lname__:
    - `-l, --lname <lname (text)>`
    - The 'lname' Option of type '?[]const u8'.
- __age__:
    - `-a, --age <age (u8)>`
    - The 'age' Option of type '?u8'.
- __admin__:
    - `-A, --admin <admin (bool)>`
    - The 'admin' Option of type '?bool'.
- __ref-ids__:
    - `-r, --ref-ids <ref-ids (u8)>`
    - The 'ref_ids' Option of type '[3]?u8'.
### Values
- __id__ (u16)
    - The 'id' Value of type 'u16'.

