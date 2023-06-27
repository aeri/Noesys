import 'package:flutter/material.dart';

void main() {
  runApp(new AddScreen());
}

class AddScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Flutter Demo',
      theme: new ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: new MyHomePage(title: 'New server'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({required this.title});

  final String title;

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text(widget.title),
        actions: <Widget>[
          new IconButton(icon: const Icon(Icons.save), onPressed: () {})
        ],
      ),
      body: new Column(
        children: <Widget>[
          new ListTile(
            leading: const Icon(Icons.format_quote),
            title: new TextField(
              decoration: new InputDecoration(
                hintText: "Name",
              ),
            ),
          ),
          new ListTile(
            leading: const Icon(Icons.link),
            title: new TextField(
              decoration: new InputDecoration(
                hintText: "URL/IP",
              ),
            ),
          ),
          new ListTile(
            leading: const Icon(Icons.flag),
            title: new TextField(
              decoration: new InputDecoration(
                hintText: "Topic",
              ),
            ),
          ),
          const Divider(
            height: 1.0,
          ),
          CheckboxListTile(
            title: Text("Alert on 4xx"),
            subtitle: const Text('Receive a notification if the system \n'
                'responds with a 4xx error'),
            value: true,
            onChanged: (newValue) {
              setState(() {
                newValue = newValue;
              });
            },
            controlAffinity:
                ListTileControlAffinity.leading, //  <-- leading Checkbox
          ),
          CheckboxListTile(
            title: Text("Alert on 5xx"),
            subtitle: const Text('Receive a notification if the system \n'
                'responds with a 5xx error'),
            value: true,
            onChanged: (newValue) {
              setState(() {
                newValue = newValue;
              });
            },
            controlAffinity:
                ListTileControlAffinity.leading, //  <-- leading Checkbox
          ),
          CheckboxListTile(
            title: Text("Alert on Timeout"),
            subtitle: const Text('Receive a notification if the system \n'
                'not responds'),
            value: true,
            onChanged: (newValue) {
              setState(() {
                newValue = newValue;
              });
            },
            controlAffinity:
                ListTileControlAffinity.leading, //  <-- leading Checkbox
          ),
          new ListTile(
            leading: const Icon(Icons.today),
            title: const Text('Birthday'),
            subtitle: const Text('February 20, 1980'),
            trailing: const Icon(
              Icons.check_circle,
              color: Colors.green,
            ),
          ),
          new ListTile(
            leading: const Icon(Icons.group),
            title: const Text('Contact group'),
            subtitle: const Text('Not specified'),
          )
        ],
      ),
    );
  }
}
