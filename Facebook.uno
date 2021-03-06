using Uno;
using Uno.Collections;
using Fuse;
using Uno.Compiler.ExportTargetInterop;
using iOS.Foundation;

[TargetSpecificImplementation]
[ForeignInclude(Language.ObjC, "FBSDKCoreKit/FBSDKCoreKit.h")]
[ForeignInclude(Language.ObjC, "FBSDKLoginKit/FBSDKLoginKit.h")]
public extern(iOS) class Facebook
{
	static Facebook () {
		debug_log "Registering callback";
		Uno.Platform2.Application.ReceivedURI += OnReceivedUri;
	}

	static void OnReceivedUri(object sender, string uri) {
		if (uri.Substring(0,2) == "fb")
			Register(uri);
		// debug_log uri;
	}

	[Foreign(Language.ObjC)]
	extern(iOS)
	public static void Register(string s)
	@{
		NSURL *url = [[NSURL alloc] initWithString:s];
		NSString *src = @"com.apple.mobilesafari";
		[[FBSDKApplicationDelegate sharedInstance]
			application:[UIApplication sharedApplication]
			openURL:url
			sourceApplication:src
			annotation:nil];
	@}
}

[ForeignInclude(Language.Java,
                "android.app.Activity")]

[TargetSpecificImplementation]
public extern(Android) class Facebook
{
	static Facebook () {
	}

	bool inited = false;
	public void Login () {
		if (!inited) {
			_intentListener = Init();
			myCallbackManager = GetCallbackManager();
			inited = true;
		}
		LoginImpl();
	}

	static Java.Object myCallbackManager;
	static Java.Object _intentListener;

	[Foreign(Language.Java)]
	extern(Android) void LoginImpl ()
	@{
		Activity a = com.fuse.Activity.getRootActivity();
		com.facebook.CallbackManager callbackManager = (com.facebook.CallbackManager)@{myCallbackManager:Get()};
		com.facebook.login.LoginManager.getInstance().registerCallback(callbackManager,
		        new com.facebook.FacebookCallback<com.facebook.login.LoginResult>() {
		            @Override
		            public void onSuccess(com.facebook.login.LoginResult loginResult) {
		            	android.util.Log.d("@(Activity.Name)", "onSuccess");
		            }

		            @Override
		            public void onCancel() {
		            	android.util.Log.d("@(Activity.Name)", "onCancel");
		            }

		            @Override
		            public void onError(com.facebook.FacebookException exception) {
		            	android.util.Log.d("@(Activity.Name)", "onError");
		            }
		});
		com.facebook.login.LoginManager.getInstance().logInWithReadPermissions(a, java.util.Arrays.asList("public_profile", "user_friends"));

	@}

	[Require("Android.ResStrings.Declaration", "<string name=\"facebook_app_id\">insertidhere</string>")]
	[Require("AndroidManifest.ApplicationElement", "<meta-data android:name=\"com.facebook.sdk.ApplicationId\" android:value=\"@string/facebook_app_id\"/>")]
	[Require("AndroidManifest.ApplicationElement", "<activity android:name=\"com.facebook.FacebookActivity\"></activity>")]
	[Require("Gradle.Dependencies.Compile","com.facebook.android:facebook-android-sdk:[4,5)")]
	[Require("Gradle.Repository","mavenCentral()")]

	[Foreign(Language.Java)]
	extern(Android) static Java.Object GetCallbackManager()
	@{
		return com.facebook.CallbackManager.Factory.create();
	@}

	[Foreign(Language.Java)]
	extern(Android) static Java.Object Init ()
	@{
		Activity a = com.fuse.Activity.getRootActivity();
		com.facebook.FacebookSdk.sdkInitialize(((android.content.Context)a));

		com.fuse.Activity.ResultListener l = new com.fuse.Activity.ResultListener() {
		    @Override public boolean onResult(int requestCode, int resultCode, android.content.Intent data) {
		        return @{OnRecieved(int,int,Java.Object):Call(requestCode, resultCode, data)};
		    }
		};
		com.fuse.Activity.subscribeToResults(l);
		return l;
	@}

	[Foreign(Language.Java)]
	static extern(Android) bool OnRecieved(int requestCode, int resultCode, Java.Object data)
	@{
		android.content.Intent i = (android.content.Intent)data;
		com.facebook.CallbackManager callbackManager = (com.facebook.CallbackManager)@{myCallbackManager:Get()};
		return callbackManager.onActivityResult(requestCode, resultCode, i);
	@}

}

public extern(!iOS && !Android) class Facebook {}

