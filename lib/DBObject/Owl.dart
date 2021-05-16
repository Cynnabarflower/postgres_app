// o_num Numeric(30) PRIMARY KEY
import 'dart:math';

import 'package:postgres/postgres.dart';

import '../game.dart';
import 'DBObject.dart';
import 'Department.dart';
import 'Owl.dart';
import 'Position.dart';
import 'Product.dart';
import 'Race.dart';

class Owl implements DBObject{
  String num;


  Owl({this.num}) {
    if (num == null) {
      Random r = Random();
      num = '${r.nextInt(10)}${r.nextInt(10)}${r.nextInt(10)}${r.nextInt(10)}-${r.nextInt(10)}${r.nextInt(10)}${r.nextInt(10)}${r.nextInt(10)}';
    }
  }

  @override
  Future addToDB({force = false}) {
    return game.connection.query('''
    INSERT INTO Owls(o_num) VALUES ('${num}')
    '''.trim()).then((value) {
      if (value is PostgreSQLException) {
        if (e is PostgreSQLException) {
          if (decode(e.toString())
              .contains("повторяющееся значение ключа")) {
            return null;
          }
          print('Exception ${decode(e.toString())}');
        }
      }
      return e;
    });
  }

  @override
  Future removeFromDB({force = false}) {
    return game.connection.query('''
      DELETE FROM Owls where o_num = '$num';
      '''.trim());
  }
}