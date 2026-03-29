import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/post.dart';
import '../exceptions/api_exceptions.dart';

class PostService {
  static const String _baseUrl = 'https://jsonplaceholder.typicode.com/posts';

  // ─── Common headers for all requests ─────────────────────────────────────
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json; charset=UTF-8',
    'Accept': 'application/json',
  };

  void _checkStatus(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw ServerException(
      'Server error: ${response.reasonPhrase}',
      response.statusCode,
    );
  }

  Future<T> _safeCall<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on SocketException {
      throw NetworkException(
          'No internet connection. Please check your network.');
    } on HttpException {
      throw NetworkException('Could not reach the server.');
    } on FormatException catch (e) {
      throw DataParseException('Invalid data format: ${e.message}');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Unexpected error: $e');
    }
  }

  // ─── GET all posts ────────────────────────────────────────────────────────
  Future<List<Post>> fetchPosts() => _safeCall(() async {
        final response = await http.get(
          Uri.parse(_baseUrl),
          headers: _headers, // ← added
        );
        _checkStatus(response);
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Post.fromJson(json)).toList();
      });

  // ─── GET single post ──────────────────────────────────────────────────────
  Future<Post> fetchPost(int id) => _safeCall(() async {
        final response = await http.get(
          Uri.parse('$_baseUrl/$id'),
          headers: _headers, // ← added
        );
        _checkStatus(response);
        return Post.fromJson(jsonDecode(response.body));
      });

  // ─── POST create ──────────────────────────────────────────────────────────
  Future<Post> createPost(Post post) => _safeCall(() async {
        final response = await http.post(
          Uri.parse(_baseUrl),
          headers: _headers,
          body: jsonEncode(post.toJson()),
        );
        _checkStatus(response);
        return Post.fromJson(jsonDecode(response.body));
      });

  // ─── PUT update ───────────────────────────────────────────────────────────
  Future<Post> updatePost(Post post) => _safeCall(() async {
        final response = await http.put(
          Uri.parse('$_baseUrl/${post.id}'),
          headers: _headers,
          body: jsonEncode({...post.toJson(), 'id': post.id}),
        );
        _checkStatus(response);
        return Post.fromJson(jsonDecode(response.body));
      });

  // ─── DELETE ───────────────────────────────────────────────────────────────
  Future<void> deletePost(int id) => _safeCall(() async {
        final response = await http.delete(
          Uri.parse('$_baseUrl/$id'),
          headers: _headers, // ← added
        );
        _checkStatus(response);
      });
}
