import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../models/app_user.dart';

class BranchService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> registerNewBranch({
    required String email,
    required String password,
    required String name,
    required String provinceId,
    required String cityId,
  }) async {
    final apiKey = Firebase.app().options.apiKey;
    final url = Uri.parse(
        'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$apiKey');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'password': password,
        'returnSecureToken': true,
      }),
    );

    final responseData = json.decode(response.body);

    if (response.statusCode != 200) {
      final error = responseData['error']['message'] ?? 'Gagal mendaftarkan cabang.';
      throw Exception(error);
    }

    final String localId = responseData['localId'];

    final newUser = AppUser(
      uid: localId,
      email: email,
      name: name,
      role: 'owner', // The creator of the branch is naturally the owner
      provinceId: provinceId,
      cityId: cityId,
    );

    await _db.collection('users').doc(localId).set(newUser.toFirestore());
    
    // Initialize default PINs for this new branch
    await _db
        .collection('provinces')
        .doc(provinceId)
        .collection('cities')
        .doc(cityId)
        .collection('settings')
        .doc('store_pins')
        .set({
      'pin_kasir': '111111',
      'pin_manager': '222222',
      'pin_owner': '333333',
    });
  }

  Stream<List<AppUser>> streamAllBranches() {
    return _db.collection('users').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => AppUser.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }
}
