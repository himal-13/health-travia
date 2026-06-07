import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_game/models/course.dart';

void main() {
  group('Trivia Game Model Tests', () {
    test('Question parsing and unique key generation', () {
      final json = {
        'course': 'Health Assistant',
        'topic': 'First Aid',
        'difficulty': 2,
        'question': 'What is the correct compression-to-ventilation ratio for adult CPR?',
        'options': ['30:2', '15:2', '30:5', '15:1'],
        'answer': 0,
        'explanation': 'The recommended CPR ratio is 30:2.'
      };

      final question = Question.fromJson(json);

      expect(question.course, 'Health Assistant');
      expect(question.topic, 'First Aid');
      expect(question.difficulty, 2);
      expect(question.question, 'What is the correct compression-to-ventilation ratio for adult CPR?');
      expect(question.options.length, 4);
      expect(question.options[0], '30:2');
      expect(question.answerIndex, 0);
      expect(question.explanation, 'The recommended CPR ratio is 30:2.');
      expect(question.uniqueKey, 'Health Assistant:First Aid:What is the correct compression-to-ventilation ratio for adult CPR?');
    });

    test('Topic and Course structures', () {
      final q1 = Question(
        course: 'Health Assistant',
        topic: 'First Aid',
        difficulty: 1,
        question: 'Q1',
        options: ['A', 'B', 'C', 'D'],
        answerIndex: 0,
        explanation: 'Exp',
      );
      final q2 = Question(
        course: 'Health Assistant',
        topic: 'First Aid',
        difficulty: 2,
        question: 'Q2',
        options: ['A', 'B', 'C', 'D'],
        answerIndex: 1,
        explanation: 'Exp',
      );

      final topic = Topic(name: 'First Aid', questions: [q1, q2]);
      final course = Course(name: 'Health Assistant', topics: [topic]);

      expect(topic.name, 'First Aid');
      expect(topic.questions.length, 2);
      expect(course.name, 'Health Assistant');
      expect(course.topics.length, 1);
      expect(course.allQuestions.length, 2);
      expect(course.allQuestions[0].question, 'Q1');
      expect(course.allQuestions[1].question, 'Q2');
    });
  });
}
