package fure.rx;

@:forward
abstract State<T>(Observable<T>) from Observable<T> to Observable<T> {
	public inline function new()
		this = new Observable(None);

	@:noUsing
	@:from
	public static inline function of<T>(value:T):State<T>
		return new Observable(Some(value));

	@:to
	public function value():T
		return this.get();

	@:op(A >> B)
	public inline function pipe<R>(op:Operator<T, R>):State<R>
		return this.pipe(op);

	public static inline function compute<T>(computer:() -> T):State<T> {
		return Observable.compute(computer);
	}
}
