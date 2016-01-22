package kiwi.tests;

import haxe.Timer;
import haxe.unit.TestCase;
import kiwi.Constraint;
import kiwi.Expression;
import kiwi.frontend.ConstraintParser;
import kiwi.frontend.VarResolver;
import kiwi.Solver;
import kiwi.Term;
import kiwi.Variable;

class TestStrengths extends TestCase {
	public function testOrdering() {
		assertTrue(Strength.weak < Strength.medium);
		assertTrue(Strength.medium < Strength.strong);
		assertTrue(Strength.strong < Strength.required);
		assertTrue(Strength.clamp(Strength.required + 1) == Strength.required);
	}
	
	public function testCreation() {
		var s1 = Strength.create(1, 2, 3);
		var s2 = Strength.create(4, 5, 6);
		
		assertTrue(s2 > s1);
	}
}

class TestExpressions extends TestCase {
	public function test() {
		var a = new Expression();
		var b = new Expression();
		
		assertTrue(a.constant == b.constant && a.constant == 0);
		assertTrue(a.isConstant() && b.isConstant());
		assertTrue(a.terms.length == 0 && b.terms.length == 0);
		assertTrue(a.value() == 0 && b.value() == 0);
		
		var c = new Expression([ new Term(new Variable("a", 1), 2) ], 3);
		var d = new Expression([ new Term(new Variable("b", 1), 3) ], 4);
		
		assertTrue(c.constant == 3 && d.constant == 4);
		assertTrue(!c.isConstant() && !d.isConstant());
		assertTrue(c.terms.length == 1 && d.terms.length == 1);
		assertTrue(c.value() == 5 && d.value() == 7);
	}
}

class TestConstraints extends TestCase {
	public function test() {
		assertTrue(true); // TODO
	}
}

class TestSolver extends TestCase {
	public function testAddRemoveConstraints() {
		
		try {
			var solver = new Solver();
			var resolver = new VarResolver();
			
			var constraints = new Array<Constraint>();
			
			trace("Parsing constraint strings");
			Timer.measure(function() {
				solver.addConstraint(ConstraintParser.parseConstraint("Var_0 == 100", resolver));
				
				for (i in 1...1001) {
					var constraintString = "Var_" + Std.string(i) + " == 100 + " + "Var_" + Std.string(i - 1);
					var constraint = ConstraintParser.parseConstraint(constraintString, resolver);
					constraints.push(constraint);
				}
			});
			
			trace("Adding " + constraints.length + " constraints to solver");
			Timer.measure(function() {
				for (constraint in constraints) {
					solver.addConstraint(constraint);
				}
			});
			
			trace("Confirming that constraints were added to solver");
			Timer.measure(function() {
				for (constraint in constraints) {
					assertTrue(solver.hasConstraint(constraint));
				}
			});
			
			trace("Removing constraints from solver");
			Timer.measure(function() {
				for (constraint in constraints) {
					solver.removeConstraint(constraint);
				}
			});
		
		} catch(msg:String) {
			trace("Error occurred: " + msg);
			assertTrue(false);
		}
		
		assertTrue(true);
	}
	
	public function testAddRemoveEditVars() {
		
		try {
			var solver = new Solver();
			var vars = new Array<Variable>();
			
			trace("Creating variables");
			Timer.measure(function() {
				for (i in 0...1000) {
					vars.push(new Variable("Var_" + Std.string(i)));
				}
			});
			
			trace("Adding " + vars.length + " edit variables to solver");
			Timer.measure(function() {
				for (i in 0...vars.length) {
					solver.addEditVariable(vars[i], Strength.create(Math.random(), Math.random(), Math.random(), 1.0));
				}
			});
			
			trace("Confirming edit vars were added to solver");
			Timer.measure(function() {
				for (i in 0...vars.length) {
					assertTrue(solver.hasEditVariable(vars[i]));
				}
			});
			
			trace("Suggesting values to solver");
			Timer.measure(function() {
				for (i in 0...vars.length) {
					solver.suggestValue(vars[i], Math.random() * 10000);
				}
			});
			
			trace("Removing edit variables from solver");
			Timer.measure(function() {
				for (i in 0...vars.length) {
					solver.removeEditVariable(vars[i]);
				}
			});
		} catch(msg:String) {
			trace("Error occurred: " + msg);
			assertTrue(false);
		}
		
		assertTrue(true);
	}
	
	public function testConstraintStrengths() {
		
		try {
			var solver = new Solver();
			var resolver = new VarResolver();
			
			var x = resolver.resolveVariable("x");
			
			var weak = addConstraint(solver, ConstraintParser.parseConstraint("x == 100", "weak", resolver));
			var medium = addConstraint(solver, ConstraintParser.parseConstraint("x == 200", "medium", resolver));
			var strong = addConstraint(solver, ConstraintParser.parseConstraint("x == 300", "strong", resolver));
			var required = addConstraint(solver, ConstraintParser.parseConstraint("x == 400", "required", resolver));
			
			solver.updateVariables();
			assertTrue(x.value == 400);
			solver.removeConstraint(required);
			solver.updateVariables();
			assertTrue(x.value == 300);
			solver.removeConstraint(strong);
			solver.updateVariables();
			assertTrue(x.value == 200);
			solver.removeConstraint(medium);
			solver.updateVariables();
			assertTrue(x.value == 100);
			solver.removeConstraint(weak);
			solver.updateVariables();
			assertTrue(x.value == 0);
			
		} catch(msg:String) {
			trace("Error occurred: " + msg);
			assertTrue(false);
		}
		
		assertTrue(true);
		
	}
	
	private function addConstraint(solver:Solver, constraint:Constraint):Constraint {
		solver.addConstraint(constraint);
		return constraint;
	}
}