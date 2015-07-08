package kiwi;

class Term {
	public var variable(default, null):Variable;
	public var coefficient(default, null):Float;
	
	public inline function new(variable:Variable, coefficient:Float = 1.0) {
		Sure.sure(variable != null);
		
		this.variable = variable;
		this.coefficient = coefficient;
	}
	
	public inline function value():Float {
		return variable.value * coefficient;
	}
}