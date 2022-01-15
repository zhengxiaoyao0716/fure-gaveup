package fure.rx;

import haxe.PosInfos;
import fure.ds.Tls;

private typedef Id = String;

class Hook {
	private final _storage:Tls<Map<Id, Any>> = new Tls();
	private var storage(get, never):Map<Id, Any>;

	private function get_storage():Map<Id, Any> {
		var value = _storage.value;
		if (value != null)
			return value;
		var value:Map<Id, Any> = [];
		_storage.value = value;
		return value;
	}

	public function new() {}

	public function useMemo<T>(computer:() -> T, ?pos:PosInfos):Observable<T> {
		var Id = '${pos.className}.${pos.methodName}#L${pos.lineNumber}';
		var storage = this.storage;
		var observable = storage.get(Id);
		if (observable != null)
			return observable;
		var observable = Observable.compute(computer);
		storage.set(Id, observable);
		return observable;
	}
}
