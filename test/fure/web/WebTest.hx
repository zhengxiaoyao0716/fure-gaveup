package fure.web;

import fure.Info;
import fure.rx.Promise;
import fure.rx.State;
import fure.test.Assert;
import fure.web.*;

using fure.Tools;
using StringTools;

class WebTest {
	static final lang:State<String> = 'zh';

	public inline function new() {}

	public function test():Promise<Any> {
		var html = '<!DOCTYPE html>
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

		return index().onSuccess(document -> assertEquals(html, document.toString()) !);
	}

	@:page('index.html')
	function index():Promise<Document> {
		var title:State<String> = 'Hello Fure-Web';
		var user:ProfileProps = {
			name: '',
			avatar: '',
			intro: '',
			email: '',
		};
		var document = Document.hxx('
		<Document lang=lang title=title>
		<meta name="viewport" content="width=device-width, initial-scale=1.0"/>
		<Stylesheets ["index.css", "test.css"] />
		<Profile (user)>
			<div id="test"><span>123</span></div>
			"test plain text"
		</Profile>
		<Scripts "index.js" />
		</Document>
		');
		return Promise.all([
			user.name.set('Test User'),
			user.avatar.set('./avatar.png'),
			user.intro.set('Some Intro'),
			user.email.set('test@test.com'),
		]).onSuccessThen(_ -> document);
	}
}

typedef ProfileProps = {
	final name:State<String>;
	final avatar:State<String>;
	final intro:State<String>;
	final email:State<String>;
};

class Profile extends Element {
	public function new(props:ProfileProps, ?inner:Inner) {
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
