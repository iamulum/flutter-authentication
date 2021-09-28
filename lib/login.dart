import 'package:flutter/material.dart';

class Login extends StatelessWidget {
  final Future<void> Function(String socmed) loginAction;
  final String loginError;

  const Login(this.loginAction, this.loginError, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        ElevatedButton(
          style: ElevatedButton.styleFrom(primary: Colors.red),
          onPressed: () async {
            await loginAction('google');
          },
          child: const Text('Sign in with Google'),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: () async {
            await loginAction('facebook');
          },
          child: const Text('Sign in with Facebook'),
        ),
        Text(loginError ?? ''),
      ],
    );
  }
}
