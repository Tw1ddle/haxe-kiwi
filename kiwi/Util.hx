package kiwi;

class Util {
	public static inline var floatMax:Float = 1e20;
	
	public static inline function nearZero(value:Float):Bool {
		return value < 0.0 ? -value < 1.0e-8 : value < 1.0e-8;
	}
}