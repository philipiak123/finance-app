import 'package:flutter/material.dart';
import 'home_page.dart';
import 'registration_page.dart';
import 'expenses_page.dart';
import 'my_account.dart';
import 'categories_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login App',
      initialRoute: '/',
      routes: {
        '/': (context) => LoginPage(),
        '/register': (context) => RegistrationPage(),
        '/my_account': (context) => MyAccount(
          userEmail: (ModalRoute.of(context)?.settings.arguments as Map)['userEmail'],
          userId: (ModalRoute.of(context)?.settings.arguments as Map)['userId'],
		  userMode: (ModalRoute.of(context)?.settings.arguments as Map)['userMode'],
        ),
        '/categories': (context) => CategoriesPage(
          userEmail: (ModalRoute.of(context)?.settings.arguments as Map)['userEmail'],
          userId: (ModalRoute.of(context)?.settings.arguments as Map)['userId'],
          userMode: (ModalRoute.of(context)?.settings.arguments as Map)['userMode'],
        ),
        '/expenses': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map?;
          return ExpensesPage(
            userEmail: args?['userEmail'],
            userId: args?['userId'],
            userMode: args?['userMode'],
          );
        },
      },
    );
  }
}
