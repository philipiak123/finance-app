import 'package:flutter/material.dart';
import 'my_account.dart'; // Import ekranu Moje Konto
import 'categories_page.dart'; // Import ekranu Kategorie
import 'expenses_page.dart'; // Import ekranu wydatków

class WelcomePage extends StatelessWidget {
  final String userEmail;
  final int userId;
  final int userMode; // Dodana zmienna userMode

  WelcomePage({required this.userEmail, required this.userId,  required this.userMode});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Witaj!'),
      ),
      drawer: Drawer(
	  child: Column(
		children: <Widget>[
		  Container(
			color: Colors.blue,
			child: DrawerHeader(
			  padding: EdgeInsets.zero,
			  margin: EdgeInsets.zero,
			  decoration: BoxDecoration(
				color: Colors.blue,
			  ),
			  child: Container(
				padding: EdgeInsets.symmetric(vertical: 20),
				child: Text(
				  'Menu',
				  style: TextStyle(
					color: Colors.white,
					fontSize: 24,
				  ),
				  textAlign: TextAlign.center,
				),
			  ),
			),
		  ),
		  ListTile(
			title: Text('Moje konto'),
			onTap: () {
			  Navigator.push(
				context,
				MaterialPageRoute(
				  builder: (context) => MyAccount(userEmail: userEmail, userId: userId),
				),
			  );
			},
		  ),
		  ListTile(
			title: Text('Kategorie'),
			onTap: () {
			  Navigator.pushNamed(context, '/categories', arguments: {'userEmail': userEmail, 'userId': userId});
			},
		  ),
		  ListTile(
			title: Text('Wydatki'),
			onTap: () {
			  Navigator.pushNamed(context, '/expenses', arguments: {'userEmail': userEmail, 'userId': userId});
			},
		  ),
		],
	  ),
	),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Witaj, $userEmail!'),
            Text('Twoje ID: $userId'), // Wyświetl ID użytkownika
            ElevatedButton(
              onPressed: () {
                // Powróć do ekranu logowania
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/',
                  (Route<dynamic> route) => false,
                );
              },
              child: Text('Wyloguj się'),
            ),
          ],
        ),
      ),
    );
  }
}
