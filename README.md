# haxe-kiwi

haxe-kiwi is a port of [Kiwi](https://github.com/nucleic/kiwi) and [Kiwi Java](https://github.com/alexbirkett/kiwi-java), implementations of the [Cassowary](https://en.wikipedia.org/wiki/Cassowary_(software) constraint solving algorithm.

## Features

Supports:
* Solving systems of linear equalities and inequalities.
* Rudimentary JSON parsing for creation of constraints.

Doesn't support:
* Stay constraints.

## Usage

haxe-kiwi depends on assertion library Sure, install that first:
```xml
haxelib install sure
```

Include the library through Project.xml:
```xml
<include path="lib/haxe-kiwi/include.xml" />
```

For an example see the demo repo: https://github.com/Tw1ddle/haxe-kiwi-demo

![Screenshot of demo app](https://github.com/Tw1ddle/haxe-kiwi-demo/blob/master/screenshots/equalities_demo.png?raw=true "Demo")

```haxe
// Basic usage
var solver = new Solver();
var problem:String = '{"inequalities":["x == 20", "x == y + 10", "z == y + 30", "q == z + x", "foo == z + x", "bar == foo + x", "baz == foo * 10", "boz == x / 10 + y / 10 + x * 5"]}';
var structure:{inequalities:Array<String>} = Json.parse(problem);

var resolver:Resolver = new Resolver(); // Simple map wrapper that caches variables so that duplicates aren't added to the solver
for (inequality in structure.inequalities) {
	var constraint = ConstraintParser.parseConstraint(inequality, resolver); // Constraints have "required" strength by default
	solver.addConstraint(constraint);
}
solver.updateVariables(); // Attempt to satisfy the constraints

// Trace the value of variable x (expect x = 20)
var x = resolver.resolveVariable("x");
trace("x = " + x.value);

resolver.traceValues(); // Trace all the values of the variables captured by the resolver

// Prepare for the next problem
solver.reset();
resolver = new Resolver();
```

## Notes
* All Haxe targets are supported.
* A unit test suite and tests to gauge performance across targets are still needed.

## Acknowledgement
* haxe-kiwi is a port of the Kiwi UI constraint solver v0.1.3. Kiwi was written by Chris Colbert, lead of
the Nucleic Development Team. Their core team that coordinates development on GitHub can be found here:
http://github.com/nucleic.
* The string parsing code for constraints was ported from [kiwi-java](https://github.com/alexbirkett/kiwi-java) by Alex Birkett, a Java port of the C++ solver by Chris Colbert.