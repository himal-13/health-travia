class Question {
  final String course;
  final String topic;
  final int difficulty;
  final String question;
  final List<String> options;
  final int answerIndex;
  final String explanation;

  Question({
    required this.course,
    required this.topic,
    required this.difficulty,
    required this.question,
    required this.options,
    required this.answerIndex,
    required this.explanation,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      course: json['course'] as String,
      topic: json['topic'] as String,
      difficulty: json['difficulty'] as int,
      question: json['question'] as String,
      options: List<String>.from(json['options'] as List),
      answerIndex: json['answer'] as int,
      explanation: json['explanation'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'course': course,
      'topic': topic,
      'difficulty': difficulty,
      'question': question,
      'options': options,
      'answer': answerIndex,
      'explanation': explanation,
    };
  }

  String get uniqueKey => '$course:$topic:$question';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Question &&
          runtimeType == other.runtimeType &&
          uniqueKey == other.uniqueKey;

  @override
  int get hashCode => uniqueKey.hashCode;
}

class Topic {
  final String name;
  final List<Question> questions;

  Topic({required this.name, required this.questions});
}

class Course {
  final String name;
  final List<Topic> topics;

  Course({required this.name, required this.topics});

  List<Question> get allQuestions => topics.expand((t) => t.questions).toList();
}
