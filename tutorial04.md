---
layout: page
permalink: /tutorial/logical_regions.html
title: Logical Regions
---

Logical regions are the core abstraction in
Legion since they provide the mechanism for
describing the structure of program data.
Logical regions are constructed by taking
the cross product of an index space with a
field space. This example shows how to create
index spaces, field spaces, and logical
regions. It also shows how to dynamically
allocate and free both elements in index spaces
and fields in field spaces. The next example
will show how create physical instances of
logical regions and how to access data.

#### Index Spaces ####

Index spaces are the Legion abstraction used
for describing row entries in logical regions.
Index spaces are created by invoking one of
several overloaded variants of the
`create_index_space` method on an instance
of the `HighLevelRuntime`. All versions of
the `create_index_space` method return an
`IndexSpace` handle that is used for referencing
the index space.

Users can create both _structured_ and
_unstructured_ index spaces. Structured index
spaces are created from `Rect` objects which
were introduced in the
[index space example](/tutorial/index_tasks.html).
An example of creating a structured index space
can be seen on lines 23-24 where we pass the task's
context and a 1-D `Rect` to the runtime and get
back a handle to the index space.

Users can also create unstructured index spaces
by calling `create_index_space` with the task's
context and an upper bound on the number of
elements that may be allocated in the index
space (line 19). We realize that specifying an
upper bound on elements is mildly restrictive
but it significantly simplifies and improves
the performance of the Legion runtime implementation.
Furthermore, most applications usually have an
approximation of how large data set sizes are,
or can specify it using an input parameters. We
would be interested in hearing of a sufficiently
compelling example where a truly unbounded number
of elements is necessary.

By default all structured index spaces are immutable
and have all of their points allocated. Alternatively,
unstructured index spaces have no points allocated,
but can dynamically allocate and free points using
`IndexAllocator` objects. `IndexAllocator` objects
must be obtained from the runtime using the
`create_index_allocator` method (lines 27-28).
Allocators can be used to allocate or free elements.
They return `ptr_t` elements which are Legion's
untyped pointer type. Pointers in a Legion are opaque
and have no data associated with them. Instead they
are used for naming the rows in logical regions which
are created using the corresponding index space.
We show how to use pointers in conjunction with
logical regions in the next example. In this example
we use our `IndexAllocator` object to allocate
all of the possible points in the unstructured
index space (line 29).

For structured index spaces, the Legion runtime
remembers the `Domain` used to create the index
space. This information can be retrieved from
the runtime using the `get_index_space_domain`
method call (line 35). Recall from earlier
examples that `Domain` objects can then be
converted back into dimensionalized `Rect`
objects using the templated `get_rect` method
on `Domain` objects (line 36).

#### Field Spaces ####

Field spaces are the abstraction that Legion uses
for describing the column entries in a logical
region. Field spaces are created using the
`create_field_space` method on a `HighLevelRuntime`
instance (line 40).

By default no fields are allocated inside of a
field space. Fields are dynamically allocated
and freed in field spaces using `FieldAllocator`
objects which are analogous to `IndexAllocator`
objects for index spaces (line 43). For performance
reasons there is a compile-time upper bound placed on
the maximum number of fields that can be allocated
in a field space. The user has access to this
compile-time limit and can modify it by changing
the value assigned to `MAX_FIELDS` in the
legion_types.h header file. If a program attempts
to exceed this maximum then the Legion runtime
will report an error and exit. There is no limit
on the number of field spaces that can be created
in a Legion program and therefore the total number
of fields in an application is unbounded.

Fields are allocated by invoking the `allocate_field`
method on a `FieldAllocator` (line 44). When a
field is allocated the application must specify
the required data size for a field entry in bytes.
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

#### Logical Regions ####

Logical regions are created by passing an index space
and a field space to the `create_logical_region` method
on a `HighLevelRuntime` instance (lines 51-52). Logical
regions can be created using both unstructured (line 52)
and structured (line 59) index spaces. Note that because both logical
regions are created using the same field space, any fields
allocated in that field space will be available on both
logical regions. Similarly, any logical regions allocated
with the same index space will have the same set of points
associated with row entries.

Every call to `create_logical_region` will create a new
logical region even when the same index space and field
space are passed as arguments. Logical regions are
uniquely defined by a triple consisting of the index
space, field space, and _region tree ID_. These three
values for every logical region can be obtained using
the `get_index_space` (line 54), `get_field_space`
(line 55), and  `get_tree_id` (line 56) methods
on `LogicalRegion` types. On lines 65-66 we create
a second logical region using the structured index
space with the same field space and then on line 67
show that it has a different region tree ID than
the first structured logical region.

#### Resource Reclamation ####

Index spaces, field spaces, and logical regions are all
resources that the Legion runtime makes available to
applications. When applications are done using
resources they should be returned to the runtime.
The `destroy_logical_region` (line 69), `destroy_field_space`
(line 72), and `destroy_index_space` (line 73) methods
are used to return logical regions, field spaces,
and index spaces to the runtime respectively. Since
Legion operates with a deferred execution model, the
runtime is smart enough to know how to defer deletions
until they are safe to perform. This means that users
do not need to wait for tasks that use logical regions
to finish before issuing deletions commands to
reclaim resources.

`IndexAllocator` and `FieldAllocator` objects are also
resources, but, are similar to `Future` objects, in that they
are reference counted. When the objects go out of the scope
the destructor is invoked and references are removed. This is
why allocators are placed in explicit C++ scopes so that
the resources are reclaimed as soon as they are done being
used (lines 26-33 and 42-49).

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
