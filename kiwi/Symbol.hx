package kiwi;

@:enum abstract SymbolType(Int) {
	var Invalid = 0;
	var External = 1;
	var Slack = 2;
	var Error = 3;
	var Dummy = 4;
}

class Symbol {
	public var type(default, null):SymbolType;
	
	public inline function new(type:SymbolType = SymbolType.Invalid) {
		this.type = type;
	}
}