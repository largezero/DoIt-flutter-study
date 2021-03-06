import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'completeList.dart';
import 'todo.dart';
import 'addTodo.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Future<Database> database = initDatabase();

    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
       primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => DatabaseApp(database),
        '/add': (context) => AddTodoApp(database),
        '/complete': (context) => CompleteListApp(database),
      },
    );
  }

  Future<Database> initDatabase() async {
    return openDatabase(
      join(await getDatabasesPath(), 'todo_database.db'),
      onCreate: (db, version) {
        return db.execute(
          "CREATE TABLE todos(id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT, content TEXT, active INTEGER)",
        );
      }, version: 1,
    );
  }
}

class DatabaseApp extends StatefulWidget {
  final Future<Database> db;
  // const DatabaseApp({Key? key, this.db}) : super(key: key);
  DatabaseApp(this.db);

  @override
  State<DatabaseApp> createState() => _DatabaseApp();
}

class _DatabaseApp extends State<DatabaseApp> {
  Future<List<Todo>>? todoList;

  @override
  void initState() {
    super.initState();
    todoList = getTodos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Database'),
        actions: [
          TextButton(onPressed: () async {
            await Navigator.of(context).pushNamed('/complete');
            setState(() {
              todoList = getTodos();
            });
          }, child: const Text('완료한 일', style: TextStyle(color: Colors.white),))
        ],
      ),
      body: Center(
        child: FutureBuilder(
          builder: (context, snapshot) {
            switch (snapshot.connectionState) {
              case ConnectionState.none: return CircularProgressIndicator();
              case ConnectionState.waiting: return CircularProgressIndicator();
              case ConnectionState.active: return CircularProgressIndicator();
              case ConnectionState.done:
                if (snapshot.hasData) {
                  return ListView.builder(itemBuilder: (context, index) {
                    Todo todo = (snapshot.data as List<Todo>)[index];
                    return ListTile(
                      title: Text(todo.title!, style: TextStyle(fontSize: 20),),
                      subtitle: Column(
                        children: [
                          Text(todo.content!),
                          Text('완료여부: ${ todo.active! ? "YES" : "NO" }'),
                          const SizedBox(height: 1, child: ColoredBox(color: Colors.blue),),
                        ],
                      ),
                      onTap: () async {
                        TextEditingController controller = TextEditingController(text: todo.content);

                        Todo result = await showDialog(context: context, builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('${todo.id} : ${todo.title}'),
                            content: TextField(
                              controller: controller,
                              keyboardType: TextInputType.text,
                              decoration: InputDecoration(labelText: todo.content),
                            ),
                            actions: [
                              TextButton(onPressed: () {
                                setState(() {
                                  todo.active = true;
                                  todo.content = controller.value.text;
                                });
                                Navigator.of(context).pop(todo);
                              }, child: const Text('예')),
                              TextButton(onPressed: () {
                                setState(() {
                                  todo.active = false;
                                  todo.content = controller.value.text;
                                });
                                Navigator.of(context).pop(todo);
                              }, child: const Text('아니오')),
                              TextButton(onPressed: () {
                                Navigator.of(context).pop(todo);
                              }, child: const Text('취소')),
                            ],
                          );
                        });
                        _updateTodo(result);
                      },
                      onLongPress: () async {
                        Todo? result = await showDialog(context: context, builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('${todo.id} : ${todo.title}'),
                            content: Text('${todo.content}를 삭제하시겠습니까?'),
                            actions: [
                              TextButton(onPressed: () {
                                Navigator.of(context).pop(todo);
                              }, child: const Text('삭제')),
                              TextButton(onPressed: () {
                                Navigator.of(context).pop();
                              }, child: const Text('취소')),
                            ],
                          );
                        });
                        if (result != null) {
                          _deleteTodo(result);
                        }
                      },
                    );
                  }, itemCount: (snapshot.data as List<Todo>).length,);
                } else {
                  return const Text('No data');
                }
            }
            return CircularProgressIndicator();
          },
          future: todoList,
        ),
      ),
      floatingActionButton: Column(
        children: [
          FloatingActionButton(
            onPressed: () async {
              final todo = await Navigator.of(context).pushNamed('/add');
              if (todo != null) {
                _insertTodo(todo as Todo);
              }
            },
            tooltip: '',
            heroTag: null,
            child: const Icon(Icons.add),
          ),
          SizedBox(height: 10,),
          FloatingActionButton(onPressed: () async {
            _allComplete();
          }, child: Icon(Icons.update),)
        ],
        mainAxisAlignment: MainAxisAlignment.end,
      ),
      // floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  void _insertTodo(Todo todo) async {
    final Database database = await widget.db;
    await database.insert('todos', todo.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    setState(() {
      todoList = getTodos();
    });
  }

  Future<List<Todo>> getTodos() async {
    final Database database = await widget.db;
    final List<Map<String, dynamic>> maps = await database.query('todos');

    return List.generate(maps.length, (i) {
      int active = maps[i]['active'] == 1 ? 1 : 0;
      return Todo(
        title: maps[i]['title'].toString(),
        content: maps[i]['content'].toString(),
        active: maps[i]['active']==1 ? true : false,
        id: maps[i]['id']
      );
    });
  }

  void _updateTodo(Todo todo) async {
    final Database database = await widget.db;
    await database.update('todos', todo.toMap(), where: 'id = ?', whereArgs: [todo.id],);
    setState(() {
      todoList = getTodos();
    });
  }

  void _deleteTodo(Todo todo) async {
    final Database database = await widget.db;
    await database.delete('todos', where: 'id = ?', whereArgs: [todo.id],);
    setState(() {
      todoList = getTodos();
    });
  }

  void _allComplete() async {
    final Database database = await widget.db;
    await database.rawUpdate('update todos set active = 1 where active = 0 ');
    setState(() {
      todoList = getTodos();
    });
  }
}
