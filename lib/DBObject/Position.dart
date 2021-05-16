// po_id Numeric(6) PRIMARY KEY,
//     po_position Varchar(40) NOT NULL,
//     po_salary Numeric(9) NOT NULL

import '../game.dart';
import 'DBObject.dart';
import 'Department.dart';
import 'Owl.dart';
import 'Position.dart';
import 'Product.dart';
import 'Race.dart';

class Position implements DBObject {
  int id;
  String name;
  int salary;
  String assetPath;

  Position(this.id, this.name, this.salary, {this.assetPath});

  @override
  Future addToDB({force = false}) {
    return game.connection.query('''
    INSERT INTO Positions(po_id, po_salary, po_name) VALUES
                  ('${id}', '${salary}', '${name}')
    '''.trim()).catchError((e) {
      if (decode(e.toString()).contains("повторяющееся значение ключа")) {
        return null;
      }
      return e;
    });
  }

  @override
  Future removeFromDB({force = false}) {
    // TODO: implement deleteFromDB
    throw UnimplementedError();
  }
}