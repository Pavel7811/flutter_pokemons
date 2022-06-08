import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:rflutter_alert/rflutter_alert.dart';
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PokeFlApp',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'PokeApp'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class PokemonResponse {
  final int count;
  final List results;

  PokemonResponse({required this.count, required this.results});

  factory PokemonResponse.fromJson(Map<String, dynamic> json) {
    return PokemonResponse(count: json['count'], results: json['results']);
  }
}

class Pokemon {
  String? name;
  String? id;
}

class PokemonUpdated {
  String name;
  int index;

  PokemonUpdated({required this.name, required this.index});
}

class _MyHomePageState extends State<MyHomePage> {
  final number = TextEditingController();

  //Список покемонов
  List pokemons = [];

  //Список из 6 покемонов
  List pokemonsBy = [];

  //На сколько увеличивать подгрузку (подгружаются 6 покемонов)
  int numberOfAdded = 6;
  int numberOfAdd = 6;

  //Сколько покемонов будет использоваться для отображения
  int numberOfPokemons = 600;

  //Функция получения списка покемонов
  getPokemons() async {
    //Обращение к API
    var resp = await http.get(Uri.encodeFull(
        "https://pokeapi.co/api/v2/pokemon?limit=$numberOfPokemons"));
    //Декодирование из json в List result и получение count числа
    PokemonResponse temporary =
    PokemonResponse.fromJson(json.decode(resp.body));
    setState(() {
      pokemons = temporary.results.sublist(0);
    });
    //Список покемонов
    pokemons = temporary.results;
    //Присваиваем каждому покемону порядковый номер URL
    //для дальнейшего отображения изображений
    for (int i = 0; i < numberOfPokemons; i++) {
      pokemons[i]['url'] = (i + 1).toString();
    }
    //Создаем список из 6 покемонов
    pokemonsBy = temporary.results.sublist(0, 6);
  }

  @override
  void dispose() {
    number.dispose();
    super.dispose();
  }

  //Загрузка покемонов при запуске
  @override
  void initState() {
    number.text = "6";
    getPokemons();
    super.initState();
  }

  //Функция расширения списка покемонов
  void expandList() {
    numberOfAdd = int.parse(number.text);
    if (numberOfAdded + numberOfAdd < pokemons.length) {
      //Добавляем в список с 6 покемонами еще 6 других
      pokemonsBy
          .addAll(pokemons.sublist(numberOfAdded, numberOfAdded + numberOfAdd));
      //Изменяем подгружаемое кол-во покемонов, чтобы подгрузить следующую партию
      setState(() {
        numberOfAdded = numberOfAdded + numberOfAdd;
      });
    }
  }

  //Отображаем:
  @override
  Widget build(BuildContext context) {
    _openSettings(context) {
      Alert(
          context: context,
          title: "Настройки пагинации",
          content: Column(
            children: <Widget>[
              TextField(
                controller: number,
                decoration: const InputDecoration(
                  labelText: 'Кол-во подгружаемых элементов:',
                ),
              ),
            ],
          ),
          buttons: [
            DialogButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Применить",
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            )
          ]).show();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Покемоны"),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              _openSettings(context);
            },
          ),
        ],
      ),
      body: Center(
          //Заружаем виджет
          child: getList()),
    );
  }

  Widget getList() {
    //Если покемоны грузятся
    if (pokemons.isEmpty) {
      return const Center(
        child: Text("Пожалуйста подождите..."),
      );
    }
    //Используем NotificationListener для получения положения прокурутки
    return NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification scrollInfo) {
          //Если скролл подошел к концу и перестали скроллить и покемоны не закончились
          if (kDebugMode) {
            print(scrollInfo.metrics.extentAfter);
          }
          if (scrollInfo is ScrollEndNotification &&
              scrollInfo.metrics.extentAfter == 0 &&
              pokemonsBy.length < numberOfPokemons) {
            //Расширяем список покемонов

            expandList();

            return true;
          }
          return false;
        },
        child: ListView.separated(
            itemBuilder: (BuildContext context, int index) {
              return getListItem(index);
            },
            separatorBuilder: (context, index) {
              return const Divider();
            },
            itemCount: pokemonsBy.length));
  }

  Widget getListItem(int i) {
    return Container(
      margin: const EdgeInsets.all(4.0),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Row(
          children: [
            Image.network(
              "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/${pokemonsBy[i]['url']}.png",
              width: 200.0,
              height: 100.0,
            ),
            Expanded(
                child: Text(
              "${pokemonsBy[i]['url']} ${pokemonsBy[i]['name']}",
              style: const TextStyle(fontSize: 18),
            ))
          ],
        ),
      ),
    );
  }
}
