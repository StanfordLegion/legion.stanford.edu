---
layout: page
permalink: /pygion/index.html
title: Pygion
---

## Overview

Pygion is task-based framework for Python based on the [Legion]({{ "/" | relative_url }}) programming system. As with Legion, Pygion provides sequential semantics. Tasks may execute asynchronously and in parallel, but only when they preserve the behavior of sequential execution. Pygion analyzes tasks (via Legion) to determine what tasks are safe to execute in parallel and when data movement or synchronization is required for safe execution.

For an overview of Pygion, the [original PAW-ATM paper]({{ "/pdfs/pygion2019.pdf" | relative_url }}).

## Getting Started

Pygion lives in the main Legion repo under
[`bindings/python`](https://github.com/StanfordLegion/legion/tree/stable/bindings/python). To
get started with Pygion, build with Make in that directory:

```
git clone https://github.com/StanfordLegion/legion.git
cd legion/bindings/python
make LG_RT_DIR=$PWD/../../runtime -j4
```

Customize the `-j` flag parameter to control the number of threads used to build, depending on your machine.

## Building with CMake

If you prefer to use CMake, then build Legion at the top level `-DLegion_BUILD_BINDINGS=ON -DLegion_USE_Python=ON`:

```
git clone https://github.com/StanfordLegion/legion.git
cd legion
mkdir build
cd build
cmake .. -DLegion_BUILD_BINDINGS=ON -DLegion_USE_Python=ON -DCMAKE_INSTALL_PREFIX=$PWD/../install
make install -j4
```

## Examples

A wide variety of examples, with detailed comments, can be found in the [`examples`](https://github.com/StanfordLegion/legion/tree/stable/bindings/python/examples) directory. Most of the important features of Pygion are demonstrated in these examples.

A dedicated tutorial series for Pygion is coming soon.
