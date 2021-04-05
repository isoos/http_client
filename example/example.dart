import 'dart:async';

import 'package:http_client/console.dart';

Future main() async {
  final client = ConsoleClient();
  final rs = await client.send(Request('GET', 'https://www.example.com/'));
  final textContent = await rs.readAsString();
  print(textContent);
  await client.close();
}
