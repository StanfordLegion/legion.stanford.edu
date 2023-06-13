---
layout: page
permalink: /tutorial/ghost.html
title: Explicit Ghost Regions
---

In our [circuit simulation]({{ "/tutorial/circuit.html" | relative_url }}) and
our [stencil example]({{ "/tutorial/multiple.html" | relative_url }}) we
demonstrated how Legion allows for applications to 
describe ghost regions using multiple partitions. There
are both benefits and costs to describing ghost regions 
in this way. The primary benefit is the ease of
programmability of describing ghost regions as another
partition in an existing region tree. Consequently
an application only needs to enumerate a stream of
different sub-tasks using different regions, and
the Legion runtime will automatically determine 
the communication patterns based on region usage.

However, there is also a cost to writing applications
in this way. If the sub-tasks being launched are
very fine-grained, the overhead of having Legion dynamically
compute the communication pattern can become a
sequential bottleneck. For cases such as these,
as well as for cases where communication patterns
are fairly simple (e.g. nearest neighbors ghost
region exchange), it is often beneficial to 
structure applications with explicit ghost regions.
Fortunately, the abstractions presented in Legion
are sufficiently powerful to express these kinds
of applications.

The rest of this page walks through how to restructure 
the  [stencil example]({{ "/tutorial/multiple.html" | relative_url }}) in
a way that uses explicit ghost regions. The
code for this example can be found in 
the `examples/full_ghost/` directory in the
[Legion repository](https://github.com/StanfordLegion/legion).
We begin by describing the high-level approach
to writing our stencil computation. We then
describe the individual features necessary
for accomplishing this. Finally, we describe
how all of the features compose to build
our stencil application.

#### Algorithm Overview ####

In our original [stencil example]({{ "/tutorial/multiple.html" | relative_url }})
we relied on the top-level task to iterate through
multiple steps and launch sub-tasks for computing 
the stencil on each of the different
sub-logical regions. In our explicit ghost cell
stencil example, we will instead launch different
sub-tasks for computing each sub-region of our stencil
and allow these sub-tasks to iterate through the
loop independently. We will create explicit ghost
regions that will enable these independent tasks
to communicate while running in parallel. Another way 
to think about this is we are effectively emulating an 
[SPMD](http://en.wikipedia.org/wiki/SPMD)
programming model in Legion. However, unlike 
existing SPMD programming models like MPI and
GASNet, in this one, our programming system will
still be aware of how data is shared and 
communicated through logical regions.

#### Creating Explicit Ghost Regions ####

The first step in writing our stencil application
with explicit logical regions is the same as
for the original stencil application: we create
index trees and region trees. Our approach this
time will be slightly different. We begin by
creating an index tree that describes our entire
space of points called `is` in the code. We first
partition this index space into disjoint sub-spaces:
one for each sub-task that we plan to launch.
In the code, the resulting `IndexPartition` is
called `disjoint_ip`. We then iterate over each
of these sub-spaces and recursively partition
them into two more sub-spaces to describe the
left and right ghost spaces. It is important
to note at this point we have not created any
logical regions yet, but simply described the
decomposition of the index space of points. The
following image illustrate the resulting index
space tree.

![]({{ "/images/ghost_tree.svg" | relative_url }})

After setting up our index space tree, we now
create the explicit ghost regions from the leaf
index spaces of the tree. Note that we do 
not actually create the logical regions for 
the sub-spaces in `disjoint_ip` until each
of the sub-tasks are launched from the top-level
task. Each sub-task will create its own logical
region from its sub-space in `disjoint_ip`. The
explicit ghost logical regions are stored in 
the `ghost_left` and `ghost_right` vectors.
Having created our explicit ghost cell regions
we can now launch off sub-tasks for computing
stencils for each of our different sub-sets
of points. We have suggestively named these
sub-tasks `spmd_tasks`. Each `spmd_task`
instance requests `READ-WRITE` privileges on
both its left and right ghost regions
as well `READ-ONLY` privileges on the left and 
right ghost regions from its adjacent neighbors 
for a total of  four logical region requirements. 
This will allow each `spmd_task` to read and write
its ghost regions as well as to read its 
neighbor ghost regions. In Legion applications
that rely on `EXCLUSIVE` coherence, many of
these sub-tasks would have explicit data
dependences. However, we use a <em>relaxed coherence</em>
mode called `SIMULTANEOUS` coherence to 
allow these tasks to run in parallel. We
describe relaxed coherence modes next.

#### Relaxed Coherence Modes ####

When a task issues a stream of sub-task launches
to Legion, Legion goes about analyzing these
sub-tasks for data dependences based on their
region requirements in program order (e.g.
the order they were issued to the Legion
runtime). Normally, region requirements are
annotated with `EXCLUSIVE` coherence, which
tells Legion that if there is a dependence
between two tasks, it must be obeyed in
keeping with program order execution.

However, there are often cases where this
is too restrictive of a constraint. In
some applications, tasks might have a data
dependence, but only need 
[serializability](http://en.wikipedia.org/wiki/Serializability)
and not explicit program order execution. In
others, the application might not want Legion
to enforce any ordering, and instead will handle
its own synchronization to data in a common
logical region. To support these cases, Legion
provides two <em>relaxed</em> coherence modes: `ATOMIC`
and `SIMULTANEOUS`. `ATOMIC` coherence allows
Legion to re-order tasks as long as access to
a particular logical region is guaranteed to
be serializable. `SIMULTANEOUS` instructs
Legion to ignore any data dependences on
logical regions with the guarantee that the
application will manage access to the shared
logical regions using its own synchronization
primitives.

For our stencil application, we use `SIMULTANEOUS`
coherence to instruct Legion to ignore data 
dependences between tasks accessing the same
explicit ghost regions with the promise
that the application will coordinate synchronization
between them (which we describe momentarily). The 
use of `SIMULTANEOUS` coherence allows tasks to 
run in parallel despite data dependences. This is 
useful if there may need to be synchronization between 
our `spmd_task` instances, but in our case, we know 
for sure that there will need to be both communication
and synchronization. We therefore want a stronger
guarantee that our sub-tasks will run
in parallel. We describe how we accomplish
this in the next section.

#### Must Parallelism Launchers ####

When using relaxed coherence modes, in some
cases applications may simply be executing
under <em>may-parallelism</em> conditions
where it is acceptable for tasks to run
in parallel, but with no expectations that
tasks be able to synchronize. In other cases,
tasks might be in a <em>must-parallelism</em>
scenario, where they must run in parallel
and be capable of synchronizing in order to
avoid hanging. Our stencil application is one
example of a must-parallelism application since
we know that we are going to need to explicitly
exchange data between the different ghost regions
of our `spmd_task` instances.  Under these conditions 
it is imperative that the application be able
to express the requirement that tasks execute
in parallel and synchronize with each other.
Legion provides a special kind of task launcher 
called a `MustEpochLauncher` that make this possible.

A `MustEpochLauncher` is actually a <em>meta-launcher</em>
that simply contains other launcher objects. The
idea is that instead of launching a bunch of tasks
to the Legion runtime separately and hoping they run
in parallel, applications can gather up a bunch of
tasks (either a collection of individual tasks or
one or more index tasks) inside of a `MustEpochLauncher`
and then issue them as a single launch to the
Legion runtime. The Legion runtime is then aware
that all the tasks must be capable of executing
in parallel and synchronizing with each other.
Legion will first check that all of the region
requirements for this set of tasks are non-interfering
and therefore capable of running in parallel.
Legion will also check any mapping decisions which might
impact the ability of the tasks to run in parallel.
For example, if two tasks in a must-parallelism
epoch are mapped onto the same processor they will
not be able to run in parallel and potentially
synchronize with each other. To help avoid this
case, Legion provides an explicit mapping call
for mapping must-parallelism epochs `map_must_epoch`
which we describe later. If there are any mapping
decisions which would prevent the must-parallelism
epoch, Legion issues a runtime error (as opposed
to silently hanging).

Our stencil application creates a `MustEpochLauncher`
and inserts a single `TaskLauncher` for each of
the `spmd_task` instances we want to create.
Since all of our region requirements ask for 
`SIMULTANEOUS` coherence, we know that there will
be no dependences on logical regions. Furthermore,
we rely on the implementation of `map_must_epoch`
in the default mapper to ensure that the mapping
decisions that are made will not prevent our
`spmd_task` instances from running in parallel.

#### Explicit Copy Operations ####

After our `spmd_task` instances begin running
in parallel, they start issuing sub-operations
for computing the stencil computation (note
we have them iterate over these operations several
times in order to illustrate how applications
might iterate through time steps in a simulation).
Each `spmd_task` instance first  launches a sub-task 
for initializing the data over which the stencil will 
be computed. After the data has been initialized, 
the `spmd_task` instances then need to exchange 
ghost cell data so that they can run the stencil 
sub-task. To exchange data through explicit ghost 
regions we use Legion's explicit region-to-region
copy operation.

`CopyLauncher` objects are used to perform an
explicit copy of data between two different logical
regions. The only requirement of the two logical
regions is that they share a common index space 
tree. (Note this is why we created all of our
explicit ghost logical regions from the same 
index space tree.) Just like all other operations
in Legion, `CopyLauncher` objects use region
requirements to name the logical regions that
they will be copying between. Legion performs
the necessary dependence analysis and will
perform the copy when it is safe to do so.
Copy operations have their own `map_copy` 
call which is invoked in order to determine
where the source and destination region
requirements are mapped.

In the case of the stencil computation, we
use explicit copies to copy data from our
local logical region `local_lr` which 
contains all of our data to our left
and right neighbor explicit ghost regions.
This will allow our neighbor `spmd_task`
instances to see the necessary ghost cell
data for performing their stencils. At
the same time our neighbors will be
doing the same operation so we will be
able to observe their ghost cell data in
our explicit ghost regions. The next
obvious question is then how to know
when it is safe to consume the data
in our explicit ghost regions. We next
describe how we perform synchronization 
between `spmd_task` instances in the
next section.

#### Phase Barriers ####

When using `SIMULTANEOUS` coherence it is 
up to the application to properly synchronize
access to a logical region. While applications
are free to construct their own synchronization
primitives, Legion also provides two useful
synchronization primitives: <em>reservations</em>
and <em>phase barriers</em>. Reservations provide
an atomic synchronization primitive similar
to locks, but capable of operating in a deferred
execution environment. Phase barriers provide
a producer-consumer synchronization mechanism
that allow a set of producer operations to
notify a set of consumer operations when data
is ready. While both of these operations can
be used directly, the common convention in 
Legion programs is to specify on launcher
objects which reservations should be acquired/released
and which phase barriers need to be waited on
or triggered before and after an operation is
executed. We now cover the use of phase barriers
in more detail since they are used in our stencil
application.

First, it is <em>very</em> important to realize
that phase barriers are in no way related to traditional
barriers in SPMD programming models such as MPI.
Instead, phase barriers are a very light-weight
producer-consumer synchronization mechanism. In
some ways they are similar to [phasers](https://www.cs.rice.edu/~vs3/PDF/SPSS08-phasers.pdf) <!-- https://doi.org/10.1145/1375527.1375568 --> in
X10 and [named barriers](http://docs.nvidia.com/cuda/parallel-thread-execution/index.html#parallel-synchronization-and-communication-instructions-bar) 
in GPU computing. Phase barriers allow a dynamic
number of consumers (possibly from different tasks)
to be registered. Once all of these producers have
finished running the <em>generation</em> of the 
barrier will be advanced. Consumers of the phase
barrier wait on a particular generation. Only
once the generation has been reached will the
consumers be allowed to execute.

When a phase barrier is created, it must be told 
how many possible tasks will be registering producers 
and/or consumers with it, but the exact number of 
producers and producers can be dynamically determined. 
The number of tasks which may be registering producers 
or consumers is called the <em>participants</em> count. 
When it is executing, each participant task can launch
as sub-operations which either arrive or wait on a 
specific phase barrier as it wants. Once it is done
launching sub-operations that use a specific generation
of the phase barrier, it then calls `advance_phase_barrier`
to get the name of the phase barrier corresponding
to the next generation. Phase barriers remain valid 
indefinitely (or until they exhaust the maximum number
of generations, usually 2^32) unless they are explicitly 
deleted by the application.

For our stencil computation, we create two phase
barriers for every explicit ghost region that we
created. The reason for needing two is that we will
need one for each `spmd_task` to be able to indicate when
its copy has been completed, and we need one for
allowing a consuming `spmd_task` to indicate it has
consumed the data in the explicit ghost region and
is ready for the next pass. We refer to these
two barriers as the `ready` and `empty` barriers
in the stencil code. We create all the necessary
phase barriers in the top-level task, and then pass
in the necessary phase barriers to each sub-task.

#### Acquire and Release Operations ####

The last feature that we need deals with how
Legion manages regions which have been mapped
with `SIMULTANEOUS` coherence. Since these
physical instances are likely being accessed
by multiple different tasks, it is unsound
for Legion to allow sub-operations within
these tasks to create other copies of the
logical region in the memory hierarchy. (We
note that Legion expresses this restriction
by setting the `restricted` field in a
`RegionRequirement` to `true` when invoking
`map_task` or other related mapper calls.)
Instead, if the application would like to
make copies of the logical region locally
within a task context, it must first issue
an <em>acquire</em> operation on the logical
region. This tells Legion that the application
is promising that it has properly synchronized
access to the logical region and it is safe
to make copies. When the application is done
launching sub-operations that may make copies
it issues a <em>release</em> operation which
then invalidates all the existing copies
and makes the previous physical instance
again the only valid copy of the data (flushing
back any dirty data in the other instances
as well). In some ways acquire and release
operations are related to 
[release consistency](http://en.wikipedia.org/wiki/Release_consistency),
but in many ways Legion is more flexible as Legion
allows anyone to operate on any logical region
consistent with its privileges at any time and
acquire and release only apply to when the Legion
runtime is permitted to make copy physical instances
of a logical region.

Acquire and release operations are the same
as other operations in Legion and are issued
using `AcquireLauncher` and `ReleaseLauncher`
objects. Instead of naming region requirements,
acquire and release operations need only name
the logical region and fields they are acquiring
and releasing. These operations also need to provide
the name of the original `PhysicalRegion` that the
parent task mapped using `SIMULTANEOUS` coherence.
Note that like other Legion operations, acquire
and release are issued asynchronously and simply
become part of the operation stream. This allows
applications to issue other operations unrelated
to the acquire and release operations and Legion
will automatically figure out where dependences
exist.

For our stencil computation, we surround our 
stencil task launch with acquire and release
operations for both of our explicit ghost cell regions. 
This allows our stencil task to be mapped 
anywhere in the machine and for
copies of our explicit ghost cell regions to
be made for the stencil task to use. The
release operation after then stencil task then
invalidate these copies, restoring the original
instance mapped by the `spmd_task` to be only
valid copy of the data. This ensures that when
the next copy copies from adjacent `spmd_task`
instances that we will see the correct version
of the data in our explicit ghost regions.

#### Putting Everything Together ####

Having described all of the features of our
explicit ghost region version of the stencil
computation, the following picture illustrates
how the stencil computation works between
a pair of `spmd_task` instances.

![]({{ "/images/phase_barrier.svg" | relative_url }})

Each of `spmd_task` instances performs several
iterations of the stencil computation. Each
iteration issues a copy to exchange ghost
cell data with its neighbor. Each copy will
arrive at a phase barrier once the copy is
complete indicating that the data is ready
to be consumed. Each `spmd_task` also issues
acquire operation which wait for the copy
operation phase barrier to trigger before
being ready. The acquire operations enable 
copies of the explicit ghost cell regions to
be made anywhere in the machine, potentially
allowing the stencil task to be executing on
a GPU. Finally a release operation is issued
that will run once the stencil task is 
completed. Each release operation then arrives
at the other phase barrier for an explicit
ghost region indicating that the ghost region
is empty and ready to be filled again by the
neighboring `spmd_task`. Note that by using
explicit ghost regions with phase barriers
and explicit acquire/release operations, each
of the `spmd_task` instances can run in
parallel and perform sub-operation launches
in parallel, leveraging Legion's ability
to do independent analysis on sub-tasks.

#### Discussion ####

One obvious question that might be raised
about this example is whether it is 
overly complex. When considering the alternative
we believe that this example is actually
relatively simple. If we attempted to do this
in MPI, we would need to post asynchronous
sends and receives and interleaving them with
explicit `cudaMemcpy` operations to move data
back and forth between the GPU. In our Legion
version all communication is encoded in the
same logical region framework, and no explicit
mapping decisions are baked into the code
making our version both portable and easily
tunable. We believe this example further illustrates
the ability of logical regions to abstract
data usage and movement.

The remaining two sections describe briefly 
some of the details and potential extensions
to this example.

#### Mapper Interactions ####

While not included in the code for this example,
there are several important details regarding the
mapping of this example that the `DefaultMapper`
implements. First, the default mapper implements
the `map_must_epoch` mapper call, which is
similar to the `map_task` call except it is
given a set of tasks that all need to be mapped.
It is also given a collection of constraints which
specify which logical regions in different tasks
must be mapped to the same physical instance
in order for tasks to be capable of running in
parallel. (`SIMULTANEOUS` coherence only allows
tasks to run in parallel if they use the same
physical instance, otherwise the resulting
behavior would be undefined.  The same is true
of `ATOMIC` coherence.) The default mapper then
knows that each of the different tasks must be
mapped onto a different target processor, and 
all of the logical regions with constraints should
be assigned the same memory ranking. If for
any reason these conditions are violated, the
Legion runtime will detect that the tasks cannot
run in parallel and therefore will issue a runtime
error instead of allowing the application to 
silently hang.

The default mapper also checks the `restricted`
flag on all region requirements in order to see
if the current physical instance is the only
one which the mapper will be permitted to map.
In these cases there is always exactly one 
instance in the `current_instances` map which
indicates which memory should be selected for
the mapping. Failure to use this memory will 
result in a failed mapping.

Finally, it is normally expected that tasks
will request accessors to all physical instances
that they map and therefore these physical instances
must be visible from the processor on which the
task is going to run. In the case of our explicit
ghost region code, this is not always the case.
Each of `spmd_task` instances map the adjacent
ghost cell regions with no intention of accessing
them using accessors, but instead only with the
intention of doing explicit region to region copies.
To prevent the runtime from throwing an error
because of this, we annotate the region requirements
for these regions with the `NO_ACCESS_FLAG` in
order to indicate that the tasks will not be
making accessors for these logical regions.

#### Hiding More Latency: Double Buffering ####

Lastly, we note here the true potential of explicit
logical regions. While this example only illustrates
single buffering, applications are 
free to create multiple explicit ghost logical regions
as well as additional phase barriers in order to implement 
[multiple buffering](http://en.wikipedia.org/wiki/Multiple_buffering).
Using multiple buffering applications can hide even more
communication latency by allowing Legion to execute even
further into the future. We have yet to explore the
full potential of this technique but we believe that it
could make a considerable difference for many applications.

