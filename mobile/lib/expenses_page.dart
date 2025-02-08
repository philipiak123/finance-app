import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:pie_chart/pie_chart.dart';
import 'categories_page.dart';

class ExpensesPage extends StatefulWidget {
  final int userId;
  final String userEmail;
  final int userMode;

  ExpensesPage({
    required this.userId,
    required this.userEmail,
    required this.userMode,
  });

  @override
  _ExpensesPageState createState() => _ExpensesPageState();
}

class _ExpensesPageState extends State<ExpensesPage> {
  List<Map<String, dynamic>> expenses = [];
  List<Map<String, dynamic>> categories = [];
  Map<String, double> expenseDataMap = {};
  bool categoriesLoaded = false;
  List<Color> pieChartColorList = [];
  late bool isDarkMode;
  double minExpenseAmount = 0.0;
  double maxExpenseAmount = double.infinity;
  
  @override
  void initState() {
    super.initState();
    isDarkMode = widget.userMode == 1;
    _fetchCategories();
    _fetchExpenses();
  }
void _sortExpensesByDate(bool ascending) {
  setState(() {
    expenses.sort((a, b) {
      DateTime dateA = DateTime.parse(a['date']);
      DateTime dateB = DateTime.parse(b['date']);
      return ascending ? dateA.compareTo(dateB) : dateB.compareTo(dateA);
    });
  });
}

void _sortExpensesByAmount(bool ascending) {
  setState(() {
    expenses.sort((a, b) {
      double amountA = a['amount'];
      double amountB = b['amount'];
      return ascending ? amountA.compareTo(amountB) : amountB.compareTo(amountA);
    });
  });
}
void _sortExpensesByName(bool ascending) {
  setState(() {
    expenses.sort((a, b) {
      String nameA = a['name'];
      String nameB = b['name'];
      return ascending ? nameA.compareTo(nameB) : nameB.compareTo(nameA);
    });
  });
}


  Future<void> _fetchCategories() async {
    final response = await http.get(Uri.parse('http://localhost:3000/categories/${widget.userId}'));
    if (response.statusCode == 200) {
      final List<dynamic> responseData = jsonDecode(response.body);
      setState(() {
        categories = responseData.map((category) => {
          'id': category['id'],
          'name': category['name'],
          'color': category['color'],
        }).toList();
        categoriesLoaded = true;
        _prepareExpenseDataMap();
      });
    } else {
      print('Error fetching categories: ${response.body}');
    }
  }

  Future<void> _fetchExpenses() async {
    final response = await http.get(Uri.parse('http://localhost:3000/expenses/${widget.userId}'));
    if (response.statusCode == 200) {
      final List<dynamic> responseData = jsonDecode(response.body);
      setState(() {
        expenses = responseData.map((expense) => {
          'id': expense['id'],
          'name': expense['name'],
          'amount': expense['amount'],
          'category': expense['category_id'],
          'date': DateFormat('yyyy-MM-dd').format(DateTime.parse(expense['date'])),
        }).toList();
        _prepareExpenseDataMap();
      });
    } else {
      print('Error fetching expenses: ${response.body}');
    }
  }

  void _prepareExpenseDataMap() {
    if (!categoriesLoaded || expenses.isEmpty) {
      return;
    }

    Map<String, double> dataMap = {};
    Map<String, Color> colorMap = {};

    for (var category in categories) {
      colorMap[category['name']] = Color(int.parse('0xFF${category['color']}'));
    }

    for (var expense in expenses) {
      String categoryName = categories
          .firstWhere((cat) => cat['id'] == expense['category'], orElse: () => {'name': 'Unknown'})['name'];
      dataMap[categoryName] = (dataMap[categoryName] ?? 0) + expense['amount'];
    }

    setState(() {
      expenseDataMap = dataMap;
      pieChartColorList = List<Color>.generate(
        expenseDataMap.length,
        (index) => colorMap[dataMap.keys.elementAt(index)]!,
      );
    });
  }

  Future<void> _sendExpenseToServer(String name, double amount, int categoryId, String date) async {
    final url = Uri.parse('http://localhost:3000/add_expense');
    final formattedDate = DateFormat('yyyy-MM-dd').format(DateTime.parse(date));
    final response = await http.post(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'name': name,
        'amount': amount,
        'categoryId': categoryId,
        'date': formattedDate,
        'userId': widget.userId,
      }),
    );

    if (response.statusCode == 200) {
      print('Expense added successfully.');
      _fetchExpenses();
    } else {
      print('Error adding expense: ${response.body}');
    }
  }

  void _addExpense(String name, double amount, int categoryId, String category, String date) async {
    await _sendExpenseToServer(name, amount, categoryId, date);

    setState(() {
      expenses.add({
        'name': name,
        'amount': amount,
        'category': categoryId,
        'date': date,
      });
      _prepareExpenseDataMap();
    });
  }

  Future<void> _editExpense(int expenseId, String name, double amount, int categoryId, String date) async {
  print(expenseId);
    final url = Uri.parse('http://localhost:3000/update_expense');
    final formattedDate = DateFormat('yyyy-MM-dd').format(DateTime.parse(date));
    final response = await http.post(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'expenseId': expenseId,
        'name': name,
        'amount': amount,
        'categoryId': categoryId,
        'date': formattedDate,
        'userId': widget.userId,
      }),
    );

    if (response.statusCode == 200) {
      print('Expense updated successfully.');
      _fetchExpenses();
    } else {
      print('Error updating expense: ${response.body}');
    }
  }

  Future<void> _deleteExpense(int expenseId) async {
    final url = Uri.parse('http://localhost:3000/delete_expense');
    final response = await http.post(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'expenseId': expenseId,
      }),
    );

    if (response.statusCode == 200) {
      print('Expense deleted successfully.');
      setState(() {
        expenses.removeWhere((expense) => expense['id'] == expenseId);
      });
      _prepareExpenseDataMap();
    } else {
      print('Error deleting expense: ${response.body}');
    }
  }

  void _showAddExpenseDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddExpenseDialog(
          onAddExpense: _addExpense,
          categories: categories,
          isDarkMode: isDarkMode,
        );
      },
    );
  }
    void _setExpenseAmountRange(double min, double max) {
    setState(() {
      minExpenseAmount = min;
      maxExpenseAmount = max;
    });
  }

void _showExpenseAmountFilterDialog() {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return ExpenseAmountFilterDialog(
        onFilter: _setExpenseAmountRange,
        minAmount: minExpenseAmount,
        maxAmount: maxExpenseAmount,
        isDarkMode: isDarkMode,
      );
    },
  );
}

  void _showEditExpenseDialog(Map<String, dynamic> expense) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return EditExpenseDialog(
          expense: expense,
          categories: categories,
          onEditExpense: _editExpense,
          isDarkMode: isDarkMode,
        );
      },
    );
  }

  String _calculateTotalExpense() {
    double total = 0.0;
    expenses.forEach((expense) {
      total += expense['amount'];
    });
    return total.toStringAsFixed(2);
  }

@override
Widget build(BuildContext context) {
  // Filtrowanie wydatków na podstawie zakresu kwot
  List<Map<String, dynamic>> filteredExpenses = expenses.where((expense) {
double amount = expense['amount'].toDouble();
    return amount >= minExpenseAmount && amount <= maxExpenseAmount;
  }).toList();
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
  title: Text('Expenses'),
  actions: <Widget>[
    PopupMenuButton<String>(
      icon: Icon(Icons.sort),
      onSelected: (value) {
        if (value == 'dateAsc') {
          _sortExpensesByDate(true);
        } else if (value == 'dateDesc') {
          _sortExpensesByDate(false);
        } else if (value == 'amountAsc') {
          _sortExpensesByAmount(true);
        } else if (value == 'amountDesc') {
          _sortExpensesByAmount(false);
        } else if (value == 'nameAsc') {
          _sortExpensesByName(true);
        } else if (value == 'nameDesc') {
          _sortExpensesByName(false);
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(
          value: 'dateAsc',
          child: Text('Sort by Date (Ascending)'),
        ),
        const PopupMenuItem<String>(
          value: 'dateDesc',
          child: Text('Sort by Date (Descending)'),
        ),
        const PopupMenuItem<String>(
          value: 'amountAsc',
          child: Text('Sort by Amount (Ascending)'),
        ),
        const PopupMenuItem<String>(
          value: 'amountDesc',
          child: Text('Sort by Amount (Descending)'),
        ),
        const PopupMenuItem<String>(
          value: 'nameAsc',
          child: Text('Sort by Name (Ascending)'),
        ),
        const PopupMenuItem<String>(
          value: 'nameDesc',
          child: Text('Sort by Name (Descending)'),
        ),
      ],
    ),
    IconButton(
      icon: Icon(Icons.filter_list),
      onPressed: () {
        _showExpenseAmountFilterDialog();
      },
    ),
  ],
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
                    arguments: {
                      'userEmail': widget.userEmail,
                      'userId': widget.userId,
                      'userMode': widget.userMode,
                    });
              },
            ),
            ListTile(
              title: Text('Categories'),
              onTap: () {
                Navigator.pushNamed(context, '/categories',
                    arguments: {
                      'userEmail': widget.userEmail,
                      'userId': widget.userId,
                      'userMode': widget.userMode,
                    });
              },
            ),
            ListTile(
              title: Text('Expenses'),
              onTap: () {
                Navigator.pushNamed(context, '/expenses',
                    arguments: {
                      'userEmail': widget.userEmail,
                      'userId': widget.userId,
                      'userMode': widget.userMode,
                    });
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text('User ID: ${widget.userId}'),
          ),
Expanded(
  child: ListView.builder(
    itemCount: filteredExpenses.length,
    itemBuilder: (context, index) {
      final expense = filteredExpenses[index];
      final category = categories.firstWhere(
        (cat) => cat['id'] == expense['category'],
        orElse: () => {'name': 'Unknown'},
      );
      return ListTile(
        title: Text(expense['name']),
        subtitle: Text(
          '${expense['amount']} PLN - Category: ${category['name']} - Date: ${expense['date']}'
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () {
                _showEditExpenseDialog(expense);  // Przekazanie wydatku do funkcji dialogowej edycji
              },
            ),
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: () {
                _deleteExpense(expense['id']);  // Przekazanie ID wydatku do funkcji usuwania
              },
            ),
          ],
        ),
      );
    },
  ),
),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  'Total Expenses: ${_calculateTotalExpense()} PLN',
                  style: TextStyle(fontSize: 20),
                ),
                ElevatedButton(
                  onPressed: _showAddExpenseDialog,
                  child: Text('Add Expense'),
                ),
              ],
            ),
          ),
          if (expenseDataMap.isEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'No expenses to display',
                style: TextStyle(fontSize: 20),
              ),
            )
          else
            Expanded(
              child: PieChart(
                dataMap: expenseDataMap,
                animationDuration: Duration(milliseconds: 800),
                chartLegendSpacing: 32,
                chartRadius: MediaQuery.of(context).size.width / 3.2,
                initialAngleInDegree: 0,
                chartType: ChartType.ring,
                ringStrokeWidth: 32,
                centerText: "Expenses",
                legendOptions: LegendOptions(
                  showLegendsInRow: true,
                  legendPosition: LegendPosition.bottom,
                  showLegends: true,
                  legendTextStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                chartValuesOptions: ChartValuesOptions(
                  showChartValuesOutside: true,
                  showChartValues: true,
                  showChartValuesInPercentage: false,
                  showChartValueBackground: true,
                ),
                colorList: pieChartColorList,
              ),
            ),
        ],
      ),
    ),
  );
}
}
class ExpenseAmountFilterDialog extends StatelessWidget {
  final Function(double, double) onFilter;
  final double minAmount;
  final double maxAmount;
  final bool isDarkMode;

  ExpenseAmountFilterDialog({
    required this.onFilter,
    required this.minAmount,
    required this.maxAmount,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    double newMinAmount = minAmount;
    double newMaxAmount = maxAmount;

    return AlertDialog(
      backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white,
      title: Text(
        'Filter by Amount Range',
        style: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TextField(
            decoration: InputDecoration(
              labelText: 'Min Amount',
              labelStyle: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              newMinAmount = double.tryParse(value) ?? minAmount;
            },
            style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
          ),
          TextField(
            decoration: InputDecoration(
              labelText: 'Max Amount',
              labelStyle: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              newMaxAmount = double.tryParse(value) ?? maxAmount;
            },
            style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
          ),
        ],
      ),
      actions: <Widget>[
        ElevatedButton(
          onPressed: () {
            onFilter(newMinAmount, newMaxAmount);
            Navigator.of(context).pop();
          },
          child: Text('Apply'),
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.resolveWith<Color>(
              (Set<MaterialState> states) {
                if (states.contains(MaterialState.disabled)) {
                  return Theme.of(context).disabledColor;
                }
                return isDarkMode ? Colors.grey[900]! : Colors.blue;
              },
            ),
          ),
        ),
      ],
    );
  }
}

class AddExpenseDialog extends StatefulWidget {
  final Function(String, double, int, String, String) onAddExpense;
  final List<Map<String, dynamic>> categories;
  final bool isDarkMode;

  AddExpenseDialog({
    required this.onAddExpense,
    required this.categories,
    required this.isDarkMode,
  });

  @override
  _AddExpenseDialogState createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends State<AddExpenseDialog> {
  late TextEditingController _nameController;
  late TextEditingController _amountController;
  late int _selectedCategoryId;
  late String _selectedCategory;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _amountController = TextEditingController();
    _selectedCategoryId = widget.categories.isNotEmpty ? widget.categories.first['id'] : 0;
    _selectedCategory = widget.categories.isNotEmpty ? widget.categories.first['name'] : '';
    _selectedDate = DateTime.now();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _presentDatePicker(BuildContext context) {
    showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2019),
      lastDate: DateTime.now(),
    ).then((pickedDate) {
      if (pickedDate == null) {
        return;
      }
      setState(() {
        _selectedDate = pickedDate;
      });
    });
  }

  void _submitData() {
    final enteredName = _nameController.text;
    final enteredAmount = double.parse(_amountController.text);
    final enteredCategoryId = _selectedCategoryId;
    final enteredCategory = _selectedCategory;
    final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);

    if (enteredName.isEmpty || enteredAmount <= 0 || enteredCategoryId <= 0) {
      return;
    }

    widget.onAddExpense(enteredName, enteredAmount, enteredCategoryId, enteredCategory, formattedDate);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: widget.isDarkMode ? Colors.grey[850] : Colors.white,
      title: Text(
        'Add Expense',
        style: TextStyle(
          color: widget.isDarkMode ? Colors.white : Colors.black,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            TextField(
              decoration: InputDecoration(
                labelText: 'Name',
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
              controller: _nameController,
              style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black),
              onSubmitted: (_) => _submitData(),
            ),
            TextField(
              decoration: InputDecoration(
                labelText: 'Amount',
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
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black),
              onSubmitted: (_) => _submitData(),
            ),
            DropdownButtonFormField<int>(
              decoration: InputDecoration(
                labelText: 'Category',
                labelStyle: TextStyle(
                  color: widget.isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              items: widget.categories
                  .map((category) => DropdownMenuItem<int>(
                        value: category['id'],
                        child: Text(
                          category['name'],
                          style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black),
                        ),
                      ))
                  .toList(),
              value: _selectedCategoryId,
              onChanged: (value) {
                setState(() {
                  _selectedCategoryId = value!;
                  _selectedCategory = widget.categories
                      .firstWhere((cat) => cat['id'] == value)['name'];
                });
              },
              style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black),
            ),
            TextButton(
              onPressed: () => _presentDatePicker(context),
              child: Text(
                'Select Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: widget.isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        ElevatedButton(
          onPressed: _submitData,
          child: Text('Add'),
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.resolveWith<Color>(
              (Set<MaterialState> states) {
                if (states.contains(MaterialState.disabled)) {
                  return Theme.of(context).disabledColor;
                }
                return widget.isDarkMode ? Colors.grey[900]! : Colors.blue;
              },
            ),
          ),
        ),
      ],
    );
  }
}


class EditExpenseDialog extends StatefulWidget {
  final Map<String, dynamic> expense;
  final Function(int, String, double, int, String) onEditExpense;
  final List<Map<String, dynamic>> categories;
  final bool isDarkMode;

  EditExpenseDialog({
    required this.expense,
    required this.onEditExpense,
    required this.categories,
    required this.isDarkMode,
  });

  @override
  _EditExpenseDialogState createState() => _EditExpenseDialogState();
}

class _EditExpenseDialogState extends State<EditExpenseDialog> {
  late TextEditingController _nameController;
  late TextEditingController _amountController;
  late int _selectedCategoryId;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.expense['name']);
    _amountController = TextEditingController(text: widget.expense['amount'].toString());
    _selectedCategoryId = widget.expense['category']; // Inicjalizacja id kategorii z wydatku
    _selectedDate = DateTime.parse(widget.expense['date']);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _presentDatePicker(BuildContext context) {
    showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2019),
      lastDate: DateTime.now(),
    ).then((pickedDate) {
      if (pickedDate == null) {
        return;
      }
      setState(() {
        _selectedDate = pickedDate;
      });
    });
  }

  void _submitData() {
    final enteredName = _nameController.text;
    final enteredAmount = double.parse(_amountController.text);
    final enteredCategoryId = _selectedCategoryId; // Użycie wybranego id kategorii
    final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);

    if (enteredName.isEmpty || enteredAmount <= 0 || enteredCategoryId <= 0) {
      return;
    }

    widget.onEditExpense(
      widget.expense['id'],
      enteredName,
      enteredAmount,
      _selectedCategoryId,
      formattedDate,
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: widget.isDarkMode ? Colors.grey[850] : Colors.white,
      title: Text(
        'Edit expense',
        style: TextStyle(
          color: widget.isDarkMode ? Colors.white : Colors.black,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            TextField(
              decoration: InputDecoration(
                labelText: 'Name',
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
              controller: _nameController,
              style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black),
              onSubmitted: (_) => _submitData(),
            ),
            TextField(
              decoration: InputDecoration(
                labelText: 'Amount',
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
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black),
              onSubmitted: (_) => _submitData(),
            ),
            DropdownButtonFormField<int>(
              decoration: InputDecoration(
                labelText: 'Category',
                labelStyle: TextStyle(
                  color: widget.isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              items: widget.categories
                  .map((category) => DropdownMenuItem<int>(
                        value: category['id'],
                        child: Text(
                          category['name'],
                          style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black),
                        ),
                      ))
                  .toList(),
              value: _selectedCategoryId,
              onChanged: (value) {
                setState(() {
                  _selectedCategoryId = value!;
                });
              },
              style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black),
            ),
            TextButton(
              onPressed: () => _presentDatePicker(context),
              child: Text(
                'Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: widget.isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        ElevatedButton(
          onPressed: _submitData,
          child: Text('Save'),
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.resolveWith<Color>(
              (Set<MaterialState> states) {
                if (states.contains(MaterialState.disabled)) {
                  return Theme.of(context).disabledColor;
                }
                return widget.isDarkMode ? Colors.grey[900]! : Colors.blue;
              },
            ),
          ),
        ),
      ],
    );
  }
}
