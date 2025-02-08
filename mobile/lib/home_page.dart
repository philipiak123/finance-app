import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'expenses_page.dart'; // Import ekranu rejestracji

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String _errorMessage = '';
  int userMode = 0; // Dodanie zmiennej userMode

  Future<void> _login(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      final response = await http.post(
        Uri.parse('http://localhost:3000/login'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'email': _emailController.text,
          'password': _passwordController.text,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final String userEmail = responseData['user']['email'];
        final int userId = responseData['user']['id'];
        userMode = responseData['user']['mode']; // Przypisanie wartości userMode

        // Logowanie do konsoli
        print('Email użytkownika: $userEmail');
        print('ID użytkownika: $userId');
        print('Tryb użytkownika: $userMode');
        
Navigator.pushReplacement(
  context,
  MaterialPageRoute(
    builder: (context) => ExpensesPage(
      userEmail: userEmail,
      userId: userId,
      userMode: userMode, // Przekazanie userMode do ExpensesPage
    ),
  ),
);

      } else {
        setState(() {
          _errorMessage = 'Niepoprawny email lub hasło.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Logowanie'),
        automaticallyImplyLeading: false, // Usunięcie strzałki cofania
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Proszę wprowadzić email.';
                  }
                  return null;
                },
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: 'Hasło'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Proszę wprowadzić hasło.';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              if (_errorMessage.isNotEmpty)
                Text(
                  _errorMessage,
                  style: TextStyle(color: Colors.red),
                ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => _login(context),
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
                      'Zaloguj się',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/register');
                },
                child: Text('Nie masz jeszcze konta? Zarejestruj się'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
