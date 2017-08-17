---
layout: page
permalink: /gasnet/index.html
title: GASNet
---

Legion uses [GASNet](http://gasnet.lbl.gov/) to support a variety of
network architectures. Compiling GASNet is non-trivial, so new users
are advised to leave it disabled until their application is fully
ported and optimized on a single node.

 * [Building GASNet](#building-gasnet)
 * [Configuring GASNet for Performance](#configuring-gasnet-for-performance)
 * [GASNet Performance Environment Variables](#gasnet-performance-environment-variables)

## Building GASNet

Before continuing users should download the most recent version of
[GASNet](http://gasnet.lbl.gov/#download) and read the associated
[README](http://gasnet.lbl.gov/dist/README).  As described in the
README, GASNet is organized around the concept of conduits. Conduits
provide implementations for different types of interconnect
networks. It is imperative that the GASNet configuration script is
setup to build the correct conduit for the target machine. The
configure script attempts to determine the underlying hardware based
on installed drivers. However, the configure script can be misled
especially if drivers are not visible in a user's path or are not
loaded by the operating system. For example, if a cluster has
Infiniband hardware, but the drivers are not loaded by the OS then the
GASNet configure script will not build the Infiniband conduit. The summary
printed at the completion of the configure script lists the detected
conduits. __BE SURE THE CONFIGURE SCRIPT BUILDS THE CORRECT CONDUIT__.

We have tested Legion on four different conduits on a wide variety of
machines ranging from our own personal Infiniband cluster to the Titan
supercomputer with a Gemini interconnect to a collection of Amazon AWS
nodes in the cloud using ethernet. The full list of flags for GASNet
configuration can be obtained via `configure --help`, but below are some
useful ones we use when building our own versions of GASNet.  (Some of these
are actually the defaults, but we specify them explicitly in case the GASNet
defaults ever change.)

* `--enable-gemini`: force GASNet to build the Gemini conduit for Cray interconnects.
* `--enable-ibv`: force GASNet to build the Infiniband conduit.
* `--enable-udp`: force GASNet to build the UDP conduit for ethernet interconnects.
* `--disable-mpi`: prevent GASNet from building the MPI conduit. It is very slow.
* `--prefix`: specify the destination for the GASNet installation.
* `--enable-par`: enable calling GASNet from multiple threads. Required for Legion.
* `--enable-mpi-compat`: allow GASNet to interoperate with MPI. Necessary
    for Legion applications which interact with MPI applications.
* `--enable-segment-fast`: necessary for supporting one-sided RDMA operations.
* `--disable-aligned-segments`: remove the requirement for aligned pinned memory.
* `--disable-pshm`: there should normally only be one GASNet process per node
    in a Legion application.  (Use `--enable-pshm` only when Legion GASNet
    applications will interoperate
    with MPI applications with more than one process per node.)

After following the instructions to build and install GASNet, there
will be a GASNet library and a binary used for running
applications. All applications using GASNet will need to link against
the GASNet library (we describe how this is handled by the Legion
build system below). Similar to running an MPI application with
`mpirun`, a GASNet application must be launched by a wrapper
script. This script is installed in the `bin` directory wherever
GASNet was installed and usually takes the form `gasnetrun_<conduit>`
where 'conduit' names the conduit that should be used
(e.g. `gasnetrun_ibv`). When Legion applications are built with
GASNet, they must be launched using this script. This script has a
number of parameters and we refer users to the GASNet documentation
regarding it.

__We strongly recommend users test the performance of their GASNet
installation.__ A GASNet installation also comes with some basic
benchmarks for determining the performance of the underlying
network. Users should run these benchmarks and compare them against
[known performance results](http://gasnet.lbl.gov/performance/) to
ensure that they meet expectations. A slow GASNet installation will
result in poor performance of Legion applications.

### Configuring GASNet for Performance

The configuration of a GASNet installation is important for
performance of many applications. Here we give two examples of
configuring GASNet for different architectures. We caution readers
that the examples shown here demonstrate some of the GASNet features
necessary for performance but are in no way comprehensive. In all
cases users should always consult the [GASNet
Documentation](http://gasnet.lbl.gov/) to ensure that they obtain
the highest possible performance installation for their target
machine.

Below is a configure command that we use for our installation of
GASNet on the [Keeneland supercomputer](http://keeneland.gatech.edu/).
(Note that this example uses a very old version of GASNet. Please use the most
recent GASNet release if possible, and keep in mind scripts or options may now
be named differently than what is shown below.)

{% highlight bash %}
./configure --prefix=/nics/d/home/sequoia/gasnet-1.22.0/ --enable-ibv \
--enable-mpi --disable-portals --disable-mxm --enable-pthreads \
--enable-segment-fast --with-segment-mmap-max=4GB --enable-par \
--disable-seq --disable-parsync --enable-mpi-compat --with-ibv-spawner=mpi \
--disable-ibv-rcv-thread --disable-aligned-segments --disable-pshm --disable-fca
{% endhighlight %}

We describe each of the flags in turn. The `--prefix` flag specifies
the target installation location for GASNet in our user space
directory (because we do not have administrative privilege on
Keeneland). We then specify the target conduits to build with the
`--enable-ibv` and `--enable-mpi` flags indicating that GASNet should
build the Infiniband and MPI conduits. The `--disable-portals` and
`--disable-mxm` tell GASNet to avoid using any available
[Portals](http://www.cs.sandia.gov/Portals/) or Mellanox APIs when
building our conduits respectively. The `--enable-pthreads` flag
instructs GASNet that it can use the Posix threads API as part of its
implementation. We instruct GASNet that it should pin 4 GB of memory
on each node to be used for its fast active message segment using the
`--enable-segment-fast --with-segment-mmap-max=4GB` flags. Legion is
multi-threaded and we therefore need the thread safe version of GASNet
which we specify with the `--enable-par` flag. We do not require the
sequential, or thread-unsafe multi-threaded GASNet versions so we
disable them with the `--disable-seq` and `--disable_parsync` flags.
We enable our GASNet implementation to inter-operate with MPI by
passing the `--enable-mpi-compat` flag. Since we usually use `mpirun`
for spawning our applications instead of the `gasnet*_run` utilities,
we set the spawner to MPI with the `--with-ibv-spawner` flag. By
default, GASNet enables a thread for receiving active messages. Legion
performs the same operation so we disable the GASNet thread with the
`--disable-ibv-rcv-thread`.  Since Keeneland is operated by an
installation of Linux with memory layout randomization we pass the
`--disable-aligned-segments` flag to guarantee correct execution by
GASNet. The `--disable-pshm` and `--disable-fca` flags disable shared
memory and fast atomic operations which are unnecessary for Legion.

While our installation for Keeneland is fairly straight-forward, some
machines require more complex GASNet installations. As an example, our
installation of GASNet on the [Titan
supercomputer](https://www.olcf.ornl.gov/titan/) requires us to
leverage a GASNet cross-configure script because the compilers on the
login nodes of Titan are different from the compilers necessary for
building code to run on Titan compute nodes. Titan is an instance of a
Cray XE architecture, therefore we use the correct GASNet
cross-configure script for the Cray XE architecture. Below are the two
command lines for first building a symbolic link to the correct
cross-configure script, and then invoking it.

{% highlight bash %}
ln -s other/contrib/cross-configure-crayxe-linux cross-configure
./cross-configure --prefix=/ccs/home/mebauer/gasnet/ --enable-gemini \
--disable-portals --enable-pthreads --enable-segment-fast \
--with-segment-mmap-max=4GB --enable-par --disable-seq \
--disable-parsync --disable-mpi --enable-mpi-compat \
--with-target-cxx=/opt/cray/xt-asyncpe/5.24/CC
{% endhighlight %}

Many of the flags are the same as previous example. We note that we
include the `--enable-gemini` flag in order to ensure that the conduit
for the Gemini interconnect is built. We also specify the correct MPI
cross-compiler with the `--with-target-cxx` flag. These two examples
should provide a useful illustration of the kinds of flags that can
influence the performance of GASNet installation and should be
considered when building an installation of GASNet to be used with
Legion.

### GASNet Performance Environment Variables

In addition to the configure time settings, GASNet also supports a
myriad array of environment variables that can influence the
performance of an application. When performance tuning an application
these variables should be properly set to match the communication
patterns of the target application. There are many environment
variables that can be set.  They are documented in the main and per-conduit
GASNet README files, and can be listed at run time by setting
`GASNET_VERBOSEENV=1`.  We cover some of the more important
performance ones here, looking first at the environment variables for
the Infiniband conduit, and then the ones for a Cray Gemini
conduit.

The documentation for the GASNet Infiniband conduit can be found
[here](http://gasnet.lbl.gov/dist/ibv-conduit/README). For all of our
applications that use the Infiniband conduit we tune the following
environment variables.

  * `GASNET_NETWORKDEPTH_PP` - Specifies the total number of operations
    (active messages and RDMA) operations that can be in flight
    between any pair of nodes.
  * `GASNET_NETWORKDEPTH_TOTAL` - Specifies the total number of operations
    that can be in flight from any one node to all the others.
  * `GASNET_AM_CREDITS_PP` - Set the total number of active messages
    that can be in flight between any pair of nodes.
  * `GASNET_AM_CREDITS_TOTAL` - Set the total number of active messages
    that can be in flight from any one node at a time.
  * `GASNET_AM_CREDITS_SLACK` - Control how quickly active message
    credits are sent back to the node that sent them.
  * `GASNET_AMRDMA_MAX_PEERS` - Control the number of nodes which
    support the faster path for active messages by using RDMA.
    We usually set this to `0` as the heuristics used within GASNet to
    guess which peers to switch to the faster path are often confused by
    Legion's message passing behavior.

The documentation for the GASNet Gemini conduit can be found
[here](http://gasnet.lbl.gov/dist/gemini-conduit/README). We regularly
tune the following variables when optimizing an application for the
Gemini conduit.

  * `GASNET_NETWORKDEPTH` - Maximum number of network operations
    which can be in flight between any pair of nodes.
  * `GASNET_NETWORKDEPTH_TOTAL` - Maximum number of network
    operations which can be in flight from an individual
    node at a time.
  * `GASNET_GNI_NUM_PD` - Control the number of UGNI post
    descriptors available for performing network operations.
  * `GASNET_GNI_MEMREG` - Specify the number of pinned memory
    allocations available for GASNet to use.  Most often
    needed when running applications without the -ll:rsize
    flag (see [here](/starting/#command-line-flags)).

In order to tune these variables we regularly employ a simple script
which sweeps the parameter space, records the performance of our
applications, and then reports the best configuration to use.
