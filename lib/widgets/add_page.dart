import 'package:flutter/material.dart';

class AddTransactionPage extends StatefulWidget {
  final bool isEdit;
  final String? originalTitle;
  final double? originalAmount;
  final String? originalType;

  AddTransactionPage({
    this.isEdit = false,
    this.originalTitle,
    this.originalAmount,
    this.originalType,
  });

  @override
  _AddTransactionPageState createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  String expression = "";
  double result = 0;
  String type = "支出";
  TextEditingController titleController = TextEditingController();
  TextEditingController amountController = TextEditingController();

  // 按鍵輸入
  void input(String value) {
    setState(() {
      // 如果 expression 是空且按的是運算符號，就自動加 0 開頭
      if (expression.isEmpty && "+-×÷".contains(value)) {
        expression = "0";
      }

      expression += value;
      _recalculate();
    });
  }

  // 清除
  void clear() {
    setState(() {
      expression = "";
      result = 0;
    });
  }

  // 簡單四則運算計算（依序從左到右，不處理括號）
  void _recalculate() {
    if (expression.isEmpty) {
      result = 0;
      return;
    }

    try {
      String exp = expression.replaceAll("×", "*").replaceAll("÷", "/");

      // 如果開頭是運算符號，補 0
      if ("+-*/".contains(exp[0])) exp = "0$exp";

      List<String> tokens = [];
      String number = "";

      for (int i = 0; i < exp.length; i++) {
        String ch = exp[i];
        if ("+-*/".contains(ch)) {
          if (number.isNotEmpty) tokens.add(number);
          tokens.add(ch);
          number = "";
        } else {
          number += ch;
        }
      }
      if (number.isNotEmpty) tokens.add(number);

      // 從左到右計算
      double temp = double.parse(tokens[0]);
      for (int i = 1; i < tokens.length; i += 2) {
        String op = tokens[i];
        double next = double.parse(tokens[i + 1]);
        if (op == "+") temp += next;
        if (op == "-") temp -= next;
        if (op == "*") temp *= next;
        if (op == "/") temp /= next;
      }

      result = temp;
    } catch (e) {
      // 不出錯時保留之前 result
    }
  }

  // ＝ 回傳資料並關閉頁面
  void submit() {
    // 如果使用者沒輸入項目名稱，自動依 type 填入
    if (titleController.text.isEmpty) {
      titleController.text = type;
    }

    // 如果結果 <= 0，不阻止返回，但給一個提示
    if (result <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("金額必須大於 0")),
      );
      return;
    }

    // 編輯模式 / 新增模式都回傳資料
    Navigator.pop(context, {
      "title": titleController.text,
      "amount": result,
      "type": type,
    });
  }

  Widget numberButton(String text, {Color? color}) {
    return Expanded(
      child: InkWell(
        onTap: () => input(text),
        child: Container(
          height: 70,
          margin: EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color ?? Colors.grey.shade200,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  Widget actionButton(String text, VoidCallback onTap, {Color? color}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 70,
          margin: EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color ?? Colors.orange.shade200,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    if (widget.isEdit) {
      titleController.text = widget.originalTitle!;
      result = widget.originalAmount!;
      type = widget.originalType!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("新增記帳項目")),
      body: Column(
        children: [
          // 顯示式子
          Container(
            alignment: Alignment.centerRight,
            padding: EdgeInsets.all(20),
            child: Text(
              expression,
              style: TextStyle(fontSize: 30),
            ),
          ),

          // 即時計算結果
          Container(
            alignment: Alignment.centerRight,
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              "＝ $result",
              style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
            ),
          ),

          SizedBox(height: 10),

          // 收入 / 支出
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ChoiceChip(
                label: Text("收入"),
                selected: type == "收入",
                onSelected: (_) => setState(() => type = "收入"),
              ),
              SizedBox(width: 10),
              ChoiceChip(
                label: Text("支出"),
                selected: type == "支出",
                onSelected: (_) => setState(() => type = "支出"),
              ),
            ],
          ),

          Padding(
            padding: EdgeInsets.all(12),
            child: TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: "項目名稱",
                border: OutlineInputBorder(),
              ),
            ),
          ),

          // 數字鍵盤
          Expanded(
            child: Column(
              children: [
                Row(children: [
                  numberButton("1"),
                  numberButton("2"),
                  numberButton("3"),
                  actionButton("C", clear, color: Colors.red.shade200),
                ]),
                Row(children: [
                  numberButton("4"),
                  numberButton("5"),
                  numberButton("6"),
                  numberButton("+", color: Colors.orange.shade100),
                ]),
                Row(children: [
                  numberButton("7"),
                  numberButton("8"),
                  numberButton("9"),
                  numberButton("-", color: Colors.orange.shade100),
                ]),
                Row(children: [
                  numberButton("×", color: Colors.orange.shade100),
                  numberButton("0"),
                  numberButton("÷", color: Colors.orange.shade100),
                  actionButton("=", submit, color: Colors.green.shade200),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}