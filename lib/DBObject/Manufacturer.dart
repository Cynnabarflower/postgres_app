// mf_id Numeric(6) PRIMARY KEY,
//     mf_name Varchar(30) NOT NULL,
//     pr_country Varchar(40) NOT NULL

import '../game.dart';
import 'DBObject.dart';
import 'Department.dart';
import 'Owl.dart';
import 'Position.dart';
import 'Race.dart';



class Manufacturer implements DBObject {
  int id;
  String name;
  String country;


  Manufacturer(this.id, this.name, this.country);

  @override
  Future addToDB({force = false}) {
    return game.connection.query('''
    INSERT INTO Manufacturers(mf_id, mf_name, mf_country) VALUES
                  ('${id}', '${name}', '${country}')
                  ON CONFLICT DO NOTHING;
    '''.trim()).catchError((e){
      print(decode(e.toString()));
      // return e;
    });
  }

  @override
  Future removeFromDB({force = false}) {
    // TODO: implement deleteFromDB
    throw UnimplementedError();
  }
}