package kiwi.frontend;

import haxe.ds.GenericStack;
import kiwi.Constraint;
import kiwi.Constraint.RelationalOperator;
import kiwi.Expression;
import kiwi.Strength;
import kiwi.Symbolics.ExpressionSymbolics;
import kiwi.Symbolics.VariableSymbolics;
import kiwi.Term;
import kiwi.Variable;

/*
 * Runtime parser for strings -> Kiwi constraints.
 * Adapted from Alex Birkett's kiwi-java port: https://github.com/alexbirkett/kiwi-java
 */
class ConstraintParser {
	private static inline var ops:String = "-+/*^";
	private static var pattern = new EReg("\\s*(.*?)\\s*(<=|==|>=)\\s*(.*?$)", "i");
	
	/*
	 * Parses an equation and returns a constraint based on the string.
	 * Constraints are written in the form: a [==|<=|>=] b [/*] c [+-] d 
	 * Throws if the string could not be parsed.
	 */
	public static function parseConstraint(constraintString:String, ?strengthString:String = "required", resolver:IResolver):Constraint {
		var matched:Bool = pattern.match(constraintString);
		
		if (!matched) {
			throw "Failed to parse " + constraintString;
		}
		
		var variable:Variable = resolver.resolveVariable(StringTools.trim(pattern.matched(1)));
		var relationalOperator:RelationalOperator = parseEqualityOperator(StringTools.trim(pattern.matched(2)));
		var expression:Expression = resolveExpression(StringTools.trim(pattern.matched(3)), resolver);
		var strength:Float = parseStrength(strengthString);
		
		return new Constraint(VariableSymbolics.subtractExpression(variable, expression), relationalOperator, strength);		
	}
	
	private static function resolveExpression(expressionString:String, resolver:IResolver):Expression {
		var postFixExpression:Array<String> = infixToPostfix(tokenizeExpression(expressionString));
		var expressionStack = new GenericStack<Expression>();
		
		for (expression in postFixExpression) {
			if (expression == "+") {
				var a = expressionStack.pop();
				var b = expressionStack.pop();
				expressionStack.add(ExpressionSymbolics.addExpression(a, b));
			} else if (expression == "-") {
				var a = expressionStack.pop();
				var b = expressionStack.pop();
				expressionStack.add(ExpressionSymbolics.subtractExpression(b, a));
			} else if (expression == "/") {
				var denominator = expressionStack.pop();
				var numerator = expressionStack.pop();
				expressionStack.add(ExpressionSymbolics.divideByExpression(numerator, denominator));
			} else if (expression == "*") {
				var a = expressionStack.pop();
				var b = expressionStack.pop();
				expressionStack.add(ExpressionSymbolics.multiplyByExpression(a, b));
			} else {
				var linearExpression:Expression = resolver.resolveConstant(StringTools.trim(expression));
				if (linearExpression == null) {
					var term = new Array<Term>();
					term.push(new Term(resolver.resolveVariable(StringTools.trim(expression))));
					linearExpression = new Expression(term);
				}
				expressionStack.add(linearExpression);
			}
		}
		
		Sure.sure(!expressionStack.isEmpty());
		return expressionStack.pop();
	}
	
	private static function parseEqualityOperator(operatorString:String):RelationalOperator {
		operatorString = StringTools.trim(operatorString);
		return switch(operatorString) {
			case RelationalOperator.EQ, RelationalOperator.GE, RelationalOperator.LE:
				cast operatorString;
			default:
				throw "Failed to convert string " + operatorString + " to a relational operator";
				null;
		}
	}
	
	private static function parseStrength(strengthString:String):Float {
		Sure.sure(strengthString != null);
		
		return switch(StringTools.trim(strengthString)) {
			case "required":
				Strength.required;
			case "strong":
				Strength.strong;
			case "medium":
				Strength.medium;
			case "weak":
				Strength.weak;
			default:
				var s = Std.parseFloat(strengthString);
				if (Math.isNaN(s)) {
					throw "Failed to parse strength string: " + strengthString;
					s;
				} else {
					s;
				}
		}
	}
	
	private static function tokenizeExpression(expressionString:String):Array<String> {		
		var tokens = new Array<String>();
		var builder:String = "";
		var i = 0;
		for (i in 0...expressionString.length) {
			var ch:String = expressionString.charAt(i);
			switch(ch) {
				case '+', '-', '*', '/', '(', ')':
					if (builder.length > 0) {
						tokens.push(builder);
						builder = "";
					}
					tokens.push(ch);
				case ' ':
				default:
					builder += ch;
			}
		}
		if (builder.length > 0) {
			tokens.push(builder);
		}
		return tokens;
	}
	
	private static function infixToPostfix(tokens:Array<String>):Array<String> {
		var s = new GenericStack<Int>();
		var postfix = new Array<String>();
		
		for (token in tokens) {
			var c:String = token.charAt(0);
			var idx:Int = ops.indexOf(c);
			if (idx != -1 && token.length == 1) {
				if (s.isEmpty()) {
					s.add(idx);
				} else {
					while (!s.isEmpty()) {
						var prec2:Int = Std.int(s.first() / 2);
						var prec1:Int = Std.int(idx / 2);
						if (prec2 > prec1 || (prec2 == prec1 && c != "^")) {
							postfix.push(ops.charAt(s.pop()));
						} else {
							break;
						}
					}
					s.add(idx);
				}
			} else if (c == "(") {
				s.add(-2);
			} else if (c == ")") {
				while (s.first() != -2) {
					postfix.push(ops.charAt(s.pop()));
				}
				s.pop();
			} else {
				postfix.push(token);
			}
		}
		
		while (!s.isEmpty()) {
			postfix.push(ops.charAt(s.pop()));
		}
		
		return postfix;
	}
}