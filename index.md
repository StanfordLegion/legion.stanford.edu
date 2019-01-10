---
layout: page 
---

Legion is a data-centric parallel programming system for
writing portable high performance programs targeted at
distributed heterogeneous architectures.  Legion presents
abstractions which allow programmers to describe properties
of program data (e.g. independence, locality).  By making the
Legion programming system aware of the structure of
program data, it can automate many of the tedious tasks
programmers currently face, including correctly extracting
task- and data-level parallelism and moving data around
complex memory hierarchies.  A novel mapping interface
provides explicit programmer controlled placement of data 
in the memory hierarchy and assignment of tasks to processors 
in a way that is orthogonal to correctness, thereby enabling 
easy porting and tuning of Legion applications to new 
architectures.

To learn more about Legion you can:

 * Read the [overview](/overview/)
 * Visit the [getting started page](/starting/)
 * Download our [publications](/publications/)
 * Ask questions on our [mailing list](/community/)

#### About Legion ####

Legion is developed as an open source project, with major
contributions from [LANL](https://www.lanl.gov/),
[NVIDIA Research](https://www.nvidia.com/en-us/research/),
[SLAC](https://www6.slac.stanford.edu/), and
[Stanford](https://www.stanford.edu/). This research was supported by
the Exascale Computing Project (17-SC-20-SC), a collaborative effort
of two U.S. Department of Energy organizations (Office of Science and
the National Nuclear Security Administration) responsible for the
planning and preparation of a capable exascale ecosystem, including
software, applications, hardware, advanced system engineering, and
early testbed platforms, in support of the nation’s exascale computing
imperative. Additional support has been provided to LANL and SLAC via
the Department of Energy [Office of Advanced Scientific Computing
Research](http://science.energy.gov/ascr) and to NVIDIA, LANL and
Stanford from the U.S. Department of Energy [National Nuclear Security
Administration Advanced Simulation and Computing
Program](http://nnsa.energy.gov/asc). Previous support for Legion has
included the U.S. Department of Energy's [ExaCT Combustion Co-Design
Center](http://exactcodesign.org/) and the Scientific Data Management,
Analysis and Visualization (SDMAV) program, DARPA, the Army High
Performance Computing Research Center, and NVIDIA, and grants from
OLCF, NERSC, and the Swiss National Supercomputing Centre (CSCS).

#### Legion Contributors ####

<table>
<tr valign="middle">
<td><b>Stanford</b></td>
<td><b>SLAC</b></td>
<td><b>Los Alamos</b></td>
<td><b>NVIDIA</b></td>
</tr>

<tr valign="middle">
<td>Todd Warszawski</td>
<td><a href="https://elliottslaughter.com">Elliott Slaughter</a></td>
<td><a href="&#109;&#097;&#105;&#108;&#116;&#111;:&#112;&#097;&#116;&#064;&#108;&#097;&#110;&#108;&#046;&#103;&#111;&#118;">Pat McCormick</a></td>
<td><a href="http://lightsighter.org">Michael Bauer</a> (<a href="http://research.nvidia.com/person/mike-bauer">NVIDIA site</a>)</td>
</tr>

<tr valign="middle">
<td>Wonchan Lee</td>
<td><a href="http://heirich.org">Alan Heirich</a></td>
<td><a href="&#109;&#097;&#105;&#108;&#116;&#111;:&#115;&#097;&#109;&#117;&#101;&#108;&#064;&#108;&#097;&#110;&#108;&#046;&#103;&#111;&#118;">Samuel Gutierrez</a></td>
<td><a href="http://cs.stanford.edu/~sjt/">Sean Treichler</a></td>
</tr>

<tr>
<td>Zhihao Jia</td>
<td><a href="mail&#116;o&#58;%73%&#54;5e%6Da&#46;&#37;6Di&#37;72&#99;ha%&#54;Eda&#110;ey&#64;%73&#116;anford%2&#69;e%64u">Seema Mirchandaney</a></td>
<td><a href="&#109;&#097;&#105;&#108;&#116;&#111;:&#103;&#115;&#104;&#105;&#112;&#109;&#097;&#110;&#064;&#108;&#097;&#110;&#108;&#046;&#103;&#111;&#118;">Galen Shipman</a></td>
</tr>

<tr>
<td>Karthik Srinivasa Murthy</td>
<td>Seshu Yamajala</td>
<td>Jonathan Graham</td>
</tr>

<tr>
<td><a href="http://theory.stanford.edu/~aiken">Alex Aiken</a></td>
<td>  </td>
<td>Irina Demeshko</td>
</tr>

<tr>
<td></td>
<td>  </td>
<td>Nick Moss</td>
</tr>

<tr>
<td></td>
<td>  </td>
<td>Wei Wu</td>
</tr>
</table>
