import 'dart:async';
import 'dart:math';

import 'package:desktop_window/desktop_window.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:intl/intl.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:postgres/postgres.dart';
import 'package:postgres_app/DBObject/Items.dart';
import 'package:postgres_app/chooser.dart';
import 'package:postgres_app/room.dart';

import 'DBObject/Category.dart';
import 'DBObject/DBObject.dart';
import 'DBObject/DangerLevel.dart';
import 'DBObject/Department.dart';
import 'DBObject/Employer.dart';
import 'DBObject/Manufacturer.dart';
import 'DBObject/Position.dart';
import 'DBObject/Product.dart';
import 'DBObject/Race.dart';
import 'DBObject/Sale.dart';
import 'creature.dart';
import 'resultWidget.dart';

Game game;

class Game extends StatefulWidget {

  bool inited = false;
  StreamController<Creature> movedStreamController = StreamController.broadcast();
  StreamController<int> producedProducts = StreamController.broadcast();
  PostgreSQLConnection connection;
  List<Product> products = [];
  GlobalKey chooserKey = GlobalKey();
  Chooser chooser;
  GlobalKey creaturesGameKey = GlobalKey();
  List<Room> rooms = [];
  List<Position> positions = [];
  List<Race> races = [];
  List<DangerLevel> dangerLevels = [];
  int currentView = 0;
  List<Employee> availableEmployers = [];
  List<Category> categories = [];
  List<String> names =
  '''
Александрова Екатерина
Алексеев Савелий
Алексеев Даниил
Аникин Илья
Аникин Сергей
Антонов Артём
Балашов Александр
Баранова Варвара
Баранова Милана
Большаков Владимир
Борисов Платон
Борисова Мия
Васильева Дарья
Вешнякова Мирослава
Волкова Алина
Воробьев Ярослав
Воробьева Виктория
Головина Арина
Голубев Семён
Григорьев Михаил
Громова Варвара
Гусева Юлия
Денисов Илья
Долгов Илья
Ефимова Екатерина
Жданов Максим
Жуков Евгений
Завьялова Анастасия
Зайцев Леон
Зотова Александра
Зыкова Дарья
Иванов Иван
Иванов Тимофей
Иванов Артём
Карпов Максим
Киселев Ярослав
Киселева София
Ковалева София
Кожевникова Светлана
Козлова Алина
Комаров Владимир
Королев Максим
Королева Татьяна
Котова Мария
Кочеткова Татьяна
Кошелева Дарина
Крюкова София
Кудряшов Сергей
Кузнецова Анна
Кузьмина Варвара
Куликов Артём
Куликова Милана
Лаврентьева Алина
Лапина Ольга
Леонова София
Леонова Анастасия
Малышева Валентина
Минаева Евгения
Михайлов Александр
Молчанов Макар
Морозов Даниил
Морозова Юлия
Никитин Кирилл
Николаева Елизавета
Никольский Роман
Овчинников Елисей
Озеров Александр
Олейников Владислав
Орехов Тимур
Орлова Кира
Павлов Анатолий
Павлова Алёна
Петрова Полина
Петровская Алина
Пименов Артём
Пономарева Алиса
Попов Андрей
Попова Злата
Потапова Алёна
Прохоров Фёдор
Рыбаков Фёдор
Самойлов Фёдор
Сахаров Руслан
Семенов Олег
Семенова Ксения
Семенова Арина
Сергеева Милена
Смирнов Максим
Смирнов Михаил
Смирнова Екатерина
Соловьев Алексей
Сорокин Даниил
Сорокина Александра
Спиридонова Дарья
Старостин Дмитрий
Терентьев Александр
Трифонов Савелий
Федоров Никита
Федотова Арина
Фролова София
  '''.trim().split('\n');


  var potionCompanies = [Manufacturer(0, "Potionary1", "c1"),Manufacturer(1, "Potionary2", "c2"),Manufacturer(2, "Potionary3", "c3")];
  var foodCompanies = [Manufacturer(3, "Agroezrot", "c1"), Manufacturer(4, "Coca-coca", "c2"), Manufacturer(5, "Cheeseee", "c3")];
  var weaponCompanies = [Manufacturer(6, "OOO Orcs", "c1"), Manufacturer(7, "Kings Armory", "c1"), Manufacturer(8, "The Mountain", "c1"),];
  var bookCompanies = [Manufacturer(9, "Lib3", "c1"), Manufacturer(10, "Lib2", "c2"), Manufacturer(11, "Lib1", "c3")];

  List<Creature> creatures = [];
  int money = 1000;


  Manufacturer getManufacturer(int i) {
    if (i == 0) {
      return potionCompanies[Random().nextInt(potionCompanies.length)];
    } else if (i == 1) {
      return foodCompanies[Random().nextInt(foodCompanies.length)];
    } else if (i == 2) {
      return weaponCompanies[Random().nextInt(weaponCompanies.length)];
    } else if (i == 3) {
      return bookCompanies[Random().nextInt(bookCompanies.length)];
    }
  }


  int getProductIndex(item) {
    if (item is Potion)
      return 0;
    else if (item is Weapon)
      return 2;
    else if (item is Food)
      return 1;
    else if (item is Book)
      return 3;
    else
      return null;
  }

  Future<bool> init() async {

    Future.wait(potionCompanies.map((element) {return element.addToDB();}));
    Future.wait(foodCompanies.map((element) {return element.addToDB();}));
    Future.wait(weaponCompanies.map((element) {return element.addToDB();}));
    Future.wait(bookCompanies.map((element) {return element.addToDB();}));

    rooms = [
      Room(() => Potion.empty(), produceDuration: Duration(milliseconds: (3000).floor()), department: Department(0, "Potionary"),),
      Room(() => Food.empty(), produceDuration: Duration(milliseconds: (5000).floor()), department: Department(1, "Kitchen")),
      Room(() => Weapon.empty(), produceDuration: Duration(milliseconds: (10000).floor()), department: Department(2, "Smithy")),
      Room(() => Book.empty(), produceDuration: Duration(milliseconds: (18000).floor()), department: Department(3, "Library"))
    ];

    for (var r in rooms) {
      categories.add(Category(r.department.num, '${r.department.name}', r.department));
      await categories.last.addToDB();
      await r.department.addToDB().then((value) {
        if (value is PostgreSQLException) {
          game.showException(value);
        }
      });
    }

    dangerLevels = [
      DangerLevel("No danger", 0),
      DangerLevel("Some danger", 1),
      DangerLevel("Boom", 2),
    ];

    Future.wait(dangerLevels.map((element) {return element.addToDB();}));

    positions = [
      Position(0, "Маг", 50, assetPath: 'employer/employer.png'),
      Position(1, "Главный маг", 100, assetPath: "employer/employerChief.png"),
      Position(2, "Повелитель магии", 200, assetPath: "employer/employerMaster.png"),
    ];
    Future.wait(positions.map((element) {return element.addToDB();}));

    races = [
      Race("Human"),
      Race("Elf"),
      Race("Orc"),
    ];
    Future.wait(races.map((element) {return element.addToDB();}));

    await game.connection.query('''
      select * from employees
      '''.trim()).then((table) {
        if (table is PostgreSQLResult) {
          for (var r in table) {
            Employee.fromRow(r);
          }
        }
    });

    products = [Potion.empty(), Food.empty(), Weapon.empty(), Book.empty()];
    availableEmployers = [Employee(), Employee(), Employee(), Employee()];

    Creature(GlobalKey());
    return true;
  }

  Game(this.connection) : super(key: GlobalKey()){
    game = this;
    init().then((value) {
      chooser = Chooser(key: chooserKey,);
      inited = true;
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        Future.delayed(Duration(seconds: 2), ()=>((key as GlobalKey).currentState as _GameState).createCreatures());
      });
    });

    movedStreamController.stream.listen((event) {
      // if (event.offset == event.movingTo) {
      //   print('Move complete ${event.offset}');
      // } else {
      //     print('Move new $event');
      // }
      // if (event.alignTo == event.alignment) {
      //   print('Move complete');
      // } else {
      //   print('Move new $event');
      // }
      event.key.currentState?.setState(() {});
    });

  }

  @override
  State createState() => _GameState();


  void showException(PostgreSQLException e) {
    showModalBottomSheet(context: (key as GlobalKey).currentContext, builder: (context) {
      var s = decode(e.toString());
      int i = s.indexOf(':');
      if (i >= 0)
        s = s.substring(i+1);
      return Container(
        color: Colors.blue,
        child: Text(s),
      );
    },);
  }

}


class _GameState extends State<Game> {

  var res;
  var loading = false;
  var currentTable;
  ScrollController _scrollController = ScrollController();
  Size deviceSize;
  GlobalKey viewButtonKey = GlobalKey();
  var centerX = 0.0;


  void changeView(view) {
    if (widget.currentView != view || view == 1) {
      if (view == 0) {
        widget.currentView = 0;
        _scrollController.animateTo(
            0, duration: Duration(seconds: 1), curve: Curves.ease);
        widget.chooser.changeCards(widget.currentView);
      } else {
        _scrollController.animateTo(
            MediaQuery.of(context).size.height
            + (view - 1) * MediaQuery.of(context).size.width * 1/0.4,
            duration: Duration(seconds: 1), curve: Curves.ease);
        if (widget.currentView == 0) {
          widget.currentView = 1;
          widget.chooser.changeCards(widget.currentView);
        }
        widget.currentView = 1;
      }
      setState(() {});
    }
  }

  createCreatures() async {
    while (mounted) {
      print(widget.creatures.length);
      if (widget.creatures.length < 1 || widget.creatures.last.movingTo.dx < -10) {
        addCreature();
      }
      await Future.delayed(Duration(milliseconds: 3500 + Random().nextInt(20) * 100));
    }
  }


  @override
  void initState() {

    super.initState();
  }


  @override
  Widget salesInfo({tag = 0})  {

    return StatefulBuilder(
      builder: (context, setState) {
        int quan;
        int summ = 0;
        Map<int, SaleView> sales = Map();
        var loading = game.connection.query('''
    select s_id, s_date, e_name, e_family, p_name, i_quantity, p_price from sales 
	left join employees on sales.s_employee = employees.e_id
	left join items on sales.s_id = items.i_check_num
	left join products on items.i_id = products.p_id
    '''.trim()).then((rows) {
        if (rows is PostgreSQLException) {
          showModalBottomSheet(context: context, builder: (context) {
            return Container(
              height: 60,
              child: Text(decode(e.toString())),
            );
          },);
          return 0;
        }
        if (rows.isEmpty || rows.first.isEmpty) {
          return 0;
        }
          for (var r in rows) {
            if (r.any((element) => element == null))
              continue;
            int q = r[5];
            summ += r[6] * q;
            print('sales ${sales.containsKey(r[0])}');
            if (!sales.containsKey(r[0])) {
              var dt = DateTime.now();
              sales[r[0]] = SaleView(r[0], r[2], r[3],  dt)
                ..items.add(['${r[4]}', '${r[5]}','${r[6] * q}']);
              print('new sales ${sales[r[0]]}');
            } else {
              var s = sales[r[0]];
              var i = s.items.firstWhere((element) => element[0] == r[4], orElse: ()=>null);
              if (i == null) {
                s.items.add([r[4], '${r[5]}', '${r[6] * q}']);
              } else {
                i[1] = '${int.parse(r[5]) + 1}';
              }
            }
          }
          quan = sales.length;
          return [quan, summ];
        }).asStream();
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
                        Flexible(
                          child: StreamBuilder(
                            stream: loading,
                            builder: (context, snapshot) {
                              print('$snapshot ${snapshot.hasData} ${snapshot.data}');
                              if (snapshot.hasData) {
                                if (sales.values.isNotEmpty)
                                return Column(
                                  children: [
                                    Container(
                                      height: 40,
                                      child: Text("Quan: ${quan} Sum: ${summ}"),
                                    ),
                                    Expanded(
                                      child: ListView(
                                        children: sales.values.map((e)
                                        => SizedBox(child:
                                        Container(
                                            decoration: BoxDecoration(
                                                color: Colors.green[200],
                                              borderRadius: BorderRadius.all(Radius.circular(4))
                                            ),

                                            child: e), width: MediaQuery.of(context).size.width / 1.1,)).toList(),
                                      ),
                                    ),
                                  ],
                                );
                                return Container(
                                  alignment: Alignment.center,
                                  child: Text('No sales yet'),
                                );
                              } else {
                                return Container(
                                  alignment: Alignment.center,
                                    child: SizedBox(
                                  width: MediaQuery.of(context).size.width/2,
                                  height: MediaQuery.of(context).size.width/2,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                                  ),
                                ));
                              }
                            },
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
      },
    );

  }

  @override
  Widget information({tag = 0}) {
    String rules =
    '''
  Вы - владелец магазинчика волшебных предметов.
  Продавайте местным жителям то что им нужно, для этого - перетяните предмет с прилавка на жителя. Житель возмет любой предмет, но платить станет только за тот который он просит.
  Все предметы поделены на 4 категории: зелья, еда, оружее и книги. Вы можете получить предметы каждой категории, наняв работников в соответствующую комнату. Чтобы перейти к комнатам - нажмите на стрелку слева от витрины или на значок категории вверху.
  Работникам нужно время на то чтобы получить предмет ( до ${widget.rooms[0].produceDuration.inSeconds} cек. на зелья, до ${widget.rooms[1].produceDuration.inSeconds} cек. на еду, до ${widget.rooms[2].produceDuration.inSeconds} cек. на оружее и до ${widget.rooms[3].produceDuration.inSeconds} cек. на книги). Чем больше работников - тем быстрее вы его получите. Одновременно у вас может быть не более 6 предметов каждого типа - 1 на витрине и еще 5 на складе. За каждый сделанный предмет, работники получают зарплату. Однако, если склад полон - вам все равно придется заплатить им 10% оклада.
  ''';
    return StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          elevation: 0,
          backgroundColor: Colors.transparent,
          contentPadding: EdgeInsets.only(top: 8),
          content: SizedBox(
            width: MediaQuery.of(context).size.width / 1.1,
            height: MediaQuery.of(context).size.width,
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
                        Flexible(
                          child: ClipRRect(
                            clipBehavior: Clip.antiAlias,
                            child: Align(
                              alignment: Alignment.center,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: SingleChildScrollView(child: Text(rules, style: TextStyle(color: Colors.black),)),
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
      },
    );

  }


  void addCreature() {
    var c = Creature(GlobalKey())
      ..offset = Offset(centerX * 2 + 150, 0)
      ..movingTo = Offset(centerX,0);
    c.waitForEnd().then((value) => c.waitForProduct());

    widget.creatures.add(c);
    setState(() {});
  }
  @override
  Widget build(BuildContext context) {
    var s = MediaQuery.of(context).size;

    if (!widget.inited) {
      Future.delayed(Duration(milliseconds: 300), (){
        if (mounted)
        setState(() {});
      });
      return Container(
        alignment: Alignment.center,
        color: Colors.green,
        child: SizedBox(
          width: s.width/2,
          height: s.width/2,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            strokeWidth: 3,
          ),
        ),
      );
    }

    if (s != deviceSize) {
      if (s.aspectRatio > 9/16 || s.aspectRatio < 1/3) {
        DesktopWindow.getWindowSize().then((value) {
          var w = max(value.height * 9/16.0, 500.0);
          DesktopWindow.setWindowSize(Size(w, value.height));
        }).catchError((_){});

      }
      print('$s ${1/s.aspectRatio}');
      deviceSize = s;
      changeView(widget.currentView);
    }

    return Scaffold(
      key: widget.creaturesGameKey,
      body: GestureDetector(
        onVerticalDragEnd: (details) {
          print(details);
          if (details.primaryVelocity > 80) {
            changeView(0);
          } else if (details.primaryVelocity < 80) {
            changeView(1);
          }
        },
        child: Stack(
          children: [
            ListView(
              physics: NeverScrollableScrollPhysics(),
              controller: _scrollController,
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height,
                  child: Column(
                    children: [

                /*      Container(
                        height: 200,
                        child: ListView(
                          children: [
                            MaterialButton(
                            child: Text('Add product'),
                            onPressed: () {
                              Manufacturer manufactorer = Manufacturer(1, "man1", "ru");
                              DangerLevel dangerLevel = DangerLevel("no-danger", 1);
                              Product product = Potion.empty();
                              product.addToDB(force: true).then((value) async {
                                print(value);
                                res = await game.connection.query("SELECT * FROM Products");
                                if (res is PostgreSQLException) {
                                  print(decode(res));

                                }
                                setState(() {
                                });
                              });
                            })
                          ],
                        ),
                      ),*/
                      Expanded(
                        child:LayoutBuilder(
                          builder: (context, constraints) {
                            return Container(
                              color: Colors.green,
                              child: Stack(
                                fit: StackFit.expand,
                                  clipBehavior: Clip.none,
                                  alignment: Alignment.center,
                                  children: [
                                    Image.asset("assets/images/grassTop.png",fit: BoxFit.fill,),
                                    Align(
                                      alignment: Alignment.topCenter,
                                      child: Image.asset("assets/images/grassTop.png",fit: BoxFit.fill,),
                                    ),
                                    // ResultWidget(res, GlobalKey(), loading),
                                    LayoutBuilder(
                                      builder: (context, constraints) {
                                        centerX = constraints.maxWidth/2;
                                        print('Cons ${constraints} ${constraints.maxWidth} ${MediaQuery.of(context).size.width}');
                                        return    Stack(
                                          clipBehavior: Clip.none,
                                          fit: StackFit.expand,
                                          children: [
                                            ...List.generate(widget.creatures.length, (index) {
                                              Creature c = widget.creatures[index];
                                              return  TweenAnimationBuilder(
                                                key: widget.creatures[index].bKey,
                                                duration: () {
                                                  var c = widget.creatures[index];
                                                  return Duration(milliseconds: ((c.offset.dx - c.movingTo.dx).abs() * 10).floor());
                                                }(),
                                                tween: Tween<double>(begin: 0, end: 1),
                                                builder: (context, value, child) {
                                                  return
                                                  Positioned(
                                                    top: c.offset
                                                          .dy + (c
                                                          .movingTo
                                                          .dy -
                                                          c.offset
                                                              .dy) *
                                                          value + (constraints.maxHeight - 300)/2,
                                                      left: c.offset
                                                          .dx + (c.movingTo.dx -
                                                          c.offset.dx) *
                                                          value - 150,
                                                      child: Container(
                                                          child: child));
                                                },
                                                child: c,
                                                onEnd: () {
                                                  // print('from ${c.alignment} to ${c.alignTo}');
                                                  // c.alignment = c.alignTo;
                                                  c.offset = c.movingTo;
                                                  // print('end $cell / $selectedCells');
                                                  widget.movedStreamController.add(c);
                                                },
                                              );
                                            })
                                          ],
                                        );
                                      },
                                    )
                                  ]
                                /*    ..add(
                                        Row(
                                          children: [
                                            IconButton(icon: Icon(Icons.directions_walk), onPressed: () {
                                              // widget.creatures.first.alignTo
                                              // = widget.creatures.first.alignment
                                              //     .add(Alignment(Random().nextInt(300)-150.0, 0));
                                              widget.creatures.first.movingTo = widget.creatures.first.offset
                                                 .translate(Random().nextInt(300)-150.0, 0);
                                              widget.creatures.first.bKey = GlobalKey();
                                              setState(() {});
                                            }),
                                            IconButton(icon: Icon(Icons.add), onPressed: () {
                                              addCreature();
                                               })
                                          ],
                                        )
                                    )*/
                              ),
                            );
                          },
                      )
                      )
                    ],
                  ),
                ),
                Column(
                  children: [
                    widget.rooms[0],
                    widget.rooms[1],
                    widget.rooms[2],
                    widget.rooms[3],
                    Container(
                      color: Color(0xff5B3341),
                      height: min(MediaQuery.of(context).size.height/5, MediaQuery.of(context).size.width/4/1.1),
                    )
                  ],
                ),
              ],
            ),
            Align(
                alignment: Alignment.bottomCenter,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.only(bottom: 16.0, left: 4.0),
                      child: IconButton(
                        icon: Icon(widget.currentView == 0 ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                          key: viewButtonKey,
                          color: Colors.white,), onPressed: () {
                        changeView(widget.currentView == 0 ? 1 : 0);
                      },),
                    ),
                    Container(child: widget.chooser),
                  ],
                )),
            SafeArea(

                child: Container(
                  height: 60,
                  padding: EdgeInsets.only(top: 30),
                  child:  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(icon: Icon(Icons.arrow_back_sharp, color: Colors.white,), onPressed: () {
                        Navigator.of(context).pop();
                      },),
                      IconButton(icon: Icon(Icons.info_outline, color: Colors.white,), onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => information(),
                        );
                      },),
                      StreamBuilder<Object>(
                          stream: widget.producedProducts.stream.asBroadcastStream(),
                          builder: (context, snapshot) {
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    changeView(1);
                                  },
                                  child: Row(
                                    children: [
                                      Image.asset("assets/images/Potion/Icon1.png",fit: BoxFit.fitHeight,),
                                      Text('${widget.rooms[0].products.length}/5 '),
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    changeView(2);
                                  },
                                  child: Row(
                                    children: [
                                      Image.asset("assets/images/Food/Apple.png",fit: BoxFit.fitHeight,),
                                      Text('${widget.rooms[1].products.length}/5 '),
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    changeView(3);
                                  },
                                  child: Row(
                                    children: [
                                      Image.asset("assets/images/Weapon/GoldenSword.png",fit: BoxFit.fitHeight,),
                                      Text('${widget.rooms[2].products.length}/5 '),
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    changeView(4);
                                  },
                                  child: Row(
                                    children: [
                                      Image.asset("assets/images/Book/Book.png",fit: BoxFit.fitHeight,),
                                      Text('${widget.rooms[3].products.length}/5 '),
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => salesInfo(),
                                    );
                                  },
                                  child: Row(
                                    children: [
                                      Image.asset("assets/images/Golden Coin.png",fit: BoxFit.fitHeight,),
                                      Text('${widget.money}'),
                                    ],
                                  ),
                                )
                              ],
                            );
                          }
                      )
                    ],
                  ),
                ))
          ],
        ),
      ),
    );
  }

  Widget myButton(String text, String query, {substitutionValues, Table table}) {
    return GestureDetector(
      onTap: () async {
        if (query.isNotEmpty) {
          loading = true;
          setState(() {});
          widget.connection.query(query, substitutionValues: substitutionValues)
              .then((value) {
            res = value;
            loading = false;
            setState(() {});
          });
        } else {
          setState(() {});
        }
      },
      child: Container(
        width: 180,
        height: 80,
        margin: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white70,
          borderRadius: BorderRadius.all(Radius.circular(8)),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              spreadRadius: 3
            )
          ]
        ),
        alignment: Alignment.center,
        child: Stack(
          children: [
            Center(child: Text(text)),
            table != null ? Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: EdgeInsets.all(8),
                child: InkWell(
                  child: Icon(Icons.add),
                  onTap: () {
                    currentTable = table;
                    setState(() {});
                  },
                ),
              ),
            ) : Container()
          ],
        ),
      ),
    );
  }

  Widget myButton2(String text, onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 180,
        height: 80,
        margin: EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: Colors.white70,
            borderRadius: BorderRadius.all(Radius.circular(8)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  spreadRadius: 3
              )
            ]
        ),
        alignment: Alignment.center,
        child: Stack(
          children: [
            Center(child: Text(text))
          ],
        ),
      ),
    );
  }
}

Widget tf(changed, label) {
  return Container(
    width: 100,
    padding: EdgeInsets.all(8),
    child: TextField(
      onChanged: changed,
      decoration: InputDecoration(
          labelText: label
      ),
    ),
  );
}

Widget dp(context, picked, label) {
  // return MaterialButton(onPressed: () => showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(1900), lastDate: DateTime.now()).then((value) {
  //   picked(value);
  // }),
  // color: Colors.lightBlue,
  // child: Text(
  //   label
  // ),
  // );

  var _dateController = TextEditingController();
  var maskFormatter = new MaskTextInputFormatter(mask: '##.##.####', filter: { "#": RegExp(r'[0-9]'), });

  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: Container(
      width: 160,
      child: TextFormField(
        controller: _dateController,
        inputFormatters: [maskFormatter],
        validator: (value) {
          if (value.isEmpty) {
            return 'Это надо заполнить';
          } else {
            var d = myDateParse(_dateController.text);
            if (d != null) {
              if (d.year > 1800)
                return null;
              else return 'Люди столько не живут';
            } else return 'Кажется, такой даты нет';
          }
        },
        decoration: InputDecoration(
            labelText: label,
            hintText: 'дд.мм.гггг',
            contentPadding:
            EdgeInsets.symmetric(horizontal: 10.0),
            border: OutlineInputBorder(),
            suffixIcon: InkWell(
                onTap: () => showDatePicker(
                  context: context,
                  initialDatePickerMode:
                  myDateParse(_dateController.text) != null ? DatePickerMode.day : DatePickerMode.year,
                  initialDate: myDateParse(_dateController.text) ?? DateTime(2012),
                  firstDate: DateTime(1950),
                  lastDate: DateTime.now(),
                ).then((value) {
                  if (value != null) {
                    _dateController.text =
                        DateFormat('dd.MM.yyyy').format(value);
                    picked(value);
                  }
                }),
                child: Icon(Icons.calendar_today))),
      ),
    ),
  );

}

DateTime myDateParse(String s) {
  if (s.isEmpty)
    return null;
  s = s.trim().replaceAll('/', '.').replaceAll('-', '.').replaceAll(',', '.').replaceAll('\\', '.').replaceAll(':', '.');
  if (s.contains('.')) {
    try {
      var d =  DateFormat('dd.MM.yyyy').parseLoose(s);
      if (d.year >= 1950)
        return d;
    }
    catch (_) {}
  }
  return null;
}