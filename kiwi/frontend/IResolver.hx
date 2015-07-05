package kiwi.frontend;

import kiwi.Expression;
import kiwi.Variable;

interface IResolver {
	public function resolveVariable(name:String):Variable;
	public function resolveConstant(expression:String):Expression;
}