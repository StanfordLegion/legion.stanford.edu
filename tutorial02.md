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
with one task per point (line 23). Note that the 
bounds on `Rect` objects are inclusive.

`Rect` objects can be converted to `Domain` objects.
`Domain` objects are a more general type for representing
sets of points regardless of whether the sets are
sparse or dense and independent of the number of dimensions.
Users can easily convert between `Domain` and `Rect` types
using the `from_rect` and `get_rect` methods (line 24).
Most Legion runtime calls take `Domain` types as arguments,
but it often helps in application code to have type 
checking support on the number of dimensions.

#### Argument and Future Maps ####

When launching a large set of tasks in a single
call, we may want to pass different arguments to each
task. `ArgumentMap` types allow the user to pass
different `TaskArgument` values to tasks associated
with different points. `ArgumentMap` types do not
need to specify arguments for all points. Legion
is intelligent about only passing arguments to tasks
which have arguments assigned. In this example we
create an `ArgumentMap` (line 26) and then pass in
different integer arguments associated with each
point (lines 27-31).

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
method (line 39). We then extract individual future
values for each point and check that each returned
value matches the expected result (lines 41-51). 
Even though we use the `get_result` method on the
`Future` objects, we know that the values will
be immediately ready because we already waited
for all the point tasks to complete.

#### Index Space Launches ####

Index space tasks are launched in a similar manner to
individual tasks using a launcher object which has
the type `IndexLauncher` (lines 33-36). `IndexLauncher` objects take
some of the same arguments as `TaskLauncher` objects
such as the ID of the task to launch and a `TaskArgument`
which is passed by value as a global argument to all
the points in the index space launch. The `IndexLauncher`
objects also take the additional arguments of an
`ArgumentMap` and a `Domain` which describes the set
of tasks to create (one for each point). Index space 
tasks are launched the same as single tasks, but 
return a `FutureMap` (line 38). Just like individual tasks, 
index space task launches are performed asynchronously.

#### Index Space Tasks ####

Index space tasks are registered the same as single
tasks but indicate using a boolean that they
can be launched as an index space task (line 69).
If an application attempts to launch an index space
task with a task ID which has not be registered for
index space task launches then a runtime error will
be raised.

Additional fields on the `Task` object are defined
when executing as an index space task. First, the 
`index_space_task` field is set to true. Next, 
index space tasks can find the point they are responsible
for executing in the `index_point` field. The `index_point`
field is a `DomainPoint` which is general form of a
`Point` type. Lines 57-58 show how a task can make
use of the `index_point` field. Finally, the `local_arglen`
and `local_arg` fields contain the `TaskArgument` values
passed in to the `ArgumentMap` for the given task's
point (if any existed). In lines 59-61, the application
does some simple computation on the input value and then
returns it. The resulting value is set in the `Future`
for the corresponding point in the `FutureMap`.

<br/>
Next Example: [Hybrid Model](/tutorial/hybrid.html)
<br/>
Previous Example: [Tasks and Futures](/tutorial/tasks_and_futures.html)

{% highlight cpp linenos %}#include <cstdio>
#include <cassert>
#include <cstdlib>
#include "legion.h"
using namespace LegionRuntime::HighLevel;

enum TaskIDs {
  TOP_LEVEL_TASK_ID,
  HELLO_WORLD_INDEX_ID,
};

void top_level_task(const Task *task,
                    const std::vector<PhysicalRegion> &regions,
                    Context ctx, HighLevelRuntime *runtime) {
  int num_points = 4;
  const InputArgs &command_args = HighLevelRuntime::get_input_args();
  if (command_args.argc > 1) {
    num_points = atoi(command_args.argv[1]);
    assert(num_points > 0);
  }
  printf("Running hello world redux for %d points...\n", num_points);

  Rect<1> launch_bounds(Point<1>(0),Point<1>(num_points-1));
  Domain launch_domain = Domain::from_rect<1>(launch_bounds);

  ArgumentMap arg_map;
  for (int i = 0; i < num_points; i++) {
    int input = i + 10;
    arg_map.set_point(DomainPoint::from_point<1>(Point<1>(i)),
        TaskArgument(&input,sizeof(input)));
  }

  IndexLauncher index_launcher(HELLO_WORLD_INDEX_ID,
                               launch_domain,
                               TaskArgument(NULL, 0),
                               arg_map);

  FutureMap fm = runtime->execute_index_space(ctx, index_launcher);
  fm.wait_all_results();

  bool all_passed = true;
  for (int i = 0; i < num_points; i++) {
    int expected = 2*(i+10);
    int received = fm.get_result<int>(DomainPoint::from_point<1>(Point<1>(i)));
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
                     Context ctx, HighLevelRuntime *runtime) {
  assert(task->index_point.get_dim() == 1); 
  printf("Hello world from task %d!\n", task->index_point.point_data[0]);
  assert(task->local_arglen == sizeof(int));
  int input = *((const int*)task->local_args);
  return (2*input);
}

int main(int argc, char **argv) {
  HighLevelRuntime::set_top_level_task_id(TOP_LEVEL_TASK_ID);
  HighLevelRuntime::register_legion_task<top_level_task>(TOP_LEVEL_TASK_ID,
      Processor::LOC_PROC, true/*single*/, false/*index*/);
  HighLevelRuntime::register_legion_task<int, index_space_task>(HELLO_WORLD_INDEX_ID,
      Processor::LOC_PROC, false/*single*/, true/*index*/);

  return HighLevelRuntime::start(argc, argv);
}
{% endhighlight %}
