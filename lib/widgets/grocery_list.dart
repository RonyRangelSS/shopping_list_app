import 'package:flutter/material.dart';
import 'package:shopping_list_app/data/categories.dart';
import 'dart:convert';
import 'package:shopping_list_app/models/grocery_item.dart';
import 'package:shopping_list_app/widgets/new_item.dart';
import 'package:http/http.dart' as http;

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> _groceryList = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  void _loadItems() async {
    final url = Uri.https("flutter-prep-5b0c2-default-rtdb.firebaseio.com", "shopping-list.json");
    final List<GroceryItem> loadedItems = [];
    final response = await http.get(url);

    if (response.statusCode >= 400) {
      setState(() {
        _error = "Failed to fetch data.\nPlease try again later!";
        
      });
    }

    print(response.body);

    final Map<String, dynamic> listData = json.decode(response.body);

    for (final item in listData.entries) {
      final caterogy = categories.entries.firstWhere((catItem) => catItem.value.name == item.value["category"] );
      loadedItems.add(
        GroceryItem(id: item.key, name: item.value["name"], quantity: item.value["quantity"], category: caterogy.value)
      );
    }

    setState(() {
      _groceryList = loadedItems; 
      _isLoading = false;
    });

  }

  void _addItem() async {
    final newItem = await Navigator.of(
      context,
    ).push<GroceryItem>(MaterialPageRoute(builder: (ctx) => NewItem()));

    if (newItem == null) {
      return;
    }

      setState(() {
        _groceryList.add(newItem);
      });
    
  }

  void _removeItem(GroceryItem groceryItem) async {
    final index = _groceryList.indexOf(groceryItem);
    setState(() {
      _groceryList.remove(groceryItem);
    }); 
    final url = Uri.https("flutter-prep-5b0c2-default-rtdb.firebaseio.com", "shopping-list/${groceryItem.id}.json");
    final response = await http.delete(url);

    if (response.statusCode >= 400) {
      _groceryList.insert(index, groceryItem);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = Center(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 12),
        child: Text(
          "No items added yet.\nAdd one!",
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
      ),
    );

    if (_isLoading) {
      content = Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_groceryList.isNotEmpty) {
      content = ListView.builder(
        itemCount: _groceryList.length,
        itemBuilder:
            (context, index) => Dismissible(
              onDismissed: (direction) {
                _removeItem(_groceryList[index]);
              },
              key: ValueKey(_groceryList[index].id),
              child: ListTile(
                title: Text(_groceryList[index].name),
                leading: Container(
                  height: 24,
                  width: 24,
                  color: _groceryList[index].category.color,
                ),
                trailing: Text(_groceryList[index].quantity.toString()),
              ),
            ),
      );
    }

    if (_error != null) {
      content = content = Center(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 12),
        child: Text(
          _error!,
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
      ),
    );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Your groceries"),
        actions: [IconButton(onPressed: _addItem, icon: Icon(Icons.add))],
      ),
      body: content,
    );
  }
}
