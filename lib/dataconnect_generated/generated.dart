// library dataconnect_generated;
// Eliminada importación inexistente y agregado stub
// import 'package:firebase_data_connect/firebase_data_connect.dart';
import 'list_movies.dart';
import 'list_users.dart';
import 'list_user_reviews.dart';
import 'get_movie_by_id.dart';
import 'search_movie.dart';
import 'create_movie.dart';
import 'upsert_user.dart';
import 'add_review.dart';
import 'delete_review.dart';

typedef Deserializer<T> = T Function(dynamic json);
typedef Serializer<V> = String Function(V vars);

class Optional<T> {
  final T? value;
  const Optional(this.value);
}

class OptionalState<T> {
  final T? value;
  const OptionalState(this.value);
}
String emptySerializer(void _) => '';
class QueryResult<T, V> {}
class QueryRef<T, V> {
  Future<QueryResult<T, V>> execute() async {
    return QueryResult<T, V>();
  }
}

class MutationRef<T, V> {
  Future<OperationResult<T, V>> execute() => throw UnimplementedError();
}
class OperationResult<T, V> {}

class FirebaseDataConnect {
  MutationRef<T, V> mutation<T, V>(String name, Deserializer<T> deserializer, Serializer<V> serializer, V vars) {
    throw UnimplementedError();
  }
  static FirebaseDataConnect instanceFor({required ConnectorConfig connectorConfig, required CallerSDKType sdkType}) {
    return FirebaseDataConnect();
  }
}

class ConnectorConfig {
  final String region;
  final String project;
  final String app;
  ConnectorConfig(this.region, this.project, this.app);
}

enum CallerSDKType { generated }







class ExampleConnector {
  
  
  ListMoviesVariablesBuilder listMovies () {
    return ListMoviesVariablesBuilder(dataConnect as dynamic);
  }
  
  
  ListUsersVariablesBuilder listUsers () {
    return ListUsersVariablesBuilder(dataConnect as dynamic);
  }
  
  
  ListUserReviewsVariablesBuilder listUserReviews () {
    return ListUserReviewsVariablesBuilder(dataConnect as dynamic);
  }
  
  
  GetMovieByIdVariablesBuilder getMovieById ({required String id, }) {
    return GetMovieByIdVariablesBuilder(dataConnect as dynamic, id: id,);
  }
  
  
  SearchMovieVariablesBuilder searchMovie () {
    return SearchMovieVariablesBuilder(dataConnect as dynamic);
  }
  
  
  CreateMovieVariablesBuilder createMovie ({required String title, required String genre, required String imageUrl, }) {
    return CreateMovieVariablesBuilder(dataConnect as dynamic, title: title,genre: genre,imageUrl: imageUrl,);
  }
  
  
  UpsertUserVariablesBuilder upsertUser ({required String username, }) {
    return UpsertUserVariablesBuilder(dataConnect as dynamic, username: username,);
  }
  
  
  AddReviewVariablesBuilder addReview ({required String movieId, required int rating, required String reviewText, }) {
    return AddReviewVariablesBuilder(dataConnect as dynamic, movieId: movieId,rating: rating,reviewText: reviewText,);
  }
  
  
  DeleteReviewVariablesBuilder deleteReview ({required String movieId, }) {
    return DeleteReviewVariablesBuilder(dataConnect as dynamic, movieId: movieId,);
  }
  

  static ConnectorConfig connectorConfig = ConnectorConfig(
    'us-east4',
    'example',
    'saneapppronuevo',
  );

  ExampleConnector({required this.dataConnect});
  static ExampleConnector get instance {
    return ExampleConnector(
        dataConnect: FirebaseDataConnect.instanceFor(
            connectorConfig: connectorConfig,
            sdkType: CallerSDKType.generated));
  }

  FirebaseDataConnect dataConnect;
}
