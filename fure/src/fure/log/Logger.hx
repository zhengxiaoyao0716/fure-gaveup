package fure.log;

import haxe.macro.Context;

#if macro
using haxe.macro.Tools;
#end
using fure.Tools;
using StringTools;

final defaultLevel = Level.getBuiltinByName(#if macro Context #else Tools #end.definedValue("FURE_LOG_LEVEL"));
final defaultFullTag = (Optional.ofNullable(#if macro Context #else Tools #end.definedValue("FURE_LOG_FULL_TAG")) || 'false') != 'false';
final defaultNoColor = (Optional.ofNullable(#if macro Context #else Tools #end.definedValue("FURE_LOG_NO_COLOR")) || 'false') != 'false';

typedef LoggerContext = {
	final name:String;
	final indent:String;
	final level:Level;
	function format(name:String, indent:String, level:Level, message:String, ?pos:haxe.PosInfos):String;
};

@:forward // forward all
@:using(fure.log.Logger)
abstract Logger(LoggerContext) from LoggerContext {
	public static function easy(config:{
		name:String,
		?indent:String,
		?level:Level,
		?fullTag:Bool,
		?noColor:Bool
	}):Logger {
		var formatConfig = {
			fullTag: Optional.ofNullable(config.fullTag) || defaultFullTag,
			noColor: Optional.ofNullable(config.noColor) || defaultNoColor,
		};
		var format = switch formatConfig {
			case {fullTag: true, noColor: true}: formatFullTagNoColorLogger;
			case {fullTag: true, noColor: false}: formatFullTagColorLogger;
			case {fullTag: false, noColor: true}: formatShortTagNoColorLogger;
			case {fullTag: false, noColor: false}: formatShortTagColorLogger;
			case _: null;
		}
		return {
			name: config.name,
			indent: Optional.ofNullable(config.indent) || ' ',
			level: Optional.ofNullable(config.level) || defaultLevel,
			format: format,
		};
	}

	public static function extend(logger:Logger, config:{
		name:String,
		?indent:String,
		?level:Level
	}):Logger {
		return {
			name: config.name,
			indent: logger.indent + (Optional.ofNullable(config.indent) || '    '),
			level: Optional.ofNullable(config.level) || logger.level,
			format: logger.format,
		}
	}

	public function print(level:Level, message:String, ?pos:haxe.PosInfos) {
		if (this.level <= level)
			stdoutWrite(this.format(this.name, this.indent, level, message, pos));
	}

	public inline function trace(message:String, ?pos:haxe.PosInfos)
		print(Level.TRACE, message, pos);

	public inline function info(message:String, ?pos:haxe.PosInfos)
		print(Level.INFO, message, pos);

	public inline function warn(message:String, ?pos:haxe.PosInfos)
		print(Level.WARN, message, pos);

	public inline function bingo(message:String, ?pos:haxe.PosInfos)
		print(Level.BINGO, message, pos);

	public inline function error(message:String, ?pos:haxe.PosInfos)
		print(Level.ERROR, message, pos);
}

function formatFullTagNoColorLogger(name:String, indent:String, level:Level, message:String, ?pos:haxe.PosInfos):String
	return easyFormat(name, indent, level.fullTag, message, pos);

function formatFullTagColorLogger(name:String, indent:String, level:Level, message:String, ?pos:haxe.PosInfos):String
	return ansiFormat(name, indent, level.ansi, level.fullTag, message, pos);

function formatShortTagNoColorLogger(name:String, indent:String, level:Level, message:String, ?pos:haxe.PosInfos):String
	return easyFormat(name, indent, level.shortTag, message, pos);

function formatShortTagColorLogger(name:String, indent:String, level:Level, message:String, ?pos:haxe.PosInfos):String
	return ansiFormat(name, indent, level.ansi, level.shortTag, message, pos);

inline function easyFormat(name:String, indent:String, tag:String, message:String, ?pos:haxe.PosInfos):String
	return '${formatPos(pos)}${tag}$name$indent$message';

inline function ansiFormat(name:String, indent:String, ansi:String, tag:String, message:String, ?pos:haxe.PosInfos):String
	return '${formatPos(pos)}\033[0;${ansi}m$tag\033[$ansi;1m$name\033[0m$indent\033[${ansi}m$message\033[0m';

function formatPos(?pos:haxe.PosInfos) {
	var text = '${pos.fileName}:${pos.lineNumber}: ';
	return text.rpad(' ', (text.length >> 4 << 4) + 16);
}

inline function stdoutWrite(text:String):Void {
	#if sys Sys.println(text) #elseif js js.Browser.window.console.log(text) #else trace(text) #end;
}
