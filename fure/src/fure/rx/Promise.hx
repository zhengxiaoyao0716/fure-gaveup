package fure.rx;

import haxe.Timer;
import haxe.Exception;

@:using(fure.rx.Promise)
enum Status<V> {
	Pending(reject:Exception->Void);
	Resolved(value:V);
	Rejected(error:Exception);
}

@:using(fure.rx.Promise)
typedef PromiseLike<V> = {
	var status(default, null):Status<V>;
	function then<R>(mapper:Status<V>->PromiseLike<R>):PromiseLike<R>;
}

@:forward
@:using(fure.rx.Promise)
abstract Promise<V>(PromiseLike<V>) from PromiseLike<V> to PromiseLike<V> {
	@:noUsing
	public static inline function empty<V>():Promise<Null<V>>
		return Result.empty();

	@:from
	@:noUsing
	public static inline function resolve<V>(val:V):Promise<V>
		return Result.ofValue(val);

	@:noUsing
	public static inline function reject<V>(err:Exception):Promise<V>
		return Result.ofError(err);

	@:from
	@:noUsing
	public static inline function future<V>(task:Future<V>->Void):Promise<V>
		return new Future(task);

	public static inline function invoke<V>(task:() -> Promise<V>):Promise<V>
		return Result.invoke(task);

	@:noUsing
	public static inline function delay<V>(task:() -> Promise<V>, delay:Int):Promise<V> {
		return Future.delay(task, delay);
	}

	public static function value<V>(status:Status<V>):Null<V> {
		return switch status {
			case Pending(_): throw new PromiseException('access pending status');
			case Resolved(value): value;
			case Rejected(_): null;
		}
	}

	public static function error<V>(status:Status<V>):Null<Exception> {
		return switch status {
			case Pending(_): throw new PromiseException('access pending status');
			case Resolved(_): null;
			case Rejected(error): error;
		}
	}

	public static function onSuccess<V, R>(promise:PromiseLike<V>, listen:V->Void):PromiseLike<Null<R>> {
		return promise.then(status -> switch status {
			case Pending(_): promise.onSuccess(listen);
			case Resolved(value): {listen(value); empty();}
			case Rejected(_): (promise : Any);
		});
	}

	public static function onFailure<V, R>(promise:PromiseLike<V>, listen:Exception->Void):PromiseLike<Null<R>> {
		return promise.then(status -> switch status {
			case Pending(_): promise.onFailure(listen);
			case Resolved(_): empty();
			case Rejected(error): {listen(error); empty();};
		});
	}

	public static function onComplete<V, R>(promise:PromiseLike<V>, listen:Status<V>->Void):PromiseLike<Null<R>> {
		return promise.then(status -> switch status {
			case Pending(_): promise.onComplete(listen);
			case _: {listen(promise.status); empty();};
		});
	}

	public static function onSuccessThen<V, R>(promise:PromiseLike<V>, mapper:V->Promise<R>):PromiseLike<R> {
		return promise.then(status -> switch status {
			case Pending(_): promise.onSuccessThen(mapper);
			case Resolved(value): mapper(value);
			case Rejected(_): (promise : Any);
		});
	}

	public static function onFailureThen<V>(promise:PromiseLike<V>, mapper:Exception->Promise<V>):PromiseLike<V> {
		return promise.then(status -> switch status {
			case Pending(_): promise.onFailureThen(mapper);
			case Resolved(_): promise;
			case Rejected(error): mapper(error);
		});
	}

	public static function onCompleteThen<V, R>(promise:PromiseLike<V>, mapper:Status<V>->Promise<R>):PromiseLike<R> {
		return promise.then(status -> switch status {
			case Pending(_): promise.onCompleteThen(mapper);
			case _: mapper(promise.status);
		});
	}

	public static function all<V>(promises:Iterable<PromiseLike<V>>):Promise<Array<V>> {
		return future(future -> {
			final array:Array<Null<V>> = [];
			var pendings = 1;
			for (promise in promises) {
				if (pendings <= 0)
					return;
				pendings++;
				final index = array.length;
				array.push(null);
				promise.onSuccess(value -> {
					array[index] = value;
					if (--pendings == 0)
						future.setSuccess(array);
				}).onFailure(error -> {
					if (pendings <= 0)
						return;
					pendings = 0;
					future.setFailure(error);
				});
			}
			if (--pendings == 0)
				future.setSuccess(array);
		});
	}

	public static function any<V>(promises:Iterable<PromiseLike<V>>):PromiseLike<V> {
		return future(future -> {
			var pendings = 1;
			for (promise in promises) {
				if (pendings <= 0)
					return;
				pendings++;
				promise.onSuccess(value -> {
					if (pendings <= 0)
						return;
					pendings = 0;
					future.setSuccess(value);
				}).onFailure(error -> {
					if (--pendings == 0)
						future.setFailure(new PromiseException('all promises were rejected'));
				});
			}
			if (--pendings == 0)
				future.setFailure(new PromiseException('all promises were rejected'));
		});
	}
}

@:using(fure.rx.Promise)
class Future<V> {
	public var status(default, null):Status<V>;

	final listeners:List<() -> Void> = new List();

	public function new(?task:Future<V>->Void) {
		status = Pending(this.setFailure);
		if (task != null)
			task(this);
	}

	public static function delay<V>(task:() -> PromiseLike<V>, delay:Int):Future<V> {
		return new Future(future -> Timer.delay(() -> {
			Promise.invoke(task).onComplete(future.setComplete);
		}, delay));
	}

	public inline function setSuccess(value:V)
		setComplete(Resolved(value));

	public inline function setFailure(error:Exception)
		setComplete(Rejected(error));

	public function setComplete(status:Status<V>) {
		// if (!this.status.match(Pending(_)))
		// 	throw new PromiseException('future has already completed');
		// if (status.match(Pending(_)))
		// 	throw new PromiseException('status should not pending');
		if (!this.status.match(Pending(_)) || status.match(Pending(_)))
			return;
		this.status = status;
		while (!listeners.isEmpty()) {
			var listener = listeners.pop();
			listener();
		}
	}

	public function then<R>(mapper:Status<V>->PromiseLike<R>):PromiseLike<R> {
		if (status.match(Pending(_)))
			return new Future(future -> listeners.add(() -> {
				var result = tryThen(status, mapper);
				result.onComplete(future.setComplete);
			}));
		return tryThen(status, mapper);
	}
}

@:using(fure.rx.Promise)
private class Result<V> {
	public var status(default, null):Status<V>;

	inline function new(status:Status<V>) {
		this.status = status;
	}

	static final EMPTY:Result<Null<Any>> = new Result(Resolved(null));

	@:noUsing
	public static inline function empty<V>():Result<Null<V>>
		return (EMPTY : Any);

	@:noUsing
	public static inline function ofValue<V>(value:V):Result<V>
		return new Result(Resolved(value));

	@:noUsing
	public static inline function ofError<V>(error:Exception):Result<V>
		return new Result(Rejected(error));

	public static function invoke<V>(task:() -> Promise<V>):Promise<V> {
		try {
			return task();
		} catch (error:Exception) {
			return ofError(error);
		}
	}

	public function then<R>(mapper:Status<V>->PromiseLike<R>):PromiseLike<R>
		return tryThen(status, mapper);
}

private inline function tryThen<V, R>(status:Status<V>, mapper:Status<V>->PromiseLike<R>):PromiseLike<R> {
	try {
		return mapper(status);
	} catch (error:Exception) {
		return Result.ofError(error);
	}
}

class PromiseException extends Exception {
	public function new(message:String)
		super(message);
}
