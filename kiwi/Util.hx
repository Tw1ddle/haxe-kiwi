package kiwi;

class Util {
	public static inline var floatMax:Float = 1e20;
	
	private static inline var eps:Float = 1.0e-8;
	
	public static inline function nearZero(value:Float):Bool {
		return value < 0.0 ? -value < eps : value < eps;
	}
}