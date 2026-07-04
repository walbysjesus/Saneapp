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
T nativeFromJson<T>(dynamic json) => json as T;
dynamic nativeToJson<T>(T value) => value;

class GetMovieByIdVariablesBuilder {
  String id;

  final FirebaseDataConnect _dataConnect;
  GetMovieByIdVariablesBuilder(this._dataConnect, {required  this.id,});
  Deserializer<GetMovieByIdData> dataDeserializer = (dynamic json)  => GetMovieByIdData.fromJson(jsonDecode(json));
  Serializer<GetMovieByIdVariables> varsSerializer = (GetMovieByIdVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<GetMovieByIdData, GetMovieByIdVariables>> execute() {
    return ref().execute();
  }

  QueryRef<GetMovieByIdData, GetMovieByIdVariables> ref() {
    GetMovieByIdVariables vars= GetMovieByIdVariables(id: id,);
    return _dataConnect.query("GetMovieById", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class GetMovieByIdMovie {
  final String id;
  final String title;
  final String genre;
  final String imageUrl;
  final GetMovieByIdMovieMetadata? metadata;
  final List<GetMovieByIdMovieReviews>? reviews;
  GetMovieByIdMovie.fromJson(dynamic json)
      : id = nativeFromJson<String>(json['id']),
        title = nativeFromJson<String>(json['title']),
        genre = nativeFromJson<String>(json['genre']),
        imageUrl = nativeFromJson<String>(json['imageUrl']),
        metadata = json['metadata'] == null ? null : GetMovieByIdMovieMetadata.fromJson(json['metadata']),
        reviews = json['reviews'] == null ? null : (json['reviews'] as List).map((e) => GetMovieByIdMovieReviews.fromJson(e)).toList();
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    final GetMovieByIdMovie otherTyped = other as GetMovieByIdMovie;
    return id == otherTyped.id && title == otherTyped.title && genre == otherTyped.genre && imageUrl == otherTyped.imageUrl && metadata == otherTyped.metadata && reviews == otherTyped.reviews;
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, title.hashCode, genre.hashCode, imageUrl.hashCode, metadata.hashCode, reviews.hashCode]);
  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['title'] = nativeToJson<String>(title);
    json['genre'] = nativeToJson<String>(genre);
    json['imageUrl'] = nativeToJson<String>(imageUrl);
    if (metadata != null) json['metadata'] = metadata!.toJson();
    if (reviews != null) json['reviews'] = reviews!.map((e) => e.toJson()).toList();
    return json;
  }
  const GetMovieByIdMovie({
    required this.id,
    required this.title,
    required this.genre,
    required this.imageUrl,
    this.metadata,
    this.reviews,
  });
}

@immutable
class GetMovieByIdMovieMetadata {
  final double? rating;
  final int? releaseYear;
  final String? description;
  GetMovieByIdMovieMetadata.fromJson(dynamic json):
  
  rating = json['rating'] == null ? null : nativeFromJson<double>(json['rating']),
  releaseYear = json['releaseYear'] == null ? null : nativeFromJson<int>(json['releaseYear']),
  description = json['description'] == null ? null : nativeFromJson<String>(json['description']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetMovieByIdMovieMetadata otherTyped = other as GetMovieByIdMovieMetadata;
    return rating == otherTyped.rating && 
    releaseYear == otherTyped.releaseYear && 
    description == otherTyped.description;
    
  }
  @override
  int get hashCode => Object.hashAll([rating.hashCode, releaseYear.hashCode, description.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (rating != null) {
      json['rating'] = nativeToJson<double?>(rating);
    }
    if (releaseYear != null) {
      json['releaseYear'] = nativeToJson<int?>(releaseYear);
    }
    if (description != null) {
      json['description'] = nativeToJson<String?>(description);
    }
    return json;
  }

  const GetMovieByIdMovieMetadata({
    this.rating,
    this.releaseYear,
    this.description,
  });
}

@immutable
class GetMovieByIdMovieReviews {
  final String? reviewText;
  final DateTime reviewDate;
  final int? rating;
  final GetMovieByIdMovieReviewsUser user;
  GetMovieByIdMovieReviews.fromJson(dynamic json):
  
  reviewText = json['reviewText'] == null ? null : nativeFromJson<String>(json['reviewText']),
  reviewDate = nativeFromJson<DateTime>(json['reviewDate']),
  rating = json['rating'] == null ? null : nativeFromJson<int>(json['rating']),
  user = GetMovieByIdMovieReviewsUser.fromJson(json['user']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetMovieByIdMovieReviews otherTyped = other as GetMovieByIdMovieReviews;
    return reviewText == otherTyped.reviewText && 
    reviewDate == otherTyped.reviewDate && 
    rating == otherTyped.rating && 
    user == otherTyped.user;
    
  }
  @override
  int get hashCode => Object.hashAll([reviewText.hashCode, reviewDate.hashCode, rating.hashCode, user.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (reviewText != null) {
      json['reviewText'] = nativeToJson<String?>(reviewText);
    }
    json['reviewDate'] = nativeToJson<DateTime>(reviewDate);
    if (rating != null) {
      json['rating'] = nativeToJson<int?>(rating);
    }
    json['user'] = user.toJson();
    return json;
  }

  const GetMovieByIdMovieReviews({
    this.reviewText,
    required this.reviewDate,
    this.rating,
    required this.user,
  });
}

@immutable
class GetMovieByIdMovieReviewsUser {
  final String id;
  final String username;
  GetMovieByIdMovieReviewsUser.fromJson(dynamic json):
  
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

    final GetMovieByIdMovieReviewsUser otherTyped = other as GetMovieByIdMovieReviewsUser;
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

  const GetMovieByIdMovieReviewsUser({
    required this.id,
    required this.username,
  });
}

@immutable
class GetMovieByIdData {
  final GetMovieByIdMovie? movie;
  GetMovieByIdData.fromJson(dynamic json):
  
  movie = json['movie'] == null ? null : GetMovieByIdMovie.fromJson(json['movie']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetMovieByIdData otherTyped = other as GetMovieByIdData;
    return movie == otherTyped.movie;
    
  }
  @override
  int get hashCode => movie.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (movie != null) {
      json['movie'] = movie!.toJson();
    }
    return json;
  }

  const GetMovieByIdData({
    this.movie,
  });
}

@immutable
class GetMovieByIdVariables {
  final String id;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  GetMovieByIdVariables.fromJson(Map<String, dynamic> json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetMovieByIdVariables otherTyped = other as GetMovieByIdVariables;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  const GetMovieByIdVariables({
    required this.id,
  });
}

