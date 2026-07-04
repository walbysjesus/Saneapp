import 'dart:convert';
import 'package:flutter/foundation.dart';

typedef Deserializer<T> = T Function(dynamic json);
typedef Serializer<T> = String Function(T value);

class FirebaseDataConnect {
  MutationRef<T, V> mutation<T, V>(String name, Deserializer<T> deserializer, Serializer<V> serializer, V vars) {
    return MutationRef<T, V>();
  }
}

class MutationRef<T, V> {
  Future<OperationResult<T, V>> execute() async {
    return OperationResult<T, V>();
  }
}

class OperationResult<T, V> {}

T nativeFromJson<T>(dynamic value) {
  return value as T;
}

dynamic nativeToJson<T>(T value) {
  return value;
}

class CreateMovieVariablesBuilder {
  String title;
  String genre;
  String imageUrl;

  final FirebaseDataConnect _dataConnect;
  CreateMovieVariablesBuilder(this._dataConnect, {required  this.title,required  this.genre,required  this.imageUrl,});
  Deserializer<CreateMovieData> dataDeserializer = (dynamic json)  => CreateMovieData.fromJson(jsonDecode(json));
  Serializer<CreateMovieVariables> varsSerializer = (CreateMovieVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<CreateMovieData, CreateMovieVariables>> execute() {
    return ref().execute();
  }

  MutationRef<CreateMovieData, CreateMovieVariables> ref() {
    CreateMovieVariables vars= CreateMovieVariables(title: title,genre: genre,imageUrl: imageUrl,);
    return _dataConnect.mutation("CreateMovie", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class CreateMovieMovieInsert {
  final String id;
  CreateMovieMovieInsert.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateMovieMovieInsert otherTyped = other as CreateMovieMovieInsert;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  const CreateMovieMovieInsert({
    required this.id,
  });
}

@immutable
class CreateMovieData {
  final CreateMovieMovieInsert movie_insert;
  CreateMovieData.fromJson(dynamic json):
  
  movie_insert = CreateMovieMovieInsert.fromJson(json['movie_insert']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateMovieData otherTyped = other as CreateMovieData;
    return movie_insert == otherTyped.movie_insert;
    
  }
  @override
  int get hashCode => movie_insert.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['movie_insert'] = movie_insert.toJson();
    return json;
  }

  const CreateMovieData({
    required this.movie_insert,
  });
}

@immutable
class CreateMovieVariables {
  final String title;
  final String genre;
  final String imageUrl;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  CreateMovieVariables.fromJson(Map<String, dynamic> json):
  
  title = nativeFromJson<String>(json['title']),
  genre = nativeFromJson<String>(json['genre']),
  imageUrl = nativeFromJson<String>(json['imageUrl']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateMovieVariables otherTyped = other as CreateMovieVariables;
    return title == otherTyped.title && 
    genre == otherTyped.genre && 
    imageUrl == otherTyped.imageUrl;
    
  }
  @override
  int get hashCode => Object.hashAll([title.hashCode, genre.hashCode, imageUrl.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['title'] = nativeToJson<String>(title);
    json['genre'] = nativeToJson<String>(genre);
    json['imageUrl'] = nativeToJson<String>(imageUrl);
    return json;
  }

  const CreateMovieVariables({
    required this.title,
    required this.genre,
    required this.imageUrl,
  });
}

