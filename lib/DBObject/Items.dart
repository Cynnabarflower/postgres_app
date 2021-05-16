// i_quantity Numeric(8) NOT NULL,
//     i_id Numeric(6) UNIQUE REFERENCES Products (p_id) NOT NULL


import '../game.dart';
import 'DBObject.dart';
import 'Department.dart';
import 'Owl.dart';
import 'Position.dart';
import 'Product.dart';
import 'Race.dart';

class Items implements DBObject{
  int quantity = 1;
  Product product;
  int check;


  Items(this.quantity, this.product);

  @override
  Future addToDB({force = false}) {
    return game.connection.query('''
    INSERT INTO Items(i_quantity, i_id, i_check_num) VALUES
                  (${quantity}, '${product.id}', $check)
    '''.trim());
  }

  @override
  Future removeFromDB({force = false}) {
    // TODO: implement deleteFromDB
    throw UnimplementedError();
  }
}