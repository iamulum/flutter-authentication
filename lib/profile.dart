import 'package:flutter/material.dart';

class Profile extends StatelessWidget {
  final Future<void> Function() logoutAction;
  final String name;
  final String email;
  final String division;
  final String picture;

  const Profile(
    this.logoutAction,
    this.name,
    this.email,
    this.division,
    this.picture, {
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blue, width: 4),
              shape: BoxShape.circle,
              // image: DecorationImage(
              //   fit: BoxFit.fill,
              //   image: NetworkImage(picture ?? ''),
              // ),
            ),
          ),
          const SizedBox(height: 24),
          const Text('FROM IDTOKEN'),
          Text('Name: $name'),
          Text('Email: $email'),
          // and many more
          const SizedBox(height: 48),
          const Text('FROM GETUSERINFO'),
          Text('Division: $division'),
          // only several fields from get user info
          const SizedBox(height: 48),
          ElevatedButton(
            onPressed: () async {
              await logoutAction();
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
