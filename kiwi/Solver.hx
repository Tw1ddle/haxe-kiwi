package kiwi;

import kiwi.Constraint.RelationalOperator;
import kiwi.Symbol;

/*
 * The constraint solver.
 */
class Solver {
	private var constraints:ConstraintMap;
	private var rows:RowMap;
	private var vars:VarMap;
	private var edits:EditMap;
	private var infeasibleRows:Array<Symbol>;
	private var objective:Row;
	private var artificial:Row;
	private var sharedInvalidSymbol:Symbol; // Shared invalid to avoid new'ing invalid symbols wherever it is unnecessary
	
	/*
	 * Construct a new constraint solver.
	 */
	public function new() {
		reset();
	}
	
	/*
	 * Reset the solver to the empty starting condition.
	 * This method resets the internal solver state to the empty starting condition, as if no constraints or edit variables have been added.
	 */
	public inline function reset():Void {		
		constraints = new ConstraintMap();
		rows = new RowMap();
		vars = new VarMap();
		edits = new EditMap();
		infeasibleRows = new Array<Symbol>();
		objective = new Row();
		artificial = null;
		sharedInvalidSymbol = new Symbol();
	}
	
	/*
	 * Add a constraint to the solver.
	 * Throws
	 * ------
	 * DuplicateConstraint
	 * 	The given constraint has already been added to the solver.
	 * UnsatisfiableConstraint
	 *	The given constraint is required and cannot be satisfied.
	 */
	public function addConstraint(constraint:Constraint):Void {
		Sure.sure(constraint != null);
		
		if (constraints.exists(constraint)) {
			throw SolverError.DuplicateConstraint;
		}
		
		// Creating a row causes symbols to reserved for the variables in the constraint.
		// If this method exits with an exception, then its possible those variables will linger in the var map.
		// Since it's likely that those variables will be used in other constraints and since exceptional conditions are uncommon, I'm not too worried about aggressive cleanup of the var map.
		var tag:Tag = new Tag();
		var row:Row = createRow(constraint, tag);
		var subject:Symbol = chooseSubject(row, tag);

		// If chooseSubject could find a valid entering symbol, one last option is available if the entire row is composed of dummy variables.
		// If the constant of the row is zero, then this represents redundant constraints and the new dummy marker can enter the basis.
		// If the constant is non-zero, then it represents an unsatisfiable constraint.
		if (subject.type == SymbolType.Invalid && allDummies(row)) {
			if (!Util.nearZero(row.constant)) {
				throw SolverError.UnsatisfiableConstraint;
			} else {
				subject = tag.marker;
			}
		}
		
		// If an entering symbol still isn't found, then the row must be added using an artificial variable.
		// If that fails, then the row represents an unsatisfiable constraint.
		if (subject.type == SymbolType.Invalid) {
			if (!addWithArtificialVariable(row)) {
				throw SolverError.UnsatisfiableConstraint;
			}
		} else {
			row.solveForSymbol(subject);
			substitute(subject, row);
			rows.set(subject, row);
		}
		
		constraints.set(constraint, tag);
		
		// Optimizing after each constraint is added performs less aggregate work due to a smaller average system size.
		// It also ensures the solver remains in a consistent state.
		optimize(objective);
	}
	
	/*
	 * Remove a constraint from the solver.
	 * Throws
	 * ------
	 * UnknownConstraint
	 *	The given constraint has not been added to the solver.
	 */
	public function removeConstraint(constraint:Constraint):Void {
		Sure.sure(constraint != null);
		
		var tag:Tag = constraints.get(constraint);
		
		if (tag == null) {
			throw SolverError.UnknownConstraint;
		}
		
		constraints.remove(constraint);
		
		// Remove the error effects from the objective function before pivoting, or substitutions into the objective will lead to incorrect solver results.
		removeConstraintEffects(constraint, tag);
		
		// If the marker is basic, simply drop the row. Otherwise, pivot the marker into the basis and then drop the row.
		var marker = tag.marker;
		var row = rows.get(marker);
		
		if(row != null) {
			rows.remove(marker);
		} else {
			var leaving = getMarkerLeavingSymbol(marker);
			if (leaving.type == SymbolType.Invalid) {
				throw SolverError.InternalSolverError;
			}
			row = rows.get(leaving);
			rows.remove(leaving);
			row.solveForSymbols(leaving, marker);
			substitute(marker, row);
		}
		
		// Optimizing after each constraint is removed ensures that the solver remains consistent.
		// It makes the solver API easier to use at a small tradeoff for speed.
		optimize(objective);
	}
	
	/*
	 * Test whether the solver contains the constraint.
	 */
	public inline function hasConstraint(constraint:Constraint):Bool {
		Sure.sure(constraint != null);
		
		return constraints.exists(constraint);
	}
	
	/*
	 * Add an edit variable to the solver.
	 * This method should be called before the 'suggestValue' method is used to supply a suggested value for the given edit variable.
	 * Throws
	 * ------
	 * DuplicateEditVariable
	 * 	The given edit variable has already been added to the solver.
	 * BadRequiredStrength
	 *	The given strength is >= required.
	 */
	public function addEditVariable(variable:Variable, strength:Float):Void {
		Sure.sure(variable != null);
		
		if (edits.exists(variable)) {
			throw SolverError.DuplicateEditVariable;
		}
		
		strength = Strength.clamp(strength);
		
		if (strength == Strength.required) {
			throw SolverError.BadRequiredStrength;
		}
		
		var terms = new Array<Term>();
		terms.push(new Term(variable));
		var constraint = new Constraint(new Expression(terms), RelationalOperator.EQ, strength);
		addConstraint(constraint);
		var info = new EditInfo(constraint, constraints.get(constraint), 0.0);
		edits.set(variable, info);
	}
	
	/*
	 * Remove an edit variable from the solver.
	 * Throws
	 * ------
	 * UnknownEditVariable
	 *	The given edit variable has not been added to the solver.
	 */
	public function removeEditVariable(variable:Variable):Void {
		Sure.sure(variable != null);
		
		var edit = edits.get(variable);
		
		if (edit == null) {
			throw SolverError.UnknownEditVariable;
		}
		
		removeConstraint(edit.constraint);
		edits.remove(variable);
	}
	
	/* 
	 * Test whether the solver contains the edit variable.
	 */
	public inline function hasEditVariable(variable:Variable):Bool {
		Sure.sure(variable != null);
		
		return edits.exists(variable);
	}
	
	/*
	 * Suggest the value of an edit variable.
	 * This method should be used after an edit variable as been added to the solver in order to suggest the value for that variable.
	 * Throws
	 * ------
	 * UnknownEditVariable
	 *	The given edit variable has not been added to the solver.	
	 */	 
	public function suggestValue(variable:Variable, value:Float):Void {
		Sure.sure(variable != null);
		
		var info:EditInfo = edits.get(variable);
		if (info == null) {
			throw SolverError.UnknownEditVariable;
		}
		
		var delta:Float = value - info.constant;
		info.constant = value;
		
		// Check if the positive error variable is basic.
		var marker = info.tag.marker;
		var row:Row = rows.get(marker);
		if (row != null) {
			if (row.add(-delta) < 0.0) {
				infeasibleRows.push(marker);
			}
			dualOptimize();
			return;
		}
		
		// Check if the negative error variable is basic.
		var other = info.tag.other;
		var row = rows.get(other);
		if (row != null) {
			if (row.add(delta) < 0.0) {
				infeasibleRows.push(other);
			}
			dualOptimize();
			return;
		}
		
		// Otherwise update each row where the error variables exist.
		for (key in rows.keys()) {
			var currentRow:Row = rows.get(key);
			var coefficient:Float = currentRow.coefficientFor(marker);
			if (coefficient != 0.0 && currentRow.add(delta * coefficient) < 0.0 && key.type != SymbolType.External) {
				infeasibleRows.push(key);
			}
		}
		dualOptimize();
	}
	
	/*
	 * Update the values of the external solver variables.
	 */
	public function updateVariables():Void {
		for (key in vars.keys()) {
			var row:Row = rows.get(vars.get(key));
			
			if (row == null) {
				key.value = 0.0;
			} else {
				key.value = row.constant;
			}
		}
	}
	
	/*
	 * Get the symbol for the given variable.
	 * If a symbol does not exist for the variable, one will be created.
	 */
	private function getVarSymbol(variable:Variable):Symbol {
		Sure.sure(variable != null);
		
		var symbol:Symbol = vars.get(variable);
		if (symbol != null) {
			return symbol;
		}
		
		symbol = new Symbol(SymbolType.External);
		vars.set(variable, symbol);
		return symbol;
	}
	
	/*
	 * Create a new Row object for the given constraint.
	 * The terms in the constraint will be converted to cells in the row.
	 * Any term in the constraint with a coefficient of zero is ignored.
	 * This method uses the 'getVarSymbol' method to get the symbol for the variables added to the row.
	 * If the symbol for a given cell variable is basic, the cell variable will be substituted with the basic row.
	 * The necessary slack and error variables will be added to the row.
	 * If the constant for the row is negative, the sign for the row will be inverted so the constant becomes positive.
	 * The tag will be updated with the marker and error symbols to use for tracking the movement of the constraint in the tableau.
	 */
	private function createRow(constraint:Constraint, tag:Tag):Row {
		Sure.sure(constraint != null);
		
		var expression:Expression = constraint.expression;
		var row:Row = new Row(expression.constant);
		
		// Substitute the current basic variables into the row.
		for (term in expression.terms) {
			if (!Util.nearZero(term.coefficient)) {
				var symbol:Symbol = getVarSymbol(term.variable);
				var otherRow:Row = rows.get(symbol);
				if (otherRow == null) {
					row.insertSymbol(symbol, term.coefficient);
				} else {
					row.insertRow(otherRow, term.coefficient);
				}
			}
		}
				
		// Add the necessary slack, error, and dummy variables.
		var strength = constraint.strength;
		switch(constraint.operator) {
			case RelationalOperator.LE, RelationalOperator.GE: {
				var coefficient:Float = constraint.operator == RelationalOperator.LE ? 1.0 : -1.0;
				var slack = new Symbol(SymbolType.Slack);
				tag.marker = slack;
				row.insertSymbol(slack, coefficient);
				if (strength < Strength.required) {
					var error = new Symbol(SymbolType.Error);
					tag.other = error;
					row.insertSymbol(error, -coefficient);
					objective.insertSymbol(error, strength);
				}
			}
			case RelationalOperator.EQ: {
				if (constraint.strength < Strength.required) {
					var errorPlus = new Symbol(SymbolType.Error);
					var errorMinus = new Symbol(SymbolType.Error);
					tag.marker = errorPlus;
					tag.other = errorMinus;
					row.insertSymbol(errorPlus, -1.0);
					row.insertSymbol(errorMinus, 1.0);
					objective.insertSymbol(errorPlus, strength);
					objective.insertSymbol(errorMinus, strength);
				} else {
					var dummy = new Symbol(SymbolType.Dummy);
					tag.marker = dummy;
					row.insertSymbol(dummy);
				}
			}
		}
		
		// Ensure the row as a positive constant.
		if (row.constant < 0.0) {
			row.reverseSign();
		}
		
		return row;
	}
	
	/*
	 * Choose the subject for solving for the row.
	 * This method will choose the best subject for using as the solve target for the row.
	 * An invalid symbol will be returned if there is no valid target.
	 * The symbols are chosen according to the following precedence:
	 * 1) The first symbol representing an external variable.
	 * 2) A negative slack or error tag variable.
	 * If a subject cannot be found, an invalid symbol will be returned.
	 */
	private function chooseSubject(row:Row, tag:Tag):Symbol {
		Sure.sure(row != null && tag != null);
		
		for (key in row.cells.keys()) {
			if (key.type == SymbolType.External) {
				return key;
			}
		}
		
		if (tag.marker.type == SymbolType.Slack || tag.marker.type == SymbolType.Error) {
			if (row.coefficientFor(tag.marker) < 0.0) {
				return tag.marker;
			}
		}
		
		if (tag.other.type == SymbolType.Slack || tag.other.type == SymbolType.Error) {
			if (row.coefficientFor(tag.other) < 0.0) {
				return tag.other;
			}
		}
		
		return sharedInvalidSymbol;
	}
	
 	/*
	 * Add the row to the tableau using an artificial variable.
	 * This will return false if the constraint cannot be satisfied.
 	 */
	private function addWithArtificialVariable(row:Row):Bool {
		Sure.sure(row != null);
		
		// Create and add the artificial variable to the tableau.
		var art:Symbol = new Symbol(SymbolType.Slack);
		rows.set(art, row.copy());
		artificial = row.copy();
		
		// Optimize the artificial objective.
		// This is successful only if the artificial objective is optimized to zero.
		optimize(artificial);
		var success:Bool = Util.nearZero(artificial.constant);
		artificial = null;
		
		// If the artificial variable is basic, pivot the row so that it becomes non-basic.
		// If the row is constant, exit early.
		var row:Row = rows.get(art);
		rows.remove(art);
		if (row != null) {
			if (row.isConstant()) {
				return success;
			}
			
			var entering = anyPivotableSymbol(row);
			
			if (entering.type == SymbolType.Invalid) {
				return false;
			}
			
			row.solveForSymbols(art, entering);
			substitute(entering, row);
			rows.set(entering, row);
		}
		
		// Remove the artificial variable from the tableau.
		for (row in rows) {
			row.remove(art);
		}
		
		objective.remove(art);
		
		return success;
	}
	
	/*
	 * Substitute the parametric symbol with the given row.
	 * This method will substitute all instances of the parametric symbol in the tableau and the objective function with the given row.	
	 */
	private function substitute(symbol:Symbol, row:Row):Void {
		Sure.sure(symbol != null && row != null);
		
		for (key in rows.keys()) {
			var currentRow:Row = rows.get(key);
			currentRow.substitute(symbol, row);
			if (key.type != SymbolType.External && currentRow.constant < 0.0) {
				infeasibleRows.push(key);
			}
		}
		
		objective.substitute(symbol, row);
		if (artificial != null) {
			artificial.substitute(symbol, row);
		}
	}
	
	/*
	 * Optimize the system for the given objective function.
	 * This method performs iterations of Phase 2 of the simplex method until the objective function reaches a minimum.
	 * Throws
	 * ------
	 * InternalSolverError
	 *	The value of the objective function is unbounded.
	 */
	private function optimize(objective:Row):Void {
		Sure.sure(objective != null);
		
		while (true) {
			var entering:Symbol = getEnteringSymbol(objective);
			if (entering.type == SymbolType.Invalid) {
				return;
			}
			var leaving:Symbol = getLeavingSymbol(entering);
			if (leaving.type == SymbolType.Invalid) {
				throw SolverError.InternalSolverError;
			}
			
			// Pivot the entering symbol into the basis.
			var row = rows.get(leaving);
			rows.remove(leaving);
			row.solveForSymbols(leaving, entering);
			rows.set(entering, row);
			substitute(entering, row);
		}
	}
	
	/*
	 * Optimize the system using the dual of the simplex method.
	 * The current state of the system should be such that the objective function is optimal, but not feasible.
	 * This method will perform an iteration of the dual simplex method to make the solution both optimal and feasible.
	 * Throws
	 * ------
	 * InternalSolverError
	 *	The system cannot be dual optimized.
	 */
	private function dualOptimize():Void {
		while (infeasibleRows.length > 0) {
			var leaving:Symbol = infeasibleRows.pop();
			var row:Row = rows.get(leaving);
			if (row != null && row.constant < 0.0) {
				var entering:Symbol = getDualEnteringSymbol(row);
				if (entering.type == SymbolType.Invalid) {
					throw SolverError.InternalSolverError;
				}
				
				// Pivot the entering symbol into the basis.
				var removed = rows.remove(leaving);
				Sure.sure(removed);
				
				row.solveForSymbols(leaving, entering);
				substitute(entering, row);
				rows.set(entering, row);
			}
		}
	}
	
	/*
	 * Compute the entering variable for a pivot operation.
	 * This method will return first symbol in the objective function which is non-dummy and has a coefficient less than zero.
	 * If no symbol meets the criteria, it means the objective function is at a minimum, and an invalid symbol is returned.
	 */
	private function getEnteringSymbol(objective:Row):Symbol {
		Sure.sure(objective != null);
		
		for (key in objective.cells.keys()) {
			if (key.type != SymbolType.Dummy && objective.cells.get(key) < 0.0) {
				return key;
			}
		}
		
		return sharedInvalidSymbol;
	}
	
	/*
	 * Compute the entering symbol for the dual optimize operation.
	 * This method will return the symbol in the row which has a positive coefficient and yields the minimum ratio for its respective symbol in the objective function.
	 * The provided row must be infeasible.
	 * If no symbol is found which meets the criteria, an invalid symbol is returned.
	 */
	private inline function getDualEnteringSymbol(row:Row):Symbol {
		Sure.sure(row != null);
		
		var entering = sharedInvalidSymbol;
		var ratio:Float = Util.floatMax;
		for (key in row.cells.keys()) {
			if (key.type == SymbolType.Dummy) {
				continue;
			}
			
			var currentCell:Float = row.cells.get(key);
			
			if (currentCell <= 0.0) {
				continue;
			}
			
			var coefficient:Float = objective.coefficientFor(key);
			var r:Float = coefficient / currentCell;
			if (r < ratio) {
				ratio = r;
				entering = key;
			}
		}
		
		return entering;
	}
	
	/*
	 * Compute the symbol for pivot exit row.
	 * This method will return the symbol for the exit row in the row map.
	 * If no appropriate exit symbol is found, an invalid symbol will be returned.
	 * This indicates that the objective function is unbounded.
	 */
	private inline function getLeavingSymbol(entering:Symbol):Symbol {
		Sure.sure(entering != null);
		
		var ratio:Float = Util.floatMax;
		var symbol = sharedInvalidSymbol;
		
		for (key in rows.keys()) {
			if (key.type != SymbolType.External) {
				var row = rows.get(key);
				var temp = row.coefficientFor(entering);
				if (temp < 0.0) {
					var tempRatio = -row.constant / temp;
					if (tempRatio < ratio) {
						ratio = tempRatio;
						symbol = key;
					}
				}
			}
		}
		
		return symbol;
	}
	
	/*
	 * Compute the leaving symbol for a marker variable.
	 * This method will return a symbol corresponding to a basic row which holds the given marker variable.
	 * The row will be chosen according to the following precedence:
	 * 1) The row with a restricted basic varible and a negative coefficient for the marker with the smallest ratio of -constant / coefficient.
	 * 2) The row with a restricted basic variable and the smallest ratio of constant / coefficient.
	 * 3) The last unrestricted row which contains the marker.
	 * If the marker does not exist in any row, an invalid symbol will be returned.
	 * This indicates an internal solver error since the marker should exist somewhere in the tableau.
	 */
	private inline function getMarkerLeavingSymbol(marker:Symbol):Symbol {
		Sure.sure(marker != null);
		
		var r1:Float = Util.floatMax;
		var r2:Float = Util.floatMax;
		
		var first:Symbol = new Symbol();
		var second:Symbol = new Symbol();
		var third:Symbol = new Symbol();
		
		for (key in rows.keys()) {
			var candidateRow:Row = rows.get(key);
			
			var c:Float = candidateRow.coefficientFor(marker);
			if (c == 0.0) {
				continue;
			}
			
			if (key.type == SymbolType.External) {
				third = key;
			} else if (c < 0.0) {
				var r:Float = -candidateRow.constant / c;
				if (r < r1) {
					r1 = r;
					first = key;
				}
			} else {
				var r:Float = candidateRow.constant / c;
				if (r < r2) {
					r2 = r;
					second = key;
				}
			}
		}
		
		if (first.type != SymbolType.Invalid) {
			return first;
		}
		
		if (second.type != SymbolType.Invalid) {
			return second;
		}
		
		return third;
	}
	
	/*
	 * Remove the effects of a constraint on the objective function.
	 */
	private inline function removeConstraintEffects(constraint:Constraint, tag:Tag):Void {
		Sure.sure(constraint != null && tag != null);
		
		if (tag.marker.type == SymbolType.Error) {
			removeMarkerEffects(tag.marker, constraint.strength);
		} else if (tag.other.type == SymbolType.Error) {
			removeMarkerEffects(tag.other, constraint.strength);
		}
	}
	
	/*
	 * Remove the effects of an error marker on the objective function.
	 */
	private function removeMarkerEffects(marker:Symbol, strength:Float):Void {
		Sure.sure(marker != null);
		
		var row:Row = rows.get(marker);
		if (row != null) {
			objective.insertRow(row, -strength);
		} else {
			objective.insertSymbol(marker, -strength);
		}
	}
	
	/*
	 * Get the first Slack or Error symbol in the row.
	 * If no such symbol is present, an Invalid symbol will be returned.
	 */
	private function anyPivotableSymbol(row:Row):Symbol {
		Sure.sure(row != null);
		
		for (symbol in row.cells.keys()) {
			if (symbol.type == SymbolType.Slack || symbol.type == SymbolType.Error) {
				return symbol;
			}
		}
		
		return new Symbol();
	}
	
	/*
	 * Test whether a row is composed of all dummy variables.
	 */
	private function allDummies(row:Row):Bool {
		Sure.sure(row != null);
		
		for (key in row.cells.keys()) {
			if (key.type != SymbolType.Dummy) {
				return false;
			}
		}
		
		return true;
	}
}

@:enum abstract SolverError(String) {
	var UnsatisfiableConstraint = "The constraint cannot be satisfied.";
	var UnknownConstraint = "The constraint has not been added to the solver.";
	var DuplicateConstraint = "The constraint has already been added to the solver.";
	var UnknownEditVariable = "The edit variable has not been added to the solver.";
	var DuplicateEditVariable = "The edit variable has already been added to the solver.";
	var BadRequiredStrength = "A required strength cannot be used in this context.";
	var InternalSolverError = "An internal solver error occurred.";
}

private class Tag {
	public var marker:Symbol;
	public var other:Symbol;
	
	public inline function new() {
		marker = new Symbol();
		other = new Symbol();
	}
}

private class EditInfo {
	public var constraint:Constraint;
	public var tag:Tag;
	public var constant:Float;
	
	public inline function new(constraint:Constraint, tag:Tag, constant:Float) {
		Sure.sure(constraint != null);
		Sure.sure(tag != null);
		Sure.sure(Math.isFinite(constant));
		
		this.constraint = constraint;
		this.tag = tag;
		this.constant = constant;
	}
}

// TODO: Haxe maps don't have key,value pair iteration, which makes it less 1:1 to the cpp implementation and probably way more inefficient - implement kiwi/Loki AssocVector using Haxe Arrays?
// TODO: Also, what are the performance implications of doing pooling on symbols etc?
typedef ConstraintMap = Map<Constraint, Tag>;
typedef RowMap = Map<Symbol, Row>;
typedef VarMap = Map<Variable, Symbol>;
typedef EditMap = Map<Variable, EditInfo>;