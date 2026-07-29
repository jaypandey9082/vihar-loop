import 'package:vihar_loop/domain/listing.dart';
import 'package:vihar_loop/domain/listing_draft_validator.dart';
import 'package:vihar_loop/local_ai/listing_suggestion.dart';
import 'package:vihar_loop/local_ai/listing_suggestion_validator.dart';
import 'package:vihar_loop/local_ai/local_ai_service.dart';

class RuleBasedListingAssistant implements LocalAiService {
  const RuleBasedListingAssistant({
    this.draftValidator = const ListingDraftValidator(),
    this.suggestionValidator = const ListingSuggestionValidator(),
  });

  final ListingDraftValidator draftValidator;
  final ListingSuggestionValidator suggestionValidator;

  static const _needPhrases = <String, int>{
    'looking for': 3,
    'want to borrow': 3,
    'can someone lend': 3,
    'can anyone lend': 3,
    'searching for': 3,
    'ढूंढ रहा': 3,
    'ढूँढ रहा': 3,
    'शोधत आहे': 3,
  };
  static const _needTokens = <String>{
    'need',
    'needed',
    'want',
    'require',
    'required',
    'चाहिए',
    'चाहिये',
    'जरूरत',
    'ज़रूरत',
    'पाहिजे',
    'पाहिजेत',
    'हवे',
  };
  static const _offerPhrases = <String, int>{
    'can lend': 3,
    'can give': 3,
    'giving away': 3,
    'can help': 3,
    'happy to lend': 3,
    'free to take': 3,
    'anyone can borrow': 3,
    'दे सकता': 3,
    'दे सकती': 3,
    'मदद कर सकता': 3,
    'मदद कर सकती': 3,
    'उपलब्ध आहे': 3,
    'देऊ शकतो': 3,
    'देऊ शकते': 3,
    'मदत करू शकतो': 3,
    'मदत करू शकते': 3,
  };
  static const _offerTokens = <String>{
    'offering',
    'available',
    'उपलब्ध',
  };

  static const _categoryRules = <ListingCategory, _CategorySignals>{
    ListingCategory.booksAndStudy: _CategorySignals(
      phrases: {
        'statistics notes': 5,
        'study notes': 5,
        'entrance exam books': 5,
        'scientific calculator': 5,
        'class notes': 5,
        'अभ्यासासाठी नोट्स': 5,
      },
      tokens: {
        'book',
        'books',
        'textbook',
        'notes',
        'syllabus',
        'exam',
        'study',
        'assignment',
        'calculator',
        'class',
        'किताब',
        'किताबें',
        'पुस्तक',
        'पुस्तके',
        'नोट्स',
        'परीक्षा',
        'अभ्यास',
        'अभ्यासासाठी',
      },
    ),
    ListingCategory.electronics: _CategorySignals(
      phrases: {
        'usb-c charger': 5,
        'type-c charger': 5,
        'laptop charger': 5,
        'power bank': 5,
        'charging cable': 5,
        'usb keyboard': 6,
      },
      tokens: {
        'charger',
        'laptop',
        'cable',
        'adapter',
        'mouse',
        'keyboard',
        'phone',
        'mobile',
        'earphones',
        'headphones',
        'usb',
        'usb-c',
        'electronic',
        'चार्जर',
        'लैपटॉप',
        'मोबाइल',
      },
    ),
    ListingCategory.homeAndTools: _CategorySignals(
      phrases: {
        'screwdriver set': 5,
        'tool kit': 5,
        'room heater': 5,
        'folding chair': 5,
      },
      tokens: {
        'screwdriver',
        'hammer',
        'drill',
        'ladder',
        'umbrella',
        'heater',
        'chair',
        'table',
        'tool',
        'tools',
        'छत्री',
        'हथौड़ा',
      },
    ),
    ListingCategory.foodAndEssentials: _CategorySignals(
      phrases: {
        'homemade tiffin': 5,
        'drinking water': 5,
        'grocery items': 5,
      },
      tokens: {
        'food',
        'meal',
        'tiffin',
        'grocery',
        'groceries',
        'water',
        'milk',
        'snack',
        'essentials',
        'खाना',
        'भोजन',
        'पाणी',
        'अन्न',
      },
    ),
    ListingCategory.skillsAndServices: _CategorySignals(
      phrases: {
        'help with': 5,
        'need help': 6,
        'set up': 5,
        'can help': 6,
        'can teach': 5,
        'can repair': 5,
        'tutoring': 5,
        'coding help': 5,
      },
      tokens: {
        'help',
        'teach',
        'tutor',
        'repair',
        'repairing',
        'install',
        'setup',
        'coding',
        'design',
        'lesson',
        'service',
        'मदद',
        'सिखा',
        'दुरुस्ती',
        'शिकव',
      },
    ),
    ListingCategory.musicHobbiesAndSports: _CategorySignals(
      phrases: {
        'guitar capo': 6,
        'music stand': 5,
        'badminton shuttle': 5,
        'badminton shuttles': 5,
        'badminton racket': 5,
        'football boots': 5,
        'cricket bat': 5,
        'musical keyboard': 6,
      },
      tokens: {
        'guitar',
        'capo',
        'tabla',
        'harmonium',
        'music',
        'musical',
        'rehearsal',
        'singing',
        'badminton',
        'shuttle',
        'shuttles',
        'racket',
        'football',
        'cricket',
        'sports',
        'गिटार',
        'कैपो',
        'तबला',
        'संगीत',
        'बैडमिंटन',
        'क्रिकेट',
        'गायन',
      },
    ),
  };

  static const _categoryTieBreak = <ListingCategory>[
    ListingCategory.skillsAndServices,
    ListingCategory.musicHobbiesAndSports,
    ListingCategory.booksAndStudy,
    ListingCategory.electronics,
    ListingCategory.homeAndTools,
    ListingCategory.foodAndEssentials,
  ];

  static const _leadingIntentPhrases = <String>[
    'can someone lend',
    'can anyone lend',
    'anyone can borrow',
    'want to borrow',
    'happy to lend',
    'free to take',
    'looking for',
    'searching for',
    'giving away',
    'can help',
    'can lend',
    'can give',
    'offering',
    'required',
    'needed',
    'require',
    'need',
    'want',
  ];

  static final _sentenceSeparator = RegExp(r'[\n\r.!?]+');
  static final _analysisSeparator = RegExp(r'''[\s,.;:!?()[\]{}"'“”]+''');
  static final _repeatedWhitespace = RegExp(r'\s+');
  static final _trailingPunctuation = RegExp(r'[,;:.\s]+$');
  static final _trailingContext = RegExp(
    r'\s+(?:near|around)\s+somaiya(?:\s+today)?$|'
    r'\s+near\s+vidyavihar(?:\s+station)?(?:\s+today)?$|'
    r'\s+in\s+vidyavihar(?:\s+today)?$|'
    r'\s+(?:today|tomorrow|this evening|for tonight|tonight|until tonight|'
    r'until tomorrow|for two hours)$|'
    r'\s+(?:before|by)\s+\d{1,2}(?::\d{2})?\s*(?:am|pm)?$',
    caseSensitive: false,
  );

  @override
  Future<ListingSuggestion> suggestListing({
    required String description,
    required ListingKind preferredKind,
  }) async {
    if (draftValidator.descriptionError(description) != null) {
      throw const InvalidLocalAiInputException();
    }

    final analysis = _normalizeForAnalysis(description);
    final suggestion = ListingSuggestion(
      kind: _detectKind(analysis, preferredKind),
      title: _generateTitle(description),
      category: _detectCategory(analysis),
      source: ListingSuggestionSource.deterministicFallback,
    );
    suggestionValidator.validateOrThrow(suggestion);
    return suggestion;
  }

  String _normalizeForAnalysis(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(_analysisSeparator, ' ')
        .replaceAll(_repeatedWhitespace, ' ');
  }

  ListingKind _detectKind(String analysis, ListingKind preferredKind) {
    final padded = ' $analysis ';
    final tokens =
        analysis.split(' ').where((value) => value.isNotEmpty).toSet();
    final needScore = _scoreSignals(
      padded,
      tokens,
      _needPhrases,
      _needTokens,
    );
    final offerScore = _scoreSignals(
      padded,
      tokens,
      _offerPhrases,
      _offerTokens,
    );
    if (needScore == offerScore) {
      return preferredKind;
    }
    return needScore > offerScore ? ListingKind.need : ListingKind.offer;
  }

  ListingCategory _detectCategory(String analysis) {
    final padded = ' $analysis ';
    final tokens =
        analysis.split(' ').where((value) => value.isNotEmpty).toSet();
    var bestScore = 0;
    var best = ListingCategory.other;

    // This explicit order makes equal category scores stable across releases.
    for (final category in _categoryTieBreak) {
      final signals = _categoryRules[category]!;
      final score = _scoreSignals(
        padded,
        tokens,
        signals.phrases,
        signals.tokens,
      );
      if (score > bestScore) {
        bestScore = score;
        best = category;
      }
    }
    return best;
  }

  int _scoreSignals(
    String padded,
    Set<String> tokens,
    Map<String, int> phrases,
    Set<String> signalTokens,
  ) {
    var score = 0;
    for (final entry in phrases.entries) {
      if (padded.contains(' ${entry.key} ')) {
        score += entry.value;
      }
    }
    for (final token in signalTokens) {
      if (tokens.contains(token)) {
        score += 1;
      }
    }
    return score;
  }

  String _generateTitle(String description) {
    final firstSentence = description
        .split(_sentenceSeparator)
        .map((value) => value.trim().replaceAll(_repeatedWhitespace, ' '))
        .firstWhere((value) => value.isNotEmpty);
    var title = firstSentence;
    final lower = title.toLowerCase();
    for (final phrase in _leadingIntentPhrases) {
      if (lower == phrase || lower.startsWith('$phrase ')) {
        title = title.substring(phrase.length).trimLeft();
        break;
      }
    }
    title = title.replaceFirst(
      RegExp(r'^(?:a|an|the|my)\s+', caseSensitive: false),
      '',
    );

    final withoutContext = title.replaceFirst(_trailingContext, '');
    if (withoutContext.trim().length >= 5) {
      title = withoutContext;
    }
    title = title.replaceFirst(_trailingPunctuation, '').trim();

    if (title.length < 5) {
      title = firstSentence.replaceFirst(_trailingPunctuation, '').trim();
    }
    title = _truncateTitle(title);
    if (title.isNotEmpty) {
      final first = title.substring(0, 1);
      title = '${first.toUpperCase()}${title.substring(1)}';
    }
    return title;
  }

  String _truncateTitle(String title) {
    if (title.length <= 80) {
      return title;
    }
    final candidate = title.substring(0, 80);
    final lastSpace = candidate.lastIndexOf(' ');
    if (lastSpace >= 5) {
      return candidate.substring(0, lastSpace).trimRight();
    }
    return candidate.trimRight();
  }
}

class _CategorySignals {
  const _CategorySignals({
    required this.phrases,
    required this.tokens,
  });

  final Map<String, int> phrases;
  final Set<String> tokens;
}
