---
layout: page
permalink: /tutorial/hello_world.html
title: Hello World 
---

No tutorial would be complete without a Hello World example. 
Below is the source code for writing Hello World using
the Legion C++ runtime interface. The source code can also
be found in the `tutorial` directory of the repository, along
with a `Makefile` for building and running the application. 
By walking through these tutorial programs in detail we
will demonstrate how to use the Legion C++ runtime API.
{% highlight cpp linenos %}#include <cstdio>
#include "legion.h"

using namespace Legion;

enum TaskID {
  HELLO_WORLD_ID,
};

void hello_world_task(const Task *task,
                      const std::vector<PhysicalRegion> &regions,
                      Context ctx, Runtime *runtime) {
  printf("Hello World!\n");
}

int main(int argc, char **argv)
{
  Runtime::set_top_level_task_id(HELLO_WORLD_ID);

  {
    TaskVariantRegistrar registrar(HELLO_WORLD_ID, "hello_world variant");
    registrar.add_constraint(ProcessorConstraint(Processor::LOC_PROC));
    Runtime::preregister_task_variant<hello_world_task>(registrar, "hello_world task");
  }

  return Runtime::start(argc, argv);
}
{% endhighlight %}

#### Legion Namespaces ####

All Legion programs begin by including the `legion.h` header 
file (line 2). This file includes the entire Legion C++ runtime 
API.  Line 4 imports the `Legion`
namespace into the current program making most of the necessary
types for writing Legion programs available.  There are other
Legion runtime namespaces that we will encounter in later examples.
Detailed documentation for Legion runtime namespaces can be
found [here]({{ "/doxygen/annotated.html" | relative_url }}).

#### Registering Legion Tasks ####

On lines 6-8 we define an enumeration for storing the IDs that
we will direct the Legion runtime to associate with each task.  In this example
we only need a single ID which we will associate with our 'Hello World' task.
Lines 21-23 show how to register 
a Legion task with a `void` return type with the Legion runtime.
In the [next example]({{ "/tutorial/tasks_and_futures.html" | relative_url }}) we'll see how
to register tasks with non-void return types.  The static method 
`preregister_task_variant` on the `Runtime` class
is templated on the function pointer to
be called to run the task (allowing the API to handle polymorphic return
types elegantly).  In this case it is templated on the function pointer to 
the `hello_world_task` on lines 10-14.  Note that all Legion tasks must have 
the same function type (with the exception of different return types). 
We'll look in detail at the arguments passed to Legion tasks in later 
examples.  The `preregister_task_variant` call takes several parameters: 

  * Task registrar - this object describes the task to be registered
  * Task name - a human-readable string naming the task

The task registrar itself records the ID of the task, a variant name
and the constraints that apply to the variant (we cover the distinction
between tasks and variants more in the [next tutorial]({{ "/tutorial/tasks_and_futures.html" | relative_url }}) ).
In this case, the variant is constrained to run on a CPU
processor (LOC, or *latency optimized core*).

There are additional parameters that can be passed to `preregister_task_variant`
call as can be seen in the [documentation](/doxygen/class_legion_1_1_runtime.html#a5e85dd4405daabc5eb4ebf3621763eb7).
We'll examine some of these additional parameters in later examples.

All Legion programs begin with a _top-level_ task which starts off
a Legion program.  The Legion runtime must be told which task to 
use as the top-level task using the `set_top_level_task_id` static 
method.  Line 17 invokes this method to register the ID we associate
with the `hello_world_task` as being the ID of the top-level task.

#### Legion Runtime Start-Up ####

When writing Legion programs, all the static member function 
invocations on the `Runtime` class must be performed
before the static method `start` is called.  It is imperative that 
this standard be followed for all Legion programs to ensure that 
they operate properly when running as MPI or GASNet programs. Legion
also supports dynamic registrations of task variants using the
`register_task_variant` method after the `start` method is called
for programs that dynamically generate JIT-compiled tasks such
as ones built on [Terra](http://terralang.org). After the runtime 
has been setup to run, the program
invokes the `start` static method on the `Runtime` class.
This call starts the Legion runtime and only returns an error code
if a problem is encountered during execution.

After `start` is called, the Legion runtime will perform any necessary
setup operations and will then invoke the top-level task.  In this
program the top-level task prints "Hello World" and then returns.  After
the top-level task completes, the Legion runtime will tear itself down
(abiding by GASNet or MPI conventions when necessary) and exit.

Next Example: [Tasks and Futures]({{ "/tutorial/tasks_and_futures.html" | relative_url }})
