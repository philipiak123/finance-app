import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RegistrationPage extends StatefulWidget {
  @override
  _RegistrationPageState createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _errorMessage; // Dodajemy pole przechowujące informację o błędzie

  Future<void> _register(BuildContext context) async {
    final response = await http.post(
      Uri.parse('http://192.168.50.174:3000/register'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'email': _emailController.text,
        'password': _passwordController.text,
      }),
    );

    if (response.statusCode == 201) {
      // Jeśli rejestracja powiedzie się, możesz przekierować użytkownika na stronę logowania
      Navigator.pushNamed(context, '/');
    } else {
      // Obsługa błędu rejestracji
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      final String? errorMessage = responseData['error'];

      setState(() {
        _errorMessage = errorMessage; // Ustawiamy komunikat błędu
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Rejestracja'),
        automaticallyImplyLeading: false, // Usunięcie strzałki cofania
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Hasło'),
              obscureText: true,
            ),
            if (_errorMessage != null) // Wyświetlenie komunikatu błędu, jeśli istnieje
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red),
                ),
              ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _register(context),
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(Color(0xFF22BF4C)), // Kolor tła
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0), // Zaokrąglenie rogów
                  ),
                ),
              ),
              child: Container(
                width: double.infinity, // Szerokość przycisku równa szerokości inputów
                child: Center(
                  child: Text(
                    'Zarejestruj się',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
            SizedBox(height: 10),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/'); // Przejście do ekranu logowania
              },
              child: Text('Masz już konto? Zaloguj się'),
            ),
          ],
        ),
      ),
    );
  }
}
