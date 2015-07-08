package kiwi;

class Expression {
	public var terms(default, null):Array<Term>;
	public var constant(default, null):Float;
	
	// TODO is there a way to get around having to create a new array and add the item manually if we only have 1 term?
	public inline function new(?terms:Array<Term>, constant:Float = 0.0) {
		if(terms == null) {
			terms = new Array<Term>();
		}
		this.terms = terms;
		this.constant = constant;
	}
	
	public function value():Float {
		var result = constant;
		for (term in terms) {
			result += term.value();
		}
		return result;
	}
	
	public inline function isConstant():Bool {
		return terms.length == 0;
	}
}