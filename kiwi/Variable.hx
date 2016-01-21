package kiwi;

class Variable {
	public var name:String;
	public var value:Float;
	
	public inline function new(name:String, value:Float = 0.0) {
		Sure.sure(name != null);
		
		this.name = name;
		this.value = value;
	}
}