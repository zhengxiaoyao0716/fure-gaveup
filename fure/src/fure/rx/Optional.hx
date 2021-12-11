package fure.rx;

abstract Optional<T>(Null<T>) to Null<T> {
	private inline function new(value:Null<T>)
		this = value;

	public inline function isEmpty():Bool
		return this == null;

	// #region factories

	@:noUsing
	public static inline function empty<T>():Optional<T>
		return null;

	@:noUsing
	public static inline function of<T>(value:T):Optional<T>
		return new Optional(value);

	@:noUsing
	public static inline function ofNullable<T>(value:Null<T>):Optional<T>
		return value == null ? empty() : Optional.of(value);

	@:noUsing
	public static inline function ofString(value:Null<String>):Optional<String>
		return value == '' ? empty() : Optional.ofNullable(value);

	@:noUsing
	public static inline function ofInt(value:Null<Int>):Optional<Int>
		return value == 0 ? empty() : Optional.ofNullable(value);

	@:noUsing
	public static inline function ofBool(value:Null<Bool>):Optional<Bool>
		return value == false ? empty() : Optional.ofNullable(value);

	@:noUsing
	public static inline function ofArray<T>(value:Null<Array<T>>):Optional<Array<T>>
		return value.length == 0 ? empty() : Optional.ofNullable(value);

	// #endregion
	// #region operators

	@:op(A && B)
	public inline function andFlatMap<R>(mapper:T->Optional<R>):Optional<R>
		return isEmpty() ? empty() : mapper(this);

	@:op(A && B)
	public inline function andFlat<R>(next:Optional<R>):Optional<R>
		return isEmpty() ? empty() : next;

	@:op(A && B)
	public inline function andMap<R>(mapper:T->R):Optional<R>
		return isEmpty() ? empty() : of(mapper(this));

	@:op(A && B)
	public inline function and<R>(next:R):Optional<R>
		return isEmpty() ? empty() : of(next);

	@:op(A || B)
	public inline function orFlatGet(ifNull:() -> Optional<T>):Optional<T>
		return isEmpty() ? ifNull() : of(this);

	@:op(A || B)
	public inline function orFlat(ifNull:Optional<T>):Optional<T>
		return isEmpty() ? ifNull : of(this);

	@:op(A || B)
	public inline function orGet(ifNull:() -> T):T
		return isEmpty() ? ifNull() : this;

	@:op(A || B)
	public inline function or(ifNull:T):T
		return isEmpty() ? ifNull : this;

	// #endregion
}
