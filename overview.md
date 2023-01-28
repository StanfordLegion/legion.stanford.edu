---
layout: page
permalink: /overview/index.html
title: Legion Overview
---

## Motivation

Modern computer architectures are increasingly composed
of heterogeneous processors and deep complex memory
hierarchies. Furthermore, the cost of data movement
within these architectures is now coming to dominate
the overall cost of computation, both in terms of power
and performance. Despite these conditions, most machines 
are still programmed using an eclectic mix of programming systems
that focus only on describing parallelism (MPI,Pthreads,
OpenMP,OpenCL,OpenACC,CUDA). Achieving high performance and
power efficiency on future architectures will require 
programming systems capable of reasoning about the
structure of program data to facilitate efficient
placement and movement of data.

## Programming Model

Legion is a data-centric programming model for writing
high-performance applications for distributed heterogeneous
architectures. Making the programming system aware of
the structure of program data gives Legion programs
three advantages:

* __User-Specification of Data Properties__: Legion 
  provides abstractions for programmers to explicitly 
  declare properties of program data including
  organization, partitioning, privileges, and 
  coherence. Unlike current programming systems in
  which these properties are implicitly managed
  by programmers, Legion makes them explicit and provides
  the implementation for programmers.
* __Automated Mechanisms__: current programming
  models require developers to explicitly specify parallelism
  and issue data movement operations. Both responsibilities
  can easily lead to the introduction of bugs in complex
  applications. By understanding the structure of program
  data and how it is used, Legion can implicitly extract
  parallelism and issue the necessary data movement operations
  in accordance with the application-specified data properties,
  thereby removing a significant burden from the programmer.
* __User-Controlled Mapping__: by providing abstractions for
  representing both tasks and data, Legion makes it easy to
  describe how to map applications onto different architectures. Legion
  provides a mapping interface which gives programmers direct
  control over all the details of how an application is mapped
  and executed. Furthermore, Legion's understanding of program
  data makes the mapping process orthogonal to correctness.
  This simplifies program performance tuning and enables
  easy porting of applications to new architectures.

There are three important abstractions in the Legion
programming model:

* __Logical Regions__: Logical regions are the fundamental
  abstraction used for describing program data in 
  Legion applications. Logical regions support a relational
  model for data. Each logical region is described by an
  index space of rows (either unstructured pointers or 
  structured 1D, 2D, or 3D arrays) and a field space of
  columns. Unlike other relational models, Legion
  supports a different class of operations on logical
  regions: logical regions can be arbitrarily _partitioned_ 
  into sub-regions based on index space or _sliced_ on
  their field space. Data structures can be encoded in
  logical regions to express locality with partitioning
  and slicing describing data independence.
* __Tree of Tasks using Regions__: Every Legion program
  executes as a tree of tasks with a top-level task
  spawning sub-tasks which can recursively spawn further
  sub-tasks. All tasks in Legion must specify the logical
  regions they will access as well as the _privileges_ and
  _coherence_ for each logical region. Legion enforces a
  functional requirement on privileges which enables a
  hierarchical and distributed scheduling algorithm that 
  is essential for scalability.
* __Mapping Interface__: Legion makes no implicit decisions
  concerning how applications are mapped onto target
  hardware. Instead mapping decisions regarding how tasks
  are assigned to processors and how _physical instances_
  of logical regions are assigned to memories are made
  entirely by _mappers_. Mappers are part of application
  code and implement a mapping interface. Mappers are 
  queried by the Legion runtime whenever any mapping decision
  needs to be made. Legion guarantees that mapping
  decisions only impact performance and are orthogonal
  to correctness which simplifies tuning of Legion
  applications and enables easy porting to different
  architectures.

There are many more details to the Legion programming
model and we encourage you to learn more about them
by reading our [publications]({{ "/publications/" | relative_url }}).

## Target Users

Legion is designed for two classes of users:

* __Advanced application developers__: programmers
  who traditionally have used combinations of MPI,
  GASNet, Pthreads, OpenCL, and/or CUDA to develop their
  applications and always re-write applications 
  from scratch for maximum performance on each 
  new architecture.
* __Domain specific language and library authors__:
  tool writers who develop high-level productivity
  languages and libraries that support separate
  implementations for every target architecture
  for maximum performance.

In both cases, Legion provides a common framework
for implementing applications which can achieve
portable performance across a range of architectures.
The target class of users also dictates that productivity
in Legion will always be a second-class design constraint 
behind performance. Instead Legion is designed to be 
extensible and to support higher-level productivity 
languages and libraries.

## Design Principles

There are several principles which have driven
the design and implementation of Legion based on
our own experience writing applications for the
target class of architectures.

* __User control of decomposition__: it is impossible to 
  develop a general algorithm capable of automatically 
  inferring the optimal decomposition of data and computation
  for every program. Consequently the Legion programming model 
  explicitly puts control of how data is decomposed
  into logical regions and how algorithms are decomposed
  into tasks in the hands of the application developer.  
* __Handle irregularity__: Legion is designed so that all
  decisions can be made dynamically to handle irregularity.
  This includes the ability to make dynamic decisions regarding 
  how data is partitioned, algorithms are decomposed into
  tasks, where data and tasks are placed, how hard and
  soft-errors are managed, etc.
* __Hybrid programming model__: tasks in Legion are functional
  with controlled side effects on logical regions which the
  Legion runtime can understand. Individual tasks consist
  of traditional imperative code. The coarse-grained functional
  model enables Legion's distributed scheduling algorithm,
  while still supporting fine-grained imperative code within
  tasks that is more familiar to most application developers.
* __Deferred execution__: all runtime calls in Legion are
  _deferred_ which means that they can be 
  launched asynchronously and Legion is responsible for
  computing the necessary dependences and not performing
  operations until it is safe to do so. This is only possible
  because Legion understands the structure of program data
  for deferring data movement operations and because Legion 
  can reason about task's side-effects on logical regions.
* __Provide mechanism but not policy__: Legion is designed
  to give programmers total control over the policy of how
  an application is executed, while still automating any operations 
  which can uniquely be inferred from the given policy. For
  example, Legion provides total control over where tasks and
  data are run, but the runtime automatically infers the 
  necessary copies and data movement operations to conform to 
  the specified privilege and coherence annotations
  on the logical regions arguments to each task. 
* __Decouple correctness from performance__: In conjunction
  with the previous design principle, Legion ensures that
  policy decisions never impact the correctness of an 
  application. Policy decisions about how to map applications
  only impact performance allowing applications to customize
  mappings to particular architectures without needing to
  be concerned with affecting correctness.

In addition to our design principles for Legion, there
were are several challenges which we explicitly avoided
in designing Legion.

* Leaf task generator: Legion is not designed to solve
  the problem of emitting high performance leaf tasks for
  heterogeneous processors. Legion aids in managing 
  multiple functionally-equivalent variants of a task
  on different processor kinds, but does not help
  with implementing them. Current Legion applications use
  kernels that have either been hand-written for each
  processor kind or JIT-compiled with 
  [Terra](http://terralang.org).
* Magic mapper/performance optimizer: while Legion
  provides a default mapper, it will never be possible
  for it to perform an optimal mapping for all
  applications. High performance will require custom
  mappings. The Legion mapper interface is intentionally
  extensible to support both custom mappers, and the
  creation of mapping tools for building custom mappers.
* Automatic decomposition: decisions regarding how and 
  at what granularity to partition logical regions is
  the responsibility of the application. Similarly the
  choice of how to decompose algorithms into tasks is
  also the responsibility of the application. In both
  cases, Legion could never make the correct decisions
  for all applications and architectures.
* High productivity: based on the target users for Legion
  productivity will always be a second-class design
  consideration for the Legion. Instead Legion is
  designed to be extensible and targeted by higher-level
  productivity compilers and libraries.

## System Architecture

![]({{ "/images/legion_arch.svg" | relative_url }})


The above figure shows the architecture of the Legion programming
system. Applications targeting Legion have the option of either being
written in the Regent programming language or written directly to the
Legion C++ runtime interface. Applications written in Regent are
compiled to LLVM (and call a C wrapper for the C++ runtime API).

The Legion runtime system implements the
Legion programming model and supports all the necessary
API calls for writing Legion applications. Mappers are
special C++ objects that are built on top of the
Legion mapping interface which is queried by the 
Legion runtime system to make all mapping decisions
when executing a Legion program. Applications can 
either chose to use the default Legion mapper or
write custom mappers for higher performance.

The Legion runtime system sits on top of a
low-level runtime interface called *Realm*. The Realm interface
is designed to provide portability to the entire
Legion system by providing primitives which can be
implemented on a wide range of architectures. Realm is a modular
runtime and supports a variety of underlying technologies for
portability across a variety of machines, including GASNet for
high-performance networking on a variety of interconnects and CUDA for
GPUs.
