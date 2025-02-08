import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'my_account.dart'; // Import ekranu Moje Konto

class CategoriesPage extends StatefulWidget {
  final int userId;
  final String userEmail;
  final int userMode;

  CategoriesPage({
    required this.userId,
    required this.userEmail,
    required this.userMode,
  });

  @override
  _CategoriesPageState createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  late List<Map<String, dynamic>> categories = [];

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    print('User mode on CategoriesPage: ${widget.userMode}'); // Wypisanie userMode do konsoli po wejściu na stronę
  }

  Future<void> _fetchCategories() async {
    final response =
        await http.get(Uri.parse('http://localhost:3000/categories/${widget.userId}'));

    if (response.statusCode == 200) {
      setState(() {
        categories =
            List<Map<String, dynamic>>.from(jsonDecode(response.body));
      });
    } else {
      print('Error loading categories: ${response.statusCode}');
    }
  }

  Future<void> _addCategory(BuildContext context,
      {int? categoryId, String? name, Color? color}) async {
    final response = await http.post(
      Uri.parse('http://localhost:3000/add_category'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'userId': widget.userId,
        'name': name,
        'color': color?.value.toRadixString(16).substring(2),
      }),
    );

    if (response.statusCode == 200) {
      _fetchCategories();
      Navigator.of(context).pop();
    } else {
      final Map<String, dynamic> errorData = jsonDecode(response.body);
      final String errorMessage = errorData['error'];
      _showErrorDialog(context, errorMessage);
    }
  }

  Future<void> _updateCategory(BuildContext context,
      {int? categoryId, String? name, Color? color}) async {
    final response = await http.post(
      Uri.parse('http://localhost:3000/update_category'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'userId': widget.userId,
        'categoryId': categoryId,
        'name': name,
        'color': color?.value.toRadixString(16).substring(2),
      }),
    );

    if (response.statusCode == 200) {
      _fetchCategories();
      Navigator.of(context).pop();
    } else {
      final Map<String, dynamic> errorData = jsonDecode(response.body);
      final String errorMessage = errorData['error'];
      _showErrorDialog(context, errorMessage);
    }
  }

  Future<void> _deleteCategory(BuildContext context, int categoryId) async {
    final response = await http.delete(
      Uri.parse('http://localhost:3000/delete_category/$categoryId'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 200) {
      _fetchCategories();
    } else {
      final Map<String, dynamic> errorData = jsonDecode(response.body);
      final String errorMessage = errorData['error'];
      _showErrorDialog(context, errorMessage);
    }
  }

  void _showErrorDialog(BuildContext context, String errorMessage) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(errorMessage),
          actions: <Widget>[
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showAddCategoryDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CategoriesPageDialog(
          onAddOrUpdateCategory: _addCategory,
          isEditing: false,
          isDarkMode: widget.userMode == 1, // Przekazanie isDarkMode
        );
      },
    );
  }

  void _showEditCategoryDialog(
      {String? name, Color? color, int? categoryId}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CategoriesPageDialog(
          onAddOrUpdateCategory: _updateCategory,
          initialName: name,
          initialColor: color,
          categoryId: categoryId,
          isEditing: true,
          isDarkMode: widget.userMode == 1, // Przekazanie isDarkMode
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = widget.userMode == 1;

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
          title: Text('Categories'),

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
                  Navigator.pushNamed(context, '/my_account',
                      arguments: {'userEmail': widget.userEmail, 'userId': widget.userId, 'userMode': widget.userMode});
                },
              ),
              ListTile(
                title: Text('Categories'),
                onTap: () {
                  Navigator.pushNamed(context, '/categories',
                      arguments: {'userEmail': widget.userEmail, 'userId': widget.userId, 'userMode': widget.userMode});
                },
              ),
              ListTile(
                title: Text('Expenses'),
                onTap: () {
                  Navigator.pushNamed(context, '/expenses',
                      arguments: {'userEmail': widget.userEmail, 'userId': widget.userId, 'userMode': widget.userMode});
                },
              ),
            ],
          ),
        ),
        body: ListView.builder(
          itemCount: categories.length,
          itemBuilder: (BuildContext context, int index) {
            final category = categories[index];
            final String categoryName = category['name'];
            final String categoryColorHex = category['color'];
            final Color categoryColor = Color(int.parse('0xFF' + categoryColorHex));
            final int categoryId = category['id'];

            return ListTile(
              title: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    color: categoryColor,
                  ),
                  SizedBox(width: 10),
                  Text(categoryName),
                  SizedBox(width: 10),
                  Text('#' + categoryColorHex),
                  Spacer(),
                  IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () {
                      _showEditCategoryDialog(
                        name: categoryName,
                        color: categoryColor,
                        categoryId: categoryId,
                      );
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () {
                      _deleteCategory(context, categoryId);
                    },
                  ),
                ],
              ),
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showAddCategoryDialog,
          child: Icon(Icons.add),
        ),
      ),
    );
  }
}

class CategoriesPageDialog extends StatefulWidget {
  final Future<void> Function(BuildContext, {int? categoryId, String? name, Color? color})
      onAddOrUpdateCategory;
  final String? initialName;
  final Color? initialColor;
  final int? categoryId;
  final bool isEditing;
  final bool isDarkMode;

  CategoriesPageDialog({
    required this.onAddOrUpdateCategory,
    this.initialName,
    this.initialColor,
    this.categoryId,
    required this.isEditing,
    required this.isDarkMode, // Dodanie isDarkMode do konstruktora
  });

  @override
  _CategoriesPageDialogState createState() => _CategoriesPageDialogState();
}

class _CategoriesPageDialogState extends State<CategoriesPageDialog> {
  final TextEditingController _nameController = TextEditingController();
  Color _selectedColor = Colors.blue;

  @override
  void initState() {
    super.initState();
    if (widget.initialName != null) {
      _nameController.text = widget.initialName!;
    }
    if (widget.initialColor != null) {
      _selectedColor = widget.initialColor!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: widget.isDarkMode ? Colors.grey[850] : Colors.white,
      title: Text(
        widget.isEditing ? 'Edit Category' : 'Add Category',
        style: TextStyle(
          color: widget.isDarkMode ? Colors.white : Colors.black,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Category Name',
              labelStyle: TextStyle(
                color: widget.isDarkMode ? Colors.white : Colors.black,
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: widget.isDarkMode ? Colors.white : Colors.black),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: widget.isDarkMode ? Colors.white : Colors.black),
              ),
            ),
            style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black),
          ),
          SizedBox(height: 20),
          Text(
            'Select Color:',
            style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black),
          ),
          SizedBox(height: 10),
          GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    backgroundColor: widget.isDarkMode ? Colors.grey[850] : Colors.white,
                    title: Text(
                      'Select Color',
                      style: TextStyle(
                        color: widget.isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    content: SingleChildScrollView(
                      child: ColorPicker(
                        pickerColor: _selectedColor,
                        onColorChanged: (Color color) {
                          setState(() {
                            _selectedColor = color;
                          });
                        },
                        showLabel: true,
                        pickerAreaHeightPercent: 0.8,
                        labelTextStyle: TextStyle(
                          color: widget.isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                    actions: <Widget>[
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text('Select'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.isDarkMode ? Colors.grey[900] : Colors.blue,
                        ),
                      ),
                    ],
                  );
                },
              );
            },
            child: Container(
              width: 100,
              height: 50,
              color: _selectedColor,
            ),
          ),
        ],
      ),
      actions: <Widget>[
        ElevatedButton(
          onPressed: () {
            widget.onAddOrUpdateCategory(
              context,
              name: _nameController.text,
              color: _selectedColor,
              categoryId: widget.categoryId,
            );
          },
          child: Text('Save'),
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.isDarkMode ? Colors.grey[900] : Colors.blue,
          ),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('Cancel'),
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.isDarkMode ? Colors.grey[900] : Colors.blue,
          ),
        ),
      ],
    );
  }
}
