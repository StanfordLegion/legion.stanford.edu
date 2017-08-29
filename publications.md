---
layout: page
permalink: /publications/index.html
title: Publications
---

## Table of Contents

  * Legion Runtime:
      * [Overview (SC 2012)](#sc2012) \[[PDF](/pdfs/sc2012.pdf)]
      * [Structure Slicing (SC 2014)](#sc2014) \[[PDF](/pdfs/legion-fields.pdf)]
      * [Michael Bauer's Thesis (2014)](#bauer_thesis) \[[PDF](/pdfs/bauer_thesis.pdf)]
  * Programming Model:
      * [Partitioning Type System (OOPSLA 2013)](#oopsla2013) \[[PDF](/pdfs/oopsla2013.pdf)]
      * [Dependent Partitioning (OOPSLA 2016)](#dpl2016) \[[PDF](/pdfs/dpl2016.pdf)]
  * [Realm (PACT 2014)](#pact2014) \[[PDF](/pdfs/realm2014.pdf)]
      * [Sean Treichler's Thesis (2016)](#treichler_thesis) \[[PDF](/pdfs/treichler_thesis.pdf)]
  * [Regent (SC 2015)](#sc2015) \[[PDF](/pdfs/regent2015.pdf)]
      * [Control Replication (SC 2017)](#cr2017) \[[PDF](/pdfs/cr2017.pdf)]
      * [Elliott Slaughter's Thesis (2017)](#slaughter_thesis) \[[PDF](/pdfs/slaughter_thesis.pdf)]
  * DSLs:
      * [Singe (PPoPP 2014)](#ppopp2014) \[[PDF](/pdfs/singe2014.pdf)]
      * [Scout (WOLFHPC 2014)](#wolfhpc2014) \[[PDF](/pdfs/scout2014.pdf)]

## Papers

<a name="sc2012"></a>__Legion: Expressing Locality and Independence with Logical Regions__ [PDF](/pdfs/sc2012.pdf) <br/>
_Michael Bauer, Sean Treichler, Elliott Slaughter, Alex Aiken_ <br/>
In the International Conference on Supercomputing ([SC 2012](http://sc12.supercomputing.org)) <br/>
__Abstract:__ Modern parallel architectures have both heterogeneous processors and deep, complex 
memory hierarchies. We present Legion, a programming model and runtime system
for achieving high performance on these machines. Legion is
organized around logical regions, which express both locality and
independence of program data, and tasks, functions that perform
computations on regions. We describe a runtime system that
dynamically extracts parallelism from Legion programs, using
a distributed, parallel scheduling algorithm that identifies both
independent tasks and nested parallelism. Legion also enables
explicit, programmer controlled movement of data through the
memory hierarchy and placement of tasks based on locality
information via a novel mapping interface. We evaluate our
Legion implementation on three applications: fluid-flow on a
regular grid, a three-level AMR code solving a heat diffusion
equation, and a circuit simulation.

<a name="oopsla2013"></a>__Language Support for Dynamic, Hierarchical Data Partitioning__ [PDF](/pdfs/oopsla2013.pdf) <br/>
_Sean Treichler, Michael Bauer, Alex Aiken_ <br/>
In Object Oriented Programming, Systems, Languages, 
and Applications ([OOPSLA 2013](http://splashcon.org/2013/program/oopsla-research-papers)) <br/>
__Abstract:__ Applications written for distributed-memory parallel architectures must 
partition their data to enable parallel execution. As memory hierarchies become deeper, 
it is increasingly necessary that the data partitioning also be hierarchical to match. 
Current language proposals perform this hierarchical partitioning statically, which excludes 
many important applications where the appropriate partitioning is itself data
dependent and so must be computed dynamically. We describe Legion, a region-based 
programming system, where each region may be partitioned into subregions. Partitions
are computed dynamically and are fully programmable. The division of data need not be 
disjoint and subregions of a region may overlap, or alias one another. Computations use
regions with certain privileges (e.g., expressing that a computation uses a region 
read-only) and data coherence (e.g., expressing that the computation need only be atomic with
respect to other operations on the region), which can be controlled on a per-region 
(or subregion) basis.

We present the novel aspects of the Legion design, in particular 
the combination of static and dynamic checks used to enforce soundness. We give an 
extended example illustrating how Legion can express computations with dynamically 
determined relationships between computations and data partitions. We prove the soundness 
of Legion's type system, and show Legion type checking improves performance by up to
71% by eliding provably safe memory checks. In particular, we show that the dynamic 
checks to detect aliasing at runtime at the region granularity have negligible overhead.
We report results for three real-world applications running
on distributed memory machines, achieving up to 62.5X
speedup on 96 GPUs on the Keeneland supercomputer.

<a name="pact2014"></a>__Realm: An Event-Based Low-Level Runtime for Distributed Memory Architectures__ [PDF](/pdfs/realm2014.pdf) <br/>
_Sean Treichler, Michael Bauer, Alex Aiken_ <br/>
In Parallel Architectures and Compilation Techniques ([PACT 2014](http://www.pactconf.org/program.php)) <br/>
__Abstract:__ We present Realm, an event-based runtime system for heterogeneous,
distributed memory machines. Realm is fully asynchronous: all runtime actions
are non-blocking. Realm supports spawning computations, moving data, and 
<em>reservations</em>, a novel synchronization primitive. Asynchrony is exposed
via a light-weight event system capable of operating without central management.

We describe an implementation of Realm that relies on a novel <em>generational event</em>
data structure for efficiently handling large numbers of events in a distributed
address space. Micro-benchmark experiments show our implementation of Realm 
approaches the underlying hardware performance limits. We measure the performance
of three real-world applications on the Keeneland supercomputer. Our results
demonstrate that Realm confers considerable latency hiding to clients, attaining
significant speedups over traditional bulk-synchronous and independently optimized
MPI codes.

<a name="sc2014"></a>__Structure Slicing: Extending Logical Regions with Fields__ [PDF](/pdfs/legion-fields.pdf) <br/>
_Michael Bauer, Sean Treichler, Elliott Slaughter, Alex Aiken_ <br/>
In the International Conference on Supercomputing ([SC 2014](http://sc14.supercomputing.org/schedule/event_detail?evid=pap522)) <br/>
__Abstract:__ Applications on modern supercomputers are increasingly limited by the
cost of data movement, but mainstream programming systems have few abstractions for
describing the structure of a program's data. Consequently, the burden of managing
data movement, placement, and layout currently falls primarily upon the programmer

To address this problem, we previously proposed a data model based on <em>logical regions</em>
and described Legion, a programming system incorporating logical regions. In this paper,
we present <em>structure slicing</em>, which incorporates <em>fields</em> into the logical
region data model. We show that structure slicing enables Legion to automatically infer
task parallelism from field non-interference, decouple the specification of data usage
from layout, and reduce the overall amount of data moved. We demonstrate that structure
slicing enables both strong and weak scaling of three Legion applications, including S3D,
a production combustion simulation that uses logical regions and thousands of fields, with
speedups of up to 3.68X over a vectorized CPU-only Fortran implementation and 1.88X over
an independently hand-tuned OpenACC code.


<a name="ppopp2014"></a>_Note: The following paper is a result of our collaboration with the [ExaCT
Combustion Co-Design Center](http://exactcodesign.org/) and shows how a DSL
compiler can be used to generate fast tasks for Legion applications._<br/>
__Singe: Leveraging Warp Specialization for High Performance on GPUs__ [PDF](/pdfs/singe2014.pdf) <br/>
_Michael Bauer, Sean Treichler, Alex Aiken_<br/>
In Principles and Practices of Parallel Programming ([PPoPP 2014](https://sites.google.com/site/ppopp2014/home/schedule/)) <br/>
__Abstract:__ We present Singe, a Domain Specific Language (DSL) compiler for combustion
chemistry that leverages _warp specialization_ to produce high performance code for GPUs.
Instead of relying on traditional GPU programming models that emphasize data-parallel
computations, warp specialization allows compilers like Singe to partition computations
into sub-computations, which are then assigned to different warps within a thread block.
Fine-grain synchronization between warps is performed efficiently in hardware using
producer-consumer named barriers.  Partitioning computations using warp specialization
allows Singe to deal efficiently with the irregularity in both data access patterns
and computation.  Furthermore, warp-specialized partitioning of computations allows
Singe to fit extremely large working sets into on-chip memories.  Finally, we describe
the architecture and general computation techniques necessary for constructing a
warp-specializing compiler.  We show that the warp-specialized code emitted by Singe
is up to 3.75X faster than previously optimized data-parallel GPU kernels.

<a name="wolfhpc2014"></a>_Note: The following paper is an example of a DSL
compiler toolchain that targets Legion as a backend._<br/>
__Exploring the Construction of a Domain-Aware Toolchain for High-Performance Computing__ [PDF](/pdfs/scout2014.pdf) <br/>
_Patrick McCormick, Christine Sweeney, Nick Moss, Dean Prichard,
Samuel K. Gutierrez, Kei Davis, Jamaludin Mohd-Yusof_<br/>
In the International Workshop on Domain-Specific Languages and High-Level Frameworks for High Performance Computing ([WOLFHPC 2014](http://conferences.computer.org/wolfhpc/2014/)) <br/>
__Abstract:__ The push towards exascale computing has sparked
a new set of explorations for providing new productive programming
environments. While many efforts are focusing on
the design and development of domain-specific languages (DSLs),
few have addressed the need for providing a fully domain-aware
toolchain. Without such domain awareness critical features for
achieving acceptance and adoption, such as debugger support,
pose a long-term risk to the overall success of the DSL approach.
In this paper we explore the use of language extensions to
design and implement the Scout DSL and a supporting toolchain
infrastructure. We highlight how language features and the
software design methodologies used within the toolchain play
a significant role in providing a suitable environment for DSL
development.


<a name="sc2015"></a>__Regent: A High-Productivity Programming Language for HPC with Logical Regions__ [PDF](/pdfs/regent2015.pdf) <br/>
_Elliott Slaughter, Wonchan Lee, Sean Treichler, Michael Bauer, and Alex Aiken_ <br/>
In the International Conference on Supercomputing ([SC 2015](http://sc15.supercomputing.org/schedule/event_detail?evid=pap326)) <br/>
__Abstract:__ We present Regent, a high-productivity programming language for high
performance computing with logical regions. Regent users compose
programs with tasks (functions eligible for parallel execution) and
logical regions (hierarchical collections of structured
objects). Regent programs appear to execute sequentially, require no
explicit synchronization, and are trivially deadlock-free. Regent's
type system catches many common classes of mistakes and guarantees
that a program with correct serial execution produces
identical results on parallel and distributed machines.

We present an optimizing compiler for Regent that translates Regent
programs into efficient implementations for Legion, an asynchronous
task-based model. Regent employs several novel compiler optimizations
to minimize the dynamic overhead of the runtime system and enable
efficient operation. We evaluate Regent on three benchmark
applications and demonstrate that Regent achieves performance
comparable to hand-tuned Legion.


<a name="dpl2016"></a>__Dependent Partitioning__ [PDF](/pdfs/dpl2016.pdf) <br/>
_Sean Treichler, Michael Bauer, Rahul Sharma, Elliott Slaughter, and Alex Aiken_ <br/>
In Object Oriented Programming, Systems, Languages,
and Applications ([OOPSLA 2016](http://2016.splashcon.org/track/splash-2016-oopsla)) <br/>
__Abstract:__ A key problem in parallel programming is how data is
*partitioned*: divided into subsets that can be operated on in
parallel and, in distributed memory machines, spread across multiple
address spaces.

We present a *dependent partitioning* framework that allows an
application to concisely describe relationships between partitions.
Applications first establish *independent partitions*, which may
contain arbitrary subsets of application data, permitting the
expression of arbitrary application-specific data distributions.
*Dependent partitions* are then derived from these using the
*dependent partitioning operations* provided by the framework.  By
directly capturing inter-partition relationships, our framework can
soundly and precisely reason about programs to perform important
program analyses crucial to ensuring correctness and achieving good
performance.  As an example of the reasoning made possible, we present
a static analysis that discharges most consistency checks on
partitioned data during compilation.

We describe an implementation of our framework within Regent, a
language designed for the Legion programming model.  The use of
dependent partitioning constructs results in a 86-96% decrease in the
lines of code required to describe the partitioning, the elimination
of many of the expensive dynamic checks required for soundness by the
current Regent partitioning implementation, and speeds up the
computation of partitions by 2.6-12.7X even on a single thread.
Furthermore, we show that a distributed implementation incorporated
into the the Legion runtime system allows partitioning of data sets
that are too large to fit on a single node and yields an additional
29X speedup of partitioning operations on 64 nodes.


<a name="cr2017"></a>__Control Replication: Compiling Implicit Parallelism to Efficient SPMD with Logical Regions__ [PDF](/pdfs/cr2017.pdf) <br/>
_Elliott Slaughter, Wonchan Lee, Sean Treichler, Wen Zhang, Michael Bauer, Galen Shipman, Patrick McCormick and Alex Aiken_ <br/>
In the International Conference on Supercomputing ([SC 2017](http://sc17.supercomputing.org/presentation/?id=pap417&sess=sess165)) <br/>
__Abstract:__ We present control replication, a technique for generating
high-performance and scalable SPMD code from implicitly parallel
programs. In contrast to traditional parallel programming models that
require the programmer to explicitly manage threads and the
communication and synchronization between them, implicitly parallel
programs have sequential execution semantics and by their nature avoid
the pitfalls of explicitly parallel programming. However, without
optimizations to distribute control overhead, scalability is often
poor.

Performance on distributed-memory machines is especially sensitive to
communication and synchronization in the program, and thus optimizations
for these machines require an intimate understanding of a program's memory
accesses. Control replication achieves particularly effective
and predictable results by leveraging language support for first-class
data partitioning in the source programming model. We evaluate an
implementation of control replication for Regent and show that it
achieves up to 99% parallel efficiency at 1024
nodes with absolute performance comparable to hand-written MPI(+X)
codes.


## Theses

<a name="bauer_thesis"></a>*Note: The following thesis is a thorough guide to the Legion programming model and covers many implementation details that are not documented elsewhere.*<br/>
**Legion: Programming Distributed Heterogeneous Architectures with Logical Regions** [PDF](/pdfs/bauer_thesis.pdf)<br/>
*Michael Edward Bauer*<br/>
December 2014<br/>
**Abstract:** This thesis covers the design and implementation of
Legion, a new programming model and runtime system for targeting
distributed heterogeneous machine architectures. Legion introduces
logical regions as a new abstraction for describing the structure and
usage of program data. We describe how logical regions provide a
mechanism for applications to express important properties of program
data, such as locality and independence, that are often ignored by
current programming systems. We also show how logical regions allow
programmers to scope the usage of program data by different
computations. The explicit nature of logical regions makes these
properties of programs manifest, allowing many of the challenging
burdens of parallel programming, including dependence analysis and
data movement, to be off-loaded from the programmer to the programming
system.

Logical regions also improve the programmability and portability of
applications by decoupling the specification of a program from how it
is mapped onto a target architecture. Logical regions abstractly
describe sets of program data without requiring any specification
regarding the placement or layout of data. To control decisions about
the placement of computations and data, we introduce a novel mapping
interface that gives an application programmatic control over mapping
decisions at runtime. Different implementations of the mapper
interface can be used to port applications to new architectures and to
explore alternative mapping choices. Legion guarantees that the
decisions made through the mapping interface are independent of the
correctness of the program, thus facilitating easy porting and tuning
of applications to new architectures with different performance
characteristics.

Using the information provided by logical regions, an implementation
of Legion can automatically extract parallelism, manage data movement,
and infer synchronization. We describe the algorithms and data
structures necessary for efficiently performing these operations. We
further show how the Legion runtime can be generalized to operate as a
distributed system, making it possible for Legion applications to
scale well. As both applications and machines continue to become more
complex, the ability of Legion to relieve application developers of
many of the tedious responsibilities they currently face will become
increasingly important.

To demonstrate the performance of Legion, we port a production
combustion simulation, called S3D, to Legion. We describe how S3D is
implemented within the Legion programming model as well as the
different mapping strategies that are employed to tune S3D for runs on
different architectures. Our performance results show that a version
of S3D running on Legion is nearly three times as fast as comparable
state-of-the-art versions of S3D when run at 8192 nodes on the number
two supercomputer in the world.

<a name="treichler_thesis"></a>**Realm: Performance Portability through Composable
Asynchrony** [PDF](/pdfs/treichler_thesis.pdf)<br/>
*Sean Jeffrey Treichler*<br/>
December 2016<br/>
**Abstract:** Modern supercomputers are growing increasingly
complicated. The laws of physics have forced processor counts into the
thousands or even millions, resulted in the creation of deep
distributed memory hierarchies, and encouraged the use of multiple
processor and memory types in the same system. Developing an
application that is able to fully utilize such a system is very
difficult. The development of an application that is able to run well
on more than one such system with current programming models is so
daunting that it is generally not even attempted.

The Legion project attempts to address these challenges by combining a
traditional hierarchical application structure (i.e. tasks/functions
calling other tasks/functions) with a hierarchical data model (logical
regions, which may be partitioned into subregions), and introducing
the concept of mapping, a process in which the tasks and regions of a
machine-agnostic description are assigned to the processors and
memories of a particular machine.

This dissertation focuses on Realm, the "low-level" runtime that
manages the execution of a mapped Legion application. Realm is a fully
asynchronous event-based runtime. Realm operations are deferred by the
runtime, returning an event that triggers upon completion of the
operation.  These events may be used as preconditions for other
operations, allowing arbitrary composition of asynchronous
operations. The resulting operation graph naturally exposes the
available parallelism in the application as well as opportunities for
hiding the latency of any required communication.  While asynchronous
task launches and non-blocking data movement are fairly common in
existing programming models, Realm makes all runtime operations
asynchronous --- this includes resource management, performance
feedback, and even, apparently paradoxically, synchronization
primitives.

Important design and implementation issues of Realm will be discussed,
including the novel generational event data structure that allows
Realm to efficiently and scalably handle a very large number of events
in a distributed environment and the machine model that provides the
information required for the mapping of a Legion application onto a
system. Realm anticipates dynamic behavior of both future applications
and future systems and includes mechanisms for application-directed
profiling, fault reporting, and dynamic code generation that further
improve performance portability by allowing an application to adapt to
and optimize for the exact system configuration used for each run.

Microbenchmarks demonstrate the efficiency and scalability of the
Realm and justify some of the non-obvious design decisions
(e.g. unfairness in locks). Experiments with several mini-apps are
used to measure the benefit of a fully asynchronous runtime compared
to existing "non-blocking" approaches. Finally, performance of Legion
applications at full-scale show how Realm's composable asynchrony and
support for heterogeneity benefit the overall Legion system on a
variety of modern supercomputers.

<a name="slaughter_thesis"></a>**Regent: A High-Productivity Programming Language for Implicit Parallelism with Logical Regions** [PDF](/pdfs/slaughter_thesis.pdf)<br/>
*Elliott Slaughter*<br/>
August 2017<br/>
**Abstract:** Modern supercomputers are dominated by distributed-memory
machines. State of the art high-performance scientific applications
targeting these machines are typically written in low-level,
explicitly parallel programming models that enable maximal performance
but expose the user to programming hazards such as data races and
deadlocks. Conversely, implicitly parallel models isolate the user
from these hazards by providing easy-to-use sequential semantics and
place responsibility for parallelism and data movement on the
system. However, traditional implementations of implicit parallelism
suffer from substantial limitations: static, compiler-based
implementations restrict the programming model to exclude dynamic
features needed for unstructured applications, while dynamic,
runtime-based approaches suffer from a sequential bottleneck that
limits the scalability of the system.

We present Regent, a programming language designed to enable a hybrid
static and dynamic analysis of implicit parallelism. Regent programs
are composed of tasks (functions with annotated data usage). Program
data is stored in regions (hierarchical collections); regions are
dynamic, first-class values, but are named statically in the type
system to ensure correct usage and analyzability of programs. Tasks
may execute in parallel when they are mutually independent as
determined by the annotated usage (read, write, etc.) of regions
passed as task arguments. A Regent implementation is responsible for
automatically discovering parallelism in a Regent program by analyzing
the executed tasks in program order.

A naive implementation of Regent would suffer from a sequential
bottleneck as tasks must be analyzed sequentially at runtime to
discover parallelism, limiting scalability. We present an optimizing
compiler for Regent which transforms implicitly parallel programs into
efficient explicitly parallel code. By analyzing the region arguments
to tasks, the compiler is able to determine the data movement implied
by the sequence of task calls, even in the presence of unstructured
and data-dependent application behavior. The compiler can then replace
the implied data movement with explicit communication and
synchronization for efficient execution on distributed-memory
machines. We measure the performance and scalability of several Regent
programs on large supercomputers and demonstrate that optimized Regent
programs perform comparably to manually optimized explicitly parallel
programs.
