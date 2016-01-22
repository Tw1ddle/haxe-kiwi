package kiwi.tests;

import haxe.unit.TestRunner;
import kiwi.tests.ParserTests;
import kiwi.tests.SolverTests;

class KiwiTestRunner {
	public function new() {
		trace("Running unit tests...");
		
		var runner = new TestRunner();
		
		runner.add(new TestStrengths());
		runner.add(new TestExpressions());
		runner.add(new TestConstraints());
		runner.add(new TestSolver());
		
		runner.add(new TestInfixToPostfix());
		
		runner.run();
		
		trace("Unit test results: " + runner.result);
	}
}