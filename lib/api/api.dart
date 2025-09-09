// import 'dart:convert';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class CallApi {
  final _urlAuth = '';
  final _urlwithoutAuth = 'https://dl.dropboxusercontent.com/s/6nt7fkdt7ck0lue/';

  getAllData(apiUrl) async {
    var fullUrl = Uri.parse(_urlwithoutAuth + apiUrl);
    return await http.get(
      fullUrl,
      headers: _setHeaders(),
    );
  }

 
 

  _setHeaders() => {
        'Content-type': 'application/json',
        'Accept': 'application/json',
        // 'Authorization': 'Bearer $token'
      };
}

