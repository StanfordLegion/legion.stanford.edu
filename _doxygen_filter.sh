#!/bin/sh
# Doxygen drops a \file block whose argument names something that is not an
# input file, which leaves the header undocumented and its members out of the
# File Members index. Strip the argument so \file documents its own file.

exec sed -E 's@^([[:space:]]*\*?[[:space:]]*[\\@]file)[[:space:]]+[^[:space:]]+@\1@' "$1"
