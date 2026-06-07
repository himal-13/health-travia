import 'package:trivia_game/models/course.dart';

class Bookmark {
  final Question question;
  final DateTime bookmarkedAt;

  Bookmark({required this.question, required this.bookmarkedAt});

  factory Bookmark.fromJson(Map<String, dynamic> json) {
    return Bookmark(
      question: Question.fromJson(json['question'] as Map<String, dynamic>),
      bookmarkedAt: DateTime.parse(json['bookmarkedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'question': question.toJson(),
      'bookmarkedAt': bookmarkedAt.toIso8601String(),
    };
  }
}
