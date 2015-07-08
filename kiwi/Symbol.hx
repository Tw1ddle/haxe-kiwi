package kiwi;

enum SymbolType {
	Invalid;
	External;
	Slack;
	Error;
	Dummy;
}

class Symbol {
	public var type(default, null):SymbolType;
	public var id(default, null):Int;
	
	public inline function new(?type:SymbolType, id:Int = 0) {
		if (type == null) {
			type = SymbolType.Invalid;
		}
		this.type = type;
		this.id = id;
	}
}