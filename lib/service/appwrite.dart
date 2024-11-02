import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:provider_celuler/model/user.dart';
import 'package:provider_celuler/screen/home.dart';
import 'package:provider_celuler/screen/login.dart';

class AppwriteService {
  Client client = Client();
  late Account account;
  late Databases databases;

  AppwriteService() {
    client
      ..setEndpoint('https://cloud.appwrite.io/v1') // Ganti dengan endpoint Appwrite Anda
      ..setProject("6724d1c0003415dc6d41"); // Ganti dengan project ID Appwrite Anda

    account = Account(client);
    databases = Databases(client);
  }

  // Fungsi untuk mendaftarkan pengguna baru
  Future<UserModel?> register(String email, String password, String name, String phoneNumber, int balance) async {
    try {
      final user = await account.create(
        userId: ID.unique(),
        email: email,
        password: password,
        name: name,
      );

      // Membuat dokumen pengguna di database dengan balance awal 0
      await createUserDocument(
        user.$id,
        UserModel(
          id: user.$id,
          name: user.name,
          email: user.email,
          phoneNumber: phoneNumber,
          balance: 0.0, // Balance awal disetel ke 0
        ),
      );

      return UserModel(
        id: user.$id,
        name: user.name,
        email: user.email,
        phoneNumber: phoneNumber,
        balance: 0.0,
      );
    } on AppwriteException catch (e) {
      print("Gagal register: $e");
      if (e.code == 409) {
        throw 'Email sudah digunakan, silahkan gunakan email lain';
      }
      throw 'Terjadi kesalahan saat register';
    }
  }

  // Fungsi untuk login pengguna
  Future<void> login(String email, String password, context) async {
    try {
      await account.createEmailPasswordSession(
        email: email,
        password: password,
      );

      print('Login berhasil');
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomePage()),
          (route) => false);
    } on AppwriteException catch (e) {
      print("Gagal login: $e");
      if (e.code == 401) {
        throw 'Email dan password salah';
      }
      throw 'Terjadi kesalahan saat login, pastikan internet Anda terhubung';
    }
  }

  // Fungsi untuk logout pengguna
  Future<void> logout(context) async {
    try {
      await account.deleteSession(sessionId: 'current');
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false);
    } catch (e) {
      throw Exception('Gagal logout');
    }
  }

  // Fungsi untuk membuat dokumen pengguna di database
  Future<void> createUserDocument(String userId, UserModel user) async {
    try {
      await databases.createDocument(
        databaseId: '6724de5400350de98022', // Ganti dengan ID database Anda
        collectionId: '6724de6200104a26cecb', // Ganti dengan ID koleksi Anda
        documentId: userId,
        data: user.toMap(),
      );
    } catch (e) {
      throw Exception('Terjadi kesalahan saat membuat dokumen pengguna');
    }
  }

  // Mendapatkan detail pengguna saat ini
  Future<UserModel?> getCurrentUser() async {
    try {
      final user = await account.get();
      final userDocument = await getUserDocument(user.$id);
      return userDocument;
    } catch (e) {
      throw Exception('Gagal mengambil data pengguna saat ini');
    }
  }

  // Mengambil dokumen pengguna dari database
  Future<UserModel?> getUserDocument(String userId) async {
    try {
      final userDocument = await databases.getDocument(
        databaseId: '6724de5400350de98022', // Ganti dengan ID database Anda
        collectionId: '6724de6200104a26cecb', // Ganti dengan ID koleksi Anda
        documentId: userId,
      );

      print(userId);
      return UserModel.fromMap(userDocument.data);
    } catch (e) {
      throw Exception('Gagal mengambil dokumen pengguna');
    }
  }
}
