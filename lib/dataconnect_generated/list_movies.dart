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

class ListMoviesVariablesBuilder {
  
  final FirebaseDataConnect _dataConnect;
  ListMoviesVariablesBuilder(this._dataConnect, );
  Deserializer<ListMoviesData> dataDeserializer = (dynamic json)  => ListMoviesData.fromJson(jsonDecode(json));
  
  Future<QueryResult<ListMoviesData, void>> execute() {
    return ref().execute();
  }

  QueryRef<ListMoviesData, void> ref() {
    
    return _dataConnect.query("ListMovies", dataDeserializer, emptySerializer, null);
  }
}

@immutable
class ListMoviesMovies {
  final String id;
  final String title;
  final String imageUrl;
  final String? genre;
  ListMoviesMovies.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  title = nativeFromJson<String>(json['title']),
  imageUrl = nativeFromJson<String>(json['imageUrl']),
  genre = json['genre'] == null ? null : nativeFromJson<String>(json['genre']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListMoviesMovies otherTyped = other as ListMoviesMovies;
    return id == otherTyped.id && 
    title == otherTyped.title && 
    imageUrl == otherTyped.imageUrl && 
    genre == otherTyped.genre;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, title.hashCode, imageUrl.hashCode, genre.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['title'] = nativeToJson<String>(title);
    json['imageUrl'] = nativeToJson<String>(imageUrl);
    if (genre != null) {
      json['genre'] = nativeToJson<String?>(genre);
    }
    return json;
  }

  const ListMoviesMovies({
    required this.id,
    required this.title,
    required this.imageUrl,
    this.genre,
  });
}

@immutable
class ListMoviesData {
  final List<ListMoviesMovies> movies;
  ListMoviesData.fromJson(dynamic json):
  
  movies = (json['movies'] as List<dynamic>)
        .map((e) => ListMoviesMovies.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListMoviesData otherTyped = other as ListMoviesData;
    return movies == otherTyped.movies;
    
  }
  @override
  int get hashCode => movies.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['movies'] = movies.map((e) => e.toJson()).toList();
    return json;
  }

  const ListMoviesData({
    required this.movies,
  });
}

