// p_id Numeric(6) PRIMARY KEY,
//     p_name Varchar(20) NOT NULL,
//     d_prod_date date NOT NULL,
// p_country Varchar(40) NOT NULL,
//     p_manufacturer Numeric(6) REFERENCES Manufacturer (mf_id) NOT NULL,
//     p_danger Varchar NOT NULL,
// p_price Numeric(8) NOT NULL,
//     p_depart Numeric(4) REFERENCES Departs (d_num)

import 'dart:async';
import 'dart:math';

import 'package:postgres/postgres.dart';
import 'package:postgres_app/DBObject/Category.dart';

import '../game.dart';
import 'DBObject.dart';
import 'DangerLevel.dart';
import 'Department.dart';
import 'Manufacturer.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';


abstract class Product extends StatelessWidget implements DBObject{
  int id;
  String name;
  DateTime date;
  Manufacturer manufacturer;
  DangerLevel danger;
  int price;
  Category category;
  var assetName = "";

  Product.empty() {
    date = DateTime.now();
    danger = game.dangerLevels[Random().nextInt(game.dangerLevels.length)];
  }

  Future setupPrice() async {
    var p = await game.connection.query("select p_price from products where p_name = '$name'");
    if (p is PostgreSQLResult) {
      if (p.isNotEmpty) {
        return p[0][0];
      }
    }
    return null;
  }

  Product(this.id, this.name, this.date, this.manufacturer,
      this.danger, this.price, this.category);

  @override
  Future addToDB({force = false}) {
    if (force) {
      // manufacturer.addToDB();
      // danger.addToDB();
      // department.addToDB();
    }
    String q = '''
    INSERT INTO Products(p_id, p_name, p_prod_date, p_manufacturer, p_danger, p_price, p_category) VALUES
                  (${id}, '${name}', '${date.toIso8601String()}', ${manufacturer.id}, '${danger.name}', ${price}, ${category.id})
    '''.trim();
     // print(q);
    return game.connection.query(q).catchError((e){
      // if (decode(e.toString()).contains("повторяющееся значение ключа")) {
      //   return null;
      // }
      print('Weapon ${decode(e.toString())}');
      return e;
    });
  }

  Widget productInfo(context) {
    return AlertDialog(
      elevation: 0,
      backgroundColor: Colors.transparent,
      contentPadding: EdgeInsets.only(top: 8),
      content: SizedBox(
        width: MediaQuery.of(context).size.width / 1.1,
        height: MediaQuery.of(context).size.width / 1.1 * 2,
        child: Material(
          elevation: 20,
          color: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            child: Container(
              color: Colors.green[400],
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 100,
                      height: 100,
                      child: assetName == null ? Container() : Image.asset(assetName, fit: BoxFit.scaleDown, filterQuality: FilterQuality.none,),
                    ),
                    Flexible(
                        child: Column(
                          children: [
                            Text('ID: ${this.id}'),
                            Text('${this.name.split('.').first.split('/').last}'),
                            Text('Category: ${this.category.name}'),
                            Text('Danger: ${this.danger.name}'),
                            Text('Manufacturer: ${this.manufacturer.name}, country: ${this.manufacturer.country}'),
                            Text('Price: ${this.price}'),
                          ],
                        )
                    ),
                    AspectRatio(
                      aspectRatio: 4 / 1,
                      child: ClipRRect(
                        clipBehavior: Clip.antiAlias,
                        child: Container(
                          child: InkWell(
                            onTap: () {
                              Navigator.of(context,
                                  rootNavigator: true)
                                  .pop();
                            },
                            child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.green[600],
                                  borderRadius: BorderRadius.only(
                                      bottomLeft:
                                      Radius.circular(16.0),
                                      bottomRight:
                                      Radius.circular(16.0)),
                                ),
//                              child: Icon(Icons.check_circle_outline, color: Colors.amberAccent, size: 56,),
                                child: Icon(Icons.check_circle, color: Colors.white54,)),
                          ),
                        ),
                      ),
                    ),
                  ]),
            ),
          ),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => productInfo(context),
        );
      },
      child: Container(
        width: 100,
        height: 100,
        child: assetName == null ? Container() : Image.asset(assetName, fit: BoxFit.fill, filterQuality: FilterQuality.none,),
      ),
    );
  }

  @override
  Future removeFromDB({force = false}) {
    throw UnimplementedError();
  }
}

class Potion extends Product {

  static var assetNames ='''Blue Potion 3.png
Green Potion 3.png
Icon1.png
Icon2.png
Icon3.png
Icon10.png
Icon11.png
Icon12.png
Icon13.png
Icon14.png
Icon15.png
Red Potion 3.png'''.split('\n');


  Potion(int id, String name, DateTime date, Manufacturer manufacturer, DangerLevel danger, int price, Category category) : super(id, name, date, manufacturer, danger, price, category) {
    assetName = 'assets/images/Potion/${assetNames[Random().nextInt(assetNames.length)]}';
  }

  Potion.empty() : super.empty() {
    this.category = game.categories[0];
    assetName = 'assets/images/Potion/${assetNames[Random().nextInt(assetNames.length)]}';
    name = assetName;
    manufacturer = game.getManufacturer(0);
    id = name.hashCode;
    setupPrice().then((value) {
      price = value ?? Random().nextInt(5) * 60 + 100;
      if (value == null)
        addToDB();
    });
  }
}

class Weapon extends Product {

  static var assetNames =
  '''Arrow.png
Axe.png
Bow.png
EmeraldStaff.png
GoldenSword.png
Hammer.png
IronShield.png
IronSword.png
Knife.png
MagicWand.png
Pickaxe.png
RubyStaff.png
SapphireStaff.png
Shovel.png
SilverSword.png
TopazStaff.png
Torch.png
WoodenShield.png
WoodenStaff.png
WoodenSword.png'''.split('\n');


  Weapon(int id, String name, DateTime date, Manufacturer manufacturer, DangerLevel danger, int price, Category category) : super(id, name, date, manufacturer, danger, price, category) {
    assetName = 'assets/images/Weapon/${assetNames[Random().nextInt(assetNames.length)]}';
  }

  Weapon.empty() : super.empty() {
    this.category = game.categories[2];
    assetName = 'assets/images/Weapon/${assetNames[Random().nextInt(assetNames.length)]}';
    name = assetName;
    manufacturer = game.getManufacturer(1);
    id = name.hashCode;
    setupPrice().then((value) {
      price =  value ?? Random().nextInt(6) * 80 + 100;
      if (value == null)
        addToDB();
    });
  }
}

class Food extends Product {

 static var assetNames =
  '''Apple.png
Beer.png
Bread.png
Cheese.png
Fish Steak.png
Green Apple.png
Ham.png
Meat.png
Mushroom.png
Wine.png
Wine 2.png'''.split('\n');


  Food(int id, String name, DateTime date, Manufacturer manufacturer, DangerLevel danger, int price, Category category) : super(id, name, date, manufacturer, danger, price, category) {
    assetName = 'assets/images/Food/${assetNames[Random().nextInt(assetNames.length)]}';
  }

  Food.empty() : super.empty() {
    this.category = game.categories[1];
    assetName = 'assets/images/Food/${assetNames[Random().nextInt(assetNames.length)]}';
    setupPrice();
    name = assetName;
    manufacturer = game.getManufacturer(2);
    id = name.hashCode;
    setupPrice().then((value) {
      price = value ?? Random().nextInt(6) * 50 + 60;
      if (value == null)
        addToDB();
    });
  }
}

class Book extends Product {

 static var assetNames =
  '''Book.png
Book 2.png
Book 3.png'''.split('\n');


  Book(int id, String name, DateTime date, Manufacturer manufacturer, DangerLevel danger, int price, Category category) : super(id, name, date, manufacturer, danger, price, category) {
    assetName = 'assets/images/Book/${assetNames[Random().nextInt(assetNames.length)]}';
  }

  Book.empty() : super.empty() {
    this.category = game.categories[3];
    assetName = 'assets/images/Book/${assetNames[Random().nextInt(assetNames.length)]}';
    name = assetName;
    manufacturer = game.getManufacturer(3);
    id = name.hashCode;
    setupPrice().then((value) {
      price = value ?? Random().nextInt(4) * 80 + 200;
      if (value == null)
        addToDB();
    });
  }
}