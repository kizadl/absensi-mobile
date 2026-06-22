import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/course_model.dart';
import '../services/api_client.dart';

/// Loads the list of courses (each with its today-status) for the home cards.
class CourseProvider extends ChangeNotifier {
  CourseProvider(this._api);

  final ApiClient _api;

  bool _isLoading = false;
  String? _error;
  List<CourseModel> _courses = const [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<CourseModel> get courses => _courses;

  /// GET /courses → {data:[ {...course, today:{...}} ]}.
  Future<void> loadCourses() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await _api.dio.get('/courses');
      final list = (res.data as Map<String, dynamic>)['data'] as List<dynamic>;
      _courses = list
          .map((e) => CourseModel.fromJson((e as Map).cast<String, dynamic>()))
          .toList();
    } on DioException catch (e) {
      _error = _messageOf(e.response?.data);
      _courses = const [];
    } catch (e) {
      _error = e.toString();
      _courses = const [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _messageOf(dynamic data) {
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }
    return 'Gagal memuat daftar mata kuliah.';
  }
}
