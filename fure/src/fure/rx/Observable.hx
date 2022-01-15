package fure.rx;

import fure.ds.Tls;
import fure.rx.Promise.Future;
import haxe.Timer;
import haxe.Exception;
import haxe.ds.Option;
import haxe.Constraints.IMap;

class Observable<T> {
	public var value(get, null):Option<T>;

	var observersId = 0;
	final observers:Map<Int, T->Void> = [];
	var updateTimer:Null<Future<T>> = null;

	public function new(value:Option<T>)
		this.value = value;

	private inline function get_value():Option<T>
		return this.value;

	public function get():T {
		var computing = Observable.computing.value;
		if (computing != null)
			computing(this);
		return switch this.value {
			case Some(v): v;
			case None: throw new ValueAbsentException();
		};
	}

	public function next(value:T):T {
		this.value = Some(value);
		for (_ => recompute in depending)
			recompute();
		for (_ => observer in observers)
			observer(value);
		if (this.updateTimer != null && this.updateTimer.status.match(Pending(_))) {
			var updateTimer = this.updateTimer;
			this.updateTimer = null;
			updateTimer.setSuccess(value);
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

	@:ifFeature('fure.rx.Observable.value')
	public inline function toString():String
		return switch this.value {
			case Some(v): Std.string(v);
			case None: Std.string(this.value);
		};

	public function observe(observer:T->Void, peekCurrent = false):{cancel:() -> Void} {
		var id = ++observersId;
		observers[id] = updateTimer == null ? observer : _v -> observers[id] = observer;
		if (peekCurrent) {
			switch this.value {
				case Some(v):
					observer(v);
				case None:
			}
		}
		return {cancel: observers.remove.bind(id)};
	}

	public inline function pipe<R>(op:Operator<T, R>):Observable<R>
		return op.pipe(this);

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

class ValueAbsentException extends Exception {
	public function new() {
		super('state has not been initialized');
	}
}
