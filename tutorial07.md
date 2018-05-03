---
layout: page
permalink: /tutorial/partitioning.html
title: Partitioning
---

Continuing with our implementation of DAXPY,
we illustrate how Legion enables applications
to further express parallelism by partitioning
logical regions into sub-regions and then
launching tasks that can operate on different
sub-regions in parallel.

#### Partitioning Index Spaces ####

The act of partitioning in Legion breaks a
set of points represented by an index space
into subsets of points, each of which will
become index sub-spaces. In our DAXPY example
we want to partition our two logical regions
into `num_subregions` different sub-regions.
(Note that `num_subregions` can be controlled
by the `-b` command line parameter now to
specify the number of _blocks_ to make.) To do
this we must partition the common index space
`is` upon which both logical regions are based.
The partition we wish to create will be called
`ip` for _index partition_ (line 66).

The first step in creating a partition is
to create an `IndexSpace` which describes the
the _color space_ of the partition. The purpose of a color space
is to associate a _color_ (a point within
the color space) with each index sub-space
we wish to make. In this DAXPY example, we
create a `color_space` with a point for each
of the desired blocks (lines 63-64, recall
`Rect` types are inclusive).

Legion contains a large number of functions for performing any sort of
partitioning the user desires. In this case, we'll use
`create_equal_partition` to create a partition with sub-regions of
roughly equal size. The resulting sub-regions are guarranteed to be
dense, but in general partitioning is quite expressive and the
resulting sub-regions of most partitioning operations need not be
dense.

For an overview of Legion's other partitioning operations, please see
the [Dependent Partitioning](/pdfs/dpl2016.pdf) paper.

#### Obtaining Logical Sub-Regions ####

While partitions are performed on index spaces,
the created index partitions and index sub-spaces
are implicitly created on all of the logical regions
that were created using the original index space.
For example, in our DAXPY application, the `is`
index space was used to create both the `input_lr`
and `output_lr` logical regions. Therefore, when
we created the `ip` index partition of `is` we
also automatically created the corresponding
partitions for both the region trees rooted by
`input_lr` and `output_lr`. (A quick performance
note: the Legion runtime lazily instantiates the data
structures for these region trees to avoid costly
overheads when dealing with large numbers of partitions
and sub-regions.) The following figure shows the
resulting index space tree and two region trees for
our DAXPY example:

![](/images/daxpy_partition.svg)

Since the logical partitions and sub-regions are
implicitly created, the application initially
has no means for obtaining handles to these objects.
The Legion runtime supports several ways of
acquiring these handles. One example can be
seen on line 69 where the application invokes
`get_logical_partition`. This method
takes a logical region `R` and an index partition
of the index space of `R` and returns the corresponding
`LogicalPartition` handle. There are a number of additional methods (such as `get_logical_partition_by_color`
and `get_logical_partition_by_tree`) which
can be used to obtain `LogicalPartition`
handles. For sub-regions, the runtime supports a corresponding
set of methods (`get_logical_subregion`,
`get_logical_subregion_by_color`, and
`get_logical_subregion_by_tree`) for discovering
the handles for logical sub-regions.

#### Projection Region Requirements ####

As in the previous DAXPY example, we now want
to launch sub-tasks for initializing fields,
performing the DAXPY computation, and checking
correctness. To take advantage of the partitioning
that was performed and increase parallelism we
need to launch separate sub-tasks for each of
the logical sub-regions that were created.
As in an earlier example, we use `IndexLauncher`
objects for launching an index space of tasks.
However, unlike launching single tasks, we need
a way to specify different `RegionRequirement`
objects for each of the points in the index space
of tasks. To accomplish this we use _projection_
region requirements.

Projection region requirements provide a two-step
mechanism for assigning a region requirement for
each point task in an index space of task launches.
First, a projection region requirement
names an upper bound on the privileges to be
requested by the index space task. This upper bound can
either be a logical region or logical partition.
The logical regions eventually requested by each
point task in the index space of tasks must be subregions
of the given upper bound. Second, a
_projection functor_ is used to pick the specific sub-regions given
to each point task. We now illustrate how
these two aspects of projection region requirements
work in our DAXPY example.

Projection region requirements are created using
an overloaded constructor for the `RegionRequirement`
type. These constructors always begin by specifying
either a logical region or logical partition as
an upper bound on the data to be accessed, followed
by a projection functor ID (lines 79-80). The
remaining arguments are the same as other
`RegionRequirement` constructors. In our DAXPY
example we use the `input_lp` and `output_lp`
logical partitions as upper bounds for our index
space task launches as each point task will
be using a sub-region of these partitions. Our
projection region requirements also use the
projection ID `0` to specify our projection
function. The `0` projection ID is a reserved
ID which we describe momentarily. Applications
can register their own projection functors either statically, before
starting the Legion runtime starts, using the
`preregister_projection_functor`, or dynamically, after it starts,
with `register_projection_functor`. This is similar to how tasks are
registered.

The second step of using projection region
requirements comes as the index space task
is executed. When the runtime enumerates the
index space of tasks, it invokes
the specified projection functor on each
point to compute the logical region requirement
for that the task. In the case of our DAXPY example,
we use the reserved `0` projection functor, which uses the identity
function to determine which sub-region to use. So task `i` in the launch will get
subregion `i` in the partition, and so on.

The tasks in an index space launch must be able to run in
parallel. This means that when using projection region requirements,
it is important that the projection functor choose a different
sub-region for every task in the launch, assuming the tasks are going
to write to their respective regions. (It's ok to pick the same
sub-region if the tasks are only going to read or use reductions on
the regions in question.)

#### Finding Index Space Bounds ####

It can be useful to get the bounds of an index space directly from a
logical region. This can be done with the `get_index_space_domain`
method on an `IndexSpace`, which returns a struct. We use this method
in all three sub-tasks to avoid needing explicitly pass the bounds of
the regions down to these tasks.

#### Region Non-Interference ####

In this version of DAXPY, we see an example of
how the Legion runtime can extract parallelism
from tasks using region non-interference. Since
each of the tasks in our index space launches
are using disjoint logical sub-regions, the Legion
runtime can infer that these tasks can be run in
parallel. The following figure shows the TDG
computed for this version of DAXPY. (Note we
could also have parallelized the checking task
if we so desired.)

![](/images/daxpy_parallel.svg)

This version of DAXPY demonstrates the power
of the Legion programming model. By understanding
the structure of program data, the runtime can
extract parallelism from both field-level and
region non-interference at the same time. Using
both forms of non-interference to discover simultaneous
task- and data-level parallelism
is something that no other programming model
we are aware of is capable of achieving.

Next Example: [Multiple Partitions](/tutorial/multiple.html)  
Previous Example: [Privileges](/tutorial/privileges.html)

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
  int num_subregions = 4;
  {
    const InputArgs &command_args = Runtime::get_input_args();
    for (int i = 1; i < command_args.argc; i++) {
      if (!strcmp(command_args.argv[i],"-n"))
        num_elements = atoi(command_args.argv[++i]);
      if (!strcmp(command_args.argv[i],"-b"))
        num_subregions = atoi(command_args.argv[++i]);
    }
  }
  printf("Running daxpy for %d elements...\n", num_elements);
  printf("Partitioning data into %d sub-regions...\n", num_subregions);

  Rect<1> elem_rect(0,num_elements-1);
  IndexSpace is = runtime->create_index_space(ctx, elem_rect);
  runtime->attach_name(is, "is");
  FieldSpace input_fs = runtime->create_field_space(ctx);
  runtime->attach_name(input_fs, "input_fs");
  {
    FieldAllocator allocator =
      runtime->create_field_allocator(ctx, input_fs);
    allocator.allocate_field(sizeof(double),FID_X);
    runtime->attach_name(input_fs, FID_X, "X");
    allocator.allocate_field(sizeof(double),FID_Y);
    runtime->attach_name(input_fs, FID_Y, "Y");
  }
  FieldSpace output_fs = runtime->create_field_space(ctx);
  runtime->attach_name(output_fs, "output_fs");
  {
    FieldAllocator allocator =
      runtime->create_field_allocator(ctx, output_fs);
    allocator.allocate_field(sizeof(double),FID_Z);
    runtime->attach_name(output_fs, FID_Z, "Z");
  }
  LogicalRegion input_lr = runtime->create_logical_region(ctx, is, input_fs);
  runtime->attach_name(input_lr, "input_lr");
  LogicalRegion output_lr = runtime->create_logical_region(ctx, is, output_fs);
  runtime->attach_name(output_lr, "output_lr");

  Rect<1> color_bounds(0,num_subregions-1);
  IndexSpace color_is = runtime->create_index_space(ctx, color_bounds);

  IndexPartition ip = runtime->create_equal_partition(ctx, is, color_is);
  runtime->attach_name(ip, "ip");

  LogicalPartition input_lp = runtime->get_logical_partition(ctx, input_lr, ip);
  runtime->attach_name(input_lp, "input_lp");
  LogicalPartition output_lp = runtime->get_logical_partition(ctx, output_lr, ip);
  runtime->attach_name(output_lp, "output_lp");

  ArgumentMap arg_map;

  IndexLauncher init_launcher(INIT_FIELD_TASK_ID, color_is,
                              TaskArgument(NULL, 0), arg_map);
  init_launcher.add_region_requirement(
      RegionRequirement(input_lp, 0/*projection ID*/,
                        WRITE_DISCARD, EXCLUSIVE, input_lr));
  init_launcher.region_requirements[0].add_field(FID_X);
  runtime->execute_index_space(ctx, init_launcher);

  init_launcher.region_requirements[0].privilege_fields.clear();
  init_launcher.region_requirements[0].instance_fields.clear();
  init_launcher.region_requirements[0].add_field(FID_Y);
  runtime->execute_index_space(ctx, init_launcher);

  const double alpha = drand48();
  IndexLauncher daxpy_launcher(DAXPY_TASK_ID, color_is,
                TaskArgument(&alpha, sizeof(alpha)), arg_map);
  daxpy_launcher.add_region_requirement(
      RegionRequirement(input_lp, 0/*projection ID*/,
                        READ_ONLY, EXCLUSIVE, input_lr));
  daxpy_launcher.region_requirements[0].add_field(FID_X);
  daxpy_launcher.region_requirements[0].add_field(FID_Y);
  daxpy_launcher.add_region_requirement(
      RegionRequirement(output_lp, 0/*projection ID*/,
                        WRITE_DISCARD, EXCLUSIVE, output_lr));
  daxpy_launcher.region_requirements[1].add_field(FID_Z);
  runtime->execute_index_space(ctx, daxpy_launcher);

  TaskLauncher check_launcher(CHECK_TASK_ID, TaskArgument(&alpha, sizeof(alpha)));
  check_launcher.add_region_requirement(
      RegionRequirement(input_lr, READ_ONLY, EXCLUSIVE, input_lr));
  check_launcher.region_requirements[0].add_field(FID_X);
  check_launcher.region_requirements[0].add_field(FID_Y);
  check_launcher.add_region_requirement(
      RegionRequirement(output_lr, READ_ONLY, EXCLUSIVE, output_lr));
  check_launcher.region_requirements[1].add_field(FID_Z);
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
  const int point = task->index_point.point_data[0];
  printf("Initializing field %d for block %d...\n", fid, point);

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
  const int point = task->index_point.point_data[0];

  const FieldAccessor<READ_ONLY,double,1> acc_x(regions[0], FID_X);
  const FieldAccessor<READ_ONLY,double,1> acc_y(regions[0], FID_Y);
  const FieldAccessor<WRITE_DISCARD,double,1> acc_z(regions[1], FID_Z);
  printf("Running daxpy computation with alpha %.8g for point %d...\n",
          alpha, point);

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

  return Runtime::start(argc, argv);
}
{% endhighlight %}
