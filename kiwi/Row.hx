package kiwi;

private typedef CellMap = Map<Symbol, Null<Float>>;

/*
 * An internal tableau row class used by the constraint solver.
 */
class Row {
	public var cells(default, null):CellMap;
	public var constant(default, null):Float;
	
	public inline function new(constant:Float = 0.0) {
		this.cells = new CellMap();
		this.constant = constant;
	}
	
	/*
	 * Create a copy of the row.
	 */
	public function copy():Row {
		var row = new Row();
		row.constant = constant;
		for (key in cells.keys()) {
			row.cells.set(key, cells.get(key));
		}
		return row;
	}
	
	/*
	 * Add a constant value to the row constant.
	 * The new value of the constant is returned.
	 */
	public inline function add(value:Float):Float {
		constant += value;
		return constant;
	}
	
	/*
	 * Insert a symbol into the row with a given coefficient.
	 * If the symbol already exists in the row, the coefficient will be added to the existing coefficient.
	 * If the resulting coefficient is zero, the symbol will be removed from the row.
	 */
	public function insertSymbol(symbol:Symbol, coefficient:Float = 1.0):Void {
		Sure.sure(symbol != null);
		
		var existingCoefficient:Null<Float> = cells.get(symbol);
		if (existingCoefficient != null) {
			coefficient += existingCoefficient;
		}
		
		if (Util.nearZero(coefficient)) {
			cells.remove(symbol);
		} else {
			cells.set(symbol, coefficient);
		}
	}
	
	/*
	 * Insert a row into this row with a given coefficient.
	 * The constant and the cells of the other row will be multiplied by the coefficient and added to this row.
	 * Any cell with a resulting coefficient of zero will be removed from the row.
	 */
	public function insertRow(row:Row, coefficient:Float = 1.0):Void {
		Sure.sure(row != null);
		Sure.sure(row != this);
		
		constant += row.constant * coefficient;
		
		for (key in row.cells.keys()) {
			var coeff:Float = row.cells.get(key) * coefficient;
			insertSymbol(key, coeff);
		}
	}
	
	/*
	 * Remove the given symbol from the row.
	 */ 
	public inline function remove(symbol:Symbol):Void {
		cells.remove(symbol);
	}
	
	/*
	 * Reverse the sign of the constant and all cells in the row.
	 */
	public function reverseSign():Void {
		constant = -constant;
		
		var newCells = new CellMap();
		for (key in cells.keys()) {
			var value:Float = -cells.get(key);
			newCells.set(key, value);
		}
		cells = newCells;
	}
	
	/*
	 * Solve the row for the given symbol.
	 * This method assumes the row is of the form a * x + b * y + c = 0 and (assuming solve for x) will modify the row to represent the right hand side of x = -b/a * y - c / a.
	 * The target symbol will be removed from the row, and the constant and other cells will be multiplied by the negative inverse of the target coefficient.
	 * The given symbol must exist in the row.
	 */
	public function solveForSymbol(symbol:Symbol):Void {
		Sure.sure(symbol != null);
		
		var cell:Null<Float> = cells.get(symbol);
		
		Sure.sure(cell != null && cell != 0); // NOTE assuming this can't deal with divide by 0
		
		var coefficient:Float = -1.0 / cell;
		cells.remove(symbol);
		constant *= coefficient;
		
		var newCells = new CellMap();
		for (key in cells.keys()) {
			var value:Float = cells.get(key) * coefficient;
			newCells.set(key, value);
		}
		cells = newCells;
	}
	
	/*
	 * Solve the row for the given symbols.
	 * This method assumes the row is of the form x = b * y + c and will solve the row such that y = x / b - c / b.
	 * The rhs symbol will be removed from the row, the lhs added, and the result divided by the negative inverse of the rhs coefficient.
	 * The lhs symbol must not exist in the row, and the rhs symbol must exist in the row.
	 */ 
	public function solveForSymbols(lhs:Symbol, rhs:Symbol):Void {
		Sure.sure(lhs != null && rhs != null);
		Sure.sure(cells.get(lhs) == null);
		Sure.sure(cells.get(rhs) != null);
		
		insertSymbol(lhs, -1.0);
		solveForSymbol(rhs);
	}
	
	/*
	 * Get the coefficient for the given symbol.
	 * If the symbol does not exist in the row, zero will be returned.
	 */
	public function coefficientFor(symbol:Symbol):Float {
		Sure.sure(symbol != null);
		
		var cell:Null<Float> = cells.get(symbol);
		if (cell == null) {
			return 0;
		} else {
			return cell;
		}
	}
	
	/*
	 * Substitute a symbol with the data from another row.
	 * Given a row of the form a * x + b and a substitution of the form x = 3 * y + c the row will be updated to reflect the expression 3 * a * y + a * c + b.
	 * If the symbol does not exist in the row, this is a no-op.
	 */
	public function substitute(symbol:Symbol, row:Row):Void {
		Sure.sure(symbol != null && row != null);
		
		var cell:Null<Float> = cells.get(symbol);
		if (cell != null) {
			cells.remove(symbol);
			insertRow(row, cell);
		}
	}
	
	/*
	 * Returns true if the row is a constant value.
	 */
	public inline function isConstant():Bool {
		var size:Int = 0;
		for (cell in cells) {
			size++;
		}
		return size == 0;
	}
}