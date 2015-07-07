# haxe-kiwi

haxe-kiwi is a port of [Kiwi](https://github.com/nucleic/kiwi), a fast implementation of the Cassowary constraint solving algorithm.
	
## Features

Supports:
* Solving systems of linear equalities and inequalities.
* Rudimentary algebra parsing to simplify creation of constraints.

Doesn't support:
* Stay constraints.

## Usage

For an example using a system of equalities with edit variables see the demo: https://github.com/Tw1ddle/haxe-kiwi-demo
	
![Screenshot of demo app](https://github.com/Tw1ddle/haxe-kiwi-demo/blob/master/screenshots/equalities_demo.png?raw=true "Demo")

Include the library through Project.xml
```xml
<include path="lib/haxe-kiwi/include.xml" />
```

```haxe
// Basic usage
var solver = new Solver();
var problem:String = '{"inequalities":["x == 20", "x == y + 10", "z == y + 30", "q == z + x", "foo == z + x", "bar == foo + x", "baz == foo * 10", "boz == x / 10 + y / 10 + x * 5"]}';
var structure:{inequalities:Array<String>} = Json.parse(problem);

var resolver:Resolver = new Resolver(); // Caches variables so that duplicates aren't added to the solver
for (inequality in structure.inequalities) {
	var constraint = ConstraintParser.parseConstraint(inequality, resolver); // Constraints have "required" strength by default
	solver.addConstraint(constraint);
}
solver.updateVariables(); // Attempt to solve the system

// Trace the value of variable x (expect x = 20)
var x = resolver.resolveVariable("x");
trace("x = " + x.value);

resolver.traceValues(); // Trace all the values of the variables captured by the resolver

// Prepare for the next problem
solver.reset();
resolver = new Resolver();
```

## Notes
All targets are supported. Some work to make performance match the original implementation is still needed.