package fure;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;

using haxe.macro.Tools;
#end

#if macro
private function genGitCommitHash():String {
	#if display
	// `#if display` is used for code completion. In this case returning an
	// empty string is good enough; We don't want to call git on every hint.
	return '';
	#else
	var args = ['rev-parse', '--short', 'HEAD'];
	var process = try {
		new sys.io.Process('git', args);
	} catch (e:haxe.Exception) {
		Context.warning('Cannot execute `git ${args.join(' ')}`, ${e.message}', Context.currentPos());
		return '';
	}
	if (process.exitCode() != 0) {
		var message = process.stderr.readAll().toString();
		Context.warning('Cannot execute `git ${args.join(' ')}`, $message', Context.currentPos());
		return '';
	}
	// read the output of the process
	return process.stdout.readLine();
	#end
}
#end

private macro function getGitCommitHash():ExprOf<String>
	return macro $v{genGitCommitHash()};

final FURE_VERSION = #if macro Context #else Tools #end.definedValue('fure');
final VERSION_HASH = #if macro genGitCommitHash #else getGitCommitHash #end ();
final FURE_WEBSITE = 'https://github.com/zheng0716/fure' + (VERSION_HASH == '' ? '' : '/tree/$VERSION_HASH');
