---
layout: page
permalink: /tutorial/logical_regions.html
title: Logical Regions
---

*Logical regions* are the core Legion abstraction for
data. Conceptually, a logical region can be thought of as being like a
relation or table in a database. In Legion, a logical region is
defined as the cross product between an *index space* and a *field
space*. These terms will be defined in this tutorial. The next example
will show how how to access data in logical regions by making
*physical instances* of those regions.

#### Index Spaces ####

If a logical region is a table, then the index space for that region
is the set of rows in the table. Or to be more precise: rows are
implicitly (or explicitly) assigned numbers, or indices, and the index
space is the set of these indices.

Indices can be plain numbers, or they can be multi-dimensional (2-D,
3-D, etc.). Thus the set of points in an index space are bounded by
a `Rect` templated on the dimensionality of the space.

As with `Rect` and `Domain`, which were introduced in the [index space
example](/tutorial/index_tasks.html), it can be useful to describe an
index space where the number of dimensions is not known at compile
time. This is simply called `IndexSpace`. The templated variant is
called `IndexSpaceT`.

Index spaces are created by invoking one of several overloaded
variants of the `create_index_space` method of `Runtime`. This returns
an `IndexSpace` or `IndexSpaceT` depending on whether the provided
argument is a `Domain` or `Rect`. Examples of these calls can be seen
on lines 20 and 24.

Index spaces are immutable. The set of points contained in an index
space cannot be modified after creation. Instead, index spaces can be
*partitioned* to create a number of subspaces that contain subsets of
the points of the parent space. This is covered in a subsequent
tutorial.

Note that in particular, partitioning can result in an index space
that is *sparse*, i.e. where the set of points contained in the space
cannot be accurately described by a bounding rectangle. Sparse index
spaces can also be created directly by creating an index space from
a set of rectangles or a set of points. These calls are documented
in the API but are not demonstrated here. We walso cover how to 
partition index spaces into subspaces in a 
[subsequent tutorial](/tutorial/partitioning.html).

Legion provides a number of API calls that can be used to retrieve
information about an index space, such as the `Domain` or `Rect` that
was used to create it. Lines 28 and 31 show examples of
such calls.

#### Field Spaces ####

If index spaces describe the rows in a logical region, then field
spaces describe the columns.

Field spaces are created using the `create_field_space` method of
`Runtime` (line 34).

Field spaces are created empty. Fields in a field space are
dynamically allocated and freed using a `FieldAllocator` object (line
37). For performance reasons there is a compile-time upper bound
placed on the maximum number of fields that can be allocated in a
single field space. The user has access to this compile-time limit and
can modify it by changing the value assigned to `MAX_FIELDS` in the
`legion_config.h` header file (the default is 512). If a program attempts 
to exceed this maximum then the Legion runtime will report an error and 
exit. There is no limit on the number of field spaces that can be created 
in a Legion program and therefore the total number of fields in an
application is unbounded.

Fields are allocated by invoking the `allocate_field`
method of `FieldAllocator` (lines 38 and 40). When a
field is allocated the application must specify
the size of the field in bytes.
The `allocate_field` method will return a `FieldID`
which is used to name the field. Users may optionally
specify the ID to be associated with the field being
allocated using the second parameter to `allocate_field`.
If this is done, then it is the responsibility of the
user to ensure that each `FieldID` is used only once
for a each field space. Legion supports parallel field
allocation in the same field space by different tasks,
but undefined behavior will result if the same `FieldID`
is allocated in the same field space by two different tasks.

Currently Legion assumes that the data stored by fields is
trivially copyable. If this is not the case, users can also
register custom serialize/deserialize or _serdez_ functors
with the runtime to aid in copying data in certain fields.
The `allocate_field` method allows users to specify the ID
for one of these functors if the data stored in the field
is not trivally copyable.

#### Logical Regions ####

Logical regions are created by passing an index space and a field
space to the `create_logical_region` method of `Runtime` (lines 46 and
53). As with index spaces, logical regions can either contain a
dynamic number of dimensions (`LogicalRegion`) or a templated number
(`LogicalRegionT`).

Note that, in the example, because both logical regions are created
using the same field space, any fields allocated in that field space
will be available on both logical regions. Similarly, any logical
regions allocated with the same index space will have the same set of
points associated with entries in the region.

Every call to `create_logical_region` will create a new logical region
even when the same index space and field space are passed as arguments
(as seen in lines 60-61). Logical regions are uniquely defined by a
triple consisting of the index space, field space, and _region tree
ID_. These three values for every logical region can be obtained using
the methods `get_index_space` (line 48), `get_field_space` (line 49),
and `get_tree_id` (line 50). Line 61 demonstrates that the two logical
regions have different region tree IDs.

#### Resource Reclamation ####

Index spaces, field spaces, and logical regions are all resources that
use memory. (Although index spaces and field spaces have no memory
directly associated with them, there is still a cost to the metadata
that is allocated.) When applications are done using
resources they should be returned to the runtime.
The `destroy_logical_region` (line 63-65), `destroy_field_space`
(line 66), and `destroy_index_space` (line 67-68) methods
are used to return logical regions, field spaces,
and index spaces to the runtime respectively. Since
Legion operates with a deferred execution model, the
runtime is smart enough to know how to defer deletions
until they are safe to perform. This means that users
do not need to wait for tasks that use logical regions
to finish before issuing deletions commands to
reclaim resources.

If a task neglects to delete a logical region that it created (or
index or field space), it will implicitly flow up to the parent task
that called it. Thus, it will not be automatically deleted when the
task finishes.

`FieldAllocator` objects are also
resources, but, are similar to `Future` objects, in that they
are reference counted. When the objects go out of the scope
the destructor is invoked and references are removed. The use of the
explicit C++ scope at line 36 is to ensure that the allocator is
reclaimed as soon as it is done being used.

Next Example: [Physical Regions](/tutorial/physical_regions.html)  
Previous Example: [Hybrid Model](/tutorial/hybrid.html)

{% highlight cpp linenos %}
#include <cstdio>
#include <cassert>
#include <cstdlib>
#include "legion.h"
using namespace Legion;

enum TaskIDs {
  TOP_LEVEL_TASK_ID,
};

enum FieldIDs {
  FID_FIELD_A,
  FID_FIELD_B,
};

void top_level_task(const Task *task,
                    const std::vector<PhysicalRegion> &regions,
                    Context ctx, Runtime *runtime) {
  const Domain domain(DomainPoint(0), DomainPoint(1023));
  IndexSpace untyped_is = runtime->create_index_space(ctx, domain);
  printf("Created untyped index space %x\n", untyped_is.get_id());

  const Rect<1> rect(0,1023);
  IndexSpaceT<1> typed_is = runtime->create_index_space(ctx, rect);
  printf("Created typed index space %x\n", typed_is.get_id());

  {
    Domain orig_domain = runtime->get_index_space_domain(ctx, untyped_is);
    assert(orig_domain == domain);
    Rect<1> orig_rect = runtime->get_index_space_domain(ctx, typed_is);
    assert(orig_rect == rect);
  }

  FieldSpace fs = runtime->create_field_space(ctx);
  printf("Created field space field space %x\n", fs.get_id());
  {
    FieldAllocator allocator = runtime->create_field_allocator(ctx, fs);
    FieldID fida = allocator.allocate_field(sizeof(double), FID_FIELD_A);
    assert(fida == FID_FIELD_A);
    FieldID fidb = allocator.allocate_field(sizeof(int), FID_FIELD_B);
    assert(fidb == FID_FIELD_B);
    printf("Allocated two fields with Field IDs %d and %d\n", fida, fidb);
  }

  LogicalRegion untyped_lr =
    runtime->create_logical_region(ctx, untyped_is, fs);
  printf("Created untyped logical region (%x,%x,%x)\n",
      untyped_lr.get_index_space().get_id(),
      untyped_lr.get_field_space().get_id(),
      untyped_lr.get_tree_id());

  LogicalRegionT<1> typed_lr =
    runtime->create_logical_region(ctx, typed_is, fs);
  printf("Created typed logical region (%x,%x,%x)\n",
      typed_lr.get_index_space().get_id(),
      typed_lr.get_field_space().get_id(),
      typed_lr.get_tree_id());

  LogicalRegion no_clone_lr =
    runtime->create_logical_region(ctx, typed_is, fs);
  assert(typed_lr.get_tree_id() != no_clone_lr.get_tree_id());

  runtime->destroy_logical_region(ctx, untyped_lr);
  runtime->destroy_logical_region(ctx, typed_lr);
  runtime->destroy_logical_region(ctx, no_clone_lr);
  runtime->destroy_field_space(ctx, fs);
  runtime->destroy_index_space(ctx, untyped_is);
  runtime->destroy_index_space(ctx, typed_is);
  printf("Successfully cleaned up all of our resources\n");
}

int main(int argc, char **argv) {
  Runtime::set_top_level_task_id(TOP_LEVEL_TASK_ID);

  {
    TaskVariantRegistrar registrar(TOP_LEVEL_TASK_ID, "top_level");
    registrar.add_constraint(ProcessorConstraint(Processor::LOC_PROC));
    Runtime::preregister_task_variant<top_level_task>(registrar, "top_level");
  }

  return Runtime::start(argc, argv);
}
{% endhighlight %}
