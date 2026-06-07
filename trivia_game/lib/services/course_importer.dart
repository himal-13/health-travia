import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:trivia_game/models/course.dart';

class CourseImporter {
  static Future<List<Course>> importAllCourses() async {
    final List<Course> courses = [];
    try {
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap =
          jsonDecode(manifestContent) as Map<String, dynamic>;

      // Match files starting with assets/courses/ and ending with .json
      final coursePaths = manifestMap.keys
          .where((key) =>
              key.startsWith('assets/courses/') && key.endsWith('.json'))
          .toList();

      // Fallback fallback if the manifest is not populated or in test environments
      if (coursePaths.isEmpty) {
        coursePaths.addAll([
          'assets/courses/health_assistant.json',
          'assets/courses/staff_nurse.json',
        ]);
      }

      for (final path in coursePaths) {
        try {
          final jsonString = await rootBundle.loadString(path);
          final List<dynamic> jsonList = jsonDecode(jsonString) as List<dynamic>;

          final questions = jsonList
              .map((q) => Question.fromJson(q as Map<String, dynamic>))
              .toList();

          if (questions.isEmpty) continue;

          final courseName = questions.first.course;
          final Map<String, List<Question>> topicGroups = {};

          for (final q in questions) {
            topicGroups.putIfAbsent(q.topic, () => []).add(q);
          }

          final List<Topic> topics = topicGroups.entries.map((entry) {
            return Topic(name: entry.key, questions: entry.value);
          }).toList();

          // Check if this course is already imported, if so combine topics
          final existingCourseIndex =
              courses.indexWhere((c) => c.name.toLowerCase() == courseName.toLowerCase());
          if (existingCourseIndex != -1) {
            final existingCourse = courses[existingCourseIndex];
            // Merge topics
            for (final t in topics) {
              final existingTopicIndex =
                  existingCourse.topics.indexWhere((et) => et.name == t.name);
              if (existingTopicIndex != -1) {
                existingCourse.topics[existingTopicIndex].questions.addAll(t.questions);
              } else {
                existingCourse.topics.add(t);
              }
            }
          } else {
            courses.add(Course(name: courseName, topics: topics));
          }
        } catch (fileError) {
          print('CourseImporter: failed to import $path: $fileError');
        }
      }
    } catch (e) {
      print('CourseImporter error loading manifest: $e');
      // Hard fallback: Load just in case
      for (final fallbackPath in [
        'assets/courses/health_assistant.json',
        'assets/courses/staff_nurse.json',
      ]) {
        try {
          final jsonString = await rootBundle.loadString(fallbackPath);
          final List<dynamic> jsonList = jsonDecode(jsonString) as List<dynamic>;
          final questions = jsonList
              .map((q) => Question.fromJson(q as Map<String, dynamic>))
              .toList();
          if (questions.isEmpty) continue;
          final courseName = questions.first.course;
          final Map<String, List<Question>> topicGroups = {};
          for (final q in questions) {
            topicGroups.putIfAbsent(q.topic, () => []).add(q);
          }
          final List<Topic> topics = topicGroups.entries.map((entry) {
            return Topic(name: entry.key, questions: entry.value);
          }).toList();
          courses.add(Course(name: courseName, topics: topics));
        } catch (_) {}
      }
    }

    return courses;
  }
}
