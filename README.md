export_val
==========

parse transform for def-like functionality.

Useful for initializing expensive values that are used frequently.

Installation
------------

### erlang.mk

```make
DEPS = export_val
dep_export_val = https://github.com/camshaft/export_val.git master
```

Usage
-----

`export_val` will memoize a 0 arity function with the following syntax:

```erlang
-module(my_mod).
-compile({parse_transform, export_val}).
-export_val([expensive_value/0]).

expensive_value() ->
  %% do expensive work here...
  Result.
```

Tests
-----

```sh
$ make test
```
