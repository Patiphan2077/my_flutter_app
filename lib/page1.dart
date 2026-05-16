import 'package:flutter/material.dart';

class Page1 extends StatelessWidget {
  const Page1({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'This is Page 1',
        style: TextStyle(fontSize: 24),
      ),
    );
  }
}
