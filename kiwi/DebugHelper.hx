package kiwi;

import kiwi.Constraint.RelationalOperator;
import kiwi.Solver.ConstraintMap;
import kiwi.Solver.EditMap;
import kiwi.Solver.RowMap;
import kiwi.Solver.VarMap;

@:access(kiwi.Solver)
class DebugHelper {
	/*
	 * Dump a representation of the solver internals to log output.
	 */
	public static inline function dumpSolverState(solver:Solver):Void {
		traceHelper(spacer());
		traceHelper("Objective");
		traceHelper(dumpRow(solver.objective));
		traceHelper(spacer());
		traceHelper("Tableau");
		traceHelper(dumpRows(solver.rows));
		traceHelper(spacer());
		traceHelper("Infeasible");
		traceHelper(dumpSymbols(solver.infeasibleRows));
		traceHelper(spacer());
		traceHelper("Variables");
		traceHelper(dumpVars(solver.vars));
		traceHelper(spacer());
		traceHelper("Edit Variables");
		traceHelper(dumpEdits(solver.edits));
		traceHelper(spacer());
		traceHelper("Constraints");
		traceHelper(dumpConstraints(solver.constraints));
		traceHelper(spacer());
	}
	
	private static inline function traceHelper(str:String):Void {
		if (str == null || StringTools.trim(str).length == 0) {
			trace("NONE");
			return;
		}
		
		trace(str);
	}
	
	public static inline function dumpRows(rows:RowMap):String {
		var dump:String = "";
		
		for (key in rows.keys()) {
			dump += "\n";
			dump += dumpSymbol(key);
			dump += " | ";
			dump += dumpRow(rows.get(key));
		}
		return dump;
	}
	
	public static inline function dumpSymbols(symbols:Array<Symbol>):String {
		var dump:String = "";
		
		for (symbol in symbols) {
			dump += "\n";
			dump += dumpSymbol(symbol);
		}
		return dump;
	}
	
	public static inline function dumpVars(vars:VarMap):String {
		var dump:String = "";
		
		for (key in vars.keys()) {
			dump += "\n";
			dump += key.name + " = ";
			dump += dumpSymbol(vars.get(key));
		}
		return dump;
	}
	
	public static inline function dumpEdits(edits:EditMap):String {
		var dump:String = "";
		
		for (key in edits.keys()) {
			dump += "\n";
			dump += key.name;
		}
		return dump;
	}
	
	public static inline function dumpConstraints(constraints:ConstraintMap):String {
		var dump:String = "";
		
		for (key in constraints.keys()) {
			dump += "\n";
			dump += dumpConstraint(key);
		}
		return dump;
	}
	
	public static inline function dumpRow(row:Row):String {
		if (row == null) {
			return "null row";
		}
		
		var dump:String = "";
		dump += Std.string(row.constant);
		for (key in row.cells.keys()) {
			dump += (" + " + row.cells.get(key) + " * ");
			dump += dumpSymbol(key);
		}
		return dump;
	}
	
	public static inline function dumpSymbol(symbol:Symbol):String {
		if (symbol == null) {
			return "null symbol";
		}
		
		return Std.string(symbol.type);
	}
	
	public static inline function dumpConstraint(constraint:Constraint):String {
		if (constraint == null) {
			return "null constraint";
		}
		
		var dump:String = "";
		
		for (term in constraint.expression.terms) {
			if (term.variable.name != null) {
				dump += (term.coefficient + " * " + term.variable.name + " + ");
			} else {
				dump += (term.coefficient + " + ");
			}
		}
		dump += Std.string(constraint.expression.constant);
		
		switch(constraint.op) {
			case RelationalOperator.LE:
				dump += " <= 0 ";
			case RelationalOperator.GE:
				dump += " >= 0 ";
			case RelationalOperator.EQ:
				dump += " == 0 ";
		}
		
		dump += ("| strength = ");
		if (constraint.strength == Strength.required) {
			dump += "REQUIRED";
		} else if (constraint.strength == Strength.strong) {
			dump += "STRONG";
		} else if (constraint.strength == Strength.medium) {
			dump += "MEDIUM";
		} else if (constraint.strength == Strength.weak) {
			dump += "WEAK";
		} else {
			dump += constraint.strength;
		}
		
		return dump;
	}
	
	private static inline function spacer():String {
		return new String("----------");
	}
}