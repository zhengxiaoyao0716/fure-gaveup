package web;

import fure.Assert.assertEquals;
import fure.web.*;

using fure.Tools;
using StringTools;

class Web_test {
	public static function test() {
		var html = '<!DOCTYPE html>
<html lang="zh">

<head>
  <!-- [fure-web 0.0.1](https://github.com/zhengxiaoyao0716/furegame) -->
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <link type="image/x-icon" rel="shortcut icon" href="favicon.ico" />
  <link rel="stylesheet" href="index.css" />
  <title>Hello Fure-Web</title>
</head>

<body>
  <noscript>You need to enable JavaScript to run this app.</noscript>
  <div class="profile">
    <p class="name">Test User</p>
    <img src="./avatar.png" class="avatar" />
    <p class="intro">Some Intro</p>
    <a href="mailto:test@test.com" class="email" />
    <div id="test"><span>123</span></div>
    test plain text
  </div>
  <script src="index.js" />
</body>

</html>
';

		assertEquals(html.replace('\r\n', '\n'), new Web_test().index().toString()).ok();
	}

	private static var title = 'Hello Fure-Web';

	public function new() {}

	@:page('index.html')
	public function index():Document {
		var user = {
			name: 'Test User',
			avatar: './avatar.png',
			intro: 'Some Intro',
			email: 'test@test.com',
		};
		return Document.hxx('
		<Document lang="zh" title=title>
		<meta name="viewport" content="width=device-width, initial-scale=1.0"/>
		<Stylesheets ["index.css"] />
		<Profile (user)>
			<div id="test"><span>123</span></div>
			"test plain text"
		</Profile>
		<Scripts ["index.js"] />
		</Document>
		');
	}
}

typedef ProfileProps = {
	name:String,
	avatar:String,
	intro:String,
	email:String,
};

class Profile extends Element {
	public function new(props:ProfileProps, ?inner:Inner) {
		var inner = hxx('
			<p classList=["name"]>${props.name}</p>
			<img classList=["avatar"] src=${props.avatar} />
			<p classList=["intro"]>${props.intro}</p>
			<a classList=["email"] href=\'mailto:${props.email}\' />
			(inner)
		');
		super('div', ['class' => 'profile'], inner);
	}
}
