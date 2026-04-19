import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

enum StatusType { success, error, info, warning }

class AppStatusHandler {
  static void showStatusToast({
    required String message,
    required StatusType type,
    ToastGravity gravity = ToastGravity.BOTTOM,
  }) {
    Color backgroundColor;
    switch (type) {
      case StatusType.success:
        backgroundColor = Colors.green;
        break;
      case StatusType.error:
        backgroundColor = Colors.red;
        break;
      case StatusType.warning:
        backgroundColor = Colors.orange;
        break;
      case StatusType.info:
        backgroundColor = Colors.black;
        break;
    }

    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: gravity,
      backgroundColor: backgroundColor,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }
}
