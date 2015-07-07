package kiwi;

class Term {
	public var variable(get, null):Variable;
	public var coefficient(get, null):Float;
	
	public inline function new(variable:Variable, coefficient:Float = 1.0) {
		Sure.sure(variable != null);
		
		this.variable = variable;
		this.coefficient = coefficient;
	}
	
	public function value():Float {
		return variable.value * coefficient;
	}
	
	private function get_variable():Variable {
		return variable;
	}
	
	private function get_coefficient():Float {
		return coefficient;
	}
}