
import 'dart:convert';
import 'package:flutter/foundation.dart';
// Stubs mínimos para compilar

class FirebaseDataConnect {
  MutationRef<T, V> mutation<T, V>(String name, Deserializer<T> deserializer, Serializer<V> serializer, V vars) {
    return MutationRef<T, V>();
  }
}
typedef Deserializer<T> = T Function(dynamic json);
typedef Serializer<T> = String Function(T value);


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

class AddReviewVariablesBuilder {
  String movieId;
  int rating;
  String reviewText;

  final FirebaseDataConnect _dataConnect;
  AddReviewVariablesBuilder(this._dataConnect, {required  this.movieId,required  this.rating,required  this.reviewText,});
  Deserializer<AddReviewData> dataDeserializer = (dynamic json)  => AddReviewData.fromJson(jsonDecode(json));
  Serializer<AddReviewVariables> varsSerializer = (AddReviewVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<AddReviewData, AddReviewVariables>> execute() {
    return ref().execute();
  }

  MutationRef<AddReviewData, AddReviewVariables> ref() {
    AddReviewVariables vars= AddReviewVariables(movieId: movieId,rating: rating,reviewText: reviewText,);
    return _dataConnect.mutation("AddReview", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class AddReviewReviewUpsert {
  final String userId;
  final String movieId;
  const AddReviewReviewUpsert({
    required this.userId,
    required this.movieId,
  });
  AddReviewReviewUpsert.fromJson(dynamic json)
      : userId = nativeFromJson<String>(json['userId']),
        movieId = nativeFromJson<String>(json['movieId']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    final AddReviewReviewUpsert otherTyped = other as AddReviewReviewUpsert;
    return userId == otherTyped.userId && movieId == otherTyped.movieId;
  }
  @override
  int get hashCode => Object.hashAll([userId.hashCode, movieId.hashCode]);
  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['userId'] = nativeToJson<String>(userId);
    json['movieId'] = nativeToJson<String>(movieId);
    return json;
  }
}

@immutable
class AddReviewData {
  final AddReviewReviewUpsert reviewUpsert;
  const AddReviewData({
    required this.reviewUpsert,
  });
  AddReviewData.fromJson(dynamic json)
      : reviewUpsert = AddReviewReviewUpsert.fromJson(json['review_upsert']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    final AddReviewData otherTyped = other as AddReviewData;
    return reviewUpsert == otherTyped.reviewUpsert;
  }
  @override
  int get hashCode => reviewUpsert.hashCode;
  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['review_upsert'] = reviewUpsert.toJson();
    return json;
  }
}

@immutable
class AddReviewVariables {
  final String movieId;
  final int rating;
  final String reviewText;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  AddReviewVariables.fromJson(Map<String, dynamic> json):
  
  movieId = nativeFromJson<String>(json['movieId']),
  rating = nativeFromJson<int>(json['rating']),
  reviewText = nativeFromJson<String>(json['reviewText']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final AddReviewVariables otherTyped = other as AddReviewVariables;
    return movieId == otherTyped.movieId && 
    rating == otherTyped.rating && 
    reviewText == otherTyped.reviewText;
    
  }
  @override
  int get hashCode => Object.hashAll([movieId.hashCode, rating.hashCode, reviewText.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['movieId'] = nativeToJson<String>(movieId);
    json['rating'] = nativeToJson<int>(rating);
    json['reviewText'] = nativeToJson<String>(reviewText);
    return json;
  }

  const AddReviewVariables({
    required this.movieId,
    required this.rating,
    required this.reviewText,
  });
}

