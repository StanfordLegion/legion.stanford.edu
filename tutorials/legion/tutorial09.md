---
layout: page
permalink: /tutorial/custom_mappers.html
title: Custom Mappers
---

One of the primary goals of Legion is to
make it easy to remap applications onto
different architectures. Up to this point
all of our applications have been mapped
by the `DefaultMapper` implementation that
is distributed with Legion. The `DefaultMapper`
class provides heuristics for performing mappings
that are good, but regularly not optimal for
specific applications or architectures. By
creating custom mappers programmers can make
application- or architecture-specific mapping
decisions. Furthermore, the mapping interface
isolates mapping decisions from application
code, allowing the same Legion applications
to be targeted at different architectures without
having to modify the application source code.

A common problem encountered when writing code
for large distributed and heterogeneous machines
is how mapping impacts correctness. In Legion, any valid set of
mapping decisions will result in the same answer being computed, and
therefore, if an application produces the correct answer on one
machine, it will produce the same answer regardless of the machine or
mapping strategy used. Mapping can therefore be considered orthogonal
to the correct execution of the program.

To introduce how to write a custom mapper we'll
implement two custom mappers. The first will be
an adversarial mapper that makes random mapping
decisions designed to stress-test the Legion runtime.
We'll also have the adversarial mapper report the chosen
mapping decisions (which will change with each run
of the application) to further emphasize the orthogonality
of mapping decisions from correctness. The second mapper
that we'll create will be used for partitioning to decide
how many sub-regions to create using _tunable_
variables. The application code for DAXPY is
identical to the code from
an [earlier example]({{ "/tutorial/partitioning.html" | relative_url }})
and is therefore omitted. We only show the new
code required for creating and implementing the
custom mappers.

#### Mapper Objects and Registration ####

Mappers are classes that implement the interface
declared in the abstract class `Mapper`. Legion provides a default
implementation of this interface defined by the
`DefaultMapper` class. The default mapper allows
applications to be developed without being
concerned with mapping decisions. Once correctness
has been established, programmers can implement
custom mappers to achieve higher performance.
Custom mappers can either extend the `DefaultMapper`
class or implement the `Mapper` interface from
scratch. In this example, we extend the
`DefaultMapper` to create both our `AdversarialMapper`
(line 20) and `PartitioningMapper` (line 41). We then override
four of the mapping interface calls in the `AdversarialMapper`
(lines 25-38) and one in the `PartitioningMapper` (lines 46-49)
to show how they work. We'll describe the semantics of these calls and our implementations
of them in the coming sections.

Mappers objects are instantiated after the
Legion runtime starts but before the application
begins executing. To instantiate mappers, the application
registers a callback function for the runtime to
invoke prior to beginning execution of the application. In this
example we create the `mapper_registration`
function (lines 52-62) and register the function
with runtime using the static method `add_registration_callback`
of `Runtime` (line 469). All callback
functions must have the same type as the `mapper_registration`
function so that the runtime can pass the
necessary parameters for creating new mappers.

In Legion, each kind of
mapper is identified by a `MapperID` (an unsigned integer).
There should be one instance of each kind of mapper
for every processor in the system. Having a single
instance for each processor guarantees that processors
can map tasks in parallel without needing to be
concerned about contention for a single mapper object. Note that in
general, mappers are permitted to be stateful, and users of the
mapping API can choose what state to track and how to manage that
state.

When `mapper_registration` callback function is invoked, it can
instantiate an arbitrary number of mappers and kinds of mappers.
For each kind, it should create one instance for
every processor in the set `local_procs` which
describes the set of processors on the local node. Note that in a
multi-node execution of Legion, this callback will be issued once on
every node in the system. The `MapperID` 0 is reserved for
the `DefaultMapper`, but applications can replace the default with their own mapper
by calling `replace_default_mapper` (lines 57-58). By replacing the default mapper, any tasks in the application will
automatically use the new `AdversarialMapper`. We register `PartitioningMapper` with
the `add_mapper` method and assign it a non-zero ID
`PARTITIONING_MAPPER_ID`. We'll show how to use
mapper IDs to determine which mapper is invoked
momentarily. Finally, notice that we iterate over
all the processors in the set of `local_procs`
to create a distinct instances of both `AdversarialMapper`
and `PartitioningMapper` for each processor (lines 57-60).

#### Legion Machine Model ####

In order to target a specific architecture, mappers need
access to a description of the underlying hardware.
Legion provides a static singleton `Machine` object
that can be used to make queries concerning the
underlying hardware. We show how to make some of these
queries as part of the constructor for our `AdversarialMapper`
object (lines 64-218).

The `Machine` object is passed as part
of the arguments to any mapper constructor, but it
can also always be obtained by calling the static method
`Machine::get_machine` from anywhere in the
application. In our constructor
we begin by obtaining the set of
all the processors in the machine (line 69). The
`Processor` objects are simply light-weight handles
that name the various processors (CPUs, GPUs, etc.) in the
machine. Generally speaking, the number and kind of processors
available in the Legion runtime are configured by passsing
command-line flags such as `-ll:cpu <C>` and `-ll:gpu <G>` (which
would create `C` CPU and `G` GPU processors). Note that certain flags
are only available when the appropriate module has been compiled into
Legion (e.g. the use of GPUs depends on `USE_CUDA` at
compile-time). More details on the available flags can be found at the
[machine configuration
page](/profiling/index.html#machine-configuration).

For illustration, we print the list of processors and memories for our
machine (lines 71-201). Note that in order to avoid seeing multiple
copies of this output, we only run this code on the first mapper (line
70). Recall a separate instance of the `AdversarialMapper`
will be made for every processor. We then
iterate over the set of all processors and print out
their ID and type (lines 75-104). Most objects
obtained from the `Machine` object have an associated
`id` field that can uniquely identify them (the special constant
`IDFMT` contains the appropriate format code for printing an ID).
There are a variety of processor types supported
by the Legion runtime: latency-optimized processors
(`LOC_PROC`) are CPU processors, throughput-optimized
processors (`TOC_PROC`) are GPUs, and utility processors
are special CPU processors used for performing Legion runtime
tasks. Legion also supports special-purpose processors for I/O,
OpenMP, and Python (not shown in this tutorial).

We then print the list of memories (lines 113-201).
Note that memory sizes are controlled by command-line
flags as well and may not accurately reflect the actual
underlying hardware. Again, the list of supported flags can be found
on the [machine configuration
page](/profiling/index.html#machine-configuration).

A useful way to think about the Legion machine model is that the
machine is a graph between processors and memories. Processors and
memories can have different affinities that describe the relative
speeds at which the various processors can access the available
memories. A processor can only access the contents of memories for
which it has an affinity. And similar, edges between memories describe
the paths along which data can be copied around the system. Note that
the exact affinity values are only approximations and do not reflect
the actual transfer bandwidth of the machine.

Line 205 uses
the `get_visible_memories` method to obtain the
set of memories that are visible from the local processor.
We then print out the affinities between the local
processor and each of these memories using the
`get_proc_mem_affinity` method (line 212).

#### Selecting Task Options ####

The first mapper call that we override is the
`select_task_options` call (lines 220-228). This
mapper call is performed on every task launch
immediately after it is made, and is used to configure certain
important aspects of task execution that the runtime needs to know up
front.

In general, mapper calls in Legion use a well-defined set of inputs
and outputs. The inputs are provided by one or more `const`
references, while the output is provided in a single non-`const`
reference struct. In this way, it is possible to determine what fields
a mapper is expected to set simply by looking at the signature of the
mapper call.

In the case of the `select_task_options` call, the following output
fields are provided to the mapper:

  * `inline_task` determines whether the child task should be executed
    directly in the parent tasks's context, using the parent task's
    physical regions. (This is option is usually left to `false` as it
    is desirable for the child to execute asynchronously with the
    parent.)
  * `stealable` is used for work-stealing load balancing and controls
    whether the task is available to be stolen by another 
  * `map_locally` determines whether subsequent mapper calls (such as
    `map_task`) should be processed by the current mapper, or the
    mapper for the processor to which the task is to be assigned.
  * `initial_proc` is used to send the task to be mapped on another
    processor. Note that the task may not necessarily execute on
    `initial_proc`, since the mapper can still use the `map_task` call
    to send it to a different final destination.

For our adversarial mapper, to demonstrate that Legion can handle any
possible mapping strategy, we just choose a random processor for the
`initial_proc`. We use two `DefaultMapper` utility methods,
`select_random_processor` and `select_random_processor_kind` to do
this (lines 226-227).

#### Slicing Index Task Spaces ####

The second call that we override is the `slice_task`
method (lines 230-277). The `slice_task` method is used to determine
how to distribute the tasks within an index space launch around the

machine. The mapper is given as input a set of slices (which initially
contains a single element representing the entire launch), and is
expected to produce as output a set of slices. In this case, since we
are attempting to stress the runtime, we create a slice for each point
task and assign it to another processor. In more typical usage, the
slices would be chosen to maximize locality in the application.

The `slice_task` method can optionally be called recursively until the
index space launch has been decomposed down to slices of the desired
size. In this case we disable this feature and only perform one level
of slicing.

#### Task Mapping ####

The next mapping call, `map_task` (lines 279-338) is one of the most
important methods. The call has a number of responsibilities:

  * Select the final (set of) processor(s) that the task will be executed on.
  * Select the variant of the task to execute.
  * Select the physical instances to hold the data for each logical region.
  * Optionally select the task priority.
  * Optionally select profiling information to collect.

On line 298, we select the final processor that the task will execute
on. In this case, we simply keep the processor that was chosen by
`select_task_options`, which is stored in the `task.target_proc`
field. Note that `output.target_procs` is a set and if multiple
processors, task will be load balanced between the selected
processors. It is a common pattern to select all of the processors on
the local node that have the appropriate type. For the adversarial
example, we only choose a single processor.

In general, a task can have multiple variants (e.g. for CPU or GPU, or
for a CPU that supports AVX instructions, or that assumes a specific
memory layout for its physical instances). Lines 283-297 select the
task variant to execute. It is important to choose a variant that is
capable of executing on the selected kind of processor. First we find
the list of available variants (lines 283-284). Then we filter this
down to those that are compatible with the kind of processor we intend
to map on (lines 286-290). Finally, since this is an adversarial
example, we select a random variant from among the valid choices. A
more typical example might use application-specific knowledge to
choose the appropriate variant to use.

Having chosen the target processor and variant, we map all the logical
regions of the task to specific physical instances (lines
299-337).

Note in certain cases, regions may already be mapped. Such regions are
said to be _premapped_. We find a list of such regions on lines
299-304; we'll just skip them in the code below.

Certain variants of tasks may assume that the data has a specific
layout. In order to ensure that the mapping is correct for the given
variant, we use `find_task_layout_constraints` to look up the _layout
constraints_ for the given variant (lines 305-307). Layout constraints
describe the layout that the variant expects to receive.

Legion is very flexible with respect to data layout and provide the
data in C or Fortran array order, in array-of-structs (AOS) or
struct-of-arrays (SOA), or in arbitrary hybrid combinations of those
layouts. Legion will transpose the data as necessary to ensure that it
always provided in the correct layout. The mapper is simply
responsible for choosing the layout that it wants for the data.

To simplify the process of choosing an appropriate layout, we use two
helper methods `map_constrained_requirement` (lines 322-323) and
`map_random_requirement` (lines 326-328) that handle the cases where
the variant specifies constraints on the layout, or leaves the layout
unconstrained, respectively. In an application-specific mapper, the
mapper might have more knowledge of the desired layout and might
include additional code here to choose a specific data layout for the
task.

Note that there are two special cases. First, as noted above, if a
task is premapped we need not (and cannot) map it (lines
309-310). Second, if the instance is _restricted_ then we know a valid
instance already exists and we can simply use this (lines
311-314). Restricted instances occur primarily as a result of
simultaneous coherence, which is an advanced feature of Legion that is
not commonly used. Since this adversarial mapper is striving to be
general-purpose, we must handle all these cases, but an
application-specific mapper could potentially skip them.

On line 330 we assign the task with a random prioritiy. In more
typical usage, the mapper would assign higher priority to tasks along
the critical path of the application, to ensure that those tasks
execute as soon as they are ready.

Finally, `map_task` can request various profiling information about a
task, such as the status (success or failure) of a task, the execution
time, and the overhead incurred (lines 332-337). These results are
then passed back to the mapper via the `report_profiling` callback
once the task completed.

#### Reporting Results ####

The last mapper call that we override for our `AdversarialMapper` is
the `report_profiling` method (lines 340-410). This method prints out
the profiling information obtained from the task execution that was
requested in `map_task`.

#### Handling Tunable Variables ####

When writing tasks, there are often many cases where
variables depend on the underlying nature of the
machine. In Legion we refer to these variables as
_tunable_ because they often need
to be specifically tuned for different architectures.
Since these variables are machine dependent and likely
to affect performance, we prefer to make these variables
explicit. To do this we provide a separate mapping call
`select_tunable_value` to explicitly request that the
mapper pick the value for this variable. We override
this call in our `PartitioningMapper` on lines 410-430.

We make a slight modification to our DAXPY code to
make the number of sub-regions to create a tunable
variable so that the mapper can pick a value based
on the number of processors on the target machine. Note that the
`top_level_task` explicitly invokes the `select_tunable_value`
to find the number of sub-regions to create. (Instead of showing the
full example again, we show only the relevant snippet below.) When
this call is made, we
pass the `PARTITIONING_MAPPER_ID` as the value to the
`MapperID` field, indicating that an instance of
our `PartitioningMapper` should be used to handle
the request and not an instance of the `AdversarialMapper`.
When we make the call we also pass in a `TunableID`
which is used to identify the name of the tunable
variable that should be set. The `TunableID`
can be arbitrary, so long as the mapper that it
is being sent to knows what to do with it. In
this case we pass `SUBREGION_TUNABLE` as the
integer name for tunable variable. The `PartitioningMapper`
instance looks up the total number of processors
in the machine and returns that as the number
of sub-regions to create.

{% highlight cpp %}
int num_subregions =
        runtime->get_tunable_value(ctx, SUBREGION_TUNABLE,
                                   PARTITIONING_MAPPER_ID).get_result<size_t>();
{% endhighlight %}

Tunable variables are returned as a future, so if the application code
needs to use the result it must call `get_result<T>` to get the value.

#### What Next? ####

Congratulations! You've reached the end of the
Legion tutorial as it currently exists. There
are many features already implemented in Legion
which are not covered by this tutorial including:

  * reduction operations, reduction privileges,
    and reduction instances
  * special accessors to obtain raw pointers and strides from physical instances
  * runtime debugging modes and flags
  * runtime performance tuning knobs
  * unmapping and remapping optimizations
  * explicit cross-region copy operations
  * additional mapping calls and settings
  * close operations and composite instances (pending)
  * profiling and debugging tools
  * relaxed coherence modes
  * acquire and release operations for simultaneous coherence
  * reservations and phase barriers for synchronization
    in a deferred execution model
  * predicated operations
  * support for speculative execution (in progress)
  * inner and idempotent tasks
  * efficient data-centric resiliency and recovery (in progress)

If you are interested in learning more about how to
use these features of Legion or you have questions
regarding how to use them, please post to the
[mailing list](http://legion.stanford.edu/resources).

Previous Example: [Multiple Partitions]({{ "/tutorial/multiple.html" | relative_url }})

{% highlight cpp linenos %}
#include <cstdio>
#include <cassert>
#include <cstdlib>
#include "legion.h"

#include "test_mapper.h"
#include "default_mapper.h"

using namespace Legion;
using namespace Legion::Mapping;

enum {
  SUBREGION_TUNABLE,
};

enum {
  PARTITIONING_MAPPER_ID = 1,
};

class AdversarialMapper : public TestMapper {
public:
  AdversarialMapper(Machine machine,
      Runtime *rt, Processor local);
public:
  virtual void select_task_options(const MapperContext    ctx,
				   const Task&            task,
				         TaskOptions&     output);
  virtual void slice_task(const MapperContext ctx,
                          const Task& task,
                          const SliceTaskInput& input,
                                SliceTaskOutput& output);
  virtual void map_task(const MapperContext ctx,
                        const Task& task,
                        const MapTaskInput& input,
                              MapTaskOutput& output);
  virtual void report_profiling(const MapperContext      ctx,
				const Task&              task,
				const TaskProfilingInfo& input);
};

class PartitioningMapper : public DefaultMapper {
public:
  PartitioningMapper(Machine machine,
      Runtime *rt, Processor local);
public:
  virtual void select_tunable_value(const MapperContext ctx,
                                    const Task& task,
                                    const SelectTunableInput& input,
                                          SelectTunableOutput& output);
};

void mapper_registration(Machine machine, Runtime *rt,
                          const std::set<Processor> &local_procs) {
  for (std::set<Processor>::const_iterator it = local_procs.begin();
        it != local_procs.end(); it++)
  {
    rt->replace_default_mapper(
        new AdversarialMapper(machine, rt, *it), *it);
    rt->add_mapper(PARTITIONING_MAPPER_ID,
        new PartitioningMapper(machine, rt, *it), *it);
  }
}

AdversarialMapper::AdversarialMapper(Machine m,
                                     Runtime *rt, Processor p)
  : TestMapper(rt->get_mapper_runtime(), m, p)
{
  std::set<Processor> all_procs;
  machine.get_all_processors(all_procs);
  if (all_procs.begin()->id + 1 == local_proc.id) {
    printf("There are %zd processors:\n", all_procs.size());
    for (std::set<Processor>::const_iterator it = all_procs.begin();
          it != all_procs.end(); it++) {
      Processor::Kind kind = it->kind();
      switch (kind) {
        // Latency-optimized cores (LOCs) are CPUs
        case Processor::LOC_PROC:
          {
            printf("  Processor ID " IDFMT " is CPU\n", it->id);
            break;
          }
        // Throughput-optimized cores (TOCs) are GPUs
        case Processor::TOC_PROC:
          {
            printf("  Processor ID " IDFMT " is GPU\n", it->id);
            break;
          }
        // Processor for doing I/O
        case Processor::IO_PROC:
          {
            printf("  Processor ID " IDFMT " is I/O Proc\n", it->id);
            break;
          }
        // Utility processors are helper processors for
        // running Legion runtime meta-level tasks and
        // should not be used for running application tasks
        case Processor::UTIL_PROC:
          {
            printf("  Processor ID " IDFMT " is utility\n", it->id);
            break;
          }
        default:
          assert(false);
      }
    }
    std::set<Memory> all_mems;
    machine.get_all_memories(all_mems);
    printf("There are %zd memories:\n", all_mems.size());
    for (std::set<Memory>::const_iterator it = all_mems.begin();
          it != all_mems.end(); it++) {
      Memory::Kind kind = it->kind();
      size_t memory_size_in_kb = it->capacity() >> 10;
      switch (kind) {
        // RDMA addressable memory when running with GASNet
        case Memory::GLOBAL_MEM:
          {
            printf("  GASNet Global Memory ID " IDFMT " has %zd KB\n",
                    it->id, memory_size_in_kb);
            break;
          }
        // DRAM on a single node
        case Memory::SYSTEM_MEM:
          {
            printf("  System Memory ID " IDFMT " has %zd KB\n",
                    it->id, memory_size_in_kb);
            break;
          }
        // Pinned memory on a single node
        case Memory::REGDMA_MEM:
          {
            printf("  Pinned Memory ID " IDFMT " has %zd KB\n",
                    it->id, memory_size_in_kb);
            break;
          }
        // A memory associated with a single socket
        case Memory::SOCKET_MEM:
          {
            printf("  Socket Memory ID " IDFMT " has %zd KB\n",
                    it->id, memory_size_in_kb);
            break;
          }
        // Zero-copy memory betweeen CPU DRAM and
        // all GPUs on a single node
        case Memory::Z_COPY_MEM:
          {
            printf("  Zero-Copy Memory ID " IDFMT " has %zd KB\n",
                    it->id, memory_size_in_kb);
            break;
          }
        // GPU framebuffer memory for a single GPU
        case Memory::GPU_FB_MEM:
          {
            printf("  GPU Frame Buffer Memory ID " IDFMT " has %zd KB\n",
                    it->id, memory_size_in_kb);
            break;
          }
        // Disk memory on a single node
        case Memory::DISK_MEM:
          {
            printf("  Disk Memory ID " IDFMT " has %zd KB\n",
                    it->id, memory_size_in_kb);
            break;
          }
        // HDF framebuffer memory for a single GPU
        case Memory::HDF_MEM:
          {
            printf("  HDF Memory ID " IDFMT " has %zd KB\n",
                    it->id, memory_size_in_kb);
            break;
          }
        // File memory on a single node
        case Memory::FILE_MEM:
          {
            printf("  File Memory ID " IDFMT " has %zd KB\n",
                    it->id, memory_size_in_kb);
            break;
          }
        // Block of memory sized for L3 cache
        case Memory::LEVEL3_CACHE:
          {
            printf("  Level 3 Cache ID " IDFMT " has %zd KB\n",
                    it->id, memory_size_in_kb);
            break;
          }
        // Block of memory sized for L2 cache
        case Memory::LEVEL2_CACHE:
          {
            printf("  Level 2 Cache ID " IDFMT " has %zd KB\n",
                    it->id, memory_size_in_kb);
            break;
          }
        // Block of memory sized for L1 cache
        case Memory::LEVEL1_CACHE:
          {
            printf("  Level 1 Cache ID " IDFMT " has %zd KB\n",
                    it->id, memory_size_in_kb);
            break;
          }
        default:
          assert(false);
      }
    }

    std::set<Memory> vis_mems;
    machine.get_visible_memories(local_proc, vis_mems);
    printf("There are %zd memories visible from processor " IDFMT "\n",
            vis_mems.size(), local_proc.id);
    for (std::set<Memory>::const_iterator it = vis_mems.begin();
          it != vis_mems.end(); it++) {
      std::vector<ProcessorMemoryAffinity> affinities;
      int results =
        machine.get_proc_mem_affinity(affinities, local_proc, *it);
      assert(results == 1);
      printf("  Memory " IDFMT " has bandwidth %d and latency %d\n",
              it->id, affinities[0].bandwidth, affinities[0].latency);
    }
  }
}

void AdversarialMapper::select_task_options(const MapperContext ctx,
                                            const Task& task,
                                                  TaskOptions& output) {
  output.inline_task = false;
  output.stealable = false;
  output.map_locally = true;
  Processor::Kind kind = select_random_processor_kind(ctx, task.task_id);
  output.initial_proc = select_random_processor(kind);
}

void AdversarialMapper::slice_task(const MapperContext      ctx,
                                   const Task&              task,
                                   const SliceTaskInput&    input,
                                         SliceTaskOutput&   output) {
  // Iterate over all the points and send them all over the world
  output.slices.resize(input.domain.get_volume());
  unsigned idx = 0;
  switch (input.domain.get_dim()) {
    case 1:
      {
        Rect<1> rect = input.domain;
        for (PointInRectIterator<1> pir(rect); pir(); pir++, idx++)
        {
          Rect<1> slice(*pir, *pir);
          output.slices[idx] = TaskSlice(slice,
              select_random_processor(task.target_proc.kind()),
              false/*recurse*/, true/*stealable*/);
        }
        break;
      }
    case 2:
      {
        Rect<2> rect = input.domain;
        for (PointInRectIterator<2> pir(rect); pir(); pir++, idx++)
        {
          Rect<2> slice(*pir, *pir);
          output.slices[idx] = TaskSlice(slice,
              select_random_processor(task.target_proc.kind()),
              false/*recurse*/, true/*stealable*/);
        }
        break;
      }
    case 3:
      {
        Rect<3> rect = input.domain;
        for (PointInRectIterator<3> pir(rect); pir(); pir++, idx++)
        {
          Rect<3> slice(*pir, *pir);
          output.slices[idx] = TaskSlice(slice,
              select_random_processor(task.target_proc.kind()),
              false/*recurse*/, true/*stealable*/);
        }
        break;
      }
    default:
      assert(false);
  }
}

void AdversarialMapper::map_task(const MapperContext         ctx,
                                 const Task&                 task,
                                 const MapTaskInput&         input,
                                       MapTaskOutput&        output) {
  const std::map<VariantID,Processor::Kind> &variant_kinds =
    find_task_variants(ctx, task.task_id);
  std::vector<VariantID> variants;
  for (std::map<VariantID,Processor::Kind>::const_iterator it =
        variant_kinds.begin(); it != variant_kinds.end(); it++) {
    if (task.target_proc.kind() == it->second)
      variants.push_back(it->first);
  }
  assert(!variants.empty());
  if (variants.size() > 1) {
    int chosen = default_generate_random_integer() % variants.size();
    output.chosen_variant = variants[chosen];
  }
  else
    output.chosen_variant = variants[0];
  output.target_procs.push_back(task.target_proc);
  std::vector<bool> premapped(task.regions.size(), false);
  for (unsigned idx = 0; idx < input.premapped_regions.size(); idx++) {
    unsigned index = input.premapped_regions[idx];
    output.chosen_instances[index] = input.valid_instances[index];
    premapped[index] = true;
  }
  const TaskLayoutConstraintSet &layout_constraints =
    runtime->find_task_layout_constraints(ctx, task.task_id,
                                          output.chosen_variant);
  for (unsigned idx = 0; idx < task.regions.size(); idx++) {
    if (premapped[idx])
      continue;
    if (task.regions[idx].is_restricted()) {
      output.chosen_instances[idx] = input.valid_instances[idx];
      continue;
    }
    if (layout_constraints.layouts.find(idx) !=
          layout_constraints.layouts.end()) {
      std::vector<LayoutConstraintID> constraints;
      for (std::multimap<unsigned,LayoutConstraintID>::const_iterator it =
            layout_constraints.layouts.lower_bound(idx); it !=
            layout_constraints.layouts.upper_bound(idx); it++)
        constraints.push_back(it->second);
      map_constrained_requirement(ctx, task.regions[idx], TASK_MAPPING,
          constraints, output.chosen_instances[idx], task.target_proc);
    }
    else
      map_random_requirement(ctx, task.regions[idx],
                             output.chosen_instances[idx],
                             task.target_proc);
  }
  output.task_priority = default_generate_random_integer();

  {
    using namespace ProfilingMeasurements;
    output.task_prof_requests.add_measurement<OperationStatus>();
    output.task_prof_requests.add_measurement<OperationTimeline>();
    output.task_prof_requests.add_measurement<RuntimeOverhead>();
  }
}

void AdversarialMapper::report_profiling(const MapperContext      ctx,
					 const Task&              task,
					 const TaskProfilingInfo& input) {
  using namespace ProfilingMeasurements;

  OperationStatus *status =
    input.profiling_responses.get_measurement<OperationStatus>();
  if (status) {
    switch (status->result) {
      case OperationStatus::COMPLETED_SUCCESSFULLY:
        {
          printf("Task %s COMPLETED SUCCESSFULLY\n", task.get_task_name());
          break;
        }
      case OperationStatus::COMPLETED_WITH_ERRORS:
        {
          printf("Task %s COMPLETED WITH ERRORS\n", task.get_task_name());
          break;
        }
      case OperationStatus::INTERRUPT_REQUESTED:
        {
          printf("Task %s was INTERRUPTED\n", task.get_task_name());
          break;
        }
      case OperationStatus::TERMINATED_EARLY:
        {
          printf("Task %s TERMINATED EARLY\n", task.get_task_name());
          break;
        }
      case OperationStatus::CANCELLED:
        {
          printf("Task %s was CANCELLED\n", task.get_task_name());
          break;
        }
      default:
        assert(false); // shouldn't get any of the rest currently
    }
    delete status;
  }
  else
    printf("No operation status for task %s\n", task.get_task_name());

  OperationTimeline *timeline =
    input.profiling_responses.get_measurement<OperationTimeline>();
  if (timeline) {
    printf("Operation timeline for task %s: ready=%lld start=%lld stop=%lld\n",
	   task.get_task_name(),
	   timeline->ready_time,
	   timeline->start_time,
	   timeline->end_time);
    delete timeline;
  }
  else
    printf("No operation timeline for task %s\n", task.get_task_name());

  RuntimeOverhead *overhead =
    input.profiling_responses.get_measurement<RuntimeOverhead>();
  if (overhead) {
    long long total = (overhead->application_time +
		       overhead->runtime_time +
		       overhead->wait_time);
    if (total <= 0) total = 1;
    printf("Runtime overhead for task %s: runtime=%.1f%% wait=%.1f%%\n",
	   task.get_task_name(),
	   (100.0 * overhead->runtime_time / total),
	   (100.0 * overhead->wait_time / total));
    delete overhead;
  }
  else
    printf("No runtime overhead data for task %s\n", task.get_task_name());
}

PartitioningMapper::PartitioningMapper(Machine m,
                                       Runtime *rt,
                                       Processor p)
  : DefaultMapper(rt->get_mapper_runtime(), m, p)
{
}

void PartitioningMapper::select_tunable_value(const MapperContext ctx,
                                              const Task& task,
                                              const SelectTunableInput& input,
                                                    SelectTunableOutput& output) {
  if (input.tunable_id == SUBREGION_TUNABLE) {
    Machine::ProcessorQuery all_procs(machine);
    all_procs.only_kind(Processor::LOC_PROC);
    runtime->pack_tunable<size_t>(all_procs.count(), output);
    return;
  }
  assert(false);
}

/*
 * Everything below here except main is the standard daxpy example and
 * is elided for brevity....
 */

int main(int argc, char **argv) {
  Runtime::set_top_level_task_id(TOP_LEVEL_TASK_ID);

  {
    TaskVariantRegistrar registrar(TOP_LEVEL_TASK_ID, "top_level");
    registrar.add_constraint(ProcessorConstraint(Processor::LOC_PROC));
    Runtime::preregister_task_variant<top_level_task>(registrar, "top_level");
  }

  {
    TaskVariantRegistrar registrar(INIT_FIELD_TASK_ID, "init_field");
    registrar.add_constraint(ProcessorConstraint(Processor::LOC_PROC));
    registrar.set_leaf();
    Runtime::preregister_task_variant<init_field_task>(registrar, "init_field");
  }

  {
    TaskVariantRegistrar registrar(DAXPY_TASK_ID, "daxpy");
    registrar.add_constraint(ProcessorConstraint(Processor::LOC_PROC));
    registrar.set_leaf();
    Runtime::preregister_task_variant<daxpy_task>(registrar, "daxpy");
  }

  {
    TaskVariantRegistrar registrar(CHECK_TASK_ID, "check");
    registrar.add_constraint(ProcessorConstraint(Processor::LOC_PROC));
    registrar.set_leaf();
    Runtime::preregister_task_variant<check_task>(registrar, "check");
  }

  // Here is where we register the callback function for
  // creating custom mappers.
  Runtime::add_registration_callback(mapper_registration);

  return Runtime::start(argc, argv);
}
{% endhighlight %}
