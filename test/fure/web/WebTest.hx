package fure.web;

import fure.Info;
import fure.log.Assert;
import fure.web.*;

using fure.Tools;
using StringTools;

class WebTest {
	static final title = 'Hello Fure-Web';

	public inline function new() {}

	public function test() {
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

		assertEquals(html, index().toString()) !;
	}

	@:page('index.html')
	function index():Document {
		var user = {
			name: 'Test User',
			avatar: './avatar.png',
			intro: 'Some Intro',
			email: 'test@test.com',
		};
		return Document.hxx('
		<Document lang="zh" title=title>
		<meta name="viewport" content="width=device-width, initial-scale=1.0"/>
		<Stylesheets ["index.css", "test.css"] />
		<Profile (user)>
			<div id="test"><span>123</span></div>
			"test plain text"
		</Profile>
		<Scripts "index.js" />
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
	final props:ProfileProps;
	final inner:Inner;

	public function new(props:ProfileProps, ?inner:Inner) {
		super('div', ['class' => 'profile']);
		this.props = props;
		this.inner = inner;
	}

	override function get_body():Inner {
		return hxx('
			<p classList=["name"]>${props.name}</p>
			<img classList=["avatar"] src=${props.avatar} />
			<p classList=["intro"]>${props.intro}</p>
			<a classList=["email"] href=\'mailto:${props.email}\' />
			(inner)
		');
	}
}
