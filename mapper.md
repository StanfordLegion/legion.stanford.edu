---
layout: page
permalink: /mapper/index.html
title: Introduction to the Legion Mapper API
---


A Legion mapper is a C++ object that handles callbacks from the Legion runtime as part of the execution of a Legion application. Mapper callbacks are performed whenever a “policy” decision has to be made regarding how best to map the Legion application to the the target machine. The callback interface is defined by a pure virtual interface defined by the Legion::Mapper class. Every mapper object must inherit from this interface either directly or through a sub-class. The most common way this is done is by inheriting from the Legion::Mapping::DefaultMapper class which provides default implementations of all the mapper callbacks and then selectively overriding particular methods. However, there is nothing preventing a mapper from implementing the Legion::Mapper interface directly.

The rest of this introduction reviews how to create and implement a custom mapper. We also encourage readers to review the detailed comments for each mapper call in legion_mapping.h.

Finally note this is a work in progress and subject to updates. 



  * [Mapper Registration](#Mapper-registration)
  * [Callback Model](#Callback-model)
      * [Machine Model](#Machine-model)
      * [Task Launch](#Task-launch)
      * [Mapping](#Mapping)
      * [Load Balancing](#Load-balancing)
      * [Message Passing](#Message-passing)
      * [Must Epoch Launches](#Must-epoch-launches)
      * [MappableData Annotations](#Mappable-data-annotations)

## Mapper Registration

By default, the Legion runtime will create one instance of the Legion::Mapping::DefaultMapper class for each processor in the machine. The default mappers are registered with mapper ID ‘0’. Before starting Legion, applications can record a “registration callback” function with the runtime. This callback function will be invoked after the runtime is created but before any application task is run. Registration functions can register new mapper implement-ations with alternative mapper IDs or even replace the default mapper for mapper ID ‘0’. 

Here is an example of replacing the default mapper with a custom mapper. This code belongs in the source file for the custom mapper. 

{% highlight cpp linenos %}
static void create_mappers(Machine machine, HighLevelRuntime *runtime, const std::set &local_procs)
{
  std::vector* procs_list = new std::vector();
  std::vector* sysmems_list = new std::vector();
  std::map >* sysmem_local_procs =
  new std::map >();
  std::map* proc_sysmems = new std::map();
  std::map* proc_regmems = new std::map();
  
  std::vector proc_mem_affinities;
  machine.get_proc_mem_affinity(proc_mem_affinities);
  
  for (unsigned idx = 0; idx < proc_mem_affinities.size(); ++idx) {
    Machine::ProcessorMemoryAffinity& affinity = proc_mem_affinities[idx];
    if (affinity.p.kind() == Processor::LOC_PROC
        || affinity.p.kind() == Processor::IO_PROC
        || affinity.p.kind() == Processor::PY_PROC) {
      if (affinity.m.kind() == Memory::SYSTEM_MEM) {
        (*proc_sysmems)[affinity.p] = affinity.m;
        if (proc_regmems->find(affinity.p) == proc_regmems->end())
          (*proc_regmems)[affinity.p] = affinity.m;
      }
      else if (affinity.m.kind() == Memory::REGDMA_MEM)
        (*proc_regmems)[affinity.p] = affinity.m;
    }
  }
  
  for (std::map::iterator it = proc_sysmems->begin();
       it != proc_sysmems->end(); ++it) {
    procs_list->push_back(it->first);
    (*sysmem_local_procs)[it->second].push_back(it->first);
  }
  
  for (std::map >::iterator it =
       sysmem_local_procs->begin(); it != sysmem_local_procs->end(); ++it)
    sysmems_list->push_back(it->first);
  
  for (std::set::const_iterator it = local_procs.begin();
       it != local_procs.end(); it++)
  {
    LifelineMapper* mapper = new LifelineMapper(runtime->get_mapper_runtime(),
                                                machine, *it, "lifeline_mapper",
                                                procs_list,
                                                sysmems_list,
                                                sysmem_local_procs,
                                                proc_sysmems,
                                                proc_regmems);
    runtime->replace_default_mapper(mapper, *it);
  }
}

void register_lifeline_mapper()
{
  HighLevelRuntime::add_registration_callback(create_mappers);
}
{% endhighlight %}

Mappers can only be registered for application processors on the “local” node. As part of the registration callback, Legion provides a set of the local application processor names for use in registering mappers. A given mapper object can be registered with one or more local application processors. The mappers registered with an application processor will handle all mapper callbacks related to that application processor. While mapper objects are registered with application processors they most commonly run on “utility” processors that are used for runtime meta-work. If there are multiple utility processors, then there is a tradeoff between parallelism and programmability: registering one mapper for all local processors can make programming easier, but may cause synchronization bottlenecks depending on the mapper synchronization model (see section 3.1). It is up to the user to determine how they would like to develop their mapper and register it for a particular application. 



## Callback Model


The mapper API is a series of callbacks that a mapper must support. For any given operation (e.g. task) launched onto the Legion runtime, a well-defined sequence of mapper callbacks will be performed. It is possible that this sequence of callbacks will actually be performed over several different mapper objects depending on how the mapper chooses to distribute the operation (e.g. move a task around).

TODO: some examples of the state machines for mapper calls for different operation kinds 


### Machine Model

In order to provide the mapper with context about the machine being targeted, each mapper object is passed a ‘Machine’ object at construction. This Machine object provides an interface for querying various properties of the machine including the number and kinds of different processors as well as the number, kinds, and capacities of different memories. The Machine object also permits queries about the topology of the machine including which processors can directly access a given memory and which memories can be directly to from other memories. We therefore encourage users to think of the machine as a graph of processors and memories, with edges between processor-memory and memory-memory pairs that can directly access each other. The Machine object also has an interface for querying the bandwidth and latency available on each of these edges. This detailed knowledge of the machine is what enables Legion mappers to make intelligent mapping decisions for a given machine.



{% highlight cpp linenos %}
std::vector proc_mem_affinities;
machine.get_proc_mem_affinity(proc_mem_affinities);
{% endhighlight %}


The machine model is currently static, processors and memories persist from the beginning to the end of the run. In future work the machine model will be dynamic and components can be added or removed during a run. 



### Synchronization

Since multiple callbacks may want to access the same mapper concurrently, we allow mappers to select a synchronization model that controls if/how concurrent mapper calls are performed to a single mapper object. Each mapper object will receive a call to the get_mapper_sync_model mapper call almost immediately after it is registered with the runtime. There are three possible models to choose from. The SERIALIZED_NON_REENTRANT_MAPPER_MODEL permits a single mapper call to be running in a given mapper object at a time and all mapper calls execute atomically. This is the easiest model to program to but permits the least concurrency. SERIALIZED_REENTRANT_MAPPER_MODEL also guarantees that a single mapper call is executing in a given mapper object at a time, but mapper calls are not guaranteed to execute atomically. If a mapper with this synchronization model calls back into the runtime then the mapper call may be preempted and other mapper calls could execute before the preempted call resumes. The CONCURRENT_MAPPER_MODEL is a truly concurrent mapper in which multiple mapper calls may be executing at the same time in the same mapper object. In this model it is the programmer’s responsibility to use mapper locking methods to control access to shared data structures. 

Here is an example of defining the synchronization model: 

{% highlight cpp linenos %}
  MapperSyncModel get_mapper_sync_model(void) const {
    return SERIALIZED_REENTRANT_MAPPER_MODEL;
}
{% endhighlight %}



### Task Launch

The lifecycle of a task starts with select_task_options. When a Legion application first launches a task the runtime invokes select_task_options in the mapper for the processor that launched the task. 


{% highlight cpp linenos %}
  virtual void select_task_options(const MapperContext    ctx,
                                   const Task&            task,
                                   TaskOptions&           output) = 0;
{% endhighlight %}

If the task is a single task then output.initial_proc defines the processor to launch it on. If output.inline_task is true the task will be inlined directly into the parent task using the parent tasks regions. If output.stealable is true then the task can be stolen for load balancing. If output.map_locally is true then map_task(task) will be called in the current mapper rather than in the mapper for the destination processor. If output.parent_priority is modified then the parent task will change priority if this is permitted by the mapper for the parent task. 

If the task is an index task launch the runtime calls slice_task to divide the index task into a set of slices that contain point tasks. One slice corresponds to one target processor. 


{% highlight cpp linenos %}
virtual void slice_task(const MapperContext      ctx,
                          const Task&              task,
                          const SliceTaskInput&    input,
                          SliceTaskOutput&         output) = 0;

struct SliceTaskInput {
  IndexSpace                             domain_is;
  Domain                                 domain;
};

struct SliceTaskOutput {
  std::vector                 slices;
  bool                                   verify_correctness; // = false
};
{% endhighlight %}

Each slice identifies an index space, a subregion of the original domain and a target processor. All of the point tasks for the subregion will be mapped by the mapper for the target processor. 

If slice.stealable is true the task can be stolen for load balancing. If slice.recurse is true the mapper for the target processor will invoke slice_task again with the slice as input. Here is sample code to create a stealable slice: 



{% highlight cpp linenos %}
TaskSlice slice;
slice.domain = slice_subregion;
slice.proc = targets[target_proc_index];
slice.recurse = false;
slice.stealable = true;
slices.push_back(slice);
{% endhighlight %}



### Mapping

If a mapper has one or more tasks that are ready to execute it calls select_tasks_to_map. This method can copy tasks to the map_tasks list to indicate the task should be mapped by this mapper. The method can copy tasks to the relocate_tasks list to indicate the task should be mapped by a mapper for a different processor. If it does neither the task stays in the ready list. 


{% highlight cpp linenos %}
virtual void select_tasks_to_map(const MapperContext          ctx,
                                   const SelectMappingInput&    input,
                                   SelectMappingOutput&         output) = 0;

struct SelectMappingInput {
  std::list                  ready_tasks;
};

struct SelectMappingOutput {
  std::set                   map_tasks;
  std::map         relocate_tasks;
  MapperEvent                             deferral_event;
};
{% endhighlight %}


If select_tasks_to_map does not map or relocate any tasks then it must assign a MapperEvent to deferral_event. When another mapper call triggers the MapperEvent the mapper will invoke select_tasks_to_map. The mapper will also invoke select_tasks_to_map if new tasks are added to the ready list. Here is an example of creating a MapperEvent: 



{% highlight cpp linenos %}
MapperEvent defer_select_tasks_to_map;
// ...
if (!defer_select_tasks_to_map.exists()) {
  defer_select_tasks_to_map = runtime->create_mapper_event(ctx);
}
output.deferral_event = defer_select_tasks_to_map;
{% endhighlight %}


Here is sample code for triggering and clearing the event: 



{% highlight cpp linenos %}
if(defer_select_tasks_to_map.exists()){
  MapperEvent temp_event = defer_select_tasks_to_map;
  defer_select_tasks_to_map = MapperEvent();
  runtime->trigger_mapper_event(ctx, temp_event);
}
{% endhighlight %}


When a task is ready to execute the runtime invokes map_task. This allows the programmer to select and rank the PhysicalInstances to be mapped and the target processors on which the task may run. Other capabilities are to choose the task variant, to create profiling requests, set the task priority, and indicate that postmap operation is needed. 



{% highlight cpp linenos %}
virtual void map_task(const MapperContext     ctx,
                      const Task&              task,
                      const MapTaskInput&      input,
                      MapTaskOutput&           output) = 0;
struct MapTaskInput {
   std::vector >     valid_instances;
   std::vector                           premapped_regions;
};

struct MapTaskOutput {
  std::vector >     chosen_instances; 
  std::vector                          target_procs;
  VariantID                                       chosen_variant; // = 0 
  ProfilingRequest                                task_prof_requests;
  ProfilingRequest                                copy_prof_requests;
  TaskPriority                                    task_priority;  // = 0
  bool                                            postmap_task; // = false
};
{% endhighlight %}


Here is example code to create a profiling request to indicate task completion: 



{% highlight cpp linenos %}
ProfilingRequest completionRequest;
completionRequest.add_measurement();
output.task_prof_requests = completionRequest;
{% endhighlight %}
 
If map_task sets output.postmap_task = true the runtime invokes postmap_task when the task completes. This lets the programmer create additional copies of the output in different memories. 
 
{% highlight cpp linenos %}
struct PostMapInput {
  std::vector >     mapped_regions;
  std::vector >     valid_instances;
};

struct PostMapOutput {
  std::vector >     chosen_instances;
};

virtual void postmap_task(const MapperContext      ctx,
                          const Task&              task,
                          const PostMapInput&      input,
                          PostMapOutput&           output) = 0;
{% endhighlight %}


### Load Balancing

The mapper supports a work stealing model for load balancing. Mappers that want to steal tasks identify the processors to steal from in select_steal_targets. Processors appear in the blacklist if a previous steal request failed due to lack of available work. Processors are removed from the blacklist automatically when they gain new work. 


{% highlight cpp linenos %}
struct SelectStealingInput {
  std::set                     blacklist;
};

struct SelectStealingOutput {
  std::set                     targets;
};

virtual void select_steal_targets(const MapperContext         ctx,
                                  const SelectStealingInput&  input,
                                  SelectStealingOutput&       output) = 0;
{% endhighlight %}


If a mapper is selected as a steal target the runtime invokes permit_steal_request. This allows the mapper to decide which tasks are to be stolen as a result of the request. 



{% highlight cpp linenos %}
struct StealRequestInput {
  Processor                               thief_proc;
  std::vector                stealable_tasks;
};

struct StealRequestOutput {
  std::set                   stolen_tasks;
};

virtual void permit_steal_request(const MapperContext         ctx,
                                  const StealRequestInput&    input,
                                  StealRequestOutput&         output) = 0;
{% endhighlight %}


### Message Passing

Mappers can communicate among themselves using message passing. Messages are guaranteed to be delivered but are not guaranteed to be in order. 


{% highlight cpp linenos %}
void send_message(MapperContext ctx, Processor target, const void *message,
                  size_t message_size, unsigned message_kind = 0) const;

void broadcast(MapperContext ctx, const void *message,
               size_t message_size, unsigned message_kind = 0, int radix = 4) const;

struct MapperMessage {
  Processor                               sender;
  unsigned                                kind;
  const void*                             message;
  size_t                                  size;
  bool                                    broadcast;
};

virtual void handle_message(const MapperContext           ctx,
                            const MapperMessage&          message) = 0;
{% endhighlight %}


### Must Epoch Launches


If the application uses must epoch launches the runtime invokes map_must_epoch. This allows the mapper to control which processors the epoch tasks are mapped on and which physical regions are mapped with them. 



{% highlight cpp linenos %}
struct MappingConstraint {
  std::vector                          constrained_tasks;
  std::vector                       requirement_indexes;
};

struct MapMustEpochInput {
  std::vector                    tasks;
  std::vector              constraints;
  MappingTagID                                mapping_tag;
};

struct MapMustEpochOutput {
  std::vector                      task_processors;
  std::vector > constraint_mappings;
};

virtual void map_must_epoch(const MapperContext           ctx,
                            const MapMustEpochInput&      input,
                            MapMustEpochOutput&           output) = 0;
{% endhighlight %}

### MappableData Annotations


Every Mappable object (a Task is a Mappable object) has an auxiliary data field that can be used to hold application-specific data. This is usually used to help in debugging by attaching unique identifiers to the different tasks. Here is an example of assigning a unique id that persists across task stealing operations: 


{% highlight cpp linenos %}
Task task;
size_t shiftBits = sizeof(taskSerialId) * sizeof(char);
unsigned long long taskId = (local_proc.id << shiftBits) + taskSerialId++;
runtime->update_mappable_data(ctx, task, &taskId, sizeof(taskId));
{% endhighlight %}

You would normally do this in two places: in select_task_options for newly created tasks; and in map_task for point tasks that are generated from index task launches in slice_task. In the second case it is necessary to distinguish between point tasks and individual tasks using `task.is_index_space == true` to identify the point tasks. Note that point tasks will enter map_task with mappable data that is copied from the parent index task launch. So you can record the parent task before overwriting the mappable data with the new identifier. 


