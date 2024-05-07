import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:study_persistence/dog.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  Database? database;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _openDatabase();
  }

  void _openDatabase() async {
    database = await openDatabase(
      join(await getDatabasesPath(), 'doggie_database.db'),
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE dogs(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, age INTEGER)',
        );
      },
      version: 1,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Builder(
        builder: (context) {
          return Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  TextField(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Name',
                      hintText: 'Enter a name',
                    ),
                    controller: _nameController,
                  ),
                  const SizedBox(height: 16,),
                  TextField(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Age',
                      hintText: 'Enter a age',
                    ),
                    keyboardType: TextInputType.number,
                    controller: _ageController,
                  ),
                  const SizedBox(height: 24,),
                  Row(
                    children: [
                      TextButton(
                          onPressed: (){
                            Dog dog = Dog(
                                name: _nameController.text,
                                age: int.parse(_ageController.text));
                            insertDog(dog);
                            _nameController.text = '';
                            _ageController.text = '';
                          },
                          child: const Text('Save')
                      ),
                      TextButton(
                          onPressed: (){
                            dogs(context);
                          },
                          child: const Text('See All')
                      )
                    ],
                  )
                ],
              ),
          );
        }
      ),
    );
  }

  // Define a function that inserts dogs into the database
  Future<void> insertDog(Dog dog) async {
    await database?.insert(
      'dogs',
      dog.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // A method that retrieves all the dogs from the dogs table.
  void dogs(BuildContext context) async {
    if (database == null) {
      return;
    }

    final List<Map<String, Object?>> dogMaps = await database!.query('dogs');

    showBottomSheet(
        context: context,
        builder: (context) => Padding(
          padding: const EdgeInsets.all(12.0),
          child: ListView.separated(
            itemCount: dogMaps.length,
            separatorBuilder: (context, index) => Divider(height: 1,),
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("${dogMaps[index]['id']}: ${dogMaps[index]['name']} - ${dogMaps[index]['age']}"),
                  IconButton(
                      onPressed: (){
                        deleteDog(context, dogMaps[index]['id'] as int);
                      },
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                      ))
                ],
              ),
            ),
          ),
        ),
    );
  }

  void deleteDog(BuildContext context, int id) async {
    await database?.delete(
      'dogs',
      // Use a `where` clause to delete a specific dog.
      where: 'id = ?',
      // Pass the Dog's id as a whereArg to prevent SQL injection.
      whereArgs: [id],
    );

    Navigator.pop(context);
  }
}
