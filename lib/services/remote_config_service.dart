import 'dart:convert';
import 'package:firebase_remote_config/firebase_remote_config.dart';

class RemoteConfigService {
  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

  Future<void> initialize() async {
    await _remoteConfig.setDefaults({
      'tips_json': '[]',
      'articles_json': '[]',
    });
    await _remoteConfig.fetchAndActivate();
  }

  List<Map<String, dynamic>> getTips() {
    final jsonString = _remoteConfig.getString('tips_json');
    return List<Map<String, dynamic>>.from(jsonDecode(jsonString));
  }

  List<Map<String, dynamic>> getArticles() {
    final jsonString = _remoteConfig.getString('articles_json');
    return List<Map<String, dynamic>>.from(jsonDecode(jsonString));
  }
}
