---
layout: page
permalink: /tutorial/tasks_and_futures.html
title: Tasks and Futures
---

In this example, we'll introduce task launches and futures
in Legion. To do so, we'll implement a simple program to 
compute the first `N` Fibonacci numbers. We note this is
not the fastest way to compute Fibonacci numbers, but it
will demonstrate the functional nature of Legion tasks 
as well as the ability to recursively spawn tasks.
Code for this example is at the bottom of the page and
can also be found in the `tutorial` directory of the 
Legion repository.

#### Registering Tasks Redux ####

For our Fibonacci program we'll register three different
tasks: a top-level task, a task for performing the 
recursive Fibonacci computation, and a helper task for
summing futures. Both the Fibonacci and sum tasks
will return an integer value and therefore require a
slightly modified registration call. For
tasks which have non-`void` return types
the `preregister_task_variant` is templated first on the
return type (`int` in this case) followed by function 
pointer for the task. Lines 97 and 104 show
the `preregister_task_variant` calls for these tasks.

The registration for the summation task on lines 101-104
also illustrates several new parameters which can be
passed when registering a task with the Legion runtime.
First, Legion allows applications to register multiple,
functionally equivalent _variants_ of a task. The optional
third parameter to `preregister_task_variant` allows the
application to specify the `VariantID` for the task. The
default value is `AUTO_GENERATE_ID` which instructs the
runtime to pick an un-used `VariantID` and return the 
chosen ID from the registration call.

A number of additional methods of `TaskVariantRegistrar` allow further
customization of the task. In this example, we use `set_leaf(true)` to
mark `sum_task` as being a _leaf_ task that launches no sub-tasks
or other Legion operations in its implementation. Knowing that 
the `sum_task` is a leaf task allows the Legion runtime to 
optimize the execution of the task.

#### Command Line Arguments ####

For our Legion implementation of Fibonacci, we want to be
able to pass a command line argument that specifies
the number of Fibonacci numbers to compute. The Legion
runtime makes the command line arguments available
via a static method `get_input_args` on the `Runtime`
class. This returns an immutable reference to an
`InputArgs` struct which describes the original command
line arguments to the application. Even in distributed
applications, Legion will make the command line arguments
available on all nodes so they can be accessed in any task 
at any time. Lines 17-28 show how the the command line arguments
are parsed in our Fibonacci program.

#### Launching Tasks ####

All Legion tasks are spawned using a _launcher_ object (except the
top-level task which is launched automatically by the runtime as
was described in the [previous example]({{ "/tutorial/hello_world.html" | relative_url }}) ).
To spawn a single task, we use a `TaskLauncher` object. A
`TaskLauncher` is a struct used for specifying the arguments
necessary for launching a task. Launchers contain many
fields which we will explore throughout this tutorial. Here
we look at the first two arguments of `TaskLauncher`:

* ID - the registered ID of the task to be launched
* argument - pass-by-value input to the task

The second field has type `TaskArgument` which points to
a buffer and specifies the size in bytes to copy by value
from the buffer. This copy of this buffer does not actually 
take place until the launcher object is passed to the 
`execute_task` call. If there is more than one argument it 
is the responsibility of the application to pack the values 
into a single buffer.

Launching a task simply requires passing a `TaskLauncher`
object and a context to the Legion runtime via the 
`execute_task` call. The context object is an opaque handle
that is passed by the runtime as an argument to the enclosing parent task.
Legion task launches (like most Legion API calls) are 
asynchronous which means that the call returns immediately.
As a place holder for the return value of the task, the
Legion runtime returns a `Future` which we describe in
the next section. Note that launcher objects can be re-used
to launch as many tasks as desired and can be modified for
the next task launch immediately once the preceding
`execute_task` call returns.

There are several examples of task launches in the Fibonacci
example. We call attention to the one in the `for` loop on
lines 32-35. We create a launcher in our top-level task
which launches one sub-task for each Fibonacci number that
we want to compute. Each launcher is assigned the 
`FIBONACCI_TASK_ID` as the task ID and passes an integer
describing the Fibonacci number to be computed in the
`TaskArgument` field. We store the resulting `Future` value
that is returned in a vector.

#### Futures ####

Futures are objects which represent a pending return value
from a task. There are two ways to use future values. First,
applications can explicitly request the value of the future
using the `get_result` method as can be seen on line 38. The
`get_result` method is templated on the type of the return
value which instructs the Legion runtime how to interpret the
bits being returned. This is a blocking call which will cause 
the task in which it is executed to pause until the sub-task 
which is completing the future returns. We discourage users
from using futures in this way for reasons described in the
section on [performance considerations](#performance-considerations).

There is a second way of using futures which does not require
blocking to wait for future values. In our Fibonacci task,
rather than waiting for the two Future values, we instead
launch a sum task which will compute the sum of the two futures.
Notice that the we can explicitly pass the futures as a special
kind of argument in the `TaskLauncher` object on lines 66-67.
Legion will ensure that the sum task does not begin until both
futures are complete and the future values are available
wherever the sum task is mapped. Future values should always
be explicitly passed in this manner and should never be 
passed through a `TaskArgument` object.

#### Task Arguments and Return Values ####

Task arguments that are passed in through the `TaskArgument` 
field in a launcher object are available in a Legion task through
the `args` and `arglen` fields on the `Task` object. The
`Task` type is the common interface that Legion presents to
both the application and mappers for describing tasks. Lines 48-49
show the Fibonacci task extracting its arguments from the `Task`
object. Since there is no type checking when using the runtime
API (a benefit provided by the Regent compiler) we encourage
applications to explicitly check that they are getting the
arguments that they expect when unpacking them from the `Task`
object before casting them.

Return values from tasks are returned in the same way as
standard C functions. The Legion runtime will automatically 
use the returned value to complete the Future that was 
created when the task was launched. In most cases the values
returned are passed by value. However, if the type of the
return value defines the methods `legion_buffer_size`,
`legion_serialize`, and `legion_deserializer`, then 
Legion automatically will invoke them to support deep
copies of more complex data types (see the `ColoringSerializer`
class in `legion.h` for an example).

The `Future` type is not permitted as return value
for a task. Attempting to do so will result in a 
compile-time assertion failure. Futures are not allowed
to escape the context in which they are created. Instead
applications should explicitly get the value of the
Future and return it directly as is done at the end of
the Fibonacci task on line 70. There virtually no
performance penalty for blocking at the very end of a task.

#### Performance Considerations ####

Legion applications should maximize the number of task 
launches performed prior to making any blocking calls 
such as waiting on futures. By doing so applications
increase the number of tasks visible to the Legion runtime
allowing the Legion runtime to discover as much task-level
parallelism as possible. This technique is visible in two
places in our Fibonacci example. First, in the top-level
task we launch sub-tasks for computing each Fibonacci
number and store future values in a vector prior to 
computing only one Fibonacci number at a time. Second,
in the implementation of our Fibonacci task, we launch
both sub-tasks and the sum task prior to waiting on
the value of the sum task.

While waiting on a future blocks a task's execution
and limits the task-level parallelism that Legion can
discover, it does not block the processor on which 
the task is executing. If additional tasks have been 
mapped onto the same processor and are ready to execute, 
then the Legion runtime will begin executing them
immediately after a blocking call is made on the 
future. After each additional task finishes executing
the runtime tests to see if the future is complete.
If it is, then the initial task is restarted, otherwise
a new task (if available) is started. If the additional
tasks also block on a future, the process is repeatedly
recursively. This approach keeps the underlying hardware 
utilized and maximizes overall task throughput.

In the sum task we invoke the `get_result` method on
the two futures passed as arguments (lines 78 and 80).
Since these futures are passed explicitly, the Legion 
runtime will not start the sum task until both these 
futures have completed. Invoking `get_result` on futures 
that are explicitly passed as arguments will never block
a task's execution.

Finally, `Future` objects are handles for actual
futures and are therefore inexpensive to pass by value.
Since futures are used both by the application and the
runtime we reference count them and automatically 
delete their resource when there are no longer any
references. The `Future` type is actually a light-weight
handle which simply contains a pointer to the actual
future implementation, which makes copying future
values inexpensive. Line 42 explicitly clears the future
vector which will invoke the `Future` destructor on
all the future values and remove references. This would
have occurred automatically when the vector went out of
scope, but we do so explicitly to show the users have
control over when references are removed.

Next Example: [Index Space Tasks]({{ "/tutorial/index_tasks.html" | relative_url }})
Previous Example: [Hello World]({{ "/tutorial/hello_world.html" | relative_url }})

{% highlight cpp linenos %}#include <cstdio>
#include <cassert>
#include <cstdlib>
#include "legion.h"
using namespace Legion;

enum TaskIDs {
  TOP_LEVEL_TASK_ID,
  FIBONACCI_TASK_ID,
  SUM_TASK_ID,
};

void top_level_task(const Task *task,
                    const std::vector<PhysicalRegion> &regions,
                    Context ctx, Runtime *runtime) {
  int num_fibonacci = 7; // Default value
  const InputArgs &command_args = Runtime::get_input_args();
  for (int i = 1; i < command_args.argc; i++) {
    // Skip any legion runtime configuration parameters
    if (command_args.argv[i][0] == '-') {
      i++;
      continue;
    }

    num_fibonacci = atoi(command_args.argv[i]);
    assert(num_fibonacci >= 0);
    break;
  }
  printf("Computing the first %d Fibonacci numbers...\n", num_fibonacci);

  std::vector<Future> fib_results;
  for (int i = 0; i < num_fibonacci; i++) {
    TaskLauncher launcher(FIBONACCI_TASK_ID, TaskArgument(&i,sizeof(i)));
    fib_results.push_back(runtime->execute_task(ctx, launcher));
  }
  
  for (int i = 0; i < num_fibonacci; i++) {
    int result = fib_results[i].get_result<int>(); 
    printf("Fibonacci(%d) = %d\n", i, result);
  }

  fib_results.clear();
}

int fibonacci_task(const Task *task,
                   const std::vector<PhysicalRegion> &regions,
                   Context ctx, Runtime *runtime) {
  assert(task->arglen == sizeof(int));
  int fib_num = *(const int*)task->args; 
  if (fib_num == 0)
    return 0;
  if (fib_num == 1)
    return 1;

  // Launch fib-1
  const int fib1 = fib_num-1;
  TaskLauncher t1(FIBONACCI_TASK_ID, TaskArgument(&fib1,sizeof(fib1)));
  Future f1 = runtime->execute_task(ctx, t1);

  // Launch fib-2
  const int fib2 = fib_num-2;
  TaskLauncher t2(FIBONACCI_TASK_ID, TaskArgument(&fib2,sizeof(fib2)));
  Future f2 = runtime->execute_task(ctx, t2);

  TaskLauncher sum(SUM_TASK_ID, TaskArgument(NULL, 0));
  sum.add_future(f1);
  sum.add_future(f2);
  Future result = runtime->execute_task(ctx, sum);

  return result.get_result<int>();
}

int sum_task(const Task *task,
             const std::vector<PhysicalRegion> &regions,
             Context ctx, Runtime *runtime) {
  assert(task->futures.size() == 2);
  Future f1 = task->futures[0];
  int r1 = f1.get_result<int>();
  Future f2 = task->futures[1];
  int r2 = f2.get_result<int>();

  return (r1 + r2);
}

int main(int argc, char **argv) {
  Runtime::set_top_level_task_id(TOP_LEVEL_TASK_ID);

  {
    TaskVariantRegistrar registrar(TOP_LEVEL_TASK_ID, "top_level");
    registrar.add_constraint(ProcessorConstraint(Processor::LOC_PROC));
    Runtime::preregister_task_variant<top_level_task>(registrar, "top_level");
  }

  {
    TaskVariantRegistrar registrar(FIBONACCI_TASK_ID, "fibonacci");
    registrar.add_constraint(ProcessorConstraint(Processor::LOC_PROC));
    Runtime::preregister_task_variant<int, fibonacci_task>(registrar, "fibonacci");
  }

  {
    TaskVariantRegistrar registrar(SUM_TASK_ID, "sum");
    registrar.add_constraint(ProcessorConstraint(Processor::LOC_PROC));
    registrar.set_leaf(true);
    Runtime::preregister_task_variant<int, sum_task>(registrar, "sum", AUTO_GENERATE_ID);
  }

  return Runtime::start(argc, argv);
}
{% endhighlight %}
