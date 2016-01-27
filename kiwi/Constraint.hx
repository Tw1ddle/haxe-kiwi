package kiwi;

/*
 * The linear constraint relational operators.
 */
@:enum abstract RelationalOperator(String) {
	var LE = "<=";
	var EQ = "==";
	var GE = ">=";
}

/*
 * A linear constraint equation.
 * A constraint equation is composed of an expression, an operator, and a strength.
 * The right hand side of the equation is implicitly zero.
 */
class Constraint {
	public var expression(default, null):Expression;
	public var operator(default, null):RelationalOperator;
	public var strength(default, null):Float;
	
	public inline function new(expression:Expression, operator:RelationalOperator, ?strength:Null<Float>) {
		Sure.sure(expression != null && operator != null);
		
		if (strength == null) {
			strength = Strength.required;
		}
		
		this.expression = reduce(expression);
		this.operator = operator;
		this.strength = Strength.clamp(strength);
	}
	
	private static function reduce(expr:Expression):Expression {
		Sure.sure(expr != null);
		
		var vars = new Map<Variable, Float>();
		
		for (term in expr.terms) {
			var value:Null<Float> = vars.get(term.variable);
			if (value == null) {
				value = 0.0;
			}
			vars.set(term.variable, value += term.coefficient);
		}
		
		var reducedTerms = new Array<Term>();
		for (variable in vars.keys()) {
			reducedTerms.push(new Term(variable, vars.get(variable)));
		}
		
		return new Expression(reducedTerms, expr.constant);
	}
}