package kiwi.tests;

import haxe.unit.TestCase;
import kiwi.frontend.ConstraintParser;

// Adapted from Alex Birkett's kiwi-java port: https://github.com/alexbirkett/kiwi-java
// Runtime parser for strings -> Kiwi constraints
@:access(kiwi.frontend.ConstraintParser)
class TestInfixToPostfix extends TestCase {
	public function testInfixToPostfixBasic():Void {
		var infix:Array<String> = ["3", "+", "4", "*", "2", "/", "(", "1", "-", "5", ")", "^", "2", "^", "3"];
		var postfix:Array<String> = ConstraintParser.infixToPostfix(infix);
		var index = 0;
		Sure.sure(postfix[index++] == "3");
		Sure.sure(postfix[index++] == "4");
		Sure.sure(postfix[index++] == "2");
		Sure.sure(postfix[index++] == "*");
		Sure.sure(postfix[index++] == "1");
		Sure.sure(postfix[index++] == "5");
		Sure.sure(postfix[index++] == "-");
		Sure.sure(postfix[index++] == "2");
		Sure.sure(postfix[index++] == "3");
		Sure.sure(postfix[index++] == "^");
		Sure.sure(postfix[index++] == "^");
		Sure.sure(postfix[index++] == "/");
		Sure.sure(postfix[index++] == "+");
	}
}

class TestExpressionTokenizer extends TestCase {
	public function testTokenWithSpaces():Void {
		// TODO
	}
}