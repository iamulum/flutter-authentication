import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'login.dart';
import 'profile.dart';

final FlutterAppAuth appAuth = FlutterAppAuth();
const FlutterSecureStorage secureStorage = FlutterSecureStorage();

/// Keycloack Variables
final String _domainEnv = dotenv.env['DOMAIN'];
final String _clientId = dotenv.env['CLIENT_ID'];
final String _redirectUri = dotenv.env['KYC_REDIRECT_URI'];

final String _realmsUri = '$_domainEnv/auth/realms/axiapp';
final String _oidUri = '$_realmsUri/protocol/openid-connect';
// based on _realmsUri/.well-known/configuration
final List<String> _scopes = <String>[
  'openid', // to get idToken (remove if u're not using idToken)
  'email',
  'user_attribute',
  'profile',
];

Future main() async {
  await dotenv.load(fileName: '.env');
  debugPrint(_domainEnv);
  debugPrint(_clientId);
  debugPrint(_redirectUri);
  debugPrint(_realmsUri);
  debugPrint(_oidUri);
  // Here we set the URL strategy for our web app.
  // It is safe to call this function when running on mobile or desktop as well.
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

// TODO: refactor using BLoc pattern and organize app routes
class _MyAppState extends State<MyApp> {
  bool isBusy = false;
  bool isLoggedIn = false;
  String errorMessage;
  String name;
  String email;
  String picture;
  String division;

  @override
  void initState() {
    initAction();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Keycloack Demo',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Keycloack Demo'),
        ),
        resizeToAvoidBottomInset: false,
        body: Center(
          child: isBusy
              ? const CircularProgressIndicator()
              : isLoggedIn
                  ? Profile(logoutAction, name, email, division, picture)
                  : Login(loginAction, errorMessage),
        ),
      ),
    );
  }

  Future<void> successAuthorizeUser(
    String accessToken,
    String refreshToken,
    String idToken,
  ) async {
    try {
      final Map<String, Object> decodedIdToken = parseIdToken(idToken);
      final Map<String, Object> userInfo = getUserInfo(accessToken);
      print('decoded $decodedIdToken');
      await secureStorage.write(key: 'refresh_token', value: refreshToken);
      debugPrint('userInfo ${userInfo['division']}');
      setState(() {
        isBusy = false;
        isLoggedIn = true;
        name = decodedIdToken['name'];
        email = decodedIdToken['email'];
        division = userInfo['division'];
      });
    } on Exception catch (e) {
      throw Exception('Failed action successAuthorizeUser:: $e');
    }
  }

  Map<String, Object> parseIdToken(String idToken) {
    final List<String> parts = idToken.split('.');
    assert(parts.length == 3);

    return jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
  }

  Map<String, String> getUserInfo(String accessToken) {
    // alternative get user info using accessToken
    final String url = '$_oidUri/userinfo';
    // TODO: hit $_oidc/userinfo using accessToken
    print('Action Get User Info Here: uri-$url, accToken-$accessToken');
    return {'division': 'device-gadget(example_return_from_user_info)'};
  }

  Future<void> loginAction(String socmed) async {
    setState(() {
      isBusy = true;
      errorMessage = '';
    });

    try {
      final AuthorizationTokenResponse result =
          await appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(_clientId, _redirectUri,
            issuer: _realmsUri, scopes: _scopes,
            // change to dynamic variable, if there are multiple socmed provided
            additionalParameters: {'kc_idp_hint': socmed}),
      );

      // debug Payload
      debugPrint('accessToken:::${result.accessToken}');
      debugPrint('refreshToken:::${result.refreshToken}');
      debugPrint('expired:::${result.accessTokenExpirationDateTime}');
      debugPrint('idToken:::${result.idToken}');
      debugPrint('tokenType:::${result.tokenType}');
      debugPrint(
          'extraAuthParams:::${result.authorizationAdditionalParameters}');
      debugPrint('extraTokenParams:::${result.tokenAdditionalParameters}');

      await successAuthorizeUser(
        result.accessToken,
        result.refreshToken,
        result.idToken,
      );
    } on Exception catch (e, s) {
      debugPrint('login error: $e - stack: $s');

      setState(() {
        isBusy = false;
        isLoggedIn = false;
        errorMessage = e.toString();
      });
    }
  }

  Future<void> logoutAction() async {
    final String refreshToken = await secureStorage.read(key: 'refresh_token');
    // TODO: hit $_oidc/logout using refreshToken
    print('Action Logout here with refresh token::$refreshToken');

    await secureStorage.delete(key: 'refresh_token');
    setState(() {
      isLoggedIn = false;
      isBusy = false;
    });
    print('PLEASE DO LOGOUT USER FROM SESSION ON KYC DASHBOARD');
  }

  Future<void> initAction() async {
    final String storedRefreshToken =
        await secureStorage.read(key: 'refresh_token');
    if (storedRefreshToken == null) return;

    setState(() {
      isBusy = true;
    });

    try {
      // TODO: hit refreshToken
      print('Action Refresh Token Here');
      // await successAuthorizeUser(
      //   response.accessToken,
      //   response.refreshToken,
      //   response.idToken,
      // );
      setState(() {
        isBusy = false;
      });
    } on Exception catch (e, s) {
      debugPrint('error on refresh token: $e - stack: $s');
      await logoutAction();
    }
  }
}
