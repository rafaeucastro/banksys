import 'dart:convert';
import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:brasil_fields/brasil_fields.dart';
import 'package:flutter/cupertino.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;

import 'package:spacepay/util/constants.dart';
import 'package:spacepay/models/user.dart';

class Users with ChangeNotifier {
  static late final List<Client> clients;
  static late final List<Admin> admins;
  // ignore: prefer_final_fields
  List<Client> _clientList = [];
  // ignore: prefer_final_fields
  List<Admin> _adminList = [];
  Client? loggedClient;

  Users(this.loggedClient, this._clientList);

  List<Client> get getClients => [..._clientList];
  // List<Admin> get admins => [..._adminList];

  Future<void> loadAdmins() async {
    _adminList.clear();

    late final http.Response responseAdm;

    try {
      responseAdm = await http.get(Uri.parse(Constants.adminsUrl));
    } on http.ClientException {
      return;
    } catch (error) {
      return;
    }
    final Map<String, dynamic> dataAdm = jsonDecode(responseAdm.body) ?? {};

    dataAdm.forEach((userID, admData) {
      _adminList.add(Admin(
        state: admData[UserAttributes.state],
        cpf: admData[UserAttributes.cpf],
        fullName: admData[UserAttributes.fullName],
        address: admData[UserAttributes.address],
        password: admData[UserAttributes.password],
        databaseID: userID,
      ));
    });

    admins = _adminList;

    notifyListeners();
  }

  Future<void> loadClients() async {
    _clientList.clear();
    late final http.Response response;

    //TODO: lidar com as exceções. ex: caso o usuário não tenha net
    try {
      response = await http.get(Uri.parse(Constants.clientsUrl));
    } on http.ClientException {
      return;
    } catch (error) {
      return;
    }

    final Map<String, dynamic> data = jsonDecode(response.body);

    data.forEach((userID, userData) {
      final newClient = Client(
        email: userData[UserAttributes.email].toString(),
        accountType: userData[UserAttributes.accountType].toString(),
        fullName: userData[UserAttributes.fullName].toString(),
        address: userData[UserAttributes.address].toString(),
        password: userData[UserAttributes.password].toString(),
        phone: int.parse(userData[UserAttributes.phone] ?? '0'),
        cpf: userData[UserAttributes.cpf].toString(),
        databaseID: userID,
      );

      _clientList.add(newClient);
    });

    clients = _clientList;

    notifyListeners();
  }

  void addClient({required Map<String, String> clientData}) async {
    String phone =
        UtilBrasilFields.removeCaracteres(clientData[UserAttributes.phone]!);
    String cpf = clientData[UserAttributes.cpf]!;
    String email = clientData[UserAttributes.email]!;
    String password = clientData[UserAttributes.password]!;
    String accountType = clientData[UserAttributes.accountType]!;
    String fullName = clientData[UserAttributes.fullName]!;
    String address = clientData[UserAttributes.address]!;

    final response = await http.post(
      Uri.parse('${Constants.baseUrl}/clients.json'),
      body: jsonEncode({
        UserAttributes.phone: phone,
        UserAttributes.cpf: cpf,
        UserAttributes.email: email,
        UserAttributes.password: password,
        UserAttributes.accountType: accountType,
        UserAttributes.fullName: fullName,
        UserAttributes.address: address,
      }),
    );

    final id = jsonDecode(response.body)['name'].toString();

    final newClient = Client(
      email: email,
      password: password,
      accountType: accountType,
      fullName: fullName,
      address: address,
      cpf: cpf,
      phone: int.parse(phone),
      databaseID: id,
    );

    _clientList.add(newClient);
  }

  Future<void> addAdmin({required Map<String, String> userData}) async {
    final newAdmin = Admin(
      state: userData[UserAttributes.state]!,
      fullName: userData[UserAttributes.fullName]!,
      address: userData[UserAttributes.address]!,
      password: userData[UserAttributes.password]!,
      cpf: userData[UserAttributes.cpf]!,
      databaseID: userData[UserAttributes.cpf]!,
    );

    _adminList.add(newAdmin);
  }

  Future<File?> _takePicture() async {
    final ImagePicker picker = ImagePicker();
    XFile? imageFile = await picker.pickImage(
      source: ImageSource.camera,
      maxHeight: 800,
      maxWidth: 800,
    );

    if (imageFile == null) return null;

    return File(imageFile.path);
  }

  Future<File?> setUserProfilePicture() async {
    final storedImage = await _takePicture();

    //if the user don't take the picture
    if (storedImage == null) return null;

    //get only the file's name
    final String fileExtension = path.extension(storedImage.path);
    final appDir = await getApplicationDocumentsDirectory();

    //save the picture locally
    final newProfilePicture = await storedImage.copy(
        '${appDir.path}/profile_picture-${loggedClient!.cpf}$fileExtension');

    loggedClient!.setProfilePicture(storedImage);

    notifyListeners();
    return newProfilePicture;
  }

  Future<File?> loadProfilePicture() async {
    final appDir = await getApplicationDocumentsDirectory();

    final profilePicture =
        File('${appDir.path}/profile_picture-${loggedClient!.cpf}.jpg');

    if (await profilePicture.exists()) {
      loggedClient!.profilePicture = profilePicture;
      return profilePicture;
    }

    return null;
  }
}
