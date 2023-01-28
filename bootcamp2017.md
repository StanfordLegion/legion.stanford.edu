---
layout: page
permalink: /bootcamp2017/index.html
title: Legion Bootcamp 2017
---

This page contains links to videos, slides, and exercises from the
Legion Bootcamp 2017. This is the third annual meeting for people
interested in learning about [Legion](http://legion.stanford.edu/). In
a departure from the first two instances, this year's bootcamp follows
a tutorial style aimed primarily at teaching users how to program in
the Legion model. The bulk of the material consists of a series of
short lectures and programming exercises, progressing from "Hello
World" to writing a non-trivial program capable of runnning on
clusters of CPUs and GPUs. (Users coming to these materials after the
fact will need to provide their own compute resources.)

The bootcamp focuses on programming in
[Regent](http://regent-lang.org/), a high level, compiled language
that implements the Legion programming model. Using Regent allows
participants to become productive very quickly and enable the bootcamp
to give participants a more in-depth understanding of the Legion
approach to task-based programming. Because many projects are also
interested in programming in Legion at the C++ level, there are talks
in the second half of the tutorial devoted to programming directly to
the Legion C++ API. The concepts in Regent and the Legion C++ API are
the same, and in our experience the Regent instruction is the best way
even for users primarily interested in using Legion through C++ to
start.

## Tutorial

  * **Part 1**: [Slides]({{ "/pdfs/bootcamp2017/TutorialPart1.pdf" | relative_url }})
      * *Tasks:* [Video](https://www.youtube.com/watch?v=sC0UBFx0lXg&list=PLUNK9XcztK7xutP-diU7tw_1PFcXMYEmE&index=1), Time Index:
          * [0:00: Overview](https://www.youtube.com/watch?v=sC0UBFx0lXg&list=PLUNK9XcztK7xutP-diU7tw_1PFcXMYEmE&index=1&t=0s)
          * [26:50: Tasks](https://www.youtube.com/watch?v=sC0UBFx0lXg&list=PLUNK9XcztK7xutP-diU7tw_1PFcXMYEmE&index=1&t=26m50s)
          * [47:25: Legion Prof](https://www.youtube.com/watch?v=sC0UBFx0lXg&list=PLUNK9XcztK7xutP-diU7tw_1PFcXMYEmE&index=1&t=47m25s)
          * [1:11:17: Parallelism](https://www.youtube.com/watch?v=sC0UBFx0lXg&list=PLUNK9XcztK7xutP-diU7tw_1PFcXMYEmE&index=1&t=1h11m17s)
      * *Structured Regions:* [Video](https://www.youtube.com/watch?v=s87dWwnWKN8&list=PLUNK9XcztK7xutP-diU7tw_1PFcXMYEmE&index=2), Time Index:
          * [0:00: Legion Spy](https://www.youtube.com/watch?v=s87dWwnWKN8&list=PLUNK9XcztK7xutP-diU7tw_1PFcXMYEmE&index=2&t=0s)
          * [5:54: Exercise 1](https://www.youtube.com/watch?v=s87dWwnWKN8&list=PLUNK9XcztK7xutP-diU7tw_1PFcXMYEmE&index=2&t=5m54s)
          * [21:32: Terra](https://www.youtube.com/watch?v=s87dWwnWKN8&list=PLUNK9XcztK7xutP-diU7tw_1PFcXMYEmE&index=2&t=21m32s)
          * [35:49: Structured Regions](https://www.youtube.com/watch?v=s87dWwnWKN8&list=PLUNK9XcztK7xutP-diU7tw_1PFcXMYEmE&index=2&t=35m49s)
      * *Partitioning:* [Video](https://www.youtube.com/watch?v=ZKfe5JG7LDo&list=PLUNK9XcztK7xutP-diU7tw_1PFcXMYEmE&index=3), Time Index:
          * [0:00: Partitioning](https://www.youtube.com/watch?v=ZKfe5JG7LDo&list=PLUNK9XcztK7xutP-diU7tw_1PFcXMYEmE&index=3&t=0s)
          * [1:05:51: Image Blur](https://www.youtube.com/watch?v=ZKfe5JG7LDo&list=PLUNK9XcztK7xutP-diU7tw_1PFcXMYEmE&index=3&t=1h5m51s)
      * *Unstructured Regions:* [Video](https://www.youtube.com/watch?v=KEMh0b4VmTU&list=PLUNK9XcztK7xutP-diU7tw_1PFcXMYEmE&index=4), Time Index:
          * [0:00: Unstructured Regions](https://www.youtube.com/watch?v=KEMh0b4VmTU&list=PLUNK9XcztK7xutP-diU7tw_1PFcXMYEmE&index=4&t=0s)
          * [14:25: Dependent Partitioning](https://www.youtube.com/watch?v=KEMh0b4VmTU&list=PLUNK9XcztK7xutP-diU7tw_1PFcXMYEmE&index=4&t=14m25s)
          * [58:12: Some Comments on Type Checking](https://www.youtube.com/watch?v=KEMh0b4VmTU&list=PLUNK9XcztK7xutP-diU7tw_1PFcXMYEmE&index=4&t=58m12s)
      * *Putting it All Together:* [Video](https://www.youtube.com/watch?v=RpF2GFtClvw&list=PLUNK9XcztK7xutP-diU7tw_1PFcXMYEmE&index=5), Time Index:
          * [0:00: Page Rank](https://www.youtube.com/watch?v=RpF2GFtClvw&list=PLUNK9XcztK7xutP-diU7tw_1PFcXMYEmE&index=5&t=0s)
  * **Part 2**: [Slides]({{ "/pdfs/bootcamp2017/TutorialPart2.pdf" | relative_url }})
      * *Performance Tuning via Mapping:* [Video](https://www.youtube.com/watch?v=zJI-APPig2g&list=PLUNK9XcztK7xutP-diU7tw_1PFcXMYEmE&index=6), Time Index:
          * [0:00: Coherence](https://www.youtube.com/watch?v=zJI-APPig2g&list=PLUNK9XcztK7xutP-diU7tw_1PFcXMYEmE&index=6&t=0s)
          * [16:06: Metaprogramming](https://www.youtube.com/watch?v=zJI-APPig2g&list=PLUNK9XcztK7xutP-diU7tw_1PFcXMYEmE&index=6&t=16m6s)
          * [28:17: Circuit Overview](https://www.youtube.com/watch?v=zJI-APPig2g&list=PLUNK9XcztK7xutP-diU7tw_1PFcXMYEmE&index=6&t=28m17s)
          * [31:05: Circuit Partitioning](https://www.youtube.com/watch?v=zJI-APPig2g&list=PLUNK9XcztK7xutP-diU7tw_1PFcXMYEmE&index=6&t=31m5s)
          * [39:34: Circuit Tasks](https://www.youtube.com/watch?v=zJI-APPig2g&list=PLUNK9XcztK7xutP-diU7tw_1PFcXMYEmE&index=6&t=39m34s)
          * [58:50: Circuit Mapping](https://www.youtube.com/watch?v=zJI-APPig2g&list=PLUNK9XcztK7xutP-diU7tw_1PFcXMYEmE&index=6&t=58m50s)
      * *Writing Performant & Portable Kernels:* [Video](https://www.youtube.com/watch?v=U_V0sd0nmzk&list=PLUNK9XcztK7xutP-diU7tw_1PFcXMYEmE&index=7), Time Index:
          * [0:00: Circuit Mapping Cont.](https://www.youtube.com/watch?v=U_V0sd0nmzk&list=PLUNK9XcztK7xutP-diU7tw_1PFcXMYEmE&index=7&t=0s)
          * [25:50: Regent Optimizations](https://www.youtube.com/watch?v=U_V0sd0nmzk&list=PLUNK9XcztK7xutP-diU7tw_1PFcXMYEmE&index=7&t=25m50s)
          * [33:48: Circuit Performance](https://www.youtube.com/watch?v=U_V0sd0nmzk&list=PLUNK9XcztK7xutP-diU7tw_1PFcXMYEmE&index=7&t=33m48s)
          * [44:31: Circuit in Legion](https://www.youtube.com/watch?v=U_V0sd0nmzk&list=PLUNK9XcztK7xutP-diU7tw_1PFcXMYEmE&index=7&t=44m31s)

## Advanced Topics

  * **Advanced Profiling:** [Slides]({{ "/pdfs/bootcamp2017/AdvancedProfiling.pdf" | relative_url }}), [Video](https://www.youtube.com/watch?v=Mk7kER1xyiA&list=PLUNK9XcztK7xutP-diU7tw_1PFcXMYEmE&index=8)
  * **Legion C++ API & Control Replication:** [Slides]({{ "/pdfs/bootcamp2017/LegionControlReplication.pdf" | relative_url }}), [Video](https://www.youtube.com/watch?v=nKBhMlPHpvY&list=PLUNK9XcztK7xutP-diU7tw_1PFcXMYEmE&index=9)
  * **Regent Update:** [Slides]({{ "/pdfs/bootcamp2017/Regent.pdf" | relative_url }}), [Video](https://www.youtube.com/watch?v=2VyhhtIOijQ&list=PLUNK9XcztK7xutP-diU7tw_1PFcXMYEmE&index=10)

## Exercises

The exercises from the bootcamp are available in a [Github repository](https://github.com/StanfordLegion/bootcamp2017). In order to run these examples on your local machine, follow the [Regent installation instructions](http://regent-lang.org/install/).

## Previous Bootcamps

  * [Legion Bootcamp 2015]({{ "/bootcamp2015/" | relative_url }})
  * [Legion Bootcamp 2014]({{ "/bootcamp2014/" | relative_url }})
