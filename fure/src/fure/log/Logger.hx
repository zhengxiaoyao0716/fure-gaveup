package fure.log;

import haxe.CallStack;
import haxe.CallStack.StackItem;
import haxe.Exception;
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

@:forward
@:using(fure.log.Logger)
abstract Logger(LoggerContext) from LoggerContext {
	@:from
	public static function easy(config:{
		name:String,
		?indent:String,
		?level:Level,
		?fullTag:Bool,
		?noColor:Bool
	}):Logger {
		var formatConfig = {
			fullTag: config.fullTag == null ? defaultFullTag : config.fullTag,
			noColor: config.noColor == null ? defaultNoColor : config.noColor,
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
			indent: config.indent == null ? ' ' : config.indent,
			level: config.level == null ? defaultLevel : config.level,
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
			indent: logger.indent + (config.indent == null ? '    ' : config.indent),
			level: config.level == null ? logger.level : config.level,
			format: logger.format,
		}
	}

	public function print(level:Level, message:String, ?pos:haxe.PosInfos) {
		if (this.level <= level)
			stdoutWrite(this.format(this.name, this.indent, level, message, pos));
	}

	public function trace(message:String, ?pos:haxe.PosInfos)
		inline print(Level.TRACE, message, pos);

	public function info(message:String, ?pos:haxe.PosInfos)
		inline print(Level.INFO, message, pos);

	public function warn(message:String, ?pos:haxe.PosInfos)
		inline print(Level.WARN, message, pos);

	public function bingo(message:String, ?pos:haxe.PosInfos)
		inline print(Level.BINGO, message, pos);

	public function error(message:String, ?error:Exception, ?pos:haxe.PosInfos) {
		var logPosStack = CallStack.toString([Method(pos.className, pos.methodName)]).trim();
		var stackAll = error.details().split('\n');
		var stack = '';
		for (line in stackAll) {
			stack += '\n    $line';
			if (line.startsWith(logPosStack))
				break;
		}
		inline print(Level.ERROR, '$message$stack', pos);
	}
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
