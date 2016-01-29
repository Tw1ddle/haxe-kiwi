package kiwi.tests;

import haxe.unit.TestCase;
import kiwi.frontend.ConstraintParser;

/*
 * Runtime parser tests for strings -> Kiwi constraints.
 * Adapted from Alex Birkett's kiwi-java port: https://github.com/alexbirkett/kiwi-java
 */
@:access(kiwi.frontend.ConstraintParser)
class TestInfixToPostfix extends TestCase {
	public function testInfixToPostfixBasic():Void {
		var infix:Array<String> = ["3", "+", "4", "*", "2", "/", "(", "1", "-", "5", ")", "^", "2", "^", "3"];
		var postfix:Array<String> = ConstraintParser.infixToPostfix(infix);
		var index = 0;
		assertTrue(postfix[index++] == "3");
		assertTrue(postfix[index++] == "4");
		assertTrue(postfix[index++] == "2");
		assertTrue(postfix[index++] == "*");
		assertTrue(postfix[index++] == "1");
		assertTrue(postfix[index++] == "5");
		assertTrue(postfix[index++] == "-");
		assertTrue(postfix[index++] == "2");
		assertTrue(postfix[index++] == "3");
		assertTrue(postfix[index++] == "^");
		assertTrue(postfix[index++] == "^");
		assertTrue(postfix[index++] == "/");
		assertTrue(postfix[index++] == "+");
	}
}