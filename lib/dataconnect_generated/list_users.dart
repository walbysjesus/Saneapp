import 'dart:convert';
import 'package:meta/meta.dart';

// Stub classes and methods for generated types
class FirebaseDataConnect {
  QueryRef<T, V> query<T, V>(String name, Deserializer<T> deserializer, Serializer<V> serializer, V vars) {
    // Stub implementation
    throw UnimplementedError();
  }
}
typedef Deserializer<T> = T Function(dynamic json);
typedef Serializer<V> = String Function(V vars);
class QueryRef<T, V> {
  Future<QueryResult<T, V>> execute() => throw UnimplementedError();
}
class QueryResult<T, V> {}
String emptySerializer(void _) => '';
T nativeFromJson<T>(dynamic json) => json as T;
dynamic nativeToJson<T>(T value) => value;

class ListUsersVariablesBuilder {
  
  final FirebaseDataConnect _dataConnect;
  ListUsersVariablesBuilder(this._dataConnect, );
  Deserializer<ListUsersData> dataDeserializer = (dynamic json)  => ListUsersData.fromJson(jsonDecode(json));
  
  Future<QueryResult<ListUsersData, void>> execute() {
    return ref().execute();
  }

  QueryRef<ListUsersData, void> ref() {
    
    return _dataConnect.query("ListUsers", dataDeserializer, emptySerializer, null);
  }
}

@immutable
class ListUsersUsers {
  final String id;
  final String username;
  ListUsersUsers.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  username = nativeFromJson<String>(json['username']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListUsersUsers otherTyped = other as ListUsersUsers;
    return id == otherTyped.id && 
    username == otherTyped.username;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, username.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['username'] = nativeToJson<String>(username);
    return json;
  }

  const ListUsersUsers({
    required this.id,
    required this.username,
  });
}

@immutable
class ListUsersData {
  final List<ListUsersUsers> users;
  ListUsersData.fromJson(dynamic json):
  
  users = (json['users'] as List<dynamic>)
        .map((e) => ListUsersUsers.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListUsersData otherTyped = other as ListUsersData;
    return users == otherTyped.users;
    
  }
  @override
  int get hashCode => users.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['users'] = users.map((e) => e.toJson()).toList();
    return json;
  }

  const ListUsersData({
    required this.users,
  });
}

