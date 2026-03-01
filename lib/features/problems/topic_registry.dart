/// Topic IDs used in settings.questionTopic.
class TopicRegistry {
  TopicRegistry._();

  static const List<String> topicIds = [
    'mixed',
    'arithmetic',
    'algebra',
    'integration',
    'geography',
  ];

  static String label(String id) {
    switch (id) {
      case 'mixed':
        return 'Mixed';
      case 'arithmetic':
        return 'Arithmetic';
      case 'algebra':
        return 'Algebra';
      case 'integration':
        return 'Integration';
      case 'geography':
        return 'Geography';
      default:
        return id;
    }
  }
}
