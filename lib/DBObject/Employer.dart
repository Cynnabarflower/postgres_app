//
// e_id Numeric(6) PRIMARY KEY,
//     e_fio varchar(50) NOT NULL,
//     e_position numeric(6) REFERENCES Positions (po_id) NOT NULL,
//     e_depart Numeric(4) REFERENCES Departs(d_num) NOT NULL,
//     e_owl Numeric(30) UNIQUE REFERENCES Owls(o_num),
// e_salary Numeric(9) NOT NULL,
//     e_race varchar(20) REFERENCES Race (r_race),
// e_director Numeric(6) REFERENCES Employer(e_id)

import 'dart:math';

import 'package:flame/spritesheet.dart';
import 'package:flame/widgets/animation_widget.dart';
import 'package:flame/widgets/sprite_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flame/animation.dart' as ani;
import 'package:postgres/postgres.dart';

import '../game.dart';
import '../room.dart';
import 'DBObject.dart';
import 'Department.dart';
import 'Owl.dart';
import 'Position.dart';
import 'Race.dart';


class Employee extends StatefulWidget implements DBObject {
  int id;
  String family;
  String name;
  Position position;
  Department department;
  Owl owl;
  int salary;
  Race race;
  int directorId;

  int hirePrice = Random().nextInt(10) * 20 + 40;
  Offset offset;
  Offset movingTo;
  Room room;
  GlobalKey tweenKey;
  String assetPath;
  ani.Animation _walkUp, _walkLeft, _walkRight, _walkDown;

  void setPosition(Position position) {
    if (position != null && position.assetPath != assetPath) {
      this.assetPath = position.assetPath;
      initAnimation();
    } else if (position != null) {
      salary = position.salary;
    }
    this.position = position;
  }

  Employee.fromRow(PostgreSQLResultRow r) : super(key: GlobalKey()) {
    this.assetPath = "employer/employer.png";
    fillFromRow(r);
    initAnimation();
  }

  void fillFromRow(PostgreSQLResultRow r) {
    // print('${fio} fill from row: ${r.toString()}');
    id = r[0];
    family = r[1];
    name = r[2];
    setPosition(game.positions[r[3]]);
      department = game.rooms[r[4]].department;
      if (room != null) {
        room.employers.remove(this);
      }
      game.rooms[r[4]].addEmployer(this);

    owl = Owl(num: r[5]);
    salary = r[6];
    race = game.races.firstWhere((element) => element.race == r[7]);
    directorId =  r[8];
  }

  Employee() : super(key: GlobalKey()) {
    this.assetPath = "employer/employer.png";
    position = null;
    // position = game.positions[Random().nextInt(game.positions.length)];
    // salary = (position.salary).floor();
    owl = Owl();
    race = game.races[Random().nextInt(game.races.length)];
    var t = game.names[Random().nextInt(game.names.length)].split(' ');
    family = t[0];
    name = t[1];

    initAnimation();
  }

  Employee.dbCopy(Employee employer) {
    setPosition(employer.position);
    salary = employer.salary;
    owl = employer.owl;
    race = employer.race;
    family = employer.family;
    name = employer.name;
    department = employer.department;
    directorId = employer.directorId;
    id = employer.id;

    // this.assetPath = employer.assetPath;
    // _walkDown = employer._walkDown;
    // _walkLeft = employer._walkLeft;
    // _walkRight = employer._walkRight;
    // _walkUp = employer._walkUp;
    // this.offset = employer.offset;
    // this.movingTo = employer.movingTo;
    // this.room = employer.room;
  }

  void initAnimation() {
    var spriteSheet = SpriteSheet(
      imageName: assetPath,
      columns: 9,
      rows: 4,
      textureWidth: 64,
      textureHeight: 64,
    );
    _walkUp = spriteSheet.createAnimation(
        0,
        stepTime: 0.2,
        loop: true
    );
    _walkLeft = spriteSheet.createAnimation(
        1,
        stepTime: 0.2,
        loop: true
    );
    _walkDown = spriteSheet.createAnimation(
        2,
        stepTime: 0.2,
        loop: true
    );
    _walkRight = spriteSheet.createAnimation(
        3,
        stepTime: 0.2,
        loop: true
    );
  }

  @override
  Future addToDB({force = false, replace = false}) async {
    if (force) {
      // await position.addToDB();
      // await department.addToDB();
      // await owl.addToDB();
      // await race.addToDB();
      // director.addToDB();
    } else {
      // await owl.addToDB();
    }
    if (replace) {
      // print('updating employer ${name} ${position?.name} ${position?.id}');
      var q = '''
        UPDATE Employees set (e_family, e_name, e_position, e_depart, e_owl, e_salary, e_race, e_director) =
                    ('${family}', '${name}', ${position?.id}, ${department.num}, '${owl.num}', ${salary}, '${race.race}', ${directorId})
                    WHERE e_id = ${id}
                    RETURNING *;
        '''.trim();
      print(q);
      return game.connection.query(
        q
      ).catchError((e) {
        game.showException(e);
      }).then((value) {
        if (value is PostgreSQLResult) {
          // print(value);
          // (room.key as GlobalKey).currentState?.setState(() {
          //   fillFromRow(value.first);
          //   (room.key as GlobalKey)?.currentState?.setState(() {});
          // });
          game.connection.query('''
          select * from Employees
          ''').then((value) {
            print('-----------');
            print(value);
            List<Employee> employees = [];
            game.rooms.forEach((element) {
              employees.addAll(List.of(element.employers));
            });
            for (var r in value) {
              for (var e in employees)
                if (e.id == r[0])
                  e.fillFromRow(r);
            }
          });
        } else {

          // print(decode(value.toString()));
        }
      });
    } else {
      print('adding employee ${name} ${position?.id} ${department.num} ${owl.num} ${salary} ${race.race} ${directorId}');
      var q = '''
      INSERT INTO Employees(e_family, e_name, e_position, e_depart, e_owl, e_salary, e_race, e_director) VALUES
                    ('${family}', '${name}', ${position?.id}, ${department.num}, '${owl.num}', ${salary}, '${race.race}', ${directorId})
                    RETURNING e_id, e_director, e_salary, e_position;
      '''.trim();
      print(q);
      return game.connection.query(q).catchError((e){
        game.showException(e);
      }).then((value) {

        if (value is PostgreSQLResult) {
          id = value.first[0];
          directorId = value.first[1];
          salary = value.first[2];
          setPosition(game.positions.firstWhere((element) => element.id == value.first[3]));
          (key as GlobalKey).currentState?.setState(() {});
        } else {
          room.employers.remove(this);
        }
        print('Decoded: ${decode(value.toString())}');
        return value;
      });
    }
  }

  @override
  Widget informationData({setParentState}) {
    return StatefulBuilder(builder: (context, setState) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: 100,
            width: 100,
            child: SpriteWidget(
              sprite: _walkDown.frames.first.sprite,
            ),
          ),
          Flexible(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: ListView(
                  scrollDirection: Axis.vertical,
                  children: [
                    Text('ID: ${id ?? 'Not set yet'}, ${race.race}'),
                    Text(directorId != null ? 'Director: ${directorId}' : ' '),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: TextField(
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Name',
                          labelText: 'Name',
                        ),
                        keyboardType: TextInputType.name,
                        onChanged: (value) {
                          name = value;
                        },
                        controller: TextEditingController(text: '$name'),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: TextField(
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Surname',
                          labelText: 'Surname',
                        ),
                        keyboardType: TextInputType.name,
                        onChanged: (value) {
                          family = value;
                        },
                        controller: TextEditingController(text: '$family'),
                      ),
                    ),
                    Visibility(
                      visible: salary != null,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: TextField(
                          decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: 'Salary',
                              labelText: 'Salary'
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            salary = int.tryParse(value) ?? 0;
                          },
                          controller: TextEditingController(text: '$salary'),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: TextField(
                        decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'Owl',
                            labelText: 'Owl'
                        ),
                        keyboardType: TextInputType.text,
                        onChanged: (value) {
                          print('changed owl: ${value}');
                          owl.num = value;
                        },
                        controller: TextEditingController(text: '${owl.num}'),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: DropdownButton(
                        disabledHint: Text('Not hired'),
                        isExpanded: true,
                        value: department == null ? null : game.rooms.firstWhere((r) => r.department.num == department.num),
                        dropdownColor: Colors.brown[700],
                        onChanged: department == null ? null: (Room value) {
                          setState((){
                            department = value.department;
                          });
                        },
                        items: game.rooms.map((e) =>
                            DropdownMenuItem(
                              child:
                            Container(
                                alignment: Alignment.centerLeft,
                                child: e.name), value: e,)).toList(),
                      ),
                    ),
                    Visibility(
                      visible: room != null && position != null,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: DropdownButton(
                          value: position?.id ?? 0,
                          isExpanded: true,
                          dropdownColor: Colors.brown[700],
                           onChanged: (value) {
                             setState((){
                               setPosition(game.positions.firstWhere((e) => e.id == value));
                               salary = position.salary;
                             });
                           },
                          items: game.positions.map((e) =>
                              DropdownMenuItem(
                                child:
                                Container(
                                    alignment: Alignment.centerLeft,
                                    child: Text(e.name, style: TextStyle(color: Colors.white),)), value: e.id,)).toList(),
                        ),
                      ),
                    ),
                    Visibility(
                        visible: room != null,
                        child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: MaterialButton(
                        color: Colors.red[400],
                        child: Text('Fire', style: TextStyle(color: Colors.white),),
                        onPressed: () {
                          room.employers.remove(this);
                          (room.key as GlobalKey)?.currentState?.setState(() {});
                          room = null;
                          this.removeFromDB();
                          (key as GlobalKey)?.currentState?.setState(() {});
                          setParentState?.call((){});
                        },
                      )
                    ))
                  ],
                ),
              )
          ),
        ],
      );
    },);

  }


  Widget animation() {
    if (movingTo == null || offset == null || movingTo == offset)
      return SpriteWidget(
      sprite: _walkDown.frames.first.sprite,
    );
    var dx = movingTo.dx - offset.dx;
    var dy = movingTo.dy - offset.dy;
    if (dx.abs() > dy.abs()) {
      if (dx > 0) {
        return AnimationWidget(
          animation: _walkRight,
        );
      } else if (dx < 0) {
        return AnimationWidget(
          animation: _walkLeft,
        );
      } else {
        return SpriteWidget(
          sprite: _walkLeft.frames.first.sprite,
        );
      }
    } else {
      if (dy < 0) {
        return AnimationWidget(
          animation: _walkUp,
        );
      } else if (dy > 0) {
        return AnimationWidget(
          animation: _walkDown,
        );
      } else {
        return SpriteWidget(
          sprite: _walkDown.frames.first.sprite,
        );
      }
    }
  }

  @override
  State<StatefulWidget> createState() => _EmployeeState();


  @override
  Widget information({tag = 0}) {
    return StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          elevation: 0,
          backgroundColor: Colors.transparent,
          contentPadding: EdgeInsets.only(top: 8),
          content: Hero(
            tag: tag,
            child: SizedBox(
              width: MediaQuery.of(context).size.width / 1.1,
              height: MediaQuery.of(context).size.width / 1.1 * 2,
              child: Material(
                elevation: 20,
                color: Colors.transparent,
                child: ClipRRect(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                  child: Container(
                    color: Colors.brown[500],
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: ClipRRect(
                              clipBehavior: Clip.antiAlias,
                              child: Align(
                                alignment: Alignment.center,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: informationData()
                                ),
                              ),
                            ),
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
                                    (key as GlobalKey).currentState?.setState(() {});
                                  },
                                  child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.brown[700],
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
          ),
        );
      },
    );

  }

  @override
  Future removeFromDB({force = false}) {
    return game.connection.query('''
      DELETE FROM Employees where e_id = $id;
      '''.trim()).catchError((e) {
      game.showException(e);
    }).then((value) => owl.removeFromDB()).then((value) {
      if (value is PostgreSQLResult) {
        game.connection.query('''
          select * from Employees
          ''').then((value) {
          List<Employee> employees = [];
          game.rooms.forEach((element) {
            employees.addAll(List.of(element.employers));
          });
          for (var r in value) {
            for (var e in employees)
              if (e.id == r[0])
                e.fillFromRow(r);
          }
        });
      } else {
        print(decode(e.toString()));
      }
    });
  }

}

class _EmployeeState extends State<Employee> {

  Stream<bool> loading() async* {
    while (!widget._walkDown.loaded() && !widget._walkLeft.loaded() && !widget._walkRight.loaded() && !widget._walkUp.loaded()) {
      yield false;
      await Future.delayed(Duration(milliseconds: 300));
    }
    yield true;
  }

  @override
  Widget build(BuildContext context) {

    var streamBuilder =  StreamBuilder<Object>(
        stream: loading(),
        builder: (context, snapshot) {
          // print('${snapshot.hasData} ${snapshot.data} ${widget._idleAnimation.loaded()}');
          if (snapshot.hasData && snapshot.data) {
            return widget.animation();
          } else {
            return FittedBox(
              fit: BoxFit.fitWidth,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
              ),
            );
          }
        }
    );
    // return streamBuilder;
    // print('drawing employer ${widget.fio}');
    if (widget.room == null) {
      return FittedBox(
        child: GestureDetector(
          onTap: () {
            print('${widget.name} ${widget.room} ${widget.offset} ${widget.movingTo}');
            showDialog(
              context: context,
              builder: (context) => widget.information(),
            );
          },
          child: Container(
            color: Colors.green,
            child: Column(
              children: [
                Container(
                    width: 100,
                    height: 100,
                    child: streamBuilder),
                Material(
                  elevation: 0,
                  child: Container(
                  width: 100,
                  height: 32,
                  color: Colors.green[800],
                  alignment: Alignment.center,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('${widget.hirePrice}',
                      style: TextStyle(color: Colors.white),),
                  ),
                )
                ),
              ],
            ),
          ),
        ),
      );
    }
    // print('drawing employer ${widget.room.cellWidth}x${widget.room.cellHeight}');
    return SizedBox(
      width: widget.room.cellWidth * 3,
      height: widget.room.cellHeight * 3,
      // color: Colors.blueAccent,
      child: streamBuilder,
    );
  }

}