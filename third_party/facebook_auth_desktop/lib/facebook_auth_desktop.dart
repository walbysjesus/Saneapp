library;

import 'package:flutter_facebook_auth_platform_interface/flutter_facebook_auth_platform_interface.dart';

class FacebookAuthDesktopPlugin extends FacebookAuthPlatform {
  static void registerWith() {
    FacebookAuthPlatform.instance = FacebookAuthDesktopPlugin();
  }

  UnsupportedError _unsupported() => UnsupportedError(
        'facebook_auth_desktop is a local stub for dependency resolution only.',
      );

  @override
    Future<AccessToken?> get accessToken async => throw _unsupported();

  @override
    Future<LoginResult> expressLogin() async => throw _unsupported();

  @override
    Future<LoginResult> login({
        List<String> permissions = const ['email', 'public_profile'],
        LoginBehavior loginBehavior = LoginBehavior.dialogOnly,
    }) async =>
      throw _unsupported();

  @override
    Future<Map<String, dynamic>> getUserData({
        String fields = 'name,email,picture.width(200)',
    }) async =>
      throw _unsupported();

  @override
  Future<void> logOut() async => throw _unsupported();

  @override
    Future<void> webAndDesktopInitialize({
        required String appId,
        required bool cookie,
        required bool xfbml,
        required String version,
    }) async => throw _unsupported();

  @override
    bool get isWebSdkInitialized => false;

  @override
    Future<void> autoLogAppEventsEnabled(bool enabled) async =>
      throw _unsupported();

  @override
    Future<bool> get isAutoLogAppEventsEnabled async => false;

  @override
    Future<FacebookPermissions?> get permissions async => throw _unsupported();
}