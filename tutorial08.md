---
layout: page
permalink: /tutorial/multiple.html
title: Multiple Partitions
---

We deviate from our running DAXPY application
in this example to illustrate how Legion permits
applications to create multiple logical partitions
of the same logical region, thereby enabling multiple
views onto the same set of data. To do this, we'll
construct a simple program to compute the derivative
of some data by performing a simple 1-D 5-point stencil
on a discretized space using the standard formula.

```
f'(x) = (-f(x+2) + 8f(x+1) - 8f(x-1) + f(x-2))/12
```

To perform the stencil computation we create the
`stencil_lr` logical region with two fields: one
field containing the input values and a second field
to store the computed derivative value at each point
(lines 37-46). After creating the logical regions
we partition the `stencil_lr` logical region in
two different ways which we cover in the next
section. After partitioning the logical region
we initialize the data in our value field using
the `init_field_task` (lines 67-73, identical
to the one from our DAXPY example). We then launch
an index space of tasks to perform the stencil
computation in parallel (lines 75-85). Finally,
a single task is launched to check the result of
the stencil computation (lines 87-95).

#### Creating and Using Multiple Partitions ####

To be able to compute the stencil computation in
parallel, we need to create two partitions: one
disjoint partition with each logical sub-region
describing the points that each tasks will write,
and a second partition with each logical sub-region
describing the points that each task will need to
read from to perform the stencil computation.
While the first partition will be disjoint, the
second partition will be _aliased_ because each
sub-region will additionally require two _ghost_ cells on
each side of the set of elements in
each sub-region in the disjoint partition.
The need for these ghost cells means that some
cells will exist in multiple sub-regions and
therefore sub-regions of the partition may overlap.

We create the disjoint partition with `create_equal_partition` as we
did the previous example (lines 51-52). For the new, aliased partition
we use another runtime method called `create_partition_by_restriction`
(lines 53-58). This method works by multiplying every index point in
the color space of the partition by a transform matrix, to determine
the offset of the subregion to create. This essentially allows us to
create a bunch of overlapping subregions of the same size, with a
certain offset between them.

After we've computed the two index partitions we obtain the
corresponding logical partitions (lines 60-63). The following figure
shows the resulting logical region tree for the application.

![](/images/stencil_partition.svg)

Legion's support of multiple partitions for
logical regions enables applications to use
different views of the same data even within
the same task. Consider the index space task
launch for performing the stencil computation.
We pass two projection region requirements
in the launcher object. The first region
requirement requests `READ_ONLY` privileges
on the aliased `ghost_lp` logical partition
for the `FID_VAL` field (lines 77-80).
The second region requirement requests
`READ_WRITE` privileges on the `disjoint_lp`
logical partition for the `FID_DERIV` field
(lines 81-84). In the next section we describe
how Legion proves that all of the stencil
tasks can be run in parallel.

#### Privilege Non-Interference ####

To prove that all of the stencil tasks can run
in parallel, the Legion runtime relies on all
three kinds of non-interference including one
we have not yet covered: privilege non-interference.
First, field non-interference ensures that any
point task's first region requirement is disjoint
from any other point task's second region requirement
as the two region requirements use different fields.
Next, logical region non-interference ensures all
tasks are non-interfering with respect to every other
task's second region requirement because a disjoint
partition is used. The last case where non-interference
must be shown is with regards to the first region
requirement between any pair of tasks. Neither field-level
nor logical region non-interference applies. However,
since all tasks are only requesting `READ_ONLY`
privileges, then the tasks are non-interfering on
privileges because tasks that are only reading data cannot
interfere with each other. Consequently, all the
point tasks in the stencil index space launch
can be run in parallel.

Next Example: [Custom Mappers](/tutorial/custom_mappers.html)  
Previous Example: [Partitioning](/tutorial/partitioning.html)

{% highlight cpp linenos %}
#include <cstdio>
#include <cassert>
#include <cstdlib>
#include "legion.h"

using namespace Legion;

enum TaskIDs {
  TOP_LEVEL_TASK_ID,
  INIT_FIELD_TASK_ID,
  STENCIL_TASK_ID,
  CHECK_TASK_ID,
};

enum FieldIDs {
  FID_VAL,
  FID_DERIV,
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
  printf("Running stencil computation for %d elements...\n", num_elements);
  printf("Partitioning data into %d sub-regions...\n", num_subregions);

  Rect<1> elem_rect(0,num_elements-1);
  IndexSpaceT<1> is = runtime->create_index_space(ctx, elem_rect);
  FieldSpace fs = runtime->create_field_space(ctx);
  {
    FieldAllocator allocator =
      runtime->create_field_allocator(ctx, fs);
    allocator.allocate_field(sizeof(double),FID_VAL);
    allocator.allocate_field(sizeof(double),FID_DERIV);
  }
  LogicalRegion stencil_lr = runtime->create_logical_region(ctx, is, fs);

  Rect<1> color_bounds(0,num_subregions-1);
  IndexSpaceT<1> color_is = runtime->create_index_space(ctx, color_bounds);

  IndexPartition disjoint_ip =
    runtime->create_equal_partition(ctx, is, color_is);
  const int block_size = (num_elements + num_subregions - 1) / num_subregions;
  Transform<1,1> transform;
  transform[0][0] = block_size;
  Rect<1> extent(-2, block_size + 1);
  IndexPartition ghost_ip =
    runtime->create_partition_by_restriction(ctx, is, color_is, transform, extent);

  LogicalPartition disjoint_lp =
    runtime->get_logical_partition(ctx, stencil_lr, disjoint_ip);
  LogicalPartition ghost_lp =
    runtime->get_logical_partition(ctx, stencil_lr, ghost_ip);

  ArgumentMap arg_map;

  IndexLauncher init_launcher(INIT_FIELD_TASK_ID, color_is,
                              TaskArgument(NULL, 0), arg_map);
  init_launcher.add_region_requirement(
      RegionRequirement(disjoint_lp, 0/*projection ID*/,
                        WRITE_DISCARD, EXCLUSIVE, stencil_lr));
  init_launcher.add_field(0, FID_VAL);
  runtime->execute_index_space(ctx, init_launcher);

  IndexLauncher stencil_launcher(STENCIL_TASK_ID, color_is,
       TaskArgument(&num_elements, sizeof(num_elements)), arg_map);
  stencil_launcher.add_region_requirement(
      RegionRequirement(ghost_lp, 0/*projection ID*/,
                        READ_ONLY, EXCLUSIVE, stencil_lr));
  stencil_launcher.add_field(0, FID_VAL);
  stencil_launcher.add_region_requirement(
      RegionRequirement(disjoint_lp, 0/*projection ID*/,
                        READ_WRITE, EXCLUSIVE, stencil_lr));
  stencil_launcher.add_field(1, FID_DERIV);
  runtime->execute_index_space(ctx, stencil_launcher);

  TaskLauncher check_launcher(CHECK_TASK_ID,
      TaskArgument(&num_elements, sizeof(num_elements)));
  check_launcher.add_region_requirement(
      RegionRequirement(stencil_lr, READ_ONLY, EXCLUSIVE, stencil_lr));
  check_launcher.add_field(0, FID_VAL);
  check_launcher.add_region_requirement(
      RegionRequirement(stencil_lr, READ_ONLY, EXCLUSIVE, stencil_lr));
  check_launcher.add_field(1, FID_DERIV);
  runtime->execute_task(ctx, check_launcher);

  runtime->destroy_logical_region(ctx, stencil_lr);
  runtime->destroy_field_space(ctx, fs);
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

void stencil_task(const Task *task,
                  const std::vector<PhysicalRegion> &regions,
                  Context ctx, Runtime *runtime) {
  assert(regions.size() == 2);
  assert(task->regions.size() == 2);
  assert(task->regions[0].privilege_fields.size() == 1);
  assert(task->regions[1].privilege_fields.size() == 1);
  assert(task->arglen == sizeof(int));
  const int max_elements = *((const int*)task->args);
  const int point = task->index_point.point_data[0];

  FieldID read_fid = *(task->regions[0].privilege_fields.begin());
  FieldID write_fid = *(task->regions[1].privilege_fields.begin());

  const FieldAccessor<READ_ONLY,double,1> read_acc(regions[0], read_fid);
  const FieldAccessor<WRITE_DISCARD,double,1> write_acc(regions[1], write_fid);

  Rect<1> rect = runtime->get_index_space_domain(ctx,
                  task->regions[1].region.get_index_space());
  if ((rect.lo[0] < 2) || (rect.hi[0] > (max_elements-3))) {
    printf("Running slow stencil path for point %d...\n", point);
    for (PointInRectIterator<1> pir(rect); pir(); pir++)
    {
      double l2, l1, r1, r2;
      if (pir[0] < 2)
        l2 = read_acc[0];
      else
        l2 = read_acc[*pir - 2];
      if (pir[0] < 1)
        l1 = read_acc[0];
      else
        l1 = read_acc[*pir - 1];
      if (pir[0] > (max_elements-2))
        r1 = read_acc[max_elements-1];
      else
        r1 = read_acc[*pir + 1];
      if (pir[0] > (max_elements-3))
        r2 = read_acc[max_elements-1];
      else
        r2 = read_acc[*pir + 2];

      double result = (-l2 + 8.0*l1 - 8.0*r1 + r2) / 12.0;
      write_acc[*pir] = result;
    }
  } else {
    printf("Running fast stencil path for point %d...\n", point);
    for (PointInRectIterator<1> pir(rect); pir(); pir++) {
      double l2 = read_acc[*pir - 2];
      double l1 = read_acc[*pir - 1];
      double r1 = read_acc[*pir + 1];
      double r2 = read_acc[*pir + 2];

      double result = (-l2 + 8.0*l1 - 8.0*r1 + r2) / 12.0;
      write_acc[*pir] = result;
    }
  }
}

void check_task(const Task *task,
                const std::vector<PhysicalRegion> &regions,
                Context ctx, Runtime *runtime) {
  assert(regions.size() == 2);
  assert(task->regions.size() == 2);
  assert(task->regions[0].privilege_fields.size() == 1);
  assert(task->regions[1].privilege_fields.size() == 1);
  assert(task->arglen == sizeof(int));
  const int max_elements = *((const int*)task->args);

  FieldID src_fid = *(task->regions[0].privilege_fields.begin());
  FieldID dst_fid = *(task->regions[1].privilege_fields.begin());

  const FieldAccessor<READ_ONLY,double,1> src_acc(regions[0], src_fid);
  const FieldAccessor<READ_ONLY,double,1> dst_acc(regions[1], dst_fid);

  Rect<1> rect = runtime->get_index_space_domain(ctx,
                  task->regions[1].region.get_index_space());

  bool all_passed = true;
  for (PointInRectIterator<1> pir(rect); pir(); pir++) {
    double l2, l1, r1, r2;
    if (pir[0] < 2)
      l2 = src_acc[0];
    else
      l2 = src_acc[*pir - 2];
    if (pir[0] < 1)
      l1 = src_acc[0];
    else
      l1 = src_acc[*pir - 1];
    if (pir[0] > (max_elements-2))
      r1 = src_acc[max_elements-1];
    else
      r1 = src_acc[*pir + 1];
    if (pir[0] > (max_elements-3))
      r2 = src_acc[max_elements-1];
    else
      r2 = src_acc[*pir + 2];

    double expected = (-l2 + 8.0*l1 - 8.0*r1 + r2) / 12.0;
    double received = dst_acc[*pir];
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
    TaskVariantRegistrar registrar(STENCIL_TASK_ID, "stencil");
    registrar.add_constraint(ProcessorConstraint(Processor::LOC_PROC));
    registrar.set_leaf();
    Runtime::preregister_task_variant<stencil_task>(registrar, "stencil");
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
