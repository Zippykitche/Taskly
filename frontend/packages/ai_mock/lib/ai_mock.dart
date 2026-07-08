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
    if (normalized.contains('baby') || normalized.contains('child') || normalized.contains('babysitting')) {
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
    if (normalized.contains('mov')) {
      return const AiTaskPreview(
        title: 'Apartment moving assistance',
        description:
            'Load, transport, and unload boxes, furniture, and personal items. Professional handling.',
        category: 'Moving',
        suggestedBudget: r'$80 - $140',
        duration: '2-3 hours',
        recommendations: [
          'Verify vehicle size requirements',
          'List heavy items beforehand',
          'Book morning slots for better traffic',
        ],
      );
    }
    if (normalized.contains('cook') || normalized.contains('restaur')) {
      return const AiTaskPreview(
        title: 'Private chef & meal prep',
        description:
            'Prepare customized weekly meals, clean kitchen afterwards, and follow dietary preferences.',
        category: 'Cooking',
        suggestedBudget: r'$60 - $100',
        duration: '2-4 hours',
        recommendations: [
          'List dietary needs and allergies',
          'Confirm kitchen equipment available',
          'Select menu items in advance',
        ],
      );
    }
    if (normalized.contains('laund')) {
      return const AiTaskPreview(
        title: 'Wash, dry, & fold laundry',
        description:
            'Sort clothes, wash, dry, fold neatly, and organize closets or shelves.',
        category: 'Laundry',
        suggestedBudget: r'$30 - $50',
        duration: '1-2 hours',
        recommendations: [
          'Specify detergent preferences',
          'Separate whites and delicates',
          'Add custom folding instructions',
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
