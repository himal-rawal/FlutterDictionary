import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dictionary/failure.dart';
import 'package:http/http.dart';

import 'package:flutter/material.dart';

class Dictionary extends StatefulWidget {
  @override
  _DictionaryState createState() => _DictionaryState();
}

class _DictionaryState extends State<Dictionary> {
  TextEditingController _controller = TextEditingController();
  StreamController _streamController;
  Stream _stream;
  String _token =
      "57c41f6e6084406f1e0c7e71f22f2be87629e7f2"; //enter your api key
  String _url = "https://owlbot.info/api/v4/dictionary/";
  Timer _debounce;

  _search() async {
    if (_controller.text == null || _controller.text.length == 0) {
      _streamController.add(null);
      return;
    }
    try {
      _streamController.add("waiting");
      Response response = await get(_url + _controller.text.trim(),
          headers: {"Authorization": "Token " + _token});
      if (response.statusCode == 200) {
        _streamController.add(json.decode(response.body));
      }
    } on SocketException {
      throw Failure("No internet connection!!");
    } on HttpException {
      throw Failure("couldn't find the word!!");
    } on FormatException {
      throw Failure("Bad response format 👎");
    }
  }

  @override
  void initState() {
    super.initState();
    _streamController = StreamController();
    _stream = _streamController.stream;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Dictionary"),
        centerTitle: true,
        bottom: PreferredSize(
            child: Row(
              children: <Widget>[
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      FocusScope.of(context).unfocus();
                    },
                    child: Container(
                      margin: const EdgeInsets.only(left: 12.0, bottom: 8.0),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30)),
                      child: TextFormField(
                        autocorrect: true,
                        autofocus: true,
                        enableSuggestions: true,
                        keyboardAppearance: Brightness.dark,
                        onChanged: (String text) {
                          if (_debounce?.isActive ?? false) _debounce.cancel();
                          _debounce =
                              Timer(const Duration(milliseconds: 1000), () {
                            _search();
                          });
                        },
                        controller: _controller,
                        decoration: InputDecoration(
                            hintText: "search any word",
                            contentPadding: EdgeInsets.only(left: 24),
                            border: InputBorder.none),
                      ),
                    ),
                  ),
                ),
                IconButton(
                    icon: Icon(
                      Icons.search,
                      color: Colors.black,
                    ),
                    onPressed: () {
                      _search();
                    })
              ],
            ),
            preferredSize: Size.fromHeight(40)),
      ),
      body: Container(
        margin: EdgeInsets.all(8.0),
        child: StreamBuilder(
            stream: _stream,
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              if (snapshot.data == null) {
                return Container(
                  child: SingleChildScrollView(
                    child: Column(
                      children: <Widget>[
                        Center(
                          child: Image(
                            image: AssetImage("assets/download.jpg"),
                            height: 400,
                            width: 400,
                            fit: BoxFit.fill,
                          ),
                        ),
                        SizedBox(
                          height: 70,
                        ),
                        Text("About:"),
                        Text("Produced By: Traitor"),
                        Text("@copyright 2020"),
                        Text("Great thanks to owlbot.info")
                      ],
                    ),
                  ),
                );
              }
              if (snapshot.data == 'waiting') {
                return Center(
                  child: CircularProgressIndicator(),
                );
              }

              return ListView.builder(
                  itemCount: snapshot.data['definitions'].length,
                  itemBuilder: (BuildContext context, int index) {
                    return ListBody(
                      children: <Widget>[
                        Container(
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: Colors.grey[400]),
                          //color: Colors.grey[400],
                          child: ListTile(
                            leading: snapshot.data['definitions'][index]
                                        ['image_url'] ==
                                    null
                                ? null
                                : CircleAvatar(
                                    radius: 27,
                                    backgroundImage: NetworkImage(
                                      snapshot.data['definitions'][index]
                                          ['image_url'],
                                    ),
                                  ),
                            title: Text(_controller.text.trim() +
                                "(" +
                                snapshot.data["definitions"][index]["type"] +
                                ")"),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(15.0),
                          child: Text(
                            '-' +
                                "  " +
                                snapshot.data["definitions"][index]
                                    ["definition"],
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 25,
                            ),
                          ),
                        )
                      ],
                    );
                  });
            }),
      ),
    );
  }
}
