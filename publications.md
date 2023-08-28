---
layout: page
permalink: /publications/index.html
title: Publications
---

## Table of Contents

  * Legion Runtime:
      * [Overview (SC 2012)](#sc2012) \[[PDF]({{ "/pdfs/sc2012.pdf" | relative_url }})]
      * [Structure Slicing (SC 2014)](#sc2014) \[[PDF](/pdfs/legion-fields.pdf)]
      * [Tracing (SC 2018)](#trace2018) \[[PDF]({{ "/pdfs/trace2018.pdf" | relative_url }})]
      * [Correctness of Dependence Analysis (Correctness 2018)](#dep2018) \[[PDF]({{ "/pdfs/dep2018.pdf" | relative_url }})]
      * [Dynamic Control Replication (PPoPP 2021)](#dcr2021) \[[PDF]({{ "/pdfs/dcr2021.pdf" | relative_url }})]
      * [Index Launches (SC 2021)](#idx2021) \[[PDF]({{ "/pdfs/idx2021.pdf" | relative_url }})]
      * [Visibility Algorithms (PPoPP 2023)](#visibility2023) \[[PDF]({{ "/pdfs/visibility2023.pdf" | relative_url }})]
  * Programming Model:
      * [Partitioning Type System (OOPSLA 2013)](#oopsla2013) \[[PDF]({{ "/pdfs/oopsla2013.pdf" | relative_url }})]
      * [Dependent Partitioning (OOPSLA 2016)](#dpl2016) \[[PDF]({{ "/pdfs/dpl2016.pdf" | relative_url }})]
  * Realm:
      * [Overview (PACT 2014)](#pact2014) \[[PDF]({{ "/pdfs/realm2014.pdf" | relative_url }})]
      * [I/O Subsystem (HiPC 2017)](#hipc2017) \[[PDF]({{ "/pdfs/hipc2017.pdf" | relative_url }})]
  * Regent:
      * [Overview (SC 2015)](#sc2015) \[[PDF]({{ "/pdfs/regent2015.pdf" | relative_url }})]
      * [Control Replication (SC 2017)](#cr2017) \[[PDF]({{ "/pdfs/cr2017.pdf" | relative_url }})]
      * [Auto-Parallelizer (SC 2019)](#parallel2019) \[[PDF]({{ "/pdfs/parallelizer2019.pdf" | relative_url }})]
  * Bindings:
      * [Python (PAW-ATM 2019)](#pygion2019) \[[PDF]({{ "/pdfs/pygion2019.pdf" | relative_url }})]
  * Libraries and Techniques:
      * [Visualization (ISAV 2017)](#isav2017) \[[PDF]({{ "/pdfs/isav2017.pdf" | relative_url }})]
      * [Graph Processesing (VLDB 2018)](#vldb2018) \[[PDF]({{ "/pdfs/vldb2018.pdf" | relative_url }}), [Software Release](https://github.com/LuxGraph/Lux)]
      * [Legate NumPy (SC 2019)](#legate2019) \[[PDF](/pdfs/legate-preprint.pdf)]
      * [Tensor Algebra (PLDI 2022)](#distal2022) \[[PDF]({{ "/pdfs/distal2022.pdf" | relative_url }})]
      * [Distributed Task Fusion (PAW-ATM 2022)](#pawatm2022) \[[PDF]({{ "/pdfs/pawatm2022.pdf" | relative_url }})]
      * [Sparse Tensor Algebra (SC 2022)](#spdistal2022) \[[PDF]({{ "/pdfs/spdistal2022.pdf" | relative_url }})]
      * [Legate Sparse (SC 2023)](#legate-sparse2023) \[[PDF](/pdfs/legate-sparse2023.pdf)]
  * Applications:
      * [S3D-Legion (2017)](#s3d2017) \[[PDF](https://www.taylorfrancis.com/books/e/9781315277400/chapters/10.1201/b21930-12)]
      * [Soleil-X (2018)](#soleilx2018) \[[PDF]({{ "/pdfs/soleilx2018.pdf" | relative_url }})]
      * [HTR Solver (2020)](#htr2020) \[[PDF](https://doi.org/10.1016/j.cpc.2020.107262)]
      * [Task Bench (SC 2020)](#taskbench2020) \[[PDF]({{ "/pdfs/taskbench2020.pdf" | relative_url }})]
      * [Meshfree Solver (PAW-ATM 2020)](#meshfree2020) \[[PDF]({{ "/pdfs/pawatm2020.pdf" | relative_url }})]
  * DSLs:
      * [Singe (PPoPP 2014)](#ppopp2014) \[[PDF]({{ "/pdfs/singe2014.pdf" | relative_url }})]
      * [Scout (WOLFHPC 2014)](#wolfhpc2014) \[[PDF]({{ "/pdfs/scout2014.pdf" | relative_url }})]
  * Theses:
      * [Michael Bauer's Thesis (2014)](#bauer_thesis) \[[PDF]({{ "/pdfs/bauer_thesis.pdf" | relative_url }})]
      * [Sean Treichler's Thesis (2016)](#treichler_thesis) \[[PDF]({{ "/pdfs/treichler_thesis.pdf" | relative_url }})]
      * [Elliott Slaughter's Thesis (2017)](#slaughter_thesis) \[[PDF]({{ "/pdfs/slaughter_thesis.pdf" | relative_url }})]
      * [Wonchan Lee's Thesis (2019)](#lee_thesis) \[[PDF]({{ "/pdfs/lee_thesis.pdf" | relative_url }})]
      * [Rupanshu Soi's Thesis (2021)](#soi_thesis) \[[PDF]({{ "/pdfs/soi_thesis.pdf" | relative_url }})]

## Papers

<a name="sc2012"></a>__Legion: Expressing Locality and Independence with Logical Regions__ [PDF]({{ "/pdfs/sc2012.pdf" | relative_url }}) <br/>
_Michael Bauer, Sean Treichler, Elliott Slaughter, Alex Aiken_ <br/>
In the International Conference for High Performance Computing, Networking, Storage and Analysis ([SC 2012](http://sc12.supercomputing.org)) <br/>
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

<a name="oopsla2013"></a>__Language Support for Dynamic, Hierarchical Data Partitioning__ [PDF]({{ "/pdfs/oopsla2013.pdf" | relative_url }}) <br/>
_Sean Treichler, Michael Bauer, Alex Aiken_ <br/>
In Object Oriented Programming, Systems, Languages, 
and Applications ([OOPSLA 2013](https://web.archive.org/web/20160806105926/http://splashcon.org/2013/program/oopsla-research-papers)) <br/>
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

<a name="pact2014"></a>__Realm: An Event-Based Low-Level Runtime for Distributed Memory Architectures__ [PDF]({{ "/pdfs/realm2014.pdf" | relative_url }}) <br/>
_Sean Treichler, Michael Bauer, Alex Aiken_ <br/>
In Parallel Architectures and Compilation Techniques ([PACT 2014](https://web.archive.org/web/20141217010120/http://www.pactconf.org/program.php)) <br/>
__Abstract:__ We present Realm, an event-based runtime system for heterogeneous,
distributed memory machines. Realm is fully asynchronous: all runtime actions
are non-blocking. Realm supports spawning computations, moving data, and 
*reservations*, a novel synchronization primitive. Asynchrony is exposed
via a light-weight event system capable of operating without central management.

We describe an implementation of Realm that relies on a novel *generational event*
data structure for efficiently handling large numbers of events in a distributed
address space. Micro-benchmark experiments show our implementation of Realm 
approaches the underlying hardware performance limits. We measure the performance
of three real-world applications on the Keeneland supercomputer. Our results
demonstrate that Realm confers considerable latency hiding to clients, attaining
significant speedups over traditional bulk-synchronous and independently optimized
MPI codes.

<a name="sc2014"></a>__Structure Slicing: Extending Logical Regions with Fields__ [PDF](/pdfs/legion-fields.pdf) <br/>
_Michael Bauer, Sean Treichler, Elliott Slaughter, Alex Aiken_ <br/>
In the International Conference for High Performance Computing, Networking, Storage and Analysis ([SC 2014](https://web.archive.org/web/20151012063525/http://sc14.supercomputing.org/schedule/event_detail?evid=pap522)) <br/>
__Abstract:__ Applications on modern supercomputers are increasingly limited by the
cost of data movement, but mainstream programming systems have few abstractions for
describing the structure of a program's data. Consequently, the burden of managing
data movement, placement, and layout currently falls primarily upon the programmer

To address this problem, we previously proposed a data model based on *logical regions*
and described Legion, a programming system incorporating logical regions. In this paper,
we present *structure slicing*, which incorporates *fields* into the logical
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
__Singe: Leveraging Warp Specialization for High Performance on GPUs__ [PDF]({{ "/pdfs/singe2014.pdf" | relative_url }}) <br/>
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
__Exploring the Construction of a Domain-Aware Toolchain for High-Performance Computing__ [PDF]({{ "/pdfs/scout2014.pdf" | relative_url }}) <br/>
_Patrick McCormick, Christine Sweeney, Nick Moss, Dean Prichard,
Samuel K. Gutierrez, Kei Davis, Jamaludin Mohd-Yusof_<br/>
In the International Workshop on Domain-Specific Languages and High-Level Frameworks for High Performance Computing ([WOLFHPC 2014](https://web.archive.org/web/20150717055110/https://conferences.computer.org/wolfhpc/2014/)) <br/>
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


<a name="sc2015"></a>__Regent: A High-Productivity Programming Language for HPC with Logical Regions__ [PDF]({{ "/pdfs/regent2015.pdf" | relative_url }}) <br/>
_Elliott Slaughter, Wonchan Lee, Sean Treichler, Michael Bauer, and Alex Aiken_ <br/>
In the International Conference for High Performance Computing, Networking, Storage and Analysis ([SC 2015](https://web.archive.org/web/20151011093701/http://sc15.supercomputing.org/schedule/event_detail?evid=pap326)) <br/>
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


<a name="dpl2016"></a>__Dependent Partitioning__ [PDF]({{ "/pdfs/dpl2016.pdf" | relative_url }}) <br/>
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


<a name="cr2017"></a>__Control Replication: Compiling Implicit Parallelism to Efficient SPMD with Logical Regions__ [PDF]({{ "/pdfs/cr2017.pdf" | relative_url }}) <br/>
_Elliott Slaughter, Wonchan Lee, Sean Treichler, Wen Zhang, Michael Bauer, Galen Shipman, Patrick McCormick and Alex Aiken_ <br/>
In the International Conference for High Performance Computing, Networking, Storage and Analysis ([SC 2017](http://sc17.supercomputing.org/presentation/?id=pap417&sess=sess165)) <br/>
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


<a name="hipc2017"></a>__Integrating External Resources with a Task-Based Programming Model__ [PDF]({{ "/pdfs/hipc2017.pdf" | relative_url }}) <br/>
_Zhihao Jia, Sean Treichler, Galen Shipman, Michael Bauer, Noah Watkins, Carlos Maltzahn, Patrick McCormick and Alex Aiken_ <br/>
In the International Conference on High Performance Computing, Data, and Analytics (HiPC 2017) <br/>
__Abstract:__ Accessing external resources (e.g., loading input
data, checkpointing snapshots, and out-of-core processing) can
have a significant impact on the performance of applications. However, no existing programming systems for high-performance computing directly manage and optimize external
accesses. As a result, users must explicitly manage external
accesses alongside their computation at the application level,
which can result in both correctness and performance issues.

We address this limitation by introducing Iris, a task-based
programming model with semantics for external resources.
Iris allows applications to describe their access requirements
to external resources and the relationship of those accesses
to the computation. Iris incorporates external I/O into a
deferred execution model, reschedules external I/O to overlap
I/O with computation, and reduces external I/O when possible.
We evaluate Iris on three microbenchmarks representative of
important workloads in HPC and a full combustion simulation,
S3D. We demonstrate that the Iris implementation of S3D
reduces the external I/O overhead by up to 20x, compared
to the Legion and the Fortran implementations.


<a name="isav2017"></a>__*In Situ* Visualization with Task-based Parallelism__ [PDF]({{ "/pdfs/isav2017.pdf" | relative_url }}) <br/>
_Alan Heirich, Elliott Slaughter, Manolis Papadakis, Wonchan Lee, Tim Biedert and Alex Aiken_ <br/>
In the Workshop on In Situ Infrastructures for Enabling Extreme-scale Analysis and Visualization (ISAV 2017) <br/>
__Abstract:__ This short paper describes an experimental prototype of *in situ*
visualization in a task-based parallel programming framework. A
set of reusable visualization tasks were composed with an existing
simulation. The visualization tasks include a local OpenGL renderer, a parallel image compositor, and a display task. These tasks
were added to an existing fluid-particle-radiation simulation and
weak scaling tests were run on up to 512 nodes of the Piz Daint
supercomputer. Benchmarks showed that the visualization components scaled and did not reduce the simulation throughput. The
compositor latency increased logarithmically with increasing node
count.


<a name="s3d2017"></a>__S3D-Legion: An Exascale Software for Direct Numerical Simulation of Turbulent Combustion with Complex Multicomponent Chemistry__ [PDF](https://www.taylorfrancis.com/books/e/9781315277400/chapters/10.1201/b21930-12) <br/>
_Sean Treichler, Michael Bauer, Ankit Bhagatwala, Giulio Borghesi, Ramanan Sankaran, Hemanth Kolla, Patrick S. McCormick, Elliott Slaughter, Wonchan Lee, Alex Aiken and Jacqueline Chen_ <br/>
In [Exascale Scientific Applications: Scalability and Performance Portability](https://www.crcpress.com/p/book/9781138197541) (CRC Press, 2017)


<a name="vldb2018"></a>__A Distributed Multi-GPU System for Fast Graph Processing__ [PDF]({{ "/pdfs/vldb2018.pdf" | relative_url }}), [Software Release](https://github.com/LuxGraph/Lux) <br/>
_Zhihao Jia, Yongkee Kwon, Galen Shipman, Pat McCormick, Mattan Erez and Alex Aiken_ <br/>
In the International Conference on Very Large Data Bases (VLDB 2018) <br/>
__Abstract:__ We present Lux, a distributed multi-GPU system that
achieves fast graph processing by exploiting the aggregate memory
bandwidth of multiple GPUs and taking advantage of locality in the
memory hierarchy of multi-GPU clusters. Lux provides two execution
models that optimize algorithmic efficiency and enable important GPU
optimizations, respectively. Lux also uses a novel dynamic load
balancing strategy that is cheap and achieves good load balance across
GPUs. In addition, we present a performance model that quantitatively
predicts the execution times and automatically selects the runtime
configurations for Lux applications. Experiments show that Lux
achieves up to 20&times; speedup over state-of-the-art shared memory systems
and up to two orders of magnitude speedup over distributed systems.


<a name="trace2018"></a>__Dynamic Tracing: Memoization of Task Graphs for Dynamic Task-Based Runtimes__ [PDF]({{ "/pdfs/trace2018.pdf" | relative_url }}) <br/>
_Wonchan Lee, Elliott Slaughter, Michael Bauer, Sean Treichler, Todd Warszawski, Michael Garland and Alex Aiken_ <br/>
In the International Conference for High Performance Computing, Networking, Storage and Analysis ([SC 2018](https://sc18.supercomputing.org/presentation/?id=pap490&sess=sess183)) <br/>
__Abstract:__ Many recent programming systems for both supercomputing
and data center workloads generate task graphs to express computations
that run on parallel and distributed machines. Due to the overhead
associated with constructing these graphs the dependence analysis that
generates them is often statically computed and memoized, and the
resulting graph executed repeatedly at runtime. However, many
applications require a dynamic dependence analysis due to data
dependent behavior, but there are new challenges in capturing and
re-executing task graphs at runtime. In this work, we introduce
dynamic tracing, a technique to capture a dynamic dependence analysis
of a trace that generates a task graph, and replay it. We show that an
implementation of dynamic tracing improves strong scaling by an
average of 4.9X and up to 7.0X on a suite of already optimized
benchmarks.


<a name="dep2018"></a>__Correctness of Dynamic Dependence Analysis for Implicitly Parallel Tasking Systems__ [PDF]({{ "/pdfs/dep2018.pdf" | relative_url }}) <br/>
_Wonchan Lee, George Stelle, Patrick McCormick and Alex Aiken_ <br/>
In the International Workshop on Software Correctness for HPC Applications ([Correctness 2018](https://correctness-workshop.github.io/2018/)) <br/>
__Abstract:__ In this paper, we rigorously verify the correctness of
dynamic dependence analysis, a key algorithm for parallelizing
programs in implicitly parallel tasking systems. A dynamic dependence
analysis of a program results in a task graph, a DAG of tasks
constraining the order of task execution. Because a program is
automatically parallelized based on its task graph, the analysis
algorithm must generate a graph with all the dependencies that are
necessary to preserve the program's original semantics for any
non-deterministic parallel execution of tasks. However, this
correctness is not straightforward to verify as implicitly parallel
tasking systems often use an optimized dependence analysis
algorithm. To study the correctness of dynamic dependence analysis in
a realistic setting, we design a model algorithm that captures the
essence of realistic analysis algorithms. We prove that this algorithm
constructs task graphs that soundly and completely express correct
parallel executions of programs. We also show that the generated task
graph is the most succinct one for a program when the program
satisfies certain conditions.


<a name="soleilx2018"></a>__Soleil-X: Turbulence, Particles, and Radiation in the Regent Programming Language__ [PDF]({{ "/pdfs/soleilx2018.pdf" | relative_url }}) <br/>
_Hilario Torres, Manolis Papadakis, Llu&iacute;s Jofre, Wonchan Lee, Alex Aiken and Gianluca Iaccarino_ <br/>
In Bulletin of the American Physical Society (2018) <br/>
__Abstract:__ The Predictive Science Academic Alliance Program (PSAAP)
II at Stanford University is developing an Exascale-ready
multi-physics solver to investigate particle-laden turbulent flows in
a radiation environment for solar energy receiver applications. To
simulate the proposed concentrated particle-based receiver design
three distinct but coupled physical phenomena must be modeled: fluid
flows, Lagrangian particle dynamics, and the transport of thermal
radiation.  Therefore, three different physics solvers (fluid,
particles, and radiation) must run concurrently with significant
cross-communication in an integrated multi-physics
simulation. However, each solver uses substantially different
algorithms and data access patterns.  Coordinating the overall data
communication, computational load balancing, and scaling these
different physics solvers together on modern massively parallel,
heterogeneous high performance computing systems presents several
major challenges.  We have adopted the Legion programming system, via
the Regent programming language, and its task parallel programming
model to address these challenges.  Our multi-physics solver Soleil-X
is written entirely in the high level Regent programming language and
is one of the largest and most complex applications written in Regent
to date. At this workshop we will give an overview of the software
architecture of Soleil-X as well as discuss how our multi-physics
solver was designed to use the task parallel programming model
provided by Legion. We will also discuss the developmentexperience,
scaling, performance, portability, and multi-physics simulation
results.


<a name="legate2019"></a>__Legate NumPy: Accelerated and Distributed Array Computing__ [PDF](/pdfs/legate-preprint.pdf) <br/>
_Michael Bauer and Michael Garland_ <br/>
In the International Conference for High Performance Computing, Networking, Storage and Analysis ([SC 2019](http://sc19.supercomputing.org)) <br/>
__Abstract:__ NumPy is a popular Python library used for performing
array-based numerical computations. The canonical implementation of
NumPy used by most programmers runs on a single CPU core and only a
few operations are parallelized across cores. This restriction to
single-node CPU-only execution limits both the size of data that can
be processed and the speed with which problems can be solved. In this
paper we introduce Legate, a programming system that transparently
accelerates and distributes NumPy programs to machines of any scale
and capability typically by changing a single module import
statement. Legate achieves this by translating the NumPy application
interface into the Legion programming model and leveraging the
performance and scalability of the Legion runtime. We demonstrate that
Legate can achieve state-of-the-art scalability when running NumPy
programs on machines with up to 1280 CPU cores and 256 GPUs, allowing
users to prototype on their desktop and immediately scale up to
significantly larger machines. Furthermore, we demonstrate that Legate
can achieve between one and two orders of magnitude better performance
than the popular Python library Dask when running comparable programs
at scale.


<a name="parallel2019"></a>__A Constraint-Based Approach to Automatic Data Partitioning for Distributed Memory Execution__ [PDF]({{ "/pdfs/parallelizer2019.pdf" | relative_url }}) <br/>
_Wonchan Lee, Manolis Papadakis, Elliott Slaughter and Alex Aiken_ <br/>
In the International Conference for High Performance Computing, Networking, Storage and Analysis ([SC 2019](http://sc19.supercomputing.org)) <br/>
__Abstract:__ Although data partitioning is required to enable
parallelism on distributed memory systems, data partitions are not
first class objects in most distributed programming models. As a
result, automatic parallelizers and application writers encode a
particular partitioning strategy in the parallelized program, leading
to a program not easily configured or composed with other parallel
programs.

We present a constraint-based approach to automatic data
partitioning. By introducing abstractions for first-class data
partitions, we express a space of correct partitioning
strategies. Candidate partitions are characterized by partitioning
constraints, which can be automatically inferred from data accesses in
parallelizable loops. Constraints can be satisfied by synthesized
partitioning code or user-provided partitions. We demonstrate that
programs auto-parallelized in our approach are easily composed with
manually parallelized parts and have scalability comparable to
hand-optimized counterparts.


<a name="pygion2019"></a>__Pygion: Flexible, Scalable Task-Based Parallelism with Python__ [PDF]({{ "/pdfs/pygion2019.pdf" | relative_url }}) <br/>
_Elliott Slaughter and Alex Aiken_ <br/>
In the Parallel Applications Workshop, Alternatives To MPI+X ([PAW-ATM 2019](https://sourceryinstitute.github.io/PAW/)) <br/>
__Abstract:__ Dynamic languages provide the flexibility needed to
implement expressive support for task-based parallel programming
constructs. We present Pygion, a Python interface for the Legion
task-based programming system, and show that it can provide features
comparable to Regent, a statically typed programming language with
dedicated support for the Legion programming model. Furthermore, we
show that the dynamic nature of Python permits the implementation of
several key optimizations (index launches, futures, mapping) currently
implemented in the Regent compiler. Together these features enable
Pygion code that is comparable in expressiveness but more flexible
than Regent, and substantially more concise, less error prone, and
easier to use than C++ Legion code. Pygion is designed to interoperate
with Regent and can use Regent to generate high-performance CPU and
GPU kernel implementations. We show that, in combination with
high-performance kernels written in Regent, Pygion is able to achieve
efficient, scalable execution on up to 512 nodes of the heterogeneous
supercomputer Piz Daint.


<a name="htr2020"></a>__HTR Solver: An Open-Source Exascale-Oriented Task-Based Multi-GPU High-Order Code for Hypersonic Aerothermodynamics__ [PDF](https://doi.org/10.1016/j.cpc.2020.107262) <br/>
_Mario Di Renzo, Lin Fu and Javier Urzay_ <br/>
In Computer Physics Communications (2020) <br/>
__Abstract:__ In this study, the open-source Hypersonics Task-based
Research (HTR) solver for hypersonic aerothermodynamics is
described. The physical formulation of the code includes
thermochemical effects induced by high temperatures (vibrational
excitation and chemical dissociation). The HTR solver uses high-order
TENO-based spatial discretization on structured grids and efficient
time integrators for stiff systems, is highly scalable in GPU-based
supercomputers as a result of its implementation in the Regent/Legion
stack, and is designed for direct numerical simulations of canonical
hypersonic flows at high Reynolds numbers. The performance of the HTR
solver is tested with benchmark cases including inviscid vortex
advection, low- and high-speed laminar boundary layers, inviscid
one-dimensional compressible flows in shock tubes, supersonic
turbulent channel flows, and hypersonic transitional boundary layers
of both calorically perfect gases and dissociating air.


<a name="taskbench2020"></a>__Task Bench: A Parameterized Benchmark for Evaluating Parallel Runtime Performance__ [PDF]({{ "/pdfs/taskbench2020.pdf" | relative_url }}) <br/>
_Elliott Slaughter, Wei Wu, Yuankun Fu, Legend Brandenburg, Nicolai Garcia, Wilhem Kautz, Emily Marx, Kaleb S. Morris, Qinglei Cao, George Bosilca, Seema Mirchandaney, Wonchan Lee, Sean Treichler, Patrick McCormick, and Alex Aiken_ <br/>
In the International Conference for High Performance Computing, Networking, Storage and Analysis ([SC 2020](https://sc20.supercomputing.org/presentation/?id=pap215&sess=sess162)) <br/>
__Abstract:__ We present Task Bench, a *parameterized* benchmark designed to
explore the performance of distributed programming systems under a
variety of application scenarios. Task Bench dramatically lowers the
barrier to benchmarking and comparing multiple programming systems by
making the implementation for a given system orthogonal to the
benchmarks themselves: every benchmark constructed with Task Bench
runs on every Task Bench implementation. Furthermore, Task Bench's
parameterization enables a wide variety of benchmark scenarios that
distill the key characteristics of larger applications.

To assess the effectiveness and overheads of the tested systems, we
introduce a novel metric, *minimum effective task granularity*
(METG). We conduct a comprehensive study with 15 programming systems
on up to 256 Haswell nodes of the Cori supercomputer. Running at
scale, 100&mu;s-long tasks are the finest granularity that any
system runs efficiently with current technologies. We also study each
system's scalability, ability to hide communication and mitigate load
imbalance.


<a name="meshfree2020"></a>__An Implicitly Parallel Meshfree Solver in Regent__ [PDF]({{ "/pdfs/pawatm2020.pdf" | relative_url }}) <br/>
_Rupanshu Soi, Nischay Ram Mamidi, Elliott Slaughter, Kumar Prasun, Anil Nemili, and S.M. Deshpande_ <br/>
In the Parallel Applications Workshop, Alternatives to MPI+X ([PAW-ATM 2020](https://sourceryinstitute.github.io/PAW/PAW-ATM20/indexPAW-ATM20.html)) <br/>
__Abstract:__ This paper presents the development of a Regent
based implicitly parallel meshfree solver for inviscid compressible
fluid flows. The meshfree solver is based on the Least Squares
Kinetic Upwind Method (LSKUM). The performance of the
Regent parallel solver is assessed by comparing with the explicitly
parallel versions of the same solver written in Fortran 90 and
Julia. The Fortran code uses MPI with PETSc libraries, while the
Julia code uses an MPI + X alternative parallel library. Numerical
results are shown to assess the performance of these solvers on
single and multiple CPU nodes.


<a name="dcr2021"></a>__Scaling Implicit Parallelism via Dynamic Control Replication__ [PDF]({{ "/pdfs/dcr2021.pdf" | relative_url }}) <br/>
_Michael Bauer, Wonchan Lee, Elliott Slaughter, Zhihao Jia, Mario Di Renzo, Manolis Papadakis, Galen Shipman, Patrick McCormick, Michael Garland, and Alex Aiken_ <br/>
In Principles and Practices of Parallel Programming ([PPoPP 2021](https://ppopp21.sigplan.org/details/PPoPP-2021-main-conference/10/Scaling-Implicit-Parallelism-via-Dynamic-Control-Replication)) <br/>
__Abstract:__ We present dynamic control replication, a run-time
program analysis that enables scalable execution of implicitly
parallel programs on large machines through a distributed and
efficient dynamic dependence analysis. Dynamic control replication
distributes dependence analysis by executing multiple copies of an
implicitly parallel program while ensuring that they still
collectively behave as a single execution.  By distributing and
parallelizing the dependence analysis, dynamic control replication
supports efficient, on-the-fly computation of dependences for programs
with arbitrary control flow at scale. We describe an asymptotically
scalable algorithm for implementing dynamic control replication that
maintains the sequential semantics of implicitly parallel programs.

An implementation of dynamic control replication in the Legion runtime
delivers the same programmer productivity as writing in other
implicitly parallel programming models, such as Dask or TensorFlow,
while providing better performance (11.4X and 14.9X respectively in
our experiments), and scalability to hundreds of nodes.  We also show
that dynamic control replication provides good absolute performance
and scaling for HPC applications, competitive in many cases with
explicitly parallel programming systems.


<a name="idx2021"></a>__Index Launches: Scalable, Flexible Representation of Parallel Task Groups__ [PDF]({{ "/pdfs/idx2021.pdf" | relative_url }}) <br/>
_Rupanshu Soi, Michael Bauer, Sean Treichler, Manolis Papadakis, Wonchan Lee, Patrick McCormick, Alex Aiken, and Elliott Slaughter_ <br/>
In the International Conference for High Performance Computing, Networking, Storage and Analysis ([SC 2021](https://sc21.supercomputing.org/presentation/?id=pap300&sess=sess176)) <br/>
__Abstract:__ It's common to see specialized language constructs in
modern task-based programming systems for reasoning about groups of
independent tasks intended for parallel execution.  However, most
systems use an ad-hoc representation that limits expressiveness and
often overfits for a given application domain.  We introduce *index
launches*, a scalable and flexible representation of a group of tasks.
Index launches use a flexible mechanism to indicate the data required
for a given task, allowing them to be used for a much broader set of
use cases while maintaining an efficient representation.  We present a
hybrid design for index launches, involving static and dynamic program
analyses, along with a characterization of how they're used in Legion
and Regent, and show how they generalize constructs found in other
task-based systems.  Finally, we present results of scaling
experiments which demonstrate that index launches are crucial for the
efficient distributed execution of several scientific codes in Regent.


<a name="distal2022"></a>__DISTAL: The Distributed Tensor Algebra Compiler__ [PDF]({{ "/pdfs/distal2022.pdf" | relative_url }}) <br/>
_Rohan Yadav, Alex Aiken and Fredrik Kjolstad_ <br/>
In the Conference on Programming Language Design and Implementation ([PLDI 2022](https://pldi22.sigplan.org/details/pldi-2022-pldi/12/DISTAL-The-Distributed-Tensor-Algebra-Compiler)) <br/>
__Abstract:__ We introduce DISTAL, a compiler for dense tensor algebra
that targets modern distributed and heterogeneous systems. DISTAL lets
users independently describe how tensors and computation map onto
target machines through separate format and scheduling languages. The
combination of choices for data and computation distribution creates a
large design space that includes many algorithms from both the past
(e.g., Cannon's algorithm) and the present (e.g., COSMA). DISTAL
compiles a tensor algebra domain specific language to a distributed
task-based runtime system and supports nodes with multi-core CPUs and
multiple GPUs. Code generated by is competitive with optimized codes
for matrix multiply on 256 nodes of the Lassen supercomputer and
outperforms existing systems by between 1.8x to 3.7x (with a 45.7x
outlier) on higher order tensor operations.


<a name="pawatm2022"></a>__Task Fusion in Distributed Runtimes__ [PDF]({{ "/pdfs/pawatm2022.pdf" | relative_url }}) <br/>
_Shiv Sundram, Wonchan Lee and Alex Aiken_ <br/>
In the Parallel Applications Workshop, Alternatives to MPI+X ([PAW-ATM 2022](https://sourceryinstitute.github.io/PAW/)) <br/>
__Abstract:__ We present distributed task fusion, a runtime
optimization for task-based runtimes operating on parallel and
heterogeneous systems. Distributed task fusion dynamically performs an
efficient buffering, analysis, and fusion of asynchronously-evaluated
distributed operations, reducing the overheads inherent to scheduling
distributed tasks in implicitly parallel frameworks and runtimes. We
identify the constraints under which distributed task fusion is
permissible and describe an implementation in Legate, a
domain-agnostic library for constructing portable and scalable
task-based libraries. We present performance results using cuNumeric,
a Legate library that enables scalable execution of NumPy pipelines on
parallel and heterogeneous systems. We realize speedups up to 1.5x
with task fusion enabled on up to 32 P100 GPUs, thus demonstrating
efficient execution of pipelines involving many successive finegrained
tasks. Finally, we discuss potential future work, including
complementary optimizations that could result in additional
performance improvements.


<a name="spdistal2022"></a>__SpDISTAL: Compiling Distributed Sparse Tensor Computations__ [PDF]({{ "/pdfs/spdistal2022.pdf" | relative_url }}) <br/>
_Rohan Yadav, Alex Aiken and Fredrik Kjolstad_ <br/>
In the International Conference for High Performance Computing, Networking, Storage and Analysis ([SC 2022](https://sc22.supercomputing.org/presentation/?id=pap204&sess=sess164)) <br/>
__Abstract:__ We introduce SpDISTAL, a compiler for sparse tensor
algebra that targets distributed systems. SpDISTAL combines separate
descriptions of tensor algebra expressions, sparse data structures,
data distribution, and computation distribution.  Thus, it enables
distributed execution of sparse tensor algebra expressions with a wide
variety of sparse data structures and data distributions. SpDISTAL is
implemented as a C++ library that targets a distributed task-based
runtime system and can generate code for nodes with both multi-core
CPUs and multiple GPUs.  SpDISTAL generates distributed code that
achieves performance competitive with hand-written distributed
functions for specific sparse tensor algebra expressions and that
outperforms general interpretation-based systems by one to two orders
of magnitude.

<a name="visibility2023"></a>__Visibility Algorithms for Dynamic Dependence Analysis and Distributed Coherence__ [PDF]({{ "/pdfs/visibility2023.pdf" | relative_url }}) <br/>
_Michael Bauer, Elliott Slaughter, Sean Treichler, Wonchan Lee, Michael Garland and Alex Aiken_ <br/>
In Principles and Practices of Parallel Programming ([PPoPP 2023](https://ppopp23.sigplan.org/details/PPoPP-2023-papers/17/Visibility-Algorithms-for-Dynamic-Dependence-Analysis-and-Distributed-Coherence)) <br/>
__Abstract:__ Implicitly parallel programming systems must solve 
the joint problems of dependence analysis and coherence to ensure 
apparently-sequential semantics for applications run on distributed 
memory machines. Solving these problems in the presence of data-dependent 
control flow and arbitrary aliasing is a challenge that most existing systems 
eschew by compromising the expressivity of their programming models and/or 
the performance of their implementations. We demonstrate a general class of 
solutions to these problems via a reduction to the visibility problem from 
computer graphics.


<a name="legate-sparse2023"></a>__Legate Sparse: Distributed Sparse Computing in Python__ [PDF]({{ "/pdfs/legate-sparse2023.pdf" | relative_url }}) <br/>
_Rohan Yadav, Wonchan Lee, Melih Elibol, Taylor Lee Patti, Manolis Papadakis, Michael Garland, Alex Aiken, Fredrik Kjolstad and Michael Bauer_ <br/>
To appear in the International Conference for High Performance Computing, Networking, Storage and Analysis (SC 2023) <br/>
__Abstract:__ The sparse module of the popular SciPy Python library is
widely used across applications in scientific computing, data analysis
and machine learning. The standard implementation of SciPy is
restricted to a single CPU and cannot take advantage of modern
distributed and accelerated computing resources. We introduce Legate
Sparse, a system that transparently distributes and accelerates
unmodified sparse matrix-based SciPy programs across clusters of CPUs
and GPUs, and composes with cuNumeric, a distributed NumPy
library. Legate Sparse uses a combination of static and dynamic
techniques to efficiently compose independently written sparse and
dense array programming libraries, providing a unified Python
interface for distributed sparse and dense array computations. We show
that Legate Sparse is competitive with single-GPU libraries like CuPy
and achieves 65% of the performance of PETSc on up to 1280 CPU cores
and 192 GPUs of the Summit supercomputer, while offering the
productivity benefits of idiomatic SciPy and NumPy.



## Theses

<a name="bauer_thesis"></a>*Note: The following thesis is a thorough guide to the Legion programming model and covers many implementation details that are not documented elsewhere.*<br/>
**Legion: Programming Distributed Heterogeneous Architectures with Logical Regions** [PDF]({{ "/pdfs/bauer_thesis.pdf" | relative_url }})<br/>
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
Asynchrony** [PDF]({{ "/pdfs/treichler_thesis.pdf" | relative_url }})<br/>
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

<a name="slaughter_thesis"></a>**Regent: A High-Productivity Programming Language for Implicit Parallelism with Logical Regions** [PDF]({{ "/pdfs/slaughter_thesis.pdf" | relative_url }})<br/>
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

<a name="lee_thesis"></a>**A Hybrid Approach to Automatic Program Parallelization via Efficient Tasking with Composable Data Partitioning** [PDF]({{ "/pdfs/lee_thesis.pdf" | relative_url }})<br/>
*Wonchan Lee*<br/>
December 2019<br/>
**Abstract:** Despite the decades of research, distributed programming
is still a painful task and programming systems designed to improve
productivity fall short in practice. Auto-parallelizing compilers
simplify distributed programming by parallelizing sequential programs
automatically for distributed execution. However, their applicability
is severely limited due to the fundamental undecidability of their
static analysis problem.  Runtime systems for implicit parallelism can
handle a broader class of programs via an expressive programming
model, but their runtime overhead often becomes a performance
bottleneck. To design a practical system for productive distributed
programming, one must combine the strengths of different
parallelization paradigms to overcome their weaknesses when used in
isolation.

This dissertation presents a hybrid approach to automatic program
parallelization, which combines an auto-parallelizing compiler with an
implicitly parallel tasking system. Our approach parallelizes programs
in two steps. First, the auto-parallelizer materializes data
parallelism in a program into task parallelism. Next, the tasking
system dynamically analyzes dependencies between tasks and executes
independent tasks in parallel. This two-stage process gives
programmers a second chance when the auto-parallelizer "fails": When a
part of a program is not amenable to the compiler
auto-parallelization, the programmer can gracefully fall back to the
runtime parallelization by writing that part directly with task
parallelism. Furthermore, hand-written tasks can be seamlessly
integrated with the auto-parallelized part via composable data
partitioning enabled by our auto-parallelizer, which allows them to
share the partitioning strategy and thereby avoid excessive
communication.

Key to the success of this hybrid approach is to minimize the overhead
of the tasking system. To achieve this goal, we introduce dynamic
tracing, a runtime mechanism for efficient tasking. The most expensive
component in the tasking system is dynamic dependence
analysis. Although this dynamic analysis is necessary when
applications exhibit true dynamic behavior, the analysis is redundant
for common cases where dependencies are (mostly) unchanging. Dynamic
tracing eliminates this redundancy in dynamic dependence analysis by
recording the dependence analysis of an execution trace and then
replaying the recording for the subsequent occurrences of the same
trace. To guarantee that a recording of a trace correctly replaces the
trace's original analysis, dynamic tracing also records memory
locations that hold valid data when it records a trace and replays the
recording only when those locations are still valid. Dynamic tracing
significantly improves the efficiency of tasking, and thereby brings
the strong scalability of explicit parallelism to implicit task
parallelism.

<a name="soi_thesis"></a>**Scaling Implicit Parallelism with Index Launches** [PDF]({{ "/pdfs/soi_thesis.pdf" | relative_url }})<br/>
*Rupanshu Soi*<br/>
December 2021<br/>
**Abstract:** Task-based programming systems are now widely used to
program modern supercomputers. Since these systems need to achieve
efficient scalable execution while being suitable for a wide variety
of application domains, their core abstraction, the task graph, needs
to have a scalable but expressive representation.

We present index launches, a technique, embedded in a general
task-based framework, to collapse a task graph to obtain a more
efficient representation. Leveraging a hybrid program analysis, we
show how a compiler can support index launches by providing safety
guarantees in virtually every case of practical importance.

In addition to the support for forall-style parallelism, we extend
index launches in two primary directions. First, we introduce cross
products, a novel abstraction for nested data partitioning, and
describe how to incorporate them in index launches. Second, to enable
index launches to represent limited forms of pipeline parallelism, we
present ordered launches, and develop the program analysis required
for an efficient implementation.

Our implementation of index launches is in Regent, a high-productivity
programming language for distributed computing. Using the Piz Daint
supercomputer, we evaluate the performance of several scientific
applications written in Regent, and show that index launches lead to
improved performance at the scales of contemporary and upcoming
high-performance machines.
