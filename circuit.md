---
layout: page
permalink: /tutorial/circuit.html
title: Circuit Simulation 
---
The first of our full program examples describes some
of the features used to implement the canonical
circuit example covered in many of our 
[publications](/publications/index.html). The source
code for this example can also be found in `examples/circuit`
directory of the Legion repository. The circuit example
simulates an arbitrary graph of integrated circuit
components. Components are represented by nodes, and wires
between components are represented as edges. Our implementation
partitions the circuit graph into components that are either
_private_ or _shared_ between circuit pieces. Further partitions
then refine the _private_, _shared_, and _ghost_ nodes for
each circuit piece. The following figure illustrates the
partitioning scheme for the node logical region tree.
<br/><br/>
![](/images/circuit_partition.svg)
<br/><br/>
An explicit iterative solver is then used to step through 
time and solve for the updated voltages and currents on 
each node and wire. The solver consists of three primary stages:

1. Calculate New Currents: examine the voltage differential
   across every wire and compute the new current flowing
   through the wire using an iterative method.
2. Distribute Charge: using the newly computed currents, 
   update the charge flowing into each node.
3. Update Voltages: based on the charge that has flowed into
   each node, compute the new voltage at each node. 

#### Reduction Privileges ####

One of the interesting features employed by the circuit 
simulation is reduction privileges. Reduction privileges 
allow the user to describe a very specific (but
common) computational paradigm to the runtime. In Legion,
reduction privileges are used to handle the scenario in
which tasks will apply values to a location using
a specific _reduction operation_, instead of needing to 
arbitrarily mutate locations in a logical region. We will 
give a mathematically precise definition of a reduction 
operation momentarily. In the next section we cover some 
of the optimizations supported by the Legion runtime 
for reductions.

A reduction operation in Legion is characterized by an _apply_ function 
which must be a pure function of the form `T1 -> T2 -> T1` 
where `T1` is the type of the field being reduced to and
`T2` is the type of the value being applied as a reduction.
One simple example of a reduction is a summation, where
both `T1` and `T2` are `double` values.  A more complex example
of a reduction might be inserting a particle into a cell where
`T1` is the type of the cell and `T2` is the type of the particle.
In addition to the apply function, reduction operations may also
support a second operation called a _fold_ which must be a pure
function of the type `T2 -> T2 -> T2` where `T2` is again the
type of the value being reduced. We describe how fold functions
are used by the runtime in the next section.
<br/>
Legion assumes that reduction operations are always _associative_
and _commutative_ in the mathematical sense. This means that
regardless of the order in which reductions are issued by tasks
the runtime is free to actually perform the apply operations in
any order. As we will see in the next section, this enables
the runtime to buffer reduction operations locally in a memory
visible to a task even though the ultimate destination of the
reductions might be in a remote memory.

In the circuit simulation, reduction operations are used in the
distribute charge phase to accumulate charge differences from
various incoming wires to each of the different nodes. Since
some wires into a node may come from different circuit pieces,
it is possible that multiple tasks will be applying reductions
to the same nodes. This illustrates an important aspect of
reductions: Legion reductions permit tasks applying reductions
to aliased regions to run in parallel. This is only possible
because the Legion runtime understands reductions are a special
operation with associative and commutative properties which can
be applied lazily.

Reduction operations in Legion must be implemented as a class
which contains very specific members. The following code block
shows the example accumulate charge reduction operation from
the circuit simulation.
{% highlight cpp linenos %}class AccumulateCharge {
public:
  typedef float LHS;
  typedef float RHS;
  static const float identity;

  template <bool EXCLUSIVE> static void apply(LHS &lhs, RHS rhs);

  template <bool EXCLUSIVE> static void fold(RHS &rhs1, RHS rhs2);
};
{% endhighlight %}
Every reduction operation must contain `typedef` declarations for
the `LHS` and `RHS` types representing the left-hand-side and 
right-hand-side functions of the reduction operation (e.g. `T1`
and `T2`). Furthermore, the reduction operation must specify an
static `apply` method. This function will be invoked by the
runtime whenever a value of the type `RHS` will be applied to
a value of `LHS`. The template parameter allows the runtime to
indicate whether or not parallel reductions might also be occurring
to the same `lhs` element simultaneously. This allows the application
to employ different operations depending on whether or not it has
`EXCLUSIVE` access to the `lhs` element. We use template specialization
to implement different versions of `apply` in the circuit simulation
as can be seen in the following code example: when we have exclusive
access we need only do a basic addition, but without exclusive access
we use an atomic compare-and-swap to perform the summation reduction.
{% highlight cpp linenos %}template <>
void AccumulateCharge::apply<true>(LHS &lhs, RHS rhs) 
{
  lhs += rhs;
}
{% endhighlight %}
In addition to the necessary reduction operation declarations, our
`AccumulateCharge` class also supports an optional `fold` function.
A fold function allows the runtime to combine two values of the 
`RHS` type into a single value. The `fold` operation allows the
runtime to support an optimized layout of data for reductions
which we describe in the next section. Supplying a `fold` function
also necessitates a declaration of an `identity` element which 
when folded with any other element returns the other element. In
the case of our `AccumulateCharge` class, the identity element is
simply zero.

Similar to tasks, reduction operations must be registered before
starting up the Legion runtime. Operations have their own space
of IDs which the application can use later for naming the reduction
operation to be performed when requesting reduction privileges.
Reduction operations are registered with the Legion runtime
using the static runtime method `register_reduction_op` which is
templated on the reduction operation class and takes as an
argument the ID to associate with the reduction operation.

#### Reduction Instances ####

While reduction operations can be directly applied to a normal
physical instances, Legion also supports the creation of a special
class of physical instances called reduction instances. Reduction 
instances enable reduction operations to be buffered up locally 
and then applied in bulk at a later point in time. This is especially
useful when the ultimate destination of reduction operations is
not visible to the processor performing the reductions. Consider
for example mapping our distribute charge computation from the 
circuit simulation onto a cluster of GPUs. In this case all the
reductions will ultimately need to be applied to a physical instance
residing in the globally visible GASNet memory. However, this memory
is not visible to individual GPU processors. Instead we create
reduction instances for the distribute charge tasks running on the
GPU. After the tasks finish executing, the reduction buffers are
then applied back to the instance containing all the shared nodes
residing in GASNet memory. An illustration depicting this scenario
within the circuit simulation is shown below.
<br/><br/>
![](/images/circuit_mapping.svg)
<br/><br/>
Legion supports the creation of two different kinds of reduction
instances. First, for basic reduction operations with no `fold`
function, Legion can create _reduction list_ instances. When
reductions are issued to the physical instance they are buffered
in a list which records the reduction operation, the destination
pointer, and the value to be reduced. Later when the reduction
instance is applied to a normal instance, these reductions are 
applied in order to the destination instance in bulk.

The second kind of reduction instance is called a _reduction fold_ 
instance and can only be used when the associated reduction
operation supports a `fold` function. Reduction fold instances
initialize a physical instance for the given logical region with
each location initialized with the identity value. As reductions
are applied to the physical instance they are folded into their
destination. In the case of the circuit simulation we create
reduction fold instances for each region requirement of every
distribute charge task. As charges are applied to individual
nodes they are folded into the destination buffer. After the
distribute charge tasks are complete, the fold reduction instances
are then applied back to the physical instance containing all
the shared nodes in GASNet memory.

For operations which support both `apply` and `fold` reduction
instances, the mapper has the option of selecting which kind of
instance to create by using the value of the `reduction_list`
flag in the `RegionRequirement` for the reduction when mapping
a task. Reduction list instances perform best when reductions are
sparse in the target logical region and the resulting list of 
reductions has fewer elements than the target logical region.
Alternatively, fold reduction instances perform best for dense
reductions where more than one reduction operation will be applied
to each location in the logical region. Locally folding reductions
saves space and allows reductions to be performed in parallel.
In our circuit simulation, since more than one reduction is applied
to each node we consider the reduction to be dense and opt for
using reduction fold instances.

#### A Legion Design Pattern ####

All languages and APIs have common conventions and design patterns
that are encouraged and Legion is no different. One common
design pattern in Legion is to employ C++ classes to scope 
Legion tasks. In this design pattern instances of the class will
describe launcher objects for launching tasks, while static
members functions will be used to give the many variant
implementations of the task. In our circuit example, each of
the three major tasks leverage this pattern by declaring
the `CalcNewCurrentsTask`, `DistributeChargeTask`, and
`UpdateVoltagesTask` classes.

The first step in implementing this pattern is to have each of
the classes extend the kind of launcher that will be used
to launch the variants of the task (in the circuit example,
the classes extend the `IndexLauncher` class since we perform
index space launches for the three major classes). The
implementation of the constructors for each of these tasks 
then fill in the `RegionRequirement` vectors for each task
launch. This explicitly co-locates in the description of the
logical regions and fields to be used by a task improving
code readability.<br/>
<br/>
For the implementation of each task, static member functions
are given for each kind of variant. For all three primary
tasks in our circuit example, we support both CPU and GPU
leaf task implementations. Note that all of these static
methods use the same naming and argument schemes. This allows
us to use generic templated functions to automatically 
register, launch, and provide wrapper code for each of the
different tasks. The `TaskHelper` namespace provides 
template functions for performing these duties for each
of the main tasks in the circuit simulation. The `dispatch_task`
function is used to launch tasks. The `register_cpu_variants`
and `register_hybrid_variants` are used to register either
the CPU-only or both CPU and GPU variants of tasks
respectively. Implementing all Legion tasks in this way
makes it possible to generalize task implementation,
thereby reducing the verbosity and the complexity of
Legion runtime code.

#### In-Situ Program Analysis ####

Due to the amount of data generated by many scientific
applications, it is often necessary for applications to 
analyze this data while in memory. One of the benefits of
using Legion is that this in-situ analysis can be done
simply by issuing additional tasks which read (and possibly
modify) existing logical regions which contain the
necessary data. For our circuit example, we have included
a very simple example of performing in-situ analysis:
checking for `NaN` (not-a-number) floating point values.

Our analysis is very simple, after each of the index space
task launch, we issue a second index space task launch of 
a checking task to verify that all the fields that were
written are free of `NaN` values. To do this we add a
`launch_check_fields` method to each of our task objects. 
This method is responsible for launching the checking task
for each kind of circuit simulation task. Since we use
the common `dispatch_task` template method for launching
all of our tasks, we simply modify this method to see
if we are performing the in-situ analysis, and if-so, 
call the `launch_check_fields` method on each launcher
object. Whether or not we perform the analysis is controlled
by the `-checks` command line flag.

The checking tasks are just like any other task to the
Legion runtime and it performs the necessary dependency
analysis to ensure that they check the correct data.
Since the checking tasks are just like any other task
they can be off-loaded onto unused processors. In this
case, all of the checking tasks only use `READ-ONLY`
privileges, which guarantees that the tasks are not on
the critical path. Note that we only have a CPU variant 
of the checking task. When running with GPU processors,
the processor mapping a checking task will indicate that
data needs to be placed in system memory (or zero-copy
memory). Legion will automatically issue the necessary
copies for creating physical instances on the CPU-side
with the correct data.

Overall this illustrates the flexibility of the Legion
runtime. In many applications, in-situ analysis must
be grafted on later, often adding considerable complexity
to the application. In Legion, in-situ analysis simply
requires launching additional tasks. Coming soon we
plan to add support for in-situ visualization tasks
that will leverage GPUs enabled for graphics to 
perform real-time visualization as the application is
executing.

#### Fast Accessors ####

While the `AccessorType::Generic` region accessor is general
purpose and works for all physical instances, it is very
slow. Most Legion applications are performance sensitive
and therefore need fast access to the data contained within
physical instances (by fast we mean as fast as C pointer
dereferences). To achieve this, we provide specialized
accessors for specific data layouts. These accessors are
templated so that significant amounts of constant folding
occurs at compile-time, resulting in memory accesses that
are effectively C pointer dereferences.

In advance we acknowledge that there are two downsides
to this approach. First, the use of C++ templates
adds significantly to the verbosity of leaf task code.
Second, programmers must anticipate all variants of
specialization that are to occur (dictated by the mapper)
and therefore must statically guarantee the instantiation
of all possible variants of tasks at compile-time. This
is clearly not ideal.

A solution to this problem is in progress. We are currently
in the process of incorporating the [Terra](https://terralang.org)
programming system into Legion. Terra is a companion to Lua
that enables Lua to be used as a meta-programming language
for generating Terra code which can be JIT-compiled to
fast x86 and PTX code. Ultimately, Legion applications will
register a Lua meta-programming generator for tasks. The
generator will be invoked by the Legion runtime for each
new combination of processor target and physical instance
layout to JIT a new task implementation. Consequently only
those combinations of processor-type and accessor kinds
that are needed will be generated. The latency of the JIT
process will be hidden like all other long-latency operations
in Legion via deferred execution. However, for the moment 
we are stuck with C++ templates.

In our circuit example, we show an example of using specialized
accessors in the `CalcNewCurrentsTask` which is the most
computationally expensive task. We add a `dense_calc_new_currents`
method to the class which will attempt to specialize all
of our region accessors into accessors for struct-of-arrays
physical instances. Note that it is possible that this
specialization fails in which case the `dense_calc_new_currents`
method returns `false` and we fall back to the slow version
of the task using generic accessors.

The accessor for struct-of-arrays physical instances is
`AccessorType::SOA`. This type is templated on the size of
the field being accessed in bytes. The template value
can also be instantiated with `0`, but this will cause
the accessor to fall back to using a dynamically computed
field size which will not be as fast C pointer dereferences
(but will always be correct). For each of our accessors,
we first call the `can_convert` method on the generic accessor
to confirm that we can convert to new accessor type. If
any of them fails, then we return `false`. If they all
succeed, then we can invoke `convert` method to get
specialized `SOA` accessors.

In addition to `SOA` accessors, there are several other
specialized accessors:

* `AOS` - array-of-struct accessors
* `HybridSOA` - for handling layouts that interleave
  multiple elements for different fields (still in
  progress, inspired by the [ISPC compiler](https://github.com/ispc/ispc/wiki/Better-in-language-support-for-aosoa-layout)
* `ReductionFold` - for reduction instances
  with an explicit fold operation
* `ReductionList` - for reduction instances
  without an explicit fold operation

Once we have converted all our accessors to `SOA` we
can then perform our kernel. Specialized accessors like `SOA` have
additional methods `ptr` and `ref` which enable applications
to get direct C pointers and C++ references to elements. Using
the `ptr` method we get pointers for the specific elements.
Since we know the elements for a field are laid out contiguously
in memory, we can use SSE vectorized loads and stores to move
data. It is is then a straight-forward
transformation to vectorize our kernel (note auto-vectorization
is much easier to do at runtime and will also be
supported by Lua-Terra for JIT-ing code for different
vector instruction sets). It is just as easy to write code
for AVX or FMA instruction extensions.

At this point, the observant reader will notice that we
have done nothing to actually specify that our
physical instances should be laid out in struct-of-arrays
order. To accomplish this we extend the `DefaultMapper`
with a custom `CircuitMapper`. In the `map_task` method,
we modify the mapping requests for each `RegionRequirement`
to specify that the `blocking_factor` should be set to
the `max_blocking_factor` allowed. This will tell the
runtime that a struct-of-arrays layout should be used.
If we had specified `1` for the blocking factor, that
would correspond to an `AOS` layout, and any value in
between would be a `HybridSOA` layout.

#### GPU Execution ####

The circuit example also illustrates how to execute tasks
on the GPU (see any of the `gpu_base_impl` methods on
the three major circuit tasks). In Legion GPU tasks 
actually begin running on a CPU thread. Legion guarantees 
that this CPU thread is already bound to a 
[CUDA device context](http://docs.nvidia.com/cuda/cuda-c-programming-guide/index.html#context) 
that is attached to the target GPU which was specified by the mapper
when the task was mapped. The physical regions for the
task are also already located in whatever GPU memory the
mapper requested (framebuffer or zero-copy) and are
visible within the device context. Therefore, 
the user simply needs to launch the corresponding GPU
kernel. Users are still responsible for selecting the
number of threadblocks and threads per threadblock
when launching their kernels.

Unlike normal CUDA applications, Legion CUDA tasks do
not need to synchronize with the GPU when they are done.
Instead, the Legion runtime automatically intercepts all 
the kernels launched during a task and defers their 
execution onto an internal CUDA stream; all kernels launched
in the same task will be run in order (no guarantees are made
about kernels from different tasks).  Legion will not
consider the task complete until all of the CUDA kernels 
launched during the task have finished. This allows the 
task to return without needing to synchronize with the GPU.
Legion tracks kernels by providing its own implementation of 
the CUDA runtime API declared in `cuda_runtime.h` (note the 
Legion runtime does not need to link against the CUDA runtime 
library `-lcudart`). Legion transparently captures all CUDA runtime 
API calls and translates them into the appropriate CUDA driver API 
calls while recording the necessary information to track when 
tasks have been completed. This approach allows Legion applications 
to be written using standard CUDA syntax and to have the CUDA 
compiler `nvcc` automatically target the Legion runtime.

By providing its own implementation of the CUDA runtime API
Legion controls the set of API calls that can be done inside
of Legion GPU tasks. In general, Legion GPU tasks should only
need to perform kernel launches with the standard `<<<...>>>`
launch syntax.  However, we do support several CUDA runtime
API calls for special cases.  Any attempt to use an API call
that we do not support will result in a link error.  <b>It is
imperative that all Legion GPU tasks use the CUDA runtime 
API</b>; use of the CUDA driver API will circumvent the ability 
of the Legion runtime to track GPU kernels launched in tasks 
and will result in undefined behavior.

In all of the GPU variants for each of the three
primary circuit simulation tasks, we create region
accessors just as before. We again create `SOA`
accessors for our physical instances (we assert if
we fail to convert right now). `SOA` accessors
guarantee that all global loads and stores in the
GPU kernels will be coalesced. The one exception is
in the `distribute_charge` task. The shared and ghost
charge regions are actually reduction-fold instances
so we create `ReductionFold` accessors for these two
regions. Since we know `ReductionFold` regions only
have a single field, we know that reductions to
these regions will also be coalesced. To perform
the reductions we use the `GPUAccumulateCharge`
class. This class serves the same functionality
as the `AccumulateCharge` task on the CPU side, but
instead uses CUDA `atomicAdd` intrinsics to perform
the reductions.

The GPU `update_voltages` task illustrates a pending
productivity issue in Legion. The `update_voltages`
kernel currently needs to look up the location of 
the node pointer to see if it is in the private
or the shared set of nodes. This can lead to
control divergence within the execution of the
GPU kernel (it is not a serious concern for
circuit as `update_voltages` is not performance
critical). Ideally, it would be nice to be
able to overlay the data for these two logical
regions on the same physical instance since
they share are common ancestor logical region.
We have several other use cases that could also
benefit for this optimization. If you develop
an application with similar characteristics
please alert us. The more demand there is for
it, the more quickly we will implement it.

