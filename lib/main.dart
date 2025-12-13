import 'package:flutter/material.dart';
import 'package:midterm/widgets/pie_chart_widget.dart'; // 動畫圓餅圖
import 'package:midterm/widgets/add_page.dart'; // 新增項目頁面
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

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
  List<Map<String, dynamic>> transactions = [
    {"title": "早餐", "amount": 80, "type": "支出","date": "2025-12-13T01:01:59.493251",},
    {"title": "午餐", "amount": 120, "type": "支出","date": "2025-12-12T01:01:59.493251",},
    {"title": "薪水", "amount": 300, "type": "收入","date": "2025-12-11T01:01:59.493251",},
    {"title": "交通", "amount": 60, "type": "支出","date": "2025-12-10T01:01:59.493251",},
    {"title": "加班", "amount": 200, "type": "收入","date": "2025-12-09T01:01:59.493251",},
  ];
  double income = 0;
  double outlay = 0;

  Future<void> saveTransactions() async {
    final prefs = await SharedPreferences.getInstance();

    List<String> jsonList = transactions.map((t) {
      return jsonEncode(t);
    }).toList();

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
      transactions.sort((a, b) =>
          DateTime.parse(b["date"]).compareTo(DateTime.parse(a["date"])));
    } // ⭐ 否則保留原本程式碼裡的 transactions 預設值
  }

  @override
  void initState() {
    super.initState();
    income = 0;
    outlay = 0;

    loadTransactions().then((_) {
      // 讀取完成後 → 計算總和
      income = transactions
          .where((t) => t["type"] == "收入")
          .fold(0, (sum, t) => sum + t["amount"]);

      outlay = transactions
          .where((t) => t["type"] == "支出")
          .fold(0, (sum, t) => sum + t["amount"]);
      saveTransactions();

      // 等第一幀後啟動動畫
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {});
      });
    });
  }

  // 排序
  void sortTransactions() {
    transactions.sort((a, b) =>
        DateTime.parse(b["date"]).compareTo(DateTime.parse(a["date"])));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("收支總覽"),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () async {
          final newItem = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddTransactionPage()),
          );

          if (newItem != null) {
            setState(() {
              transactions.add({
                "title": newItem["title"],
                "amount": newItem["amount"],
                "type": newItem["type"],
                "date": newItem["date"],
              });

              if (newItem["type"] == "收入") {
                income += newItem["amount"];
              } else {
                outlay += newItem["amount"];
              }
              sortTransactions();
            });
            saveTransactions();
          }
        },
      ),
      body: Column(
        children: [
          // 圓餅圖固定在上方
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.transparent,
            child: PieChartWidget(
              income: income,
              outlay: outlay,
              colors: [
                Color(0xFF2563EB), // 收入：青藍（中亮）
                Color(0xFF93C5FD), // 支出：淡藍灰（柔和）
              ],
              size: 250,
            )
            ,
          ),

          // 可滾動 List
          Expanded(
            child: ListView.builder(
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final item = transactions[index];
                final String dateString = item["date"].toString();
                final DateTime date = DateTime.parse(dateString);

                return Dismissible(
                  key: Key(item["date"]),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.only(right: 20),
                    child: Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (direction) {
                    final removed = transactions.removeAt(index);
                    setState(() {
                      // 更新收入/支出
                      if (removed["type"] == "收入") {
                        income -= removed["amount"];
                      } else {
                        outlay -= removed["amount"];
                      }
                      // 再排序
                      sortTransactions();
                    });
                    saveTransactions();
                  },

                  child: Card(
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    elevation: 3,
                    child: ListTile(
                      onTap: () async {
                        final updatedItem = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddTransactionPage(
                              isEdit: true,
                              originalTitle: item["title"],
                              originalAmount: item["amount"],
                              originalType: item["type"],
                              originalDate: DateTime.parse(item["date"]),
                            ),
                          ),
                        );

                        if (updatedItem != null) {
                          setState(() {
                            if (item["type"] == "收入") {
                              income -= item["amount"];
                            } else {
                              outlay -= item["amount"];
                            }

                            transactions[index] = {
                              "title": updatedItem["title"],
                              "amount": updatedItem["amount"],
                              "type": updatedItem["type"],
                              "date": updatedItem["date"], // ⭐ 保留原時間
                            };
                            if (updatedItem["type"] == "收入") {
                              income += updatedItem["amount"];
                            } else {
                              outlay += updatedItem["amount"];
                            }
                            sortTransactions();
                          });

                          saveTransactions();
                        }
                      },
                      leading: Icon(
                        item["type"] == "收入" ? Icons.arrow_upward : Icons.arrow_downward,
                        color: item["type"] == "收入" ? Color(0xFF007FFF) : Color(0xFFD35400),
                      ),
                      title: Text(item["title"]),
                      subtitle: Text(
                        "${date.year}/"
                        "${date.month.toString().padLeft(2, '0')}/"
                        "${date.day.toString().padLeft(2, '0')}",
                        style: TextStyle(color: Colors.grey),
                      ),
                      trailing: Text(
                        "${item["amount"]} 元",
                        style: TextStyle(
                          color: item["type"] == "收入" ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}