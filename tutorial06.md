---
layout: page
permalink: /tutorial/privileges.html
title: Privileges
---

In this example we again implement DAXPY
but use a different approach that uses sub-tasks
to perform each of the different operations on
logical regions. We implement three different
sub-tasks: one for initializing a field of a
logical region with random data (lines 95-112),
one for performing the DAXPY computation
(lines 114-137), and one for checking the
results (lines 139-168). We show how to launch
sub-tasks that request access to logical regions,
how sub-tasks manage physical instances, and how
privileges are passed. We also discuss how operations
can be executed in parallel based on field
non-interference and further illustrate how
deferred execution works in Legion.

#### Task Region Requirements ####

In this example we launch sub-tasks to perform
all aspects of the DAXPY computation. The top-level
task begins by implementing the same region scheme
as was used in the previous example (lines 34-51).
The top-level task then launches sub-tasks for
initializing the two fields (lines 53-63), performing
the DAXPY computation (lines 66-75), and finally
for checking the result (lines 77-86). All task
launches are performing using `TaskLauncher`
objects which were introduced earlier in the tutorial
for launching a single sub-task. However, when
launching sub-tasks in this example, we also
pass `RegionRequirement` objects as part of the
task launches in order to specify the logical
regions on which the sub-tasks will operate.

Unlike inline mappings, sub-tasks can specify
an arbitrary number of `RegionRequirement` objects
in their launchers. The `RegionRequirement` objects
that are stored in an STL vector inside of the launcher
under the `region_requirements` field. `RegionRequirement`
objects can be added directly to the launcher or
by calling the `add_region_requirement` method on
the `TaskLauncher` (lines 54-55). For each of the
`RegionRequirement` objects requested by a sub-task
the Legion runtime will grant the sub-task the
requested _privileges_ on the specified logical
regions on fields, thereby allowing the sub-task
to mutate the state of data in the logical regions
in ways consistent with the granted privileges.

#### Functional Region Privileges ####

An important property of the Legion programming model
is that sub-tasks are only allowed to request privileges
which are a subset of their parent task's privileges.
To enforce this invariant, privileges can only be passed
in a functional manner through sub-tasks calls. An astute
reader will notice that there is no mechanism either in
Legion or Regent for
naming privileges or storing them anywhere. Instead
privileges are only passed through `RegionRequirement`
objects used for launching sub-tasks. To reinforce the
functional nature of privileges `RegionRequirement`
objects require applications to name the parent task's
logical region from which the sub-task (or inline
mapping or other operation) is obtaining privileges.

We now describe one instance of how privileges are
passed from the top-level task to one of its sub-tasks.
When a task creates a logical region it is granted full
read-write privileges for the created logical region.
When the top-level task create the `input_lr` and
`output_lr` logical regions it obtains full read-write
privileges on those regions. When the DAXPY sub-task
is invoked on lines 66-73, the sub-task is passed
`READ_ONLY` privileges on the `input_lr` for fields
`FID_X` and `FID_Y` and `WRITE_DISCARD` on field
`FID_Z`. The sub-task's request for those privileges
is valid since they are a subset of the privileges
owned by the parent task. If a task that created a
logical region fails to delete it, the privileges
for the region implicitly escape into the parent
task's context. If the privileges escape the top-level
task Legion will issue a warning noting that the
logical region was leaked.

There are four kinds of privileges: `READ_WRITE`,
`READ_ONLY`, `REDUCE`, and `WRITE_DISCARD`. `READ_WRITE`
privileges give the task full permission to mutate
the specified fields of the logical region using any
kind of operation (read, write, reduction). `READ_ONLY`
restricts the task to only be able to perform reads
and `REDUCE` restricts the task to only be able to
perform reductions. `WRITE_DISCARD` is a special form
of `READ_WRITE` that still permits the task to perform
any kind of operation, but informs the runtime that
the task intends to overwrite all previous data stored
in the logical region without reading it. This enables
the runtime to perform several performance optimizations
associated with removing unnecessary data movement
operations. The various kinds of privileges form a
semi-lattice with `READ_WRITE` and `WRITE_DISCARD`
privileges occupying the top position and `READ_ONLY`
and `REDUCE` privileges each representing a subset
of the top privileges. The bottom element represents
having no privileges.

The privilege system of the Legion programming model
is essential to both the correctness and performance
of Legion applications. Privilege passing is
checked by the Legion runtime and will result in
runtime errors if violated. In Regent, privilege passing is checked statically
by the type system resulting in easier to diagnose
compile-time errors. The enforcement of functional
privilege passing makes possible Legion's hierarchical
and distributed scheduling algorithm. For more details
on this we refer you to our
[publications](/publications/).

#### Task Physical Regions ####

When a task requests privileges on logical regions
using `RegionRequirement` objects, it is commonly
the case that the task will need physical instances
of these requested regions. If a task was launched
with N region requirements, then it will be passed
back N `PhysicalRegion` objects in the `region`
STL vector that is an argument to all Legion tasks
(line 96). The `PhysicalRegion` objects are identical
to the ones described in the previous example that
are used to name physical instances. The only
difference in this case is that the Legion runtime
is intelligent about starting tasks that need
`PhysicalRegion` objects, and will not begin
execution of the task until all of the `PhysicalRegion`
objects are valid.

In general, most Legion application tasks will map
all of their logical region requests to physical
instances as part of their mapping phase (discussed
in a coming example). However, in some cases tasks
need only pass privileges for accessing a region
without needing an explicit physical instance. In
these cases, the _mapper_ which maps the task may
request that one or more logical region requirements
be _virtually mapped_. In these cases no physical
instance is created, but the task is still granted
privileges for the requested logical region and fields.
Tasks can test whether a `PhysicalRegion` has been
virtually mapped by invoking the `is_mapped` method
which will return `false` if virtually mapped.
The Legion default mapper will never virtually map
a region, but other mappers may choose to do so
and tasks should be implemented to handle such
scenarios.

The original `RegionRequirement` objects that were
used to launch a task are available to the task
implementation via the `Task` object. The `regions`
field of the `Task` object is an STL vector
containing the passed `RegionRequirement` objects.
Having access to these arguments is very powerful
as it even permits the implementation of
_field-polymorphic_ tasks which can perform the
same operation on a dynamically determined set
of fields. For example, in our DAXPY example,
the `init_field_task` is a field-polymorphic
function as it examines the `RegionRequirement`
passed to it to see which field to initialize
(line 101). We can therefore use the same task
to initialize both the 'X' and 'Y' fields.
Field-polymorphic tasks occur regularly in Legion
as it is common for many applications to want
to perform the same operation over many different
fields using a single task implementation.

#### Deferred Execution Revisited ####

The top-level task in this implementation of DAXPY
has a very interesting property: it never records
any `Future` objects as part of its sub-task
launches (lines 57,63,75,86). As a result there is
no way for it to explicitly block execution or chain
dependences between sub-tasks. Furthermore, because
all task launches are deferred, it's possible for
the top-level task to launch all its sub-tasks and
finish executing even before the first sub-task begins
running. So how is it possible that this application
computes the correct answer?

The crucial insight is that Legion understands the
structure of program data (in this case the two
logical regions `input_lr` and `output_lr` and their
fields). As the top-level task executes, Legion computes
a _Task Dataflow Graph_ (TDG) which captures data
dependences between operations based on the logical
regions, fields, and privileges that operations request.
Dependences in legion are computed based on the
__program order__ in which operations are issued to
the runtime. Legion therefore maintains sequential
execution semantics for all operations, even though
operations may ultimately execute in parallel. By
maintaining sequential execution semantics, Legion
significantly simplifies reasoning about operations
within a task. The following figure shows the computed
TDG for this DAXPY example:
<br/><br/>
![](/images/daxpy_sequential.svg)
<br/><br/>
In this figure we see that the DAXPY task has data
dependences on the two field initialization tasks
(one on field 'X' and one on field 'Y' of the `input_lr`
logical region). The checking
task then has a data dependence on the DAXPY task
(on field 'Z' of the `output_lr` region). (There are
also transitive data dependences from the initialization
tasks to the checking task on the two fields of `input_lr`
but we omit them for simplicity.) Finally, the deletions
of the two logical regions must wait until the last task
using the regions finishes executing. Legion is able to
efficiently compute this graph because it knows about
the structure of program data in the form of logical
regions as well as how tasks use logical regions.

By constructing the TDG for every task execution, Legion
can defer all the operations launched within a task
context. It is important to note that this is strictly
more powerful that traditional asynchronous execution.
In asynchronous execution, operations can be launched
asynchronously only once all their input dependences
have been satisfied. On the other hand, in a deferred
execution model such as Legion's, sub-tasks and other
operations can be issued even before dependences have
been satisfied. Doing so ensures as many operations
as possible are in flight, allowing the runtime to
discover the full parallelism available in applications,
make maximal use of machine resources, and hide long
latency operations with parallel work.

While all the sub-tasks executed within a task's context
are deferred, a task is not permitted to _complete_ until
all of its sub-tasks have completed. In our DAXPY example,
this prevents the top-level task from completing until
all the sub-tasks and deletion operations are complete.
Legion automatically manages this phase of a task's execution.

#### Field-Level Non-Interference ####

Determining that two sub-tasks have _non-interfering_
`RegionRequirement` objects is how Legion implicitly
extracts parallelism from applications. There are three
forms of non-interference:

* __Region non-interference__: two `RegionRequirement` objects
  are non-interfering on regions if they access logical
  regions from different region trees, or disjoint logical
  regions in the same tree.
* __Field-level non-interference__: two `RegionRequirement`
  objects are non-interfering on fields if they access
  disjoint sets of fields within the same logical region.
* __Privileges non-interference__: two `RegionRequirement`
  objects are non-interfering on privileges if they
  are both request `READ_ONLY` privileges, or they
  both request `REDUCE` privileges with the same
  reduction operator.

We'll see examples of region and privilege non-interference
in the next two examples. In this DAXPY example we have
an example of field-level non-interference. Both
of the `init_field_task` launches both request the same
logical region with `WRITE_DISCARD` privilege and therefore
neither region nor privilege non-interference applies. However,
because the `RegionRequirement` objects request privileges
on different fields, the two sets of fields are disjoint.
Thus, even though the two `init_field_task` launches are
performed sequentially, Legion infers that the tasks can
be run in parallel. This is reflected in the TDG where
there are no data dependence edges between the nodes for
the two tasks.

It is important to note that even though Legion has
determined that these two tasks may be run in parallel,
it is up to the mapper to assign them to different processors.
If they are assigned to the same processor, Legion will
serialize their execution, resulting in correct but
sequential behavior. This is just one example of how
mapping decisions can influence the performance of applications.
We'll investigate the mapping process in more detail in
a later example.

Next Example: [Partitioning](/tutorial/partitioning.html)
<br/>
Previous Example: [Physical Regions](/tutorial/physical_regions.html)

{% highlight cpp linenos %}
#include <cstdio>
#include <cassert>
#include <cstdlib>
#include "legion.h"
using namespace Legion;

enum TaskIDs {
  TOP_LEVEL_TASK_ID,
  INIT_FIELD_TASK_ID,
  DAXPY_TASK_ID,
  CHECK_TASK_ID,
};

enum FieldIDs {
  FID_X,
  FID_Y,
  FID_Z,
};

void top_level_task(const Task *task,
                    const std::vector<PhysicalRegion> &regions,
                    Context ctx, Runtime *runtime) {
  int num_elements = 1024;
  {
    const InputArgs &command_args = Runtime::get_input_args();
    for (int i = 1; i < command_args.argc; i++) {
      if (!strcmp(command_args.argv[i],"-n"))
        num_elements = atoi(command_args.argv[++i]);
    }
  }
  printf("Running daxpy for %d elements...\n", num_elements);

  const Rect<1> elem_rect(0,num_elements-1);
  IndexSpace is = runtime->create_index_space(ctx, elem_rect);
  FieldSpace input_fs = runtime->create_field_space(ctx);
  {
    FieldAllocator allocator =
      runtime->create_field_allocator(ctx, input_fs);
    allocator.allocate_field(sizeof(double),FID_X);
    allocator.allocate_field(sizeof(double),FID_Y);
  }
  FieldSpace output_fs = runtime->create_field_space(ctx);
  {
    FieldAllocator allocator =
      runtime->create_field_allocator(ctx, output_fs);
    allocator.allocate_field(sizeof(double),FID_Z);
  }
  LogicalRegion input_lr = runtime->create_logical_region(ctx, is, input_fs);
  LogicalRegion output_lr = runtime->create_logical_region(ctx, is, output_fs);

  TaskLauncher init_launcher(INIT_FIELD_TASK_ID, TaskArgument(NULL, 0));
  init_launcher.add_region_requirement(
      RegionRequirement(input_lr, WRITE_DISCARD, EXCLUSIVE, input_lr));
  init_launcher.add_field(0/*idx*/, FID_X);
  runtime->execute_task(ctx, init_launcher);

  init_launcher.region_requirements[0].privilege_fields.clear();
  init_launcher.region_requirements[0].instance_fields.clear();
  init_launcher.add_field(0/*idx*/, FID_Y);

  runtime->execute_task(ctx, init_launcher);

  const double alpha = drand48();
  TaskLauncher daxpy_launcher(DAXPY_TASK_ID, TaskArgument(&alpha, sizeof(alpha)));
  daxpy_launcher.add_region_requirement(
      RegionRequirement(input_lr, READ_ONLY, EXCLUSIVE, input_lr));
  daxpy_launcher.add_field(0/*idx*/, FID_X);
  daxpy_launcher.add_field(0/*idx*/, FID_Y);
  daxpy_launcher.add_region_requirement(
      RegionRequirement(output_lr, WRITE_DISCARD, EXCLUSIVE, output_lr));
  daxpy_launcher.add_field(1/*idx*/, FID_Z);

  runtime->execute_task(ctx, daxpy_launcher);

  TaskLauncher check_launcher(CHECK_TASK_ID, TaskArgument(&alpha, sizeof(alpha)));
  check_launcher.add_region_requirement(
      RegionRequirement(input_lr, READ_ONLY, EXCLUSIVE, input_lr));
  check_launcher.add_field(0/*idx*/, FID_X);
  check_launcher.add_field(0/*idx*/, FID_Y);
  check_launcher.add_region_requirement(
      RegionRequirement(output_lr, READ_ONLY, EXCLUSIVE, output_lr));
  check_launcher.add_field(1/*idx*/, FID_Z);

  runtime->execute_task(ctx, check_launcher);

  runtime->destroy_logical_region(ctx, input_lr);
  runtime->destroy_logical_region(ctx, output_lr);
  runtime->destroy_field_space(ctx, input_fs);
  runtime->destroy_field_space(ctx, output_fs);
  runtime->destroy_index_space(ctx, is);
}

void init_field_task(const Task *task,
                     const std::vector<PhysicalRegion> &regions,
                     Context ctx, Runtime *runtime) {
  assert(regions.size() == 1);
  assert(task->regions.size() == 1);
  assert(task->regions[0].privilege_fields.size() == 1);
  FieldID fid = *(task->regions[0].privilege_fields.begin());
  printf("Initializing field %d...\n", fid);
  const FieldAccessor<WRITE_DISCARD,double,1> acc(regions[0], fid);

  Rect<1> rect = runtime->get_index_space_domain(ctx,
                  task->regions[0].region.get_index_space());
  for (PointInRectIterator<1> pir(rect); pir(); pir++)
    acc[*pir] = drand48();
}

void daxpy_task(const Task *task,
                const std::vector<PhysicalRegion> &regions,
                Context ctx, Runtime *runtime) {
  assert(regions.size() == 2);
  assert(task->regions.size() == 2);
  assert(task->arglen == sizeof(double));
  const double alpha = *((const double*)task->args);

  const FieldAccessor<READ_ONLY,double,1> acc_x(regions[0], FID_X);
  const FieldAccessor<READ_ONLY,double,1> acc_y(regions[0], FID_Y);
  const FieldAccessor<WRITE_DISCARD,double,1> acc_z(regions[1], FID_Z);

  printf("Running daxpy computation with alpha %.8g...\n", alpha);
  Rect<1> rect = runtime->get_index_space_domain(ctx,
                  task->regions[0].region.get_index_space());
  for (PointInRectIterator<1> pir(rect); pir(); pir++)
    acc_z[*pir] = alpha * acc_x[*pir] + acc_y[*pir];
}

void check_task(const Task *task,
                const std::vector<PhysicalRegion> &regions,
                Context ctx, Runtime *runtime) {
  assert(regions.size() == 2);
  assert(task->regions.size() == 2);
  assert(task->arglen == sizeof(double));
  const double alpha = *((const double*)task->args);
  const FieldAccessor<READ_ONLY,double,1> acc_x(regions[0], FID_X);
  const FieldAccessor<READ_ONLY,double,1> acc_y(regions[0], FID_Y);
  const FieldAccessor<READ_ONLY,double,1> acc_z(regions[1], FID_Z);

  printf("Checking results...");
  Rect<1> rect = runtime->get_index_space_domain(ctx,
                  task->regions[0].region.get_index_space());
  bool all_passed = true;
  for (PointInRectIterator<1> pir(rect); pir(); pir++) {
    double expected = alpha * acc_x[*pir] + acc_y[*pir];
    double received = acc_z[*pir];
    if (expected != received)
      all_passed = false;
  }
  if (all_passed)
    printf("SUCCESS!\n");
  else
    printf("FAILURE!\n");
}

int main(int argc, char **argv)
{
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

  return Runtime::start(argc, argv);
}
{% endhighlight %}

