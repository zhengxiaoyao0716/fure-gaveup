package fure.rx;

import fure.rx.Promise.Future;
import haxe.Timer;
import haxe.Exception;
import haxe.ds.Option;
import haxe.Constraints.IMap;

class Observable<T> {
	var value:Option<T>;
	var observersId = 0;
	final observers:Map<Int, T->Void> = [];
	var updateTimer:Null<Future<T>>;

	public function new(value:Option<T>)
		this.value = value;

	public function get():T {
		if (computing.value != null)
			computing.value(this);
		return switch value {
			case Some(v): v;
			case None: throw new ValueAbsentException();
		};
	}

	public function fock<R>(present:T->Option<R>, ?absent:() -> Option<R>):Observable<R> {
		return switch value {
			case Some(v): new Observable(present(v));
			case None: new Observable(absent == null ? None : absent());
		}
	}

	public function next(value:T):T {
		this.value = Some(value);
		for (_ => recompute in depending)
			recompute();
		for (_ => observer in observers)
			observer(value);
		if (this.updateTimer != null && this.updateTimer.status.match(Pending(_))) {
			this.updateTimer.setSuccess(value);
			this.updateTimer = null;
		}
		return value;
	}

	// set = next & debounce(0)
	public function set(value:T):Promise<T> {
		this.value = Some(value);
		for (_ => recompute in depending)
			recompute();
		if (this.updateTimer == null) {
			this.updateTimer = Future.delay(() -> {
				this.updateTimer = null;
				var value = get();
				for (_ => observer in observers)
					observer(value);
				return Promise.resolve(value);
			}, 0);
		}
		return this.updateTimer;
	}

	@:ifFeature('fure.rx.State.value')
	public inline function toString():String
		return switch value {
			case Some(v): Std.string(v);
			case None: Std.string(value);
		};

	public function observe(observer:T->Void):{cancel:() -> Void} {
		var id = ++observersId;
		observers[id] = observer;
		return {cancel: observers.remove.bind(id)};
	}

	static final computing:Tls<Null<Observable<Any>->Void>> = new Tls();

	final depending:IMap<Observable<Any>, () -> Void> = //
		#if java
		new haxe.ds.WeakMap(); // [Available on all platforms???](https://api.haxe.org/haxe/ds/WeakMap.html)
		#else
		([] : Map<Observable<Any>, () -> Void>);
		#end

	public static function compute<T>(computer:() -> T):Observable<T> {
		var deps:Map<Observable<Any>, Any> = [];
		computing.value = (observable:Observable<Any>) -> deps[observable] = true;
		var value = computer();
		computing.value = null;

		var result = new Observable(Some(value));
		var updateTimer:Null<Timer> = null;
		var recompute = () -> {
			if (updateTimer != null)
				return;
			updateTimer = Timer.delay(() -> {
				var value = computer();
				result.value = Some(value);
				for (_ => observer in result.observers)
					observer(value);
			}, 0);
		};
		for (observable => _ in deps)
			observable.depending.set(result, recompute);
		return result;
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
	public inline function new()
		this = new Observable(None);

	@:from
	public static inline function of<T>(value:T):State<T>
		return new Observable(Some(value));

	@:to
	public function value():T
		return this.get();

	@:op(A >> B)
	public function pipe<R>(op:Operator<T, R>):State<R> {
		var state:State<R> = op.init(this);
		this.observe(value -> op.iter(this, state));
		return state;
	}

	public static inline function compute<T>(computer:() -> T):State<T> {
		return Observable.compute(computer);
	}
}

private typedef _Op<T, R> = {init:State<T>->State<R>, iter:(State<T>, State<R>) -> Void};

@:forward
abstract Operator<T, R>(_Op<T, R>) from _Op<T, R> {
	// pipe = map & debounce(0)
	@:from
	public static function pipe<T, R>(mapper:T->R):Operator<T, R> {
		return {
			init: origin -> origin.fock(v -> Some(mapper(v))),
			iter: (origin, state) -> state.set(mapper(origin.get())),
		};
	}

	public static function map<T, R>(mapper:T->R):Operator<T, R> {
		return {
			init: origin -> origin.fock(v -> Some(mapper(v))),
			iter: (origin, state) -> state.next(mapper(origin.get())),
		};
	}

	public static function peek<T>(observer:T->Void):Operator<T, T> {
		return {
			init: origin -> origin.fock(v -> Some(v)),
			iter: (origin, state) -> {
				var value = origin.get();
				observer(value);
				state.next(value);
			},
		};
	}

	public static function filter<T>(predicate:T->Bool):Operator<T, T> {
		return {
			init: origin -> origin.fock(value -> predicate(value) ? Some(value) : None),
			iter: (origin, state) -> {
				var value = origin.get();
				if (predicate(value))
					state.next(value);
			},
		};
	}

	public static function debounce<T>(delay:Int):Operator<T, T> {
		var timer:Null<Timer>;
		return {
			init: origin -> origin.fock(v -> Some(v)),
			iter: (origin, state) -> {
				if (timer == null) {
					timer = Timer.delay(() -> {
						timer = null;
						state.set(origin.get());
					}, delay);
				}
			},
		};
	}

	public static function throttle<T>(duration:Int):Operator<T, T> {
		var timer:Null<Timer>;
		return {
			init: origin -> origin.fock(v -> Some(v)),
			iter: (origin, state) -> {
				if (timer == null) {
					state.set(origin.get());
					timer = Timer.delay(() -> {
						timer = null;
					}, duration);
				}
			},
		};
	}

	public static function fold<T, R>(init:R, acc:(T, R) -> R):Operator<T, R> {
		return {
			init: origin -> init,
			iter: (origin, state) -> state.next(acc(origin.get(), state.get())),
		};
	}

	public static macro function sum<T>():ExprOf<Operator<T, T>> {
		return macro {
			init: origin -> origin.fock(v -> Some(v), () -> Some(0)),
			iter: (origin, state) -> state.next(origin.get() + state.get()),
		};
	}

	// (1, 2, 3, ...) => ([1], [1, 2], [1, 2, 3], ...)
	public static inline function push<T>(maxSize = -1):Operator<T, Array<T>> {
		return {
			init: origin -> origin.fock(v -> Some([v]), () -> Some([])),
			iter: (origin, state) -> {
				var arr = state.get();
				arr.push(origin.get());
				if (maxSize > 0) {
					var out = arr.length - maxSize;
					if (out > 0) {
						state.next(arr.slice(out));
						return;
					}
				}
				state.next(arr);
			},
		};
	}
}

class ValueAbsentException extends Exception {
	public function new() {
		super('state has not been initialized');
	}
}
