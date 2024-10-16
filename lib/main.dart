import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart' as rootBundle;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FireLady Store',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: StorePage(),
    );
  }
}

class StorePage extends StatefulWidget {
  @override
  _StorePageState createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
  List<Item> items = [];
  List<CartItem> cart = [];

  @override
  void initState() {
    super.initState();
    loadItems();
  }

  Future<void> loadItems() async {
    final String response =
        await rootBundle.rootBundle.loadString('assets/items.json');
    final List<dynamic> data = json.decode(response);
    setState(() {
      items = data.map((item) => Item.fromJson(item)).toList();
    });
  }

  void addToCart(Item item, String color, int quantity) {
    setState(() {
      cart.add(CartItem(item: item, color: color, quantity: quantity));
    });
  }

  void removeFromCart(CartItem cartItem) {
    setState(() {
      cart.remove(cartItem);
    });
  }

  double get totalPrice {
    return cart.fold(0.0,
        (sum, cartItem) => sum + (cartItem.item.price * cartItem.quantity));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('FireLady Store'),
        actions: [
          IconButton(
            icon: Icon(Icons.shopping_cart),
            onPressed: () => showModalBottomSheet(
              context: context,
              builder: (_) => CartPage(
                  cart: cart,
                  totalPrice: totalPrice,
                  removeFromCart: removeFromCart),
            ),
          )
        ],
      ),
      body: items.isEmpty
          ? Center(child: CircularProgressIndicator())
          : GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.75,
              ),
              padding: EdgeInsets.all(10),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                String selectedColor = 'Red';
                int quantity = 1;
                return Card(
                  elevation: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Image.asset(
                          item.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Icon(Icons.image, size: 50),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.name,
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                            Text('\$${item.price.toStringAsFixed(2)}'),
                            Text(
                                'Size: ${item.size} - Weight: ${item.weight} kg'),
                            SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () => showModalBottomSheet(
                                context: context,
                                builder: (context) {
                                  return StatefulBuilder(
                                    builder: (context, setState) {
                                      return Padding(
                                        padding: EdgeInsets.all(16.0),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text('Select Color',
                                                style: TextStyle(fontSize: 18)),
                                            DropdownButton<String>(
                                              value: selectedColor,
                                              items: ['Red', 'Blue', 'Green']
                                                  .map((color) {
                                                return DropdownMenuItem(
                                                  value: color,
                                                  child: Text(color),
                                                );
                                              }).toList(),
                                              onChanged: (value) {
                                                setState(() {
                                                  selectedColor = value!;
                                                });
                                              },
                                            ),
                                            SizedBox(height: 10),
                                            Text('Quantity',
                                                style: TextStyle(fontSize: 18)),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                IconButton(
                                                  icon: Icon(Icons.remove),
                                                  onPressed: () {
                                                    setState(() {
                                                      if (quantity > 1)
                                                        quantity--;
                                                    });
                                                  },
                                                ),
                                                Text(quantity.toString(),
                                                    style: TextStyle(
                                                        fontSize: 18)),
                                                IconButton(
                                                  icon: Icon(Icons.add),
                                                  onPressed: () {
                                                    setState(() {
                                                      quantity++;
                                                    });
                                                  },
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 10),
                                            ElevatedButton(
                                              onPressed: () {
                                                addToCart(item, selectedColor,
                                                    quantity);
                                                Navigator.pop(context);
                                              },
                                              child: Text('Add to Cart'),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                              child: Text('Add to Cart'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class CartPage extends StatelessWidget {
  final List<CartItem> cart;
  final double totalPrice;
  final Function(CartItem) removeFromCart;

  CartPage({
    required this.cart,
    required this.totalPrice,
    required this.removeFromCart,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Cart', style: TextStyle(fontSize: 24)),
          SizedBox(height: 10),
          if (cart.isEmpty)
            Text('Your cart is empty')
          else
            Column(
              children: cart.map((cartItem) {
                return ListTile(
                  leading: Image.asset(cartItem.item.imageUrl,
                      width: 50,
                      height: 50,
                      errorBuilder: (context, error, stackTrace) =>
                          Icon(Icons.image)),
                  title: Text(cartItem.item.name),
                  subtitle: Text(
                      'Color: ${cartItem.color} - Quantity: ${cartItem.quantity} - Size: ${cartItem.item.size} - Weight: ${cartItem.item.weight} kg - \$${(cartItem.item.price * cartItem.quantity).toStringAsFixed(2)}'),
                  trailing: IconButton(
                    icon: Icon(Icons.remove_circle),
                    onPressed: () => removeFromCart(cartItem),
                  ),
                );
              }).toList(),
            ),
          SizedBox(height: 20),
          Text('Total: \$${totalPrice.toStringAsFixed(2)}'),
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              // Handle checkout
            },
            child: Text('Checkout'),
          ),
        ],
      ),
    );
  }
}

class Item {
  final String name;
  final double price;
  final String imageUrl;
  final String size;
  final double weight;

  Item(
      {required this.name,
      required this.price,
      required this.imageUrl,
      required this.size,
      required this.weight});

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      name: json['name'],
      price: json['price'],
      imageUrl: json['imageUrl'],
      size: json['size'],
      weight: json['weight'],
    );
  }
}

class CartItem {
  final Item item;
  final String color;
  final int quantity;

  CartItem({required this.item, required this.color, required this.quantity});
}
