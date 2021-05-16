// c_id Numeric(6) PRIMARY KEY,
//     c_name Varchar(30) NOT NULL,
//     c_depart Numeric(4) REFERENCES Departs (d_num) NOT NULL




import '../game.dart';
import 'DBObject.dart';
import 'Department.dart';

class Category implements DBObject{
  int id;
  String name;
  Department department;


  Category(this.id, this.name, this.department);

  @override
  Future addToDB({force = false}) {
    if (force)
      department.addToDB();
    return game.connection.query('''
    INSERT INTO Categories(c_id, c_name, c_depart) VALUES
                  ('${id}', '${name}', ${department.num})
                  ON CONFLICT DO NOTHING;
    '''.trim());
  }

  @override
  Future removeFromDB({force = false}) {
    // TODO: implement deleteFromDB
    throw UnimplementedError();
  }
}