package fure.rx;

abstract Pipeable<T>(T) from T to T {
	public inline function peek(fn:T->Void):Pipeable<T> {
		fn(this);
		return this;
	}

	@:op(A >> B)
	public inline function pipe<R>(fn:T->R):Pipeable<R>
		return fn(this);

	@:op(A >> B)
	public function pipeAll(fns:Array<T->T>):Pipeable<T> {
		var value = this;
		for (fn in fns)
			value = fn(value);
		return value;
	}
}
