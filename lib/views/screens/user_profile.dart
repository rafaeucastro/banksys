import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spacepay/models/auth.dart';

import '../../models/exceptions/auth_exception.dart';
import '../../providers/users.dart';
import '../../util/routes.dart';
import '../../util/utils.dart';

class UserProfile extends StatelessWidget {
  const UserProfile({super.key});

  void _takePicture(BuildContext context) async {
    final File? photo = await Provider.of<Users>(context, listen: false)
        .setUserProfilePicture();

    if (photo == null) return;
  }

  void _changePassword(BuildContext context) {
    Utils.showLoadingDialog(context);

    final email = Provider.of<Auth>(context, listen: false).client.email;

    try {
      FirebaseAuth.instance.sendPasswordResetEmail(email: email).then((value) {
        Navigator.of(context).pop();
        Utils.showSnackBar(
          "Para resetar a sua senha siga os passos no email que enviamos para você.",
          context,
        );
      });
    } on FirebaseAuthException catch (error) {
      Utils.showSnackBar(AuthException.translateException(error.code), context);
      Navigator.of(context).pop();
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final client = Provider.of<Auth>(context, listen: false).client;
    final textScale = MediaQuery.of(context).textScaleFactor;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        backgroundColor: colorScheme.background,
        title: const Text("Meu Perfil"),
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Consumer<Auth>(
                  builder: (context, auth, child) {
                    final profilePicture = auth.client.profilePicture;

                    return Column(
                      children: [
                        profilePicture != null
                            ? Hero(
                                tag: profilePicture,
                                child: CircleAvatar(
                                  backgroundImage: FileImage(profilePicture),
                                  maxRadius: 120,
                                ),
                              )
                            : const CircleAvatar(
                                maxRadius: 120,
                                backgroundImage:
                                    AssetImage('assets/images/app_logo2.jpg'),
                              ),
                        child!
                      ],
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(top: 20.0),
                    child: Text(
                      client.fullName,
                      style: TextStyle(
                        fontSize: textScale * 50,
                        fontFamily: 'Eczar',
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: size.height * 0.25,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(200, 50),
                      ),
                      onPressed: () => _takePicture(context),
                      child: const Text("Alterar foto do perfil"),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(200, 50),
                      ),
                      onPressed: () => _changePassword(context),
                      child: const Text("Alterar senha"),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(200, 50),
                      ),
                      onPressed: () {
                        Provider.of<Auth>(context, listen: false).logout();
                        Navigator.of(context)
                            .pushReplacementNamed(AppRoutes.LOGIN);
                      },
                      child: const Text("Sair"),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
