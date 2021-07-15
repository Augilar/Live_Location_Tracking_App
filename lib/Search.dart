import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'main.dart';
import 'package:firebase_core/firebase_core.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage>
    with SingleTickerProviderStateMixin {
  bool _isSearching = false;
  bool _isLoading = false;
  String searchQuery = "Search query";

  static final GlobalKey<ScaffoldState> scaffoldKey =
      new GlobalKey<ScaffoldState>();

  late String _username;
  List<String> _usernames = <String>[];
  List<String> _selectedusernames = <String>[];
  Map<String, bool> _selectedusernamesbool = <String, bool>{};
  final TextEditingController _searchQuery = TextEditingController();

  @override
  void initState() {
    FirebaseAuth _auth = FirebaseAuth.instance;
    _username = _auth.currentUser!.displayName.toString();
    super.initState();
  }

  Widget _buildSearchField() {
    return new TextField(
      controller: _searchQuery,
      autofocus: true,
      decoration: const InputDecoration(
        hintText: "Search by username",
        border: InputBorder.none,
        hintStyle: const TextStyle(color: Colors.white30),
      ), // Input Decoration

      style: const TextStyle(color: Colors.white, fontSize: 16.0),
      onChanged: (text) {
        int i = 0;
        _usernames.clear(); // clear all the usernames in this list

        FirebaseFirestore.instance
            .collection('data')
            .where('full_name', isEqualTo: text)
            .get()
            .then((snapshot) {
          setState(() {
            _isLoading = true;
          });

          setState(() {
            snapshot.docs.forEach((element) {
              if (element['full_name'] != _username) {
                // if the current document is not of the current user

                if (!_usernames.contains(element['full_name'])) {
                  // if _usernames list doesn't contain this
                  _usernames.insert(i, element['full_name']); // add it

                  if (_selectedusernames.contains(element['full_name'])) {
                    // if this element user is in _selectedusernames update the map accordingly
                    _selectedusernamesbool.update(
                        element['full_name'], (value) => true,
                        ifAbsent: () => true);
                  } else {
                    _selectedusernamesbool.update(
                        element['full_name'], (value) => false,
                        ifAbsent: () => false);
                  }
                }
                i++;
              }
              ;
            });
            _isLoading = false;
          });
        });
      },
    );
  }

  // search box in AppBar template functions

  void _startSearch() {
    print("open search box");
    ModalRoute.of(context)!
        .addLocalHistoryEntry(new LocalHistoryEntry(onRemove: _stopSearching));

    setState(() {
      _isLoading = true;
      _isSearching = true;
    });
  }

  void _stopSearching() {
    _clearSearchQuery();

    setState(() {
      _isSearching = false;
    });
  }

  void _clearSearchQuery() {
    print("close search box");
    setState(() {
      _searchQuery.clear();
      updateSearchQuery("Search query");
    });
  }

  Widget _buildTitle(BuildContext context) {
    var horizontalTitleAlignment =
        Platform.isIOS ? CrossAxisAlignment.center : CrossAxisAlignment.start;

    return new InkWell(
      onTap: () => scaffoldKey.currentState!.openDrawer(),
      child: new Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: new Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: horizontalTitleAlignment,
          children: <Widget>[
            const Text('Seach box'),
          ],
        ),
      ),
    );
  }

  void updateSearchQuery(String newQuery) {
    setState(() {
      searchQuery = newQuery;
      _isLoading = true;
    });
    print("search query " + newQuery);
  }

  List<Widget> _buildActions() {
    if (_isSearching) {
      return <Widget>[
        new IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            if (_searchQuery == null || _searchQuery.text.isEmpty) {
              Navigator.pop(context);
              return;
            }
            _clearSearchQuery();
          },
        ),
      ];
    }

    return <Widget>[
      new IconButton(
        icon: const Icon(Icons.search),
        onPressed: _startSearch,
      ),
    ];
  }

  Widget _buildChip(String label, Color color) {
    return Chip(
      labelPadding: EdgeInsets.all(2.0),
      avatar: CircleAvatar(
        backgroundColor: Colors.black,
        child: Text(label[0].toUpperCase()),
      ),
      label: Text(
        label,
        style: TextStyle(
          color: Colors.white,
        ),
      ),
      deleteIcon: Icon(
        Icons.close,
      ),
      onDeleted: () => _deleteselected(label),
      backgroundColor: color,
      elevation: 6.0,
      shadowColor: Colors.grey[60],
      padding: EdgeInsets.all(8.0),
    );
  }

  void _deleteselected(String label) {
    setState(() {
      _selectedusernames.remove(label);
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        key: scaffoldKey,
        appBar: new AppBar(
          leading: _isSearching ? const BackButton() : null,
          title: _isSearching ? _buildSearchField() : _buildTitle(context),
          actions: _buildActions(),
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator())
            : Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: Wrap(
                            spacing: 6.0,
                            runSpacing: 6.0,
                            children: _selectedusernames
                                .map((item) =>
                                    _buildChip(item, Color(0xffff6666)))
                                .toList()
                                .cast<Widget>()),
                      )),
                  Divider(thickness: 1.0),
                  SizedBox(
                    height: 200.0,
                    child: ListView.builder(
                      itemCount: _usernames.length,
                      itemBuilder: (context, index) {
                        return Container(
                          color: _selectedusernames.contains(_usernames[index])
                              ? Colors.grey
                              : Colors.white,
                          child: ListTile(
                            title: Text('${_usernames[index]}'),
                            onLongPress: () {
                              setState(() {
                                if (!_selectedusernames
                                    .contains(_usernames[index])) {
                                  _selectedusernames.add(_usernames[index]);
                                }
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ));
  }
}

/////// Have to put the below code somewhere

// _isLoading = true;
