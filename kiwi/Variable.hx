package kiwi;

class Variable {
	public var name:String;
	public var value:Float;
	
	public inline function new(name:String, value:Float = 0.0) {
		Sure.sure(name != null && name.length > 0);
		
		this.name = name;
		this.value = value;
	}
}