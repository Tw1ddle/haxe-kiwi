package kiwi;

class Util {
	public static inline var floatMax:Float = 3.4028230e+38; // Largest single-precision IEEE-754
	
	private static inline var epsilon = 1.0e-8;
	public static inline function nearZero(value:Float):Bool {
		return value < 0.0 ? -value < epsilon : value < epsilon;
	}
}