import '../game.dart';
import '../room.dart';
import 'DBObject.dart';
import 'Department.dart';

class Department implements DBObject{
  int num;
  String name;
  Room room;


  Department(this.num, this.name);

  @override
  Future addToDB({force = false}) {
    return game.connection.query('''
    INSERT INTO Departs(d_num, d_name) VALUES
                  ('${num}', '${name}')
    '''.trim()).catchError((e){
      // print(decode(e.toString()));
      if (decode(e.toString()).contains('повторяющееся значение ключа')) {
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