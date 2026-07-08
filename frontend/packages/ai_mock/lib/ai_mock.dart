import 'package:shared_models/shared_models.dart';

class AiTaskPreview {
  const AiTaskPreview({
    required this.title,
    required this.description,
    required this.category,
    required this.suggestedBudget,
    required this.duration,
    required this.recommendations,
  });

  final String title;
  final String description;
  final String category;
  final String suggestedBudget;
  final String duration;
  final List<String> recommendations;
}

class AiMockService {
  Future<AiTaskPreview> generateTaskPreview(String prompt) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    final normalized = prompt.toLowerCase();
    if (normalized.contains('clean')) {
      return const AiTaskPreview(
        title: 'Deep clean apartment',
        description:
            'Clean kitchen, bathrooms, living areas, floors, surfaces, and final tidy-up.',
        category: 'Cleaning',
        suggestedBudget: r'$120 - $160',
        duration: '3-4 hours',
        recommendations: [
          'Book morning slots',
          'Add parking notes',
          'Choose verified cleaners',
        ],
      );
    }
    if (normalized.contains('baby') || normalized.contains('child')) {
      return const AiTaskPreview(
        title: 'Evening babysitting',
        description:
            'Childcare support with meal routine, bedtime preparation, and light cleanup.',
        category: 'Babysitting',
        suggestedBudget: r'$28 - $36/hr',
        duration: '4 hours',
        recommendations: [
          'Require ID verified tasker',
          'Share emergency contact',
          'Prefer 4.9+ rating',
        ],
      );
    }
    return const AiTaskPreview(
      title: 'Personal task request',
      description:
          'A local tasker will help complete your request with the details you provide.',
      category: 'Errands',
      suggestedBudget: r'$40 - $80',
      duration: '1-2 hours',
      recommendations: [
        'Add clear instructions',
        'Set flexible time window',
        'Compare top matches',
      ],
    );
  }

  List<String> quickReplies() => const [
    'Ask for arrival ETA',
    'Share access instructions',
    'Confirm task scope',
  ];

  List<TaskerProfile> rankedTaskers() => taskers;
}
