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
	public function test() {
		assertTrue(Strength.weak < Strength.medium);
		assertTrue(Strength.medium < Strength.strong);
		assertTrue(Strength.strong < Strength.required);
		assertTrue(Strength.clamp(Strength.required + 1) == Strength.required);
		
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

class TestPerformance extends TestCase {
	public function testAddRemove() {
		
		try {
			var solver = new Solver();
			var resolver = new VarResolver();
			
			var constraints = new Array<Constraint>();
			
			// Parse constraint strings
			trace("Parsing constraint strings");
			Timer.measure(function() {
				solver.addConstraint(ConstraintParser.parseConstraint("Var_0 == 100", resolver));
				
				for (i in 1...1001) {
					var constraintString = "Var_" + Std.string(i) + " == 100 + " + "Var_" + Std.string(i - 1);
					var constraint = ConstraintParser.parseConstraint(constraintString, resolver);
					constraints.push(constraint);
				}
			});
			
			// Add constraints
			trace("Adding " + constraints.length + " constraints to solver");
			Timer.measure(function() {
				for (constraint in constraints) {
					solver.addConstraint(constraint);
				}
			});
			
			// Remove constraints
			trace("Removing constraints from solver");
			Timer.measure(function() {
				for (constraint in constraints) {
					solver.removeConstraint(constraint);
				}
			});
		
		} catch(msg:String) {
			trace("Error occurred: " + msg);
		}
		
		assertTrue(true);
	}
}