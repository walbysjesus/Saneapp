// All imports and part directives must be at the top
import 'dart:convert';
import 'package:meta/meta.dart';

// Stub classes and methods for generated types
class FirebaseDataConnect {
  MutationRef<T, V> mutation<T, V>(String name, Deserializer<T> deserializer, Serializer<V> serializer, V vars) {
    // Stub implementation
    throw UnimplementedError();
  }
}
typedef Deserializer<T> = T Function(dynamic json);
typedef Serializer<V> = String Function(V vars);
class MutationRef<T, V> {
  Future<OperationResult<T, V>> execute() => throw UnimplementedError();
}
class OperationResult<T, V> {}
T nativeFromJson<T>(dynamic json) => json as T;
dynamic nativeToJson<T>(T value) => value;

class DeleteReviewVariablesBuilder {
  String movieId;

  final FirebaseDataConnect _dataConnect;
  DeleteReviewVariablesBuilder(this._dataConnect, {required  this.movieId,});
  Deserializer<DeleteReviewData> dataDeserializer = (dynamic json)  => DeleteReviewData.fromJson(jsonDecode(json));
  Serializer<DeleteReviewVariables> varsSerializer = (DeleteReviewVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<DeleteReviewData, DeleteReviewVariables>> execute() {
    return ref().execute();
  }

  MutationRef<DeleteReviewData, DeleteReviewVariables> ref() {
    DeleteReviewVariables vars= DeleteReviewVariables(movieId: movieId,);
    return _dataConnect.mutation("DeleteReview", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class DeleteReviewReviewDelete {
  final String userId;
  final String movieId;
  DeleteReviewReviewDelete.fromJson(dynamic json)
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
    final DeleteReviewReviewDelete otherTyped = other as DeleteReviewReviewDelete;
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
  const DeleteReviewReviewDelete({
    required this.userId,
    required this.movieId,
  });
}

@immutable
class DeleteReviewData {
  final DeleteReviewReviewDelete? reviewDelete;
  DeleteReviewData.fromJson(dynamic json)
      : reviewDelete = json['review_delete'] == null
            ? null
            : DeleteReviewReviewDelete.fromJson(json['review_delete']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    final DeleteReviewData otherTyped = other as DeleteReviewData;
    return reviewDelete == otherTyped.reviewDelete;
  }
  @override
  int get hashCode => reviewDelete.hashCode;
  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (reviewDelete != null) {
      json['review_delete'] = reviewDelete!.toJson();
    }
    return json;
  }
  const DeleteReviewData({
    this.reviewDelete,
  });
}

@immutable
class DeleteReviewVariables {
  final String movieId;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  DeleteReviewVariables.fromJson(Map<String, dynamic> json)
      : movieId = nativeFromJson<String>(json['movieId']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    final DeleteReviewVariables otherTyped = other as DeleteReviewVariables;
    return movieId == otherTyped.movieId;
  }
  @override
  int get hashCode => movieId.hashCode;
  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['movieId'] = nativeToJson<String>(movieId);
    return json;
  }
  const DeleteReviewVariables({
    required this.movieId,
  });
}

