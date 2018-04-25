---
layout: page
permalink: /tutorial/physical_regions.html
title: Physical Regions
---

Now that we have introduced many of
the necessary features for constructing
Legion programs we can begin
constructing full applications
that make use of logical regions. Starting
with this example, and for most of the
remaining examples, we gradually
refine an implementation of the BLAS
DAXPY routine to introduce new features.
In this section we begin
with a sequential implementation of DAXPY
to show how to create _physical instances_
of logical regions and access data. In
later examples we will show how to extend
this implementation to execute parallel sub-tasks.

#### A Useful Analogy ####

To build intuition before jumping into the
example, we begin by introducing an analogy that we
have found useful when describing the relationship
between logical regions and physical instances to
new Legion users. In many ways the relationship
between logical regions and physical instances
is isomorphic to that of variables and registers
in the C language. A logical region (variable in C)
gives a name to data. This data can be mutated
over time. While a logical region (variable name)
uniquely identifies data, the Legion runtime (C compiler)
can store data in different physical instances (registers)
throughout the execution of the application.

Writing to the Legion runtime API is therefore
analogous to writing inline assembly code in C as
the user is explicitly responsible for managing
the mapping from logical regions (variable names) to
physical instances (registers).

There is also a programming language called
[Regent](http://regent-lang.org/) that makes this easier. Writing in Regent is
analogous to writing in C, as Regent makes no distinction
between logical and physical regions. Instead the
Regent compiler automatically manages the mapping from
logical regions to physical instances just like the
C compiler automatically manages the mapping from a
variable name to different registers. Users targeting
the Legion runtime API should be aware that they
are effectively writing low-level Legion code and
are therefore responsible for managing the mapping
from logical regions to physical instances. We'll
cover how to handle this responsibility in this example.

Interested users can compare the code below to the [equivalent Regent
code](http://regent-lang.org/tutorial/05_physical_regions/) to see how
managing regions differs between the two approaches.

#### Region Strategy ####

To implement DAXPY we'll create two logical
regions with a common index space. One logical
region will store the inputs and the other
will store the results. The input region will
have two fields, one for storing the `X` values
and the other for storing the `Y` values. The
output region will have a single `Z` field for
storing the result of the DAXPY computation.

On lines 31-32 we create a 1D `Rect` to describe
the space of elements and
use it to create an index space. We then
create two field spaces: one for describing
the two input fields (line 33) and one for
describing the output (line 40). In the input
field space `input_fs` we allocate two fields
with field IDs `FID_X` and `FID_Y` which each
hold double-precision floating-point values.
In the output field space `output_fs` we allocate
a single field `FID_Z` for storing the result
of the computation.

After creating the two fields spaces and allocating
fields, we create two logical regions each with
the same index space (lines 46-47). The `input_lr`
and `output_lr` logical regions store the input
and output logical regions respectively. We'll
make use of the same region scheme throughout
all of our remaining DAXPY examples. The next
few sections describe the primary building
blocks of our DAXPY implementation, while the
last section will describe the overall structure
of the application.

#### Physical Instances ####

Having created logical regions for describing our
data, we now want to instantiate _physical instances_
of these regions which we can use for accessing
data. Unlike logical regions which are abstractions
for describing how data is organized and have no
implied placement or layout in the memory hierarchy,
physical instances will have an explicit placement
and layout. (The choice of placement and layout are
made by the mapping process which we cover in a
later example.) Physical instances that are created
are represented by `PhysicalRegion` handles which
we discuss in more detail momentarily.

One common criticism about the Legion C++ runtime
API is there exists a dichotomy between logical
and physical regions which programmers are explicitly
expected to manage. This increases the verbosity
of Legion applications, but is a common artifact
of targeting a runtime API. Regent does not suffer from the same effect as
there are only _regions_ and the compiler automatically
manages the distinction between logical and physical
regions analogous to how sequential
compilers manages the mapping between variables and
hardware registers. This is consistent with the
design principles laid out in our
[Legion overview](/overview/index.html):
the runtime API is designed for expressiveness while
productivity features primarily only appear in Regent.

#### Inline Mappings ####

We now introduce one way to create physical instances
of logical regions using _inline mappings_. (We'll
discuss other ways to create physical instances in
coming examples.) Inline mappings provide a mechanism
for a task to manifest a physical instance of
a logical region directly inline as part of the task's
execution. Performing an inline mapping will give
a task a copy of the data for the specified logical
region consistent with given privileges and
coherence. In this particular DAXPY example, our
first mapping of our logical regions will simply
create an empty physical instances containing space
for the data since the data in the logical regions
has not yet been initialized.

To perform an inline mapping, applications create an
`InlineLauncher` object similar to other launcher
objects for launching tasks (line 53). The argument
passed to the `InlineLauncher` constructor is a
`RegionRequirement` which is used to describe the
logical region requested. `RegionRequirement` objects
are covered in the next section. Once we have have
set up the launcher, we invoke the `map_region`
runtime method and pass the launcher. This call
returns a `PhysicalRegion` handle which represents
the physical instance of the data. In keeping with
Legion's deferred execution model, the `map_region`
call is asynchronous, allowing the application to
issue many operations in flight and perform other
useful work while waiting for the region to be
ready. We describe the interface for `PhysicalRegion`
objects later in this example.

#### Region Requirements ####

`RegionRequirement` objects are used to describe
the logical regions requested by launcher objects as
well as what privileges and coherence are requested
on the specified logical region. On line
49 we create a `RegionRequirement` that requests
the `input_lr` logical region with `READ_WRITE`
privileges and `EXCLUSIVE` coherence. The last
argument specifies the logical region for which
the enclosing parent task has privileges. We
discuss privileges in more detail in the next
example. By default most Legion applications should
use `EXCLUSIVE` coherence. For those interested
in learning more about _relaxed_ coherence we
encourage them to read our
[OOPSLA paper](/publications/index.html) which
covers the semantics of various coherence modes.
After specifying the requested logical region,
`RegionRequirement` objects must also specify
which fields on the logical region to request.
Fields are added by calling the `add_field` method
on the `RegionRequirement` (lines 50-51). There are
many other constructors, methods, and fields
on `RegionRequirement` objects, some of which
we will see in the remaining examples.

#### Physical Regions ####

`PhysicalRegion` objects are handles which name physical
instances. However, similar to `Future` objects
which represent values which need to be completed,
`PhysicalRegion` objects must be explicitly checked
for completion as part of Legion's deferred
execution model. The application can either poll
a `PhysicalRegion` to see if it is complete
using the `is_valid` method or it can explicitly
wait for the physical instance to be ready
by invoking the `wait_until_valid` method (line 55).
Just like waiting for a `Future`, if the physical
instance is not ready the task is preempted
and other tasks may be run while waiting for
the region to be ready. Applications do not need
to explicitly wait for a physical region to
be ready, but any attempt to create a region
_accessor_ (described in the next section) will
implicitly cause the task to wait until the
physical instance contains valid data for the
corresponding logical region to maintain correctness.
This guarantees that the application can only
access the data contained in the physical instance
once the data is valid.

Like other resources applications can
explicitly release physical instances that it
has mapped. We discuss how to explicitly unmap
a `PhysicalRegion` later in this example.
`PhysicalRegion` objects are also reference
counted so when the handles go out of scope references
are removed. If the runtime detects that all
handles to the `PhysicalRegion` have gone out
of scope, it will automatically unmap the
physical instance as well.

#### Region Accessors ####

To access data within a physical region,
an application must create `FieldAccessor` objects.
Physical instances can be laid out in many different
ways including array-of-struct (AOS), struct-of-array
(SOA), and hybrid formats depending on decisions
made as part of the process of mapping a Legion
application. `FieldAccessor` objects provide the
necessary level of indirection to make application
code independent of the selected mapping and therefore
correct under all possible mapping decisions.

`FieldAccessor` objects are tied directly to the
`PhysicalRegion` for which they are created. Once
the physical region is invalidated, either because
it is reclaimed or it is explicitly unmapped by
the application, then all accessors for the physical
instance are also invalidated and any attempt to
re-use them will result in undefined behavior. Each
region accessor is also associated with a specific
field of the physical instance. To build an accessor, invoke the
constructor the physical region and field ID (lines 57-58, 74). Field
accessors are templated on the privilege, field type, and number of
dimensions of the region being used.

The `FieldAccessor` provides an overloaded `operator[]` method (lines
62-63, 78) which can be used to access the data within the region. The
method expects to receive a `Point` with the same number of dimensions
as the region being accessed. For our DAXPY example, we use the
`PointInRectIterator` iterator object to iterate over all the points
in the index space associated with both of our logical regions
whenever we need to access values in our logical regions (lines 60, 77).

We quickly recall an important observation about
points made in a earlier example. Legion
points do not directly reference data, but instead
name an entry in an index space. They are used when
accessing data within accessors for logical regions.
The accessor is specifically associated with the field
being accessed and the point names the row entry.
Since points are associated with index spaces they
can be used with an accessor for physical instance. In
this way Legion points are not tied to memory address
spaces or physical instances, but instead can be used
to access data for any physical instance of a logical
region created with an index space to which the pointer
belongs.

#### Unmapping and Remapping Regions ####

When launching sub-tasks that use logical regions
that alias with the parent task's logical regions, it is
necessary to unmap all physical instances of the aliased
logical regions. Effectively this is the calling convention
for sub-tasks and is analogous to the calling convention
for functions in a C compiler's implementation of its
application-binary interface (ABI). We'll provide a compelling
case when this occurs in the next example.

`PhysicalRegion` objects can be explicitly unmapped using the
`Runtime` method `unmap_region` (line 82). This allows
the application to maintain a handle to the physical instance
in case it decides to remap the region using the
`remap_region` method. The `remap_region` method will
ensure that the exact same physical instance is brought
up to date which does not invalidate any `FieldAccessor`
objects.

The other way of remapping a region is to perform
another inline mapping (possibly with different
privileges or coherence) as we do in this example.
The process of mapping may ultimately create a new
`PhysicalRegion` object which will invalidate all earlier
`FieldAccessor` objects. Attempts to use `FieldAccessor`
objects which have been invalidated will result
in undefined behavior.

#### DAXPY Implementation ####

Having covered the initial components for constructing a
Legion DAXPY application, we can now describe the overall
structure of the application. Lines 20-28 handle command
line arguments and allow programmers to deviate from the
default number of elements by passing a `-n` flag with
the new number of elements to use when creating our
index space. The application then creates the index space,
field spaces, and logical regions (lines 31-47). The
fields for each of the two field spaces are allocated
in lines 35-38 and 42-44.

After the primary resources for DAXPY have been set up, we
first map a physical instance of input region by
performing an inline mapping (lines 49-55). Using
the physical instance that is created we create
accessors for both of the fields in the `input_lr`
logical region (lines 57-58) and iterate over all the
points in the index space to initialize all entries for
both fields with random numbers (lines 60-64).

Having all the necessary data in the input logical
region, we then map the output logical region using
another inline mapping (lines 66-70) and then
create a region accessor (lines 74, note we do
not explicitly wait for the `FieldAccessor` but
instead wait for the runtime to do it for us when
creating the accessor). Having mapping physical instances
of both logical regions, we then perform the DAXPY
computation using a single iterator over the single
index space used to create both logical regions
(lines 77-78).

When the DAXPY computation is complete, we then
unmap the `PhysicalRegion` for the output logical
region and remap it using a new inline mapping
(lines 82-85) to illustrate changing the mapping
privileges from `WRITE_DISCARD` to `READ_ONLY`.
Note that because we performed a new inline
mapping instead of calling `remap_region` we
had to create a new `FieldAccessor` since it
was possible we received a new physical instance
(line 87). We then check the results of our
DAXPY computation to make sure they are correct
and report the result (lines 89-100). Finally,
we clean up our resources (lines 102-106).

Next Example: [Privileges](/tutorial/privileges.html)  
Previous Example: [Logical Regions](/tutorial/logical_regions.html)

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
    for (int i = 1; i < command_args.argc; i++)
    {
      if (!strcmp(command_args.argv[i],"-n"))
        num_elements = atoi(command_args.argv[++i]);
    }
  }
  printf("Running daxpy for %d elements...\n", num_elements);

  Rect<1> elem_rect(0,num_elements-1);
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

  RegionRequirement req(input_lr, READ_WRITE, EXCLUSIVE, input_lr);
  req.add_field(FID_X);
  req.add_field(FID_Y);

  InlineLauncher input_launcher(req);
  PhysicalRegion input_region = runtime->map_region(ctx, input_launcher);
  input_region.wait_until_valid();

  const FieldAccessor<READ_WRITE,double,1> acc_x(input_region, FID_X);
  const FieldAccessor<READ_WRITE,double,1> acc_y(input_region, FID_Y);

  for (PointInRectIterator<1> pir(elem_rect); pir(); pir++)
  {
    acc_x[*pir] = drand48();
    acc_y[*pir] = drand48();
  }

  InlineLauncher output_launcher(RegionRequirement(output_lr, WRITE_DISCARD,
                                                   EXCLUSIVE, output_lr));
  output_launcher.requirement.add_field(FID_Z);

  PhysicalRegion output_region = runtime->map_region(ctx, output_launcher);

  const double alpha = drand48();
  {
    const FieldAccessor<WRITE_DISCARD,double,1> acc_z(output_region, FID_Z);

    printf("Running daxpy computation with alpha %.8g...", alpha);
    for (PointInRectIterator<1> pir(elem_rect); pir(); pir++)
      acc_z[*pir] = alpha * acc_x[*pir] + acc_y[*pir];
  }
  printf("Done!\n");

  runtime->unmap_region(ctx, output_region);

  output_launcher.requirement.privilege = READ_ONLY;
  output_region = runtime->map_region(ctx, output_launcher);

  const FieldAccessor<READ_ONLY,double,1> acc_z(output_region, FID_Z);

  printf("Checking results...");
  bool all_passed = true;
  for (PointInRectIterator<1> pir(elem_rect); pir(); pir++) {
    double expected = alpha * acc_x[*pir] + acc_y[*pir];
    double received = acc_z[*pir];
    if (expected != received)
      all_passed = false;
  }
  if (all_passed)
    printf("SUCCESS!\n");
  else
    printf("FAILURE!\n");

  runtime->destroy_logical_region(ctx, input_lr);
  runtime->destroy_logical_region(ctx, output_lr);
  runtime->destroy_field_space(ctx, input_fs);
  runtime->destroy_field_space(ctx, output_fs);
  runtime->destroy_index_space(ctx, is);
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
