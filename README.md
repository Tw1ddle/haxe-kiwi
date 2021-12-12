[![Project logo](https://github.com/Tw1ddle/haxe-kiwi/blob/master/screenshots/logo.png?raw=true "Haxe Kiwi - an implementation of the Cassowary constraint solving algorithm")](https://tw1ddle.github.io/haxe-kiwi-demo/)

haxe-kiwi is a port of [Kiwi](https://github.com/nucleic/kiwi) and [Kiwi Java](https://github.com/alexbirkett/kiwi-java), implementations of the [Cassowary](https://en.wikipedia.org/wiki/Cassowary_(software)) constraint solving algorithm. Run the demo [in your browser](https://tw1ddle.github.io/haxe-kiwi-demo/).

## Features

Supports:
* Solving systems of linear constraint equations.
* String parsing for constraint creation.
* Edit variables.

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

See the [demo code](https://github.com/Tw1ddle/haxe-kiwi-demo), the [unit tests](https://github.com/Tw1ddle/haxe-kiwi-unit-tests), or run the [demo in the browser](https://tw1ddle.github.io/haxe-kiwi-demo/) for usage examples.

![Screenshot of demo app](https://github.com/Tw1ddle/haxe-kiwi-demo/blob/master/screenshots/layout_animation.gif?raw=true "Demo")

```haxe
// Basic usage
var solver = new Solver();

// Constraints are written in the form: a [==|<=|>=] b [*/] c [+-] d
var problem:String = '{"inequalities":["x == 20", "x == y + 10", "z == y + 30", "q == z + x", "foo == z + x", "bar == foo + x", "baz == foo * 10", "boz == x / 10 + y / 10 + x * 5"]}';
var structure:{inequalities:Array<String>} = Json.parse(problem);

var resolver:VarResolver = new VarResolver(); // Simple map wrapper that caches variables so that duplicates aren't added to the solver
for (inequality in structure.inequalities) {
    var constraint = ConstraintParser.parseConstraint(inequality, resolver, "required");
    solver.addConstraint(constraint);
}
solver.updateVariables(); // Update the values of the external solver variables

// Trace the value of external solver variable x (expect 20)
var x = resolver.resolveVariable("x");
trace("x = " + x.value);

resolver.traceVariables(); // Trace all the variables captured by the resolver
```

## Notes
* There is a unit test repository for the library [here](https://github.com/Tw1ddle/haxe-kiwi-unit-tests).
* All Haxe targets are supported.

## Acknowledgement
* haxe-kiwi is a port of the Kiwi UI constraint solver v0.1.3. Kiwi was written by Chris Colbert, lead of the Nucleic Development Team. Their core team that coordinates development on GitHub can be found here: https://github.com/nucleic.
* Parts of this port were adapted from Kiwi.js, a JavaScript port of Kiwi, which is also written by the Nucleic Development Team.
* String parsing code for constraints and some tests were ported from [kiwi-java](https://github.com/alexbirkett/kiwi-java), a Java port of Kiwi by Alex Birkett.