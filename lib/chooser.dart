
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:postgres_app/DBObject/Employer.dart';

import 'DBObject/Product.dart';
import 'game.dart';

class Chooser extends StatefulWidget {

  List<Widget> chooseItems = [];
  Function remove;
  Function update;

  @override
  State createState() => _ChooserState();

  Chooser({key}) : super(key: key) {
    game.chooser = this;
  }

  void changeCards(int i) {
    if (i == 0) {
          while (chooseItems.isNotEmpty) {
            game.availableEmployers.insert(0, chooseItems.last);
            (game.chooserKey.currentState as _ChooserState).removeNice(chooseItems.last);
          }
          (game.chooserKey.currentState as _ChooserState).update();
    } else {
          while (chooseItems.isNotEmpty) {
            game.products.insert(0, chooseItems.last);
            (game.chooserKey.currentState as _ChooserState).removeNice(chooseItems.last);
          }
          (game.chooserKey.currentState as _ChooserState).update();
      // }
    }
  }

}

class _ChooserState extends State<Chooser> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey();
  var top = 0.0;
  var left = 0.0;
  bool available = true;
  Widget message;
  int dragIndex = -1;



  void showMessage(Widget message) {
    this.message = message;
    setState(() {});
  }

  void hideMessage() {
    this.message = null;
    setState(() {});
  }

  void setAvailable(a) {
    setState(() {
      available = a;
    });
  }

  step() async {
    int dLen = widget.chooseItems.length;
    for (int i = 0; i < widget.chooseItems.length; i++) {
      if (widget.chooseItems.length < dLen) {
        i--;
        dLen = widget.chooseItems.length;
      }
    }
//    await Future.delayed(Duration(milliseconds: 200));
  }

  void update() {

    while ((widget.chooseItems.length < 4 || (widget.chooseItems.length < 5 && game.currentView > 0)) &&  _addAnItem()) {}

    setState(() {});
    print('${widget.chooseItems}');
  }

  @override
  void initState() {
    widget.remove = this.remove;
    widget.update = this.update;
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => update());
  }

  @override
  Widget build(BuildContext context) {
    // widget.remove = this.remove;
    var width = MediaQuery.of(context).size.width;
    var height = min(width / 4 / 1.1, MediaQuery.of(context).size.height / 5);
    return AnimatedContainer(
      height: height,
      alignment: Alignment.center,
      duration: Duration(milliseconds: 200),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: ClipRRect(
          clipBehavior: Clip.antiAlias,
          borderRadius: BorderRadius.all(Radius.circular(8)),
          child: Stack(
              fit: StackFit.expand,
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Image.asset("assets/images/chooserBack.png", fit: BoxFit.fill, width: width, height: height,),
                AnimatedSwitcher(
                  duration: Duration(milliseconds: 300),
                  child: message == null ? Container() : message,
                ),
                AnimatedPositioned(
                  top: message == null ? 0 :  height * 0.9,
                  duration: Duration(milliseconds: 300),
                  child: Container(
                    width: width,
                    height: height,
                    child: AbsorbPointer(
                      absorbing: !available,
                      child: Stack(
                        children: [
                          AnimatedList(
                            physics: NeverScrollableScrollPhysics(),
                            scrollDirection: Axis.horizontal,
                            padding:
                            EdgeInsets.symmetric(horizontal: 4),
                            key: _listKey,
                            initialItemCount: widget.chooseItems.length,
                            itemBuilder: (context, index, animation) {
                              // print('chooseItems: ${widget.chooseItems}');
                              return _buildItem(context, widget.chooseItems[index], animation);
                            }
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ),
      ),
    );
  }

  Widget _buildItem(
      BuildContext context, Widget item, Animation<double> animation) {
    Widget back = Container(width: 100, height: 100);
    if (item is Product) {
      if (item is Potion) {
        back = Container(width: 100,
          height: 100,
          child: Image.asset("assets/images/potionBack.png", fit: BoxFit.fill,
            filterQuality: FilterQuality.none,),);
      } else if (item is Weapon) {
        back = Container(width: 100,
          height: 100,
          child: Image.asset("assets/images/swordBack.png", fit: BoxFit.fill,
              filterQuality: FilterQuality.none),);
      } else if (item is Food) {
        back = Container(width: 100,
          height: 100,
          child: Image.asset("assets/images/appleBack.png", fit: BoxFit.fill,
              filterQuality: FilterQuality.none),);
      } else if (item is Book) {
        back = Container(width: 100,
          height: 100,
          child: Image.asset("assets/images/bookBack.png", fit: BoxFit.fill,
              filterQuality: FilterQuality.none),);
      }
      back = Stack(
        children: [
          Opacity(
              opacity: 0.4,
              child: back),
          Text('  ${(item as Product).price ?? " "}', style: TextStyle(color: Colors.white),)
        ],
      );
    }

    return FittedBox(
      fit: BoxFit.cover,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 4),
        child: Stack(
          children: [
            back,
            SlideTransition(
              position: animation
                  .drive(Tween(begin: Offset(0.0, 4.0), end: Offset(0.0, 0.0))),
              child: Draggable(
                  data: item,
                  maxSimultaneousDrags:
                  true
                      ? 1
                      : 0,
                  feedback: Container(
                    child: item,
                  ),
                  childWhenDragging: Container(
                      child: Container(
                        width: 100,
                        height: 100,
                      )),
                  onDragStarted: () {
                    dragIndex = game.getProductIndex(item);
                    setState(() {
                      // (widget.gamefield.key as GlobalKey).currentState.setState(() {});
                      // widget.gamefield.dragItem = item;
                    });
                  },
                  onDragEnd: (details) {

                  },
                  onDragCompleted: () async {
                    Product item;
                    int _dragIndex = dragIndex;
                    if (game.currentView == 0) {
                      if (_dragIndex != null) {
                        print('Chooser products ${game.rooms[_dragIndex].products}');
                        if (game.rooms[_dragIndex].products.isEmpty) {
                          game.rooms[_dragIndex].addEmptyProduct();
                          print('Chooser waiting for ${_dragIndex}');
                          game.producedProducts.stream
                              .asBroadcastStream()
                              .firstWhere((e) => e == _dragIndex).then((value) {
                                print('Chooser got new ${value}');
                                if (game.currentView == 0) {
                                  remove(widget.chooseItems[_dragIndex]);
                                  item = game.rooms[_dragIndex].products.first;
                                  game.rooms[_dragIndex].products.removeAt(0);
                                  _addAnItem(index: _dragIndex, item: item);
                                  setState(() {});
                                } else {
                                  print('adding to game products');
                                  int emptyIndex = game.products
                                      .indexWhere((e) => e.assetName == null && game.getProductIndex(e) == _dragIndex);
                                  if (emptyIndex >= 0) {
                                    game.products.removeAt(emptyIndex);
                                    item = game.rooms[_dragIndex].products.first;
                                    game.rooms[_dragIndex].products.removeAt(0);
                                    game.products.insert(emptyIndex, item);
                                  }
                                }
                          });
                        }
                        if (game.rooms[_dragIndex].products.isNotEmpty) {
                          item = game.rooms[_dragIndex].products.first;
                          game.rooms[_dragIndex].products.removeAt(0);
                        } else {
                          throw Exception('Room must not be empty');
                        }
                        _addAnItem(index: _dragIndex, item: item);
                      }
                      else {
                        throw Exception("Chooser dragIndex not found");
                      }
                    } else {

                    }
                    dragIndex = null;
                  },
                  child: Stack(
                    children: [
                      item,
                      Container(
                        color: Colors.white.withOpacity(available ? 0 : 0.5),
                        alignment: Alignment.center,
                      )
                    ],
                  )),
            ),
          ],
        ),
      ),
    );
  }

  _removeItem(context, animation) {
    return Container();
  }

  _removeItemNice(context, item, animation, {begin: const Offset(-4.0, 0.0), end: const Offset(0.0, 0.0)}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: SlideTransition(
          position: animation
              .drive(Tween(begin: begin as Offset, end: end as Offset)),
          child: item),
    );
  }

  void remove(item) {
    _listKey.currentState.removeItem(widget.chooseItems.indexOf(item),
            (context, animation) => _removeItem(context, animation));
    widget.chooseItems.remove(item);
    print('remove ${widget.chooseItems.length}');
  }

  void removeNice(item,
      {begin: const Offset(4.0, 0.0),
        end: const Offset(0.0, 0.0),
        duration: const Duration(milliseconds: 400)}) {
    _listKey.currentState.removeItem(
        widget.chooseItems.indexOf(item),
            (context, animation) =>
            _removeItemNice(context, item, animation, begin: begin, end: end),
        duration: duration);
    widget.chooseItems.remove(item);
    print('remove nice ${widget.chooseItems.length}');
  }

  bool _addAnItem({index, item}) {
    assert(index == null || item != null);
    if (index == null) {
      if (game.currentView == 0) {
        if (game.products.isNotEmpty) {
          widget.chooseItems.add(game.products.first);
          game.products.removeAt(0);
        } else {
          print('false');
          return false;
        }
      } else {
        if (game.availableEmployers.isNotEmpty) {
          widget.chooseItems.add(game.availableEmployers.first);
          game.availableEmployers.removeAt(0);
          game.availableEmployers.add(Employee());
        } else {
          print('false');
          return false;
        }
      }
      print('true ${widget.chooseItems.length}');
      _listKey.currentState.insertItem(widget.chooseItems.length - 1);
    } else {
      widget.chooseItems.insert(index, item);
      _listKey.currentState.insertItem(index);
    }
    return true;
  }

}
