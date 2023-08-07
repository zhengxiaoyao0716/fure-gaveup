package fure.web;

import fure.http.*;
import fure.Info;
import fure.rx.*;
import fure.test.Assert;
import fure.web.*;

using fure.Tools;
using StringTools;

@:route('/test')
class WebTest implements Router {
	public function new() {}

	public function test():Promise<Any> {
		return index().onSuccess(html -> assertEquals(indexHtml, html) !);
	}

	private final hook = new Hook();

	@:route.Get('/index.html')
	function index(?request):Promise<String> {
		var indexDom = hook.useMemo(Index.new).get();
		var props = indexDom.user.props;
		return Promise.all([
			props.name.set('Test User'),
			props.avatar.set('./avatar.png'),
			props.intro.set('Some Intro'),
			props.email.set('test@test.com'),
		]).onSuccessThen(_ -> indexDom.dom.toString());
	}
}

class Profile extends Element {
	public final props = {
		name: State.of(''),
		avatar: State.of(''),
		intro: State.of(''),
		email: State.of(''),
	};

	public function new(_props:{}, ?inner:Inner) {
		super('div', ['class' => 'profile']);
		this.body = hxx('
			<p classList=["name"]>${props.name}</p>
			<img classList=["avatar"] src=${props.avatar} />
			<p classList=["intro"]>${props.intro}</p>
			<a classList=["email"] href=(${props.email >> (email -> 'mailto:$email')}) />
			(inner)
		');
	}
}

class Index {
	public final dom:Document;
	public final user:Profile;

	public function new() {
		Document.hxx('
		<Document=dom lang="zh" title="Hello Fure-Web">
			<meta name="viewport" content="width=device-width, initial-scale=1.0"/>
			<Stylesheets ["index.css", "test.css"] />
			<Profile=user>
				<div id="test"><span>123</span></div>
				"test plain text"
			</Profile>
			<Scripts "index.js" />
		</Document>
		');
	}
}

private final indexHtml = '<!DOCTYPE html>
<html lang="zh">

<head>
  <!-- [fure-web ${FURE_VERSION}](${FURE_WEBSITE}) -->
  <meta charset="UTF-8" />
  <meta content="width=device-width, initial-scale=1.0" name="viewport" />
  <link href="favicon.ico" rel="shortcut icon" type="image/x-icon" />
  <link href="index.css" rel="stylesheet" />
  <link href="test.css" rel="stylesheet" />
  <title>Hello Fure-Web</title>
</head>

<body>
  <noscript>You need to enable JavaScript to run this app.</noscript>
  <div class="profile">
    <p class="name">Test User</p>
    <img class="avatar" src="./avatar.png" />
    <p class="intro">Some Intro</p>
    <a class="email" href="mailto:test@test.com" />
    <div id="test"><span>123</span></div>
    test plain text
  </div>
  <script src="index.js" />
</body>

</html>
'.replace('\r\n', '\n');
