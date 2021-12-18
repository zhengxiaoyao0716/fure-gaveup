package fure.rx;

class Observable<T> {
	var value:T;
	var observersId = 0;
	final observers:Map<Int, T->Void> = [];
	var updateTimer:Null<Promise<T>>;

	public function new(value:T)
		this.value = value;

	public function get():T {
		// TODO
		return value;
	}

	public function set(value:T):Promise<T> {
		this.value = value;
		if (this.updateTimer == null) {
			this.updateTimer = Promise.delay(() -> {
				this.updateTimer = null;
				for (_ => observer in observers)
					observer(this.value);
				return this.value;
			}, 0);
		}
		return this.updateTimer;
	}

	@:ifFeature('fure.rx.State.value')
	public inline function toString():String
		return Std.string(value);

	public function observe(observer:T->Void):() -> Void {
		var id = ++observersId;
		observers[id] = observer;
		return () -> observers.remove(id);
	}

	private static final computing:Tls<Null<() -> Void>> = new Tls();

	public static function compute<T>(computer:() -> T):Observable<T> {
		computing.value = () -> {
			// TODO
		};
		var value = computer();
		computing.value = null;
		// TODO
		return new Observable(value);
	}
}

#if target.threaded
typedef Tls<T> = sys.thread.Tls<T>;
#else
private class Tls<T> {
	public var value:T;

	public inline function new() {}
}
#end

@:forward
abstract State<T>(Observable<T>) from Observable<T> to Observable<T> {
	@:from
	public inline function new(init:T)
		this = new Observable(init);

	@:to
	public function value():T
		return this.get();

	@:op(A >> B)
	public function pipe<R>(mapper:T->R):State<R> {
		var state = new Observable(mapper(this.get()));
		this.observe(value -> state.set(mapper(value)));
		return state;
	}
}
