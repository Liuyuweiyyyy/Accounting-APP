import 'package:flutter/material.dart';
import 'package:midterm/widgets/pie_chart_widget.dart'; // 動畫圓餅圖
import 'package:midterm/widgets/add_page.dart'; // 新增項目頁面
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart'; // 用來生成唯一 id
import 'package:month_picker_dialog/month_picker_dialog.dart';

void main() {
  runApp(MaterialApp(
    home: ExpensePage(),
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      primaryColor: Color(0xFFFFD93D),
      scaffoldBackgroundColor: Color(0xFFFFF7F0),

      appBarTheme: AppBarTheme(
        backgroundColor: Color(0xFFFFD93D),
        foregroundColor: Colors.white,
        elevation: 3,
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: Color(0xFFFFD93D),
        foregroundColor: Colors.white,
      ),

      cardTheme: CardThemeData(
        color: Colors.white,
        shadowColor: Colors.black26,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      listTileTheme: ListTileThemeData(
        titleTextStyle: TextStyle(
          color: Colors.black87,
          fontSize: 16,
        ),
      ),
    ),
  ));
}

class ExpensePage extends StatefulWidget {
  @override
  _ExpensePageState createState() => _ExpensePageState();
}

class _ExpensePageState extends State<ExpensePage> {
  DateTime selectedMonth = DateTime( // 當前月份
    DateTime.now().year,
    DateTime.now().month,
  );
  List<Map<String, dynamic>> transactions = [
    {"id": Uuid().v4(),"title": "早餐", "amount": 80, "type": "支出","date": "2025-12-13T01:01:59.493251",},
    {"id": Uuid().v4(),"title": "午餐", "amount": 120, "type": "支出","date": "2025-12-13T01:02:59.493251",},
    {"id": Uuid().v4(),"title": "薪水", "amount": 300, "type": "收入","date": "2025-12-11T01:01:59.493251",},
    {"id": Uuid().v4(),"title": "交通", "amount": 60, "type": "支出","date": "2025-12-10T01:01:59.493251",},
    {"id": Uuid().v4(),"title": "加班", "amount": 200, "type": "收入","date": "2025-12-09T01:01:59.493251",},
    {"id": Uuid().v4(),"title": "蹺班", "amount": 50, "type": "支出","date": "2026-01-09T01:01:59.493251",},
    {"id": Uuid().v4(),"title": "加班", "amount": 200, "type": "收入","date": "2025-11-21T01:01:59.493251",},
    {"id": Uuid().v4(),"title": "加班", "amount": 200, "type": "收入","date": "2025-11-09T01:01:59.493251",},
  ];
  double income = 0;
  double outlay = 0;

  Future<void> saveTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> jsonList = transactions.map((t) => jsonEncode(t)).toList();
    await prefs.setStringList('transactions', jsonList);
  }


  Future<void> loadTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? jsonList = prefs.getStringList('transactions');

    if (jsonList != null && jsonList.isNotEmpty) {
      transactions = jsonList
          .map((t) => jsonDecode(t) as Map<String, dynamic>)
          .toList();
      // ⭐ 依時間排序，最新的在最前面
      sortTransactions();
    } // ⭐ 否則保留原本程式碼裡的 transactions 預設值
  }

  Future<void> pickMonth() async {
    final selected = await showMonthPicker(
      context: context,
      initialDate: selectedMonth,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (selected != null) {
      setState(() {
        selectedMonth = DateTime(selected.year, selected.month);
        recalcMonthSummary();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    income = 0;
    outlay = 0;

    loadTransactions().then((_) {
      // 讀取完成後 → 計算總和
      recalcMonthSummary();
      saveTransactions();
      // 等第一幀後啟動動畫
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {});
      });
    });
  }

  // 排序
  void sortTransactions() {
    transactions.sort((a, b) {
      DateTime dateTimeA = DateTime.parse(a["date"]);
      DateTime dateTimeB = DateTime.parse(b["date"]);

      // 比較日期（年/月/日）
      DateTime dayA = DateTime(dateTimeA.year, dateTimeA.month, dateTimeA.day);
      DateTime dayB = DateTime(dateTimeB.year, dateTimeB.month, dateTimeB.day);

      int cmpDay = dayB.compareTo(dayA); // 日期晚 → 早
      if (cmpDay != 0) return cmpDay;

      // 同一天就比較時間（早 → 晚）
      return dateTimeA.compareTo(dateTimeB);
    });
  }


  // 日期
  String formatDate(DateTime date) {
    return "${date.year}/"
        "${date.month.toString().padLeft(2, '0')}/"
        "${date.day.toString().padLeft(2, '0')}";
  }

  // 每月總合
  void recalcMonthSummary() {
    income = 0;
    outlay = 0;

    for (var t in transactions) {
      final date = DateTime.parse(t["date"]);
      if (date.year == selectedMonth.year &&
          date.month == selectedMonth.month) {
        if (t["type"] == "收入") {
          income += t["amount"];
        } else {
          outlay += t["amount"];
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> monthlyTransactions = transactions.where((t) {
      final date = DateTime.parse(t["date"]);
      return date.year == selectedMonth.year && date.month == selectedMonth.month;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(Icons.chevron_left),
              onPressed: () {
                setState(() {
                  selectedMonth = DateTime(
                      selectedMonth.year,
                      selectedMonth.month - 1);
                  recalcMonthSummary();
                });
              },
            ),
            GestureDetector(
              onTap: pickMonth, // 點擊文字就彈出月份選擇器
              child: Text("${selectedMonth.year} 年 ${selectedMonth.month} 月"),
            ),            IconButton(
              icon: Icon(Icons.chevron_right),
              onPressed: () {
                setState(() {
                  selectedMonth = DateTime(
                      selectedMonth.year,
                      selectedMonth.month + 1);
                  recalcMonthSummary();
                });
              },
            ),
          ],
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () async {
          final newItem = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddTransactionPage(
              originalDate: DateTime(
                  selectedMonth.year,
                  selectedMonth.month,
                  DateTime.now().day),
            )),
          );

          if (newItem != null) {
            setState(() {
              transactions.add({
                "id": Uuid().v4(),
                "title": newItem["title"],
                "amount": newItem["amount"],
                "type": newItem["type"],
                "date": newItem["date"],
              });
              sortTransactions();
              recalcMonthSummary();
            });
            saveTransactions();
          }
        },
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            child: PieChartWidget(
              income: income,
              outlay: outlay,
              colors: [Color(0xFF2563EB), Color(0xFF93C5FD)],
              size: 250,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: monthlyTransactions.length,
              itemBuilder: (context, index) {
                final item = monthlyTransactions[index];
                final currentDate = DateTime.parse(item["date"]);
                final currentDay = formatDate(currentDate);

                bool showDateHeader = index == 0 ||
                    formatDate(DateTime.parse(monthlyTransactions[index - 1]["date"])) != currentDay;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showDateHeader)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                        child: Text(currentDay, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    Dismissible(
                      key: Key(item["id"]),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: EdgeInsets.only(right: 20),
                        child: Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (direction) {
                        setState(() {
                          if (item["type"] == "收入") income -= item["amount"];
                          else outlay -= item["amount"];
                          transactions.removeWhere((t) => t["id"] == item["id"]);
                          recalcMonthSummary();
                        });
                        saveTransactions();
                      },
                      child: Card(
                        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: ListTile(
                          onTap: () async {
                            final updatedItem = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AddTransactionPage(
                                  isEdit: true,
                                  originalTitle: item["title"],
                                  originalAmount: (item["amount"] as num).toDouble(),
                                  originalType: item["type"],
                                  originalDate: DateTime.parse(item["date"]),
                                ),
                              ),
                            );

                            if (updatedItem != null) {
                              setState(() {
                                final realIndex = transactions.indexWhere((t) => t["id"] == item["id"]);
                                if (realIndex != -1) {
                                  if (transactions[realIndex]["type"] == "收入") income -= transactions[realIndex]["amount"];
                                  else outlay -= transactions[realIndex]["amount"];

                                  transactions[realIndex] = {
                                    "id": item["id"],
                                    "title": updatedItem["title"],
                                    "amount": updatedItem["amount"],
                                    "type": updatedItem["type"],
                                    "date": updatedItem["date"],
                                  };

                                  if (updatedItem["type"] == "收入") income += updatedItem["amount"];
                                  else outlay += updatedItem["amount"];

                                  sortTransactions();
                                  recalcMonthSummary();
                                }
                              });
                              saveTransactions();
                            }
                          },
                          leading: Icon(
                            item["type"] == "收入" ? Icons.arrow_upward : Icons.arrow_downward,
                            color: item["type"] == "收入" ? Colors.green : Colors.red,
                          ),
                          title: Text(item["title"]),
                          trailing: Text("${item["amount"]} 元"),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}