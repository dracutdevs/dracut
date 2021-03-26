# BASH Notes

## basename
Don't use `basename`, use:
```shell
  file=${path##*/}
```

## dirname
Don't use `dirname`, use:
```shell
  dir=${path%/*}
```

## shopt
If you set `shopt` in a function, reset to its default state with `trap`:
```shell
func() {
  trap "$(shopt -p nullglob globstar)" RETURN
  shopt -q -s nullglob globstar
}
```

## find, grep, print0, -0, -z

Don't use `find` in `for` loops, because filenames can contain spaces.
Try to use `globstar` and `nullglob` or null byte terminated strings.

Instead of:
```shell
func() {
    for file in $(find /usr/lib* -type f -name 'lib*.a' -print0 ); do
      echo $file
    done
}
```

use:
```shell
func() {
    trap "$(shopt -p nullglob globstar)" RETURN
    shopt -q -s nullglob globstar

    for file in /usr/lib*/**/lib*.a; do
      [[ -f $file ]] || continue
      echo "$file"
    done
}
```

Or collect the filenames in an array, if you need them more than once:
```shell
func() {
    trap "$(shopt -p nullglob globstar)" RETURN
    shopt -q -s nullglob globstar

    filenames=( /usr/lib*/**/lib*.a )

    for file in "${filenames[@]}"; do
      [[ -f $file ]] || continue
      echo "$file"
    done
}
```

Or, if you really want to use `find`, use `-print0` and an array:
```shell
func() {
    mapfile -t -d '' filenames < <(find /usr/lib* -type f -name 'lib*.a' -print0)
    for file in "${filenames[@]}"; do
      echo "$file"
    done
}
```

Note: `-d ''` is the same as `-d $'\0'` and sets the null byte as the delimiter.

or:
```shell
func() {
    find /usr/lib* -type f -name 'lib*.a' -print0 | while read -r -d '' file; do
      echo "$file"
    done
}
```

or
```shell
func() {
    while read -r -d '' file; do
      echo "$file"
    done < <(find /usr/lib* -type f -name 'lib*.a' -print0)
}
```

Use the tool options for null terminated strings, like `-print0`, `-0`, `-z`, etc.

## prefix or suffix array elements

Instead of:
```shell
func() {
  other-cmd $(for k in "$@"; do echo "prefix-$k"; done)
}
```
do
```shell
func() {
  other-cmd "${@/#/prefix-}"
}
```

or suffix:
```shell
func() {
  other-cmd "${@/%/-suffix}"
}
```

## Join array elements with a separator char

Here we have an associate array `_drivers`, where we want to print the keys separated by ',':
```shell
    if [[ ${!_drivers[*]} ]]; then
        echo "rd.driver.pre=$(IFS=, ;echo "${!_drivers[*]}")" > "${initdir}"/etc/cmdline.d/00-watchdog.conf
    fi
```

## Optional parameters to commands

If you want to call a command `cmd` with an option, if a variable is set, rather than doing:

```shell
func() {
  local param="$1"

  if [[ $param ]]; then
    param="--this-special-option $param"
  fi

  cmd $param
}
```

do it like this:

```shell
func() {
  local param="$1"

  cmd ${param:+--this-special-option "$param"}
}

# cmd --this-special-option 'abc'
func 'abc'

# cmd
func ''

# cmd
func
```

If you want to specify the option even with an empty string do this:

```shell
func() {
  local -a special_params

  if [[ ${1+_} ]]; then
    # only declare `param` if $1 is set (even as null string)
    local param="$1"
  fi

  # check if `param` is set (even as null string)
  if [[ ${param+_} ]]; then
    special_params=( --this-special-option "${param}" )
  fi

  cmd ${param+"${special_params[@]}"}
}

# cmd --this-special-option 'abc'
func 'abc'

# cmd --this-special-option ''
func ''

# cmd
func
```

Or more simple, if you only have to set an option:
```shell
func() {
  if [[ ${1+_} ]]; then
    # only declare `param` if $1 is set (even as null string)
    local param="$1"
  fi

  cmd ${param+--this-special-option}
}

# cmd --this-special-option
func 'abc'

# cmd --this-special-option
func ''

# cmd
func
```

