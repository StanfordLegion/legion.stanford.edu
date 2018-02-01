---
layout: page
permalink: /tutorial/index_tasks.html
title: Index Space Tasks
---

This example illustrates how to launch a large
number of _non-interfering_ tasks in Legion using
a single _index space_ task launch. (We discuss
what it means to be non-interfering in a later example.)
It also describes the basic Legion types for arrays,
domains, and points and gives examples of how they work.

#### Rectangles and Domains ####

To aid in describing structured data, Legion supports
a `Rect` type which is used to describe an arbitrary-dimensional
dense arrays of points. `Rect` types are templated on the number
of dimensions that they describe. To specify a `Rect` a
user gives two `Point` objects which specify the lower and
upper bounds in all dimensions respectively. Similar to
the `Rect` type, a `Point` type is templated on the
number of dimensions it stores. In this example we create
a 1-D `Rect` for which we'll launch an array of tasks
with one task per point (line 29). Note that the
bounds on `Rect` objects are inclusive.

It can be useful to be able to refer to a rectangle where the number
of dimensions is not known at compile time. The `Domain` class is used
for this purpose. While we do not use `Domain` in this example, and
Legion runtime calls almost always accept `Rect`, you may see this
in Legion code in the wild.

#### Argument and Future Maps ####

When launching a large set of tasks in a single
call, we may want to pass different arguments to each
task. `ArgumentMap` types allow the user to pass
different `TaskArgument` values to tasks associated
with different points. `ArgumentMap` types do not
need to specify arguments for all points. Legion
is intelligent about only passing arguments to tasks
which have arguments assigned. In this example we
create an `ArgumentMap` (line 31) and then pass in
different integer arguments associated with each
point (lines 32-35).

Legion also provides `FutureMap` types as a mechanism
for managing the many return values that are returned
from an index space task launch. `FutureMap` objects
store a future value for every point in the index
space task launch. Applications can either wait on the
`FutureMap` for all tasks in the index space launch
to complete, or it can extract individual `Future`
objects associated with specific points in the
index space task launch.

In this example we wait for all the point tasks in
the index space task launch using the `wait_all_results`
method (line 43). We then extract individual future
values for each point and check that each returned
value matches the expected result (lines 45-55).
Even though we use the `get_result` method on the
`Future` objects, we know that the values will
be immediately ready because we already waited
for all the point tasks to complete.

#### Index Space Launches ####

Index space tasks are launched in a similar manner to
individual tasks using a launcher object which has
the type `IndexLauncher` (lines 37-40). `IndexLauncher` objects take
some of the same arguments as `TaskLauncher` objects
such as the ID of the task to launch and a `TaskArgument`
which is passed by value as a global argument to all
the points in the index space launch. The `IndexLauncher`
objects also take the additional arguments of an
`ArgumentMap` and a `Rect` which describes the set
of tasks to create (one for each point). Index space
tasks are launched the same as single tasks, but
return a `FutureMap` (line 42). Just like individual tasks,
index space task launches are performed asynchronously.

#### Index Space Tasks ####

Index space tasks are registered the same as single
tasks.

Additional fields on the `Task` object are defined
when executing as an index space task. First, the
`index_space_task` field is set to true. Next,
index space tasks can find the point they are responsible
for executing in the `index_point` field. The `index_point`
field is a `DomainPoint` which is the general form of a
`Point` type. Lines 61-62 show how a task can make
use of the `index_point` field. Finally, the `local_arglen`
and `local_arg` fields contain the `TaskArgument` values
passed in to the `ArgumentMap` for the given task's
point (if any existed). In lines 63-65, the application
does some simple computation on the input value and then
returns it. The resulting value is set in the `Future`
for the corresponding point in the `FutureMap`.

Next Example: [Hybrid Model](/tutorial/hybrid.html)  
Previous Example: [Tasks and Futures](/tutorial/tasks_and_futures.html)

{% highlight cpp linenos %}#include <cstdio>
#include <cassert>
#include <cstdlib>
#include "legion.h"
using namespace Legion;

enum TaskIDs {
  TOP_LEVEL_TASK_ID,
  INDEX_SPACE_TASK_ID,
};

void top_level_task(const Task *task,
                    const std::vector<PhysicalRegion> &regions,
                    Context ctx, Runtime *runtime) {
  int num_points = 4;
  const InputArgs &command_args = Runtime::get_input_args();
  for (int i = 1; i < command_args.argc; i++) {
    if (command_args.argv[i][0] == '-') {
      i++;
      continue;
    }

    num_points = atoi(command_args.argv[i]);
    assert(num_points > 0);
    break;
  }
  printf("Running hello world redux for %d points...\n", num_points);

  Rect<1> launch_bounds(0,num_points-1);

  ArgumentMap arg_map;
  for (int i = 0; i < num_points; i++) {
    int input = i + 10;
    arg_map.set_point(i, TaskArgument(&input, sizeof(input)));
  }

  IndexLauncher index_launcher(INDEX_SPACE_TASK_ID,
                               launch_bounds,
                               TaskArgument(NULL, 0),
                               arg_map);

  FutureMap fm = runtime->execute_index_space(ctx, index_launcher);
  fm.wait_all_results();

  bool all_passed = true;
  for (int i = 0; i < num_points; i++) {
    int expected = 2*(i+10);
    int received = fm.get_result<int>(i);
    if (expected != received) {
      printf("Check failed for point %d: %d != %d\n", i, expected, received);
      all_passed = false;
    }
  }
  if (all_passed)
    printf("All checks passed!\n");
}

int index_space_task(const Task *task,
                     const std::vector<PhysicalRegion> &regions,
                     Context ctx, Runtime *runtime) {
  assert(task->index_point.get_dim() == 1);
  printf("Hello world from task %lld!\n", task->index_point.point_data[0]);
  assert(task->local_arglen == sizeof(int));
  int input = *((const int*)task->local_args);
  return (2*input);
}

int main(int argc, char **argv) {
  Runtime::set_top_level_task_id(TOP_LEVEL_TASK_ID);

  {
    TaskVariantRegistrar registrar(TOP_LEVEL_TASK_ID, "top_level");
    registrar.add_constraint(ProcessorConstraint(Processor::LOC_PROC));
    Runtime::preregister_task_variant<top_level_task>(registrar, "top_level");
  }

  {
    TaskVariantRegistrar registrar(INDEX_SPACE_TASK_ID, "index_space_task");
    registrar.add_constraint(ProcessorConstraint(Processor::LOC_PROC));
    registrar.set_leaf();
    Runtime::preregister_task_variant<int, index_space_task>(registrar, "index_space_task");
  }

  return Runtime::start(argc, argv);
}
{% endhighlight %}
