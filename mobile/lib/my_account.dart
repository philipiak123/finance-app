import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class MyAccount extends StatefulWidget {
  final String userEmail;
  final int userId;
  int userMode; // Zmiana na pole, które można modyfikować

  MyAccount({
    required this.userEmail,
    required this.userId,
    required this.userMode,
  });

  @override
  _MyAccountState createState() => _MyAccountState();
}

class _MyAccountState extends State<MyAccount> {
  late bool isDarkMode;

  @override
  void initState() {
    super.initState();
    isDarkMode = widget.userMode == 1;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: Scaffold(
        appBar: AppBar(
          title: Text('Moje Konto'),
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              DrawerHeader(
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[850]! : Colors.blue,
                ),
                child: Text(
                  'Menu',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                ),
              ),
              ListTile(
                title: Text('My Account'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Text('Categories'),
                onTap: () {
                  Navigator.pushNamed(context, '/categories', arguments: {
                    'userEmail': widget.userEmail,
                    'userId': widget.userId,
                    'userMode': widget.userMode,
                  });
                },
              ),
              ListTile(
                title: Text('Expenses'),
                onTap: () {
                  Navigator.pushNamed(context, '/expenses', arguments: {
                    'userEmail': widget.userEmail,
                    'userId': widget.userId,
                    'userMode': widget.userMode,
                  });
                },
              ),
            ],
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('My Account'),
              Text('Email: ${widget.userEmail}'),
              ElevatedButton(
                onPressed: () {
                  _showChangePasswordDialog(context, isDarkMode);
                },
                child: Text('Change password'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDarkMode ? Colors.grey[900] : Colors.blue,
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  _toggleUserMode();
                },
                child: Text('Zmień tryb użytkownika'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDarkMode ? Colors.grey[900] : Colors.blue,
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/',
                    (Route<dynamic> route) => false,
                  );
                },
                child: Text('Logout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDarkMode ? Colors.grey[900] : Colors.blue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context, bool isDarkMode) {
    TextEditingController currentPasswordController = TextEditingController();
    TextEditingController newPasswordController = TextEditingController();
    TextEditingController confirmNewPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white,
          title: Text(
            'Zmiana hasła',
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Actual password',
                    labelStyle: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                ),
                TextField(
                  controller: newPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'New password',
                    labelStyle: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                ),
                TextField(
                  controller: confirmNewPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Confirm new password',
                    labelStyle: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
              ),
            ),
            ElevatedButton(
              onPressed: () {
                _updatePassword(
                  currentPasswordController.text,
                  newPasswordController.text,
                  confirmNewPasswordController.text,
                  context,
                  isDarkMode,
                );
              },
              child: Text('Change'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDarkMode ? Colors.grey[900] : Colors.blue,
              ),
            ),
          ],
        );
      },
    );
  }

  void _updatePassword(
    String currentPassword,
    String newPassword,
    String confirmPassword,
    BuildContext context,
    bool isDarkMode,
  ) async {
    if (newPassword != confirmPassword) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: isDarkMode ? Colors.grey[850]! : Colors.white,
            title: Text(
              'Błąd',
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            content: Text(
              'The new password and its confirmation are not the same.',
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            actions: [
              TextButton(
                child: Text(
                  'OK',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: TextButton.styleFrom(
                ),
              ),
            ],
          );
        },
      );
      return;
    }

    final url = Uri.parse('http://localhost:3000/update_password');
    final response = await http.post(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'userId': widget.userId,
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      }),
    );

    if (response.statusCode == 200) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: isDarkMode ? Colors.grey[850]! : Colors.white,
            title: Text(
              'Sukces',
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            content: Text(
              'Hasło zostało pomyślnie zmienione.',
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            actions: [
              TextButton(
                child: Text(
                  'OK',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop(); 
                },
                style: TextButton.styleFrom(
                ),
              ),
            ],
          );
        },
      );
    } else {
      String errorMessage = 'Nie udało się zmienić hasła. Spróbuj ponownie później.';
      if (response.body.isNotEmpty) {
        try {
          final errorJson = jsonDecode(response.body);
          if (errorJson.containsKey('message')) {
            errorMessage = errorJson['message'];
          }
        } catch (e) {
          print('Błąd dekodowania JSON: $e');
          print('Odpowiedź serwera: ${response.body}');
        }
      }

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: isDarkMode ? Colors.grey[850]! : Colors.white,
            title: Text(
              'Błąd',
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            content: Text(
              errorMessage,
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            actions: [
              TextButton(
                child: Text(
                  'OK',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: TextButton.styleFrom(
                  // backgroundColor: Colors.blue, // Możesz ustawić tło przycisku tutaj, jeśli jest potrzebne
                ),
              ),
            ],
          );
        },
      );
    }
  }

  void _toggleUserMode() async {
    final url = Uri.parse('http://localhost:3000/toggle_mode_mobile');
    try {
      final response = await http.post(
        url,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'userId': widget.userId,
        }),
      );

      if (response.statusCode == 200) {
        final newMode = jsonDecode(response.body)['newMode'];
        setState(() {
          // Ustawienie nowego trybu użytkownika
          widget.userMode = newMode;
          // Ustawienie isDarkMode na podstawie nowego trybu użytkownika
          isDarkMode = newMode == 1;
        });
        print('Sucesfully changed theme: $newMode');
      } else {
        throw Exception('Nie udało się przełączyć trybu użytkownika');
      }
    } catch (e) {
      print('Błąd podczas przełączania trybu użytkownika: $e');
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: isDarkMode ? Colors.grey[850]! : Colors.white,
            title: Text(
              'Błąd',
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            content: Text(
              'Nie udało się przełączyć trybu użytkownika. Spróbuj ponownie później.',
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            actions: [
              TextButton(
                child: Text(
                  'OK',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: TextButton.styleFrom(
                  // Tutaj możesz ustawić tło przycisku, jeśli jest potrzebne
                ),
              ),
            ],
          );
        },
      );
    }
  }
}
