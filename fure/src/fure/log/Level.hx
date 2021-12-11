package fure.log;

import fure.Tools.Optional;
import haxe.exceptions.ArgumentException;

using StringTools;

typedef LevelStruct = {
	final ordinal:Int;
	final fullTag:String;
	final shortTag:String;
	final ansi:Ansi;
};

@:forward // forward all
abstract Level(LevelStruct) {
	public static final TRACE = builtin(1 << 5, '[ TRACE ] ', '    ', Ansi.WHITE);
	public static final INFO = builtin(2 << 5, '[ INFO  ] ', '[I] ', Ansi.BLUE);
	public static final WARN = builtin(3 << 5, '[ WARN  ] ', '[W] ', Ansi.YELLOW);
	public static final BINGO = builtin(4 << 5, '[ BINGO ] ', '', Ansi.GREEN);
	public static final ERROR = builtin(5 << 5, '[ ERROR ] ', '[E] ', Ansi.RED);

	private function new(ordinal:Int, fullTag:String, shortTag:String, ansi:Ansi) {
		this = {
			ordinal: ordinal,
			fullTag: fullTag,
			shortTag: shortTag,
			ansi: ansi
		};
	}

	public static function custom(ordinal:Int, fullTag:String, shortTag:String, ansi:Ansi):Level {
		var name = builtinLevelNames[ordinal];
		if (name == null)
			return new Level(ordinal, fullTag, shortTag, ansi);
		// ordinal & (TRACE.ordinal - 1) == 0 && ordinal <= ERROR.ordinal
		throw new ArgumentException('the ordinal of custom level duplicate with builtin Level.${name}');
	}

	private static function builtin(ordinal:Int, fullTag:String, shortTag:String, ansi:Ansi) {
		var name = fullTag.substr(2, -3).trim();
		builtinLevelNames[ordinal] = name;
		var level = new Level(ordinal, fullTag, shortTag, ansi);
		builtinNameLevels[name] = level;
		return level;
	}

	public static function getBuiltinByName(name:Null<String>):Level
		return Optional.ofNullable(name) && builtinNameLevels.get || INFO;

	@:op(A <= B)
	public inline function le(level:Level):Bool
		return this.ordinal <= level.ordinal;
}

private final builtinLevelNames:Map<Int, String> = [];
private final builtinNameLevels:Map<String, Level> = [];

enum abstract Ansi(Int) from Int to Int {
	var BLACK = 30;
	var RED = 31;
	var GREEN = 32;
	var YELLOW = 33;
	var BLUE = 34;
	var PURPLE = 35;
	var CYAN = 36;
	var WHITE = 37;

	@:to
	public inline function toString():String
		return Std.string(this);
}
