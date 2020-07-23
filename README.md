# duken
A gprof output parser.

## Presentation

Duken is a script that aims at extracting informations from gprof's output. It was created with a specific task in mind: being able to identify informations about "spontaneous" functions, that is to say function whose caller was not determined by gprof.

## Features (with examples)

Here are described a small subset of the features availables (though honestly there isn't much more to this). If one wants to learn more, one can have a look at the file duken/ArgHandler.pm.

The examples are using the file czanalyse.txt, which is provided in this repo and comes from the profiling of the project godefarig, available at <https://github.com/mooss/godefarig>.

### Signature selection

The fact that duken is written in Perl made it simple (and desirable) to rely on Perl's support for regulars expressions.
An example is the signature selection feature which allow us to filter out non-matching signatures ('*--signature, -s*'):

`./duken.pl czanalyse.txt --signature ^gfg::cascade_node::`

The above example selects only member functions of the class *cascade_node* located inside the namespace *gfg*.

### Output formatting

It is possible to format what is displayed before and after the name of the function ('*--before -B*', '*--after -A*')

The argument of those options is a string describing what the output should be like, with some token carrying a special meaning:
 - '~i' is replaced by the number of functions that can *potentially* call the current one.
 - '~inclist' is replaced by the list of potential callers of the current function.
 - '~o' is replaced by the number of functions *potentially* called by the current one.
 - '~c' is replaced by the number of calls to the current function that occured during the execution.

To illustrate this, we can output the numbers of callers and the number of calls of the function gfg::cascade_node::index, using the following command:

`./duken.pl czanalyse.txt --signature ^gfg::cascade_node::index --before "==========\n~i callers \ncalled ~c times\n"`

which outputs:
```
==========
4 callers
called 20971404 times
gfg::cascade_node::index() const
```

## Potentials evolutions
 - Adding an option to filter out (or prettify) the ugly and terribly long function names of some parts of boost and the stl.
 - Being able to output calltrees as graphs, using graphviz.
 - Being able to display/manipulate more informations extracted from gprof (such as the time spend inside a function).
 - Make the code and the structure of the program more readable/flexible/clean (perhaps rewrite everything with moose).
