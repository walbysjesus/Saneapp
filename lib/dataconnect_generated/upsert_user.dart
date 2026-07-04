// ...existing code...
import 'dart:convert';
import 'package:flutter/foundation.dart';
// Stubs for missing types
class FirebaseDataConnect {
  MutationRef<T, V> mutation<T, V>(String name, Deserializer<T> deserializer, Serializer<V> serializer, V vars) {
    return MutationRef<T, V>();
  }
}
typedef Deserializer<T> = T Function(dynamic json);
typedef Serializer<T> = dynamic Function(T value);
class MutationRef<T, V> {
  Future<OperationResult<T, V>> execute() async => OperationResult<T, V>();
}
class OperationResult<T, V> {}
T nativeFromJson<T>(dynamic json) => json as T;
dynamic nativeToJson<T>(T value) => value;
// ...existing code...

class UpsertUserVariablesBuilder {
  String username;
  final FirebaseDataConnect _dataConnect;
  UpsertUserVariablesBuilder(this._dataConnect, {required this.username});
  Deserializer<UpsertUserData> dataDeserializer = (dynamic json) => UpsertUserData.fromJson(jsonDecode(json));
  Serializer<UpsertUserVariables> varsSerializer = (UpsertUserVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<UpsertUserData, UpsertUserVariables>> execute() {
    return ref().execute();
  }
  MutationRef<UpsertUserData, UpsertUserVariables> ref() {
    UpsertUserVariables vars = UpsertUserVariables(username: username);
    return _dataConnect.mutation("UpsertUser", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class UpsertUserUserUpsert {
  final String id;
  UpsertUserUserUpsert.fromJson(dynamic json)
      : id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    final UpsertUserUserUpsert otherTyped = other as UpsertUserUserUpsert;
    return id == otherTyped.id;
  }
  @override
  int get hashCode => id.hashCode;
  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }
  const UpsertUserUserUpsert({
    required this.id,
  });
}

@immutable
class UpsertUserData {
  final UpsertUserUserUpsert userUpsert;
  UpsertUserData.fromJson(dynamic json)
      : userUpsert = UpsertUserUserUpsert.fromJson(json['user_upsert']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    final UpsertUserData otherTyped = other as UpsertUserData;
    return userUpsert == otherTyped.userUpsert;
  }
  @override
  int get hashCode => userUpsert.hashCode;
  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['user_upsert'] = userUpsert.toJson();
    return json;
  }
  const UpsertUserData({
    required this.userUpsert,
  });
}

@immutable
class UpsertUserVariables {
  final String username;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  UpsertUserVariables.fromJson(Map<String, dynamic> json)
      : username = nativeFromJson<String>(json['username']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    final UpsertUserVariables otherTyped = other as UpsertUserVariables;
    return username == otherTyped.username;
  }
  @override
  int get hashCode => username.hashCode;
  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['username'] = nativeToJson<String>(username);
    return json;
  }
  const UpsertUserVariables({
    required this.username,
  });
}

