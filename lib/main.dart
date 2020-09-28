import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      brightness: Brightness.light,
      primaryColor: Colors.blue,
      accentColor: Colors.orange,
    ),
    home: MyApp(),
  ));
}

// final dummySnapshot = [
//   {"name": "Filip", "votes": 15},
//   {"name": "Abraham", "votes": 14},
//   {"name": "Richard", "votes": 11},
//   {"name": "Ike", "votes": 10},
//   {"name": "Justin", "votes": 1},
// ];

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Firebase.initializeApp(),
      builder: (context, snapshot) {
        // エラー時に表示するWidget
        if (snapshot.hasError) {
          return Container(color: Colors.white);
        }

        // Firebaseのinitialize完了したら表示したいWidget
        if (snapshot.connectionState == ConnectionState.done) {
          return MyHomePage();
        }

        // Firebaseのinitializeが完了するのを待つ間に表示するWidget
        return Container(color: Colors.blue);
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List votesList = List();
  String name = "";
  num votes = 0;
  String id = '0';

  createVotes() {
    DocumentReference documentReference =
        FirebaseFirestore.instance.collection('Votes').doc(id);

    // Map
    Map<String, dynamic> votesList = {"name": name, "votes": votes, "id": id};

    documentReference.set(votesList).whenComplete(() {
      print("$name $votes $id created");
    });

    try {
      num numId = int.parse(id);
      id = (numId + 1).toString();
      name = "";
    } catch (e) {
      print(e);
    }
  }

  deleteTodos(item) {
    DocumentReference documentReference =
        FirebaseFirestore.instance.collection('Votes').doc(item);

    documentReference.delete().whenComplete(() {
      print("deleted");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Vote App'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                title: Text("Add Votelist"),
                content: TextField(
                  onChanged: (String value) {
                    name = value;
                  },
                ),
                actions: <Widget>[
                  FlatButton(
                      onPressed: () {
                        createVotes();

                        Navigator.of(context).pop();
                      },
                      child: Text("Add"))
                ],
              );
            },
          );
        },
        child: Icon(Icons.add, color: Colors.white),
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    // return _buildList(context, dummySnapshot);
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('Votes').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return LinearProgressIndicator();
        print(snapshot.data.docs);
        return _buildList(context, snapshot.data.docs);
      },
    );
  }

  // Widget _buildList(BuildContext context, List<Map> snapshot) {
  Widget _buildList(BuildContext context, List<DocumentSnapshot> snapshot) {
    return ListView(
      padding: const EdgeInsets.only(top: 20.0),
      children: snapshot.map((data) => _buildListItem(context, data)).toList(),
    );
  }

  Widget _buildListItem(BuildContext context, DocumentSnapshot data) {
    final record = Record.fromSnapshot(data);
    return Padding(
      key: ValueKey(record.name),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(5.0),
        ),
        child: ListTile(
            leading: IconButton(
              icon: Icon(
                Icons.delete,
                color: Colors.red,
              ),
              onPressed: () {
                print(data.get('id'));
                deleteTodos(data.get('id'));
              },
            ),
            title: Text(record.name),
            trailing: Text(record.votes.toString()),
            // onTap: () => print(record),
            onTap: () =>
                record.reference.update({'votes': FieldValue.increment(1)})),
      ),
    );
  }
}

class Record {
  final String name;
  final int votes;
  final DocumentReference reference;

  // コンストラクタ
  // FirestoreからのデータをDartで使える形に変換している
  Record.fromMap(Map<String, dynamic> map, {this.reference})
      // assertはDartの例外処理
      : assert(map['name'] != null),
        assert(map['votes'] != null),
        name = map['name'],
        votes = map['votes'];

  // FirestoreからのデータをDartで使える形に変換している
  Record.fromSnapshot(DocumentSnapshot snapshot)
      : this.fromMap(snapshot.data(), reference: snapshot.reference);

  @override
  String toString() => "Record<$name: $votes>";
}
