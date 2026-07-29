import 'dart:ui' show SemanticsValidationResult;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:vihar_loop/core/accessibility/accessible_heading.dart';
import 'package:vihar_loop/core/clock.dart';
import 'package:vihar_loop/data/listing_repository.dart';
import 'package:vihar_loop/domain/listing.dart';
import 'package:vihar_loop/domain/listing_draft.dart';
import 'package:vihar_loop/domain/listing_draft_validator.dart';
import 'package:vihar_loop/features/create_listing/create_listing_view_model.dart';
import 'package:vihar_loop/local_ai/listing_suggestion.dart';
import 'package:vihar_loop/local_ai/local_ai_service.dart';

class CreateListingScreen extends StatefulWidget {
  const CreateListingScreen({
    required this.repository,
    required this.localAiService,
    required this.clock,
    super.key,
  });

  final ListingRepository repository;
  final LocalAiService localAiService;
  final Clock clock;

  @override
  State<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends State<CreateListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleKey = GlobalKey<FormFieldState<String>>();
  final _descriptionKey = GlobalKey<FormFieldState<String>>();
  final _categoryKey = GlobalKey<FormFieldState<ListingCategory>>();
  final _areaKey = GlobalKey<FormFieldState<ApproximateArea>>();
  final _contactKey = GlobalKey<FormFieldState<ContactPreference>>();
  final _deadlineKey = GlobalKey<FormFieldState<DateTime>>();
  final _validator = const ListingDraftValidator();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _titleFocus = FocusNode(debugLabel: 'Title');
  final _descriptionFocus = FocusNode(debugLabel: 'Description');
  final _categoryFocus = FocusNode(debugLabel: 'Category');
  final _areaFocus = FocusNode(debugLabel: 'Approximate area');
  final _contactFocus = FocusNode(debugLabel: 'Contact preference');
  final _deadlineFocus = FocusNode(debugLabel: 'Deadline');
  final _submitFocus = FocusNode(debugLabel: 'Post listing');

  late final CreateListingViewModel _viewModel;
  ListingKind _kind = ListingKind.need;
  ListingCategory? _category;
  ApproximateArea? _area;
  ContactPreference? _contactPreference;
  DateTime? _activeUntil;
  bool _showValidation = false;

  @override
  void initState() {
    super.initState();
    _viewModel = CreateListingViewModel(
      repository: widget.repository,
      localAiService: widget.localAiService,
    );
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _titleFocus.dispose();
    _descriptionFocus.dispose();
    _categoryFocus.dispose();
    _areaFocus.dispose();
    _contactFocus.dispose();
    _deadlineFocus.dispose();
    _submitFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final submitting = _viewModel.isSubmitting;
        final suggesting = _viewModel.isSuggesting;
        final busy = _viewModel.isBusy;
        return PopScope<Listing>(
          canPop: !submitting,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop && submitting) {
              _showMessage('Posting this listing…');
            }
          },
          child: Scaffold(
            appBar: AppBar(title: const Text('Post a need or offer')),
            body: SafeArea(
              top: false,
              child: Form(
                key: _formKey,
                autovalidateMode: _showValidation
                    ? AutovalidateMode.onUserInteraction
                    : AutovalidateMode.disabled,
                child: FocusTraversalGroup(
                  child: ListView(
                    scrollCacheExtent: const ScrollCacheExtent.pixels(2400),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                    children: [
                      Text(
                        'Share one small, time-sensitive need or offer with '
                        'people around Vidyavihar.',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Choose a broad area below. Don’t include a flat or '
                        'room number, street address, PIN code, map '
                        'coordinates, phone number, email, link, social '
                        'handle, or payment ID.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 28),
                      AccessibleHeading(
                        level: 2,
                        child: Text(
                          'What are you posting?',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      const SizedBox(height: 8),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final direction = _kindSelectorDirection(
                            context,
                            constraints.maxWidth,
                          );
                          return SegmentedButton<ListingKind>(
                            direction: direction,
                            expandedInsets: direction == Axis.horizontal
                                ? EdgeInsets.zero
                                : null,
                            segments: const [
                              ButtonSegment(
                                value: ListingKind.need,
                                icon: Icon(Icons.search),
                                label: Text('I need something'),
                              ),
                              ButtonSegment(
                                value: ListingKind.offer,
                                icon: Icon(Icons.volunteer_activism_outlined),
                                label: Text('I’m offering something'),
                              ),
                            ],
                            selected: {_kind},
                            onSelectionChanged: submitting || suggesting
                                ? null
                                : (selection) {
                                    setState(() => _kind = selection.single);
                                  },
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        key: _titleKey,
                        controller: _titleController,
                        focusNode: _titleFocus,
                        enabled: !submitting,
                        decoration: const InputDecoration(
                          labelText: 'Title',
                          border: OutlineInputBorder(),
                        ),
                        maxLength: 80,
                        maxLines: 1,
                        textInputAction: TextInputAction.next,
                        validator: _validator.titleError,
                        onFieldSubmitted: (_) =>
                            _descriptionFocus.requestFocus(),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        key: _descriptionKey,
                        controller: _descriptionController,
                        focusNode: _descriptionFocus,
                        enabled: !submitting && !suggesting,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          helperText:
                              'Describe what someone should know without '
                              'contact details or a precise location.',
                          border: OutlineInputBorder(),
                        ),
                        minLines: 4,
                        maxLines: 7,
                        maxLength: 500,
                        keyboardType: TextInputType.multiline,
                        textCapitalization: TextCapitalization.sentences,
                        textInputAction: TextInputAction.newline,
                        validator: _validator.descriptionError,
                        onChanged: (_) {
                          if (_viewModel.suggestion != null) {
                            _viewModel.dismissSuggestion();
                          }
                        },
                      ),
                      const SizedBox(height: 20),
                      _buildDraftAssist(
                        suggesting: suggesting,
                        busy: busy,
                      ),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<ListingCategory>(
                        key: _categoryKey,
                        focusNode: _categoryFocus,
                        isExpanded: true,
                        initialValue: _category,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          for (final value in ListingCategory.values)
                            DropdownMenuItem(
                              value: value,
                              child: Text(value.label),
                            ),
                        ],
                        onChanged: submitting
                            ? null
                            : (value) => setState(() => _category = value),
                        validator: (value) =>
                            value == null ? 'Choose a category.' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<ApproximateArea>(
                        key: _areaKey,
                        focusNode: _areaFocus,
                        isExpanded: true,
                        initialValue: _area,
                        decoration: const InputDecoration(
                          labelText: 'Approximate area',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          for (final value in ApproximateArea.values)
                            DropdownMenuItem(
                              value: value,
                              child: Text(value.label),
                            ),
                        ],
                        onChanged: submitting
                            ? null
                            : (value) => setState(() => _area = value),
                        validator: (value) => value == null
                            ? 'Choose an approximate area.'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<ContactPreference>(
                        key: _contactKey,
                        focusNode: _contactFocus,
                        isExpanded: true,
                        initialValue: _contactPreference,
                        decoration: const InputDecoration(
                          labelText: 'Contact preference',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          for (final value in ContactPreference.values)
                            DropdownMenuItem(
                              value: value,
                              child: Text(value.label),
                            ),
                        ],
                        onChanged: submitting
                            ? null
                            : (value) =>
                                setState(() => _contactPreference = value),
                        validator: (value) => value == null
                            ? 'Choose how people should coordinate.'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      FormField<DateTime>(
                        key: _deadlineKey,
                        initialValue: _activeUntil,
                        validator: (value) =>
                            _validator.activeUntilError(value, widget.clock()),
                        builder: (field) {
                          final callback = submitting ? null : _pickDeadline;
                          final value = _activeUntil == null
                              ? 'Not selected'
                              : _formatDeadline(context, _activeUntil!);
                          final hint = [
                            if (field.errorText != null) field.errorText!,
                            'Choose date and time',
                          ].join('. ');

                          return Semantics(
                            container: true,
                            button: true,
                            enabled: !submitting,
                            focusable: !submitting,
                            focused: _deadlineFocus.hasFocus,
                            label: _kind.activeUntilLabel,
                            value: value,
                            hint: hint,
                            onTapHint: 'Choose date and time',
                            validationResult: field.hasError
                                ? SemanticsValidationResult.invalid
                                : SemanticsValidationResult.valid,
                            onTap: callback,
                            onFocus:
                                submitting ? null : _deadlineFocus.requestFocus,
                            child: ExcludeSemantics(
                              child: InkWell(
                                key: const Key('deadline-control'),
                                focusNode: _deadlineFocus,
                                canRequestFocus: !submitting,
                                onFocusChange: (_) => setState(() {}),
                                onTap: callback,
                                borderRadius: BorderRadius.circular(4),
                                child: InputDecorator(
                                  decoration: InputDecoration(
                                    labelText: _kind.activeUntilLabel,
                                    errorText: field.errorText,
                                    border: const OutlineInputBorder(),
                                    suffixIcon: const Icon(
                                      Icons.calendar_month_outlined,
                                    ),
                                    enabled: !submitting,
                                  ),
                                  child: Text(
                                    _activeUntil == null
                                        ? 'Choose date and time'
                                        : _formatDeadline(
                                            context,
                                            _activeUntil!,
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      _buildSubmitButton(
                        submitting: submitting,
                        busy: busy,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Axis _kindSelectorDirection(BuildContext context, double availableWidth) {
    final style = Theme.of(context).textTheme.labelLarge;
    final scaler = MediaQuery.textScalerOf(context);
    double labelWidth(String label) {
      final painter = TextPainter(
        text: TextSpan(text: label, style: style),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      final width = painter.width;
      painter.dispose();
      return width;
    }

    final contentWidth = labelWidth('I need something') +
        labelWidth('I’m offering something') +
        152;
    return contentWidth <= availableWidth ? Axis.horizontal : Axis.vertical;
  }

  Widget _buildDraftAssist({
    required bool suggesting,
    required bool busy,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final suggestion = _viewModel.suggestion;
    final failure = _viewModel.suggestionFailureMessage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AccessibleHeading(
          level: 2,
          child: Text(
            'Draft Assist',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Use the description above to suggest the type, title, and '
          'category. It runs locally, and nothing is posted automatically.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 12),
        if (suggesting)
          Semantics(
            container: true,
            button: true,
            enabled: false,
            liveRegion: true,
            label: 'Suggesting type, title, and category',
            child: ExcludeSemantics(
              child: OutlinedButton.icon(
                onPressed: null,
                icon: const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                label: const Text('Suggesting…'),
              ),
            ),
          )
        else
          OutlinedButton.icon(
            key: const Key('draft-assist-suggest'),
            onPressed: busy ? null : _suggestListing,
            icon: const Icon(Icons.auto_fix_high_outlined),
            label: const Text('Suggest type, title & category'),
          ),
        if (failure != null) ...[
          const SizedBox(height: 12),
          Semantics(
            container: true,
            liveRegion: true,
            child: Text(
              failure,
              style: TextStyle(color: colorScheme.error),
            ),
          ),
        ],
        if (suggestion != null) ...[
          const SizedBox(height: 16),
          Semantics(
            container: true,
            liveRegion: true,
            label: 'Suggested type, title, and category are ready for review.',
            child: const SizedBox.square(dimension: 1),
          ),
          _SuggestionPreview(
            suggestion: suggestion,
            onApply: _applySuggestion,
            onDismiss: _viewModel.dismissSuggestion,
          ),
        ],
      ],
    );
  }

  Widget _buildSubmitButton({
    required bool submitting,
    required bool busy,
  }) {
    final button = SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        focusNode: _submitFocus,
        onPressed: busy ? null : _submit,
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
        ),
        icon: submitting
            ? const ExcludeSemantics(
                child: SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : const Icon(Icons.add_circle_outline),
        label: Text(
          submitting
              ? 'Posting…'
              : _kind == ListingKind.need
                  ? 'Post need'
                  : 'Post offer',
        ),
      ),
    );

    if (!submitting) {
      return button;
    }

    return Semantics(
      container: true,
      button: true,
      enabled: false,
      liveRegion: true,
      label: 'Posting listing',
      child: ExcludeSemantics(child: button),
    );
  }

  Future<void> _suggestListing() async {
    setState(() => _showValidation = true);
    final valid = _descriptionKey.currentState?.validate() ?? false;
    if (!valid) {
      await _focusDescription();
      return;
    }

    await _viewModel.suggestListing(
      description: _descriptionController.text,
      preferredKind: _kind,
    );
  }

  Future<void> _focusDescription() async {
    await WidgetsBinding.instance.endOfFrame;
    final descriptionContext = _descriptionKey.currentContext;
    if (descriptionContext != null && descriptionContext.mounted) {
      await Scrollable.ensureVisible(
        descriptionContext,
        duration: const Duration(milliseconds: 200),
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      );
    }
    if (mounted) {
      _descriptionFocus.requestFocus();
    }
  }

  void _applySuggestion() {
    final suggestion = _viewModel.suggestion;
    if (suggestion == null) {
      return;
    }
    setState(() {
      _kind = suggestion.kind;
      _titleController.text = suggestion.title;
      _category = suggestion.category;
    });
    _categoryKey.currentState?.didChange(suggestion.category);
    if (_showValidation) {
      _titleKey.currentState?.validate();
      _categoryKey.currentState?.validate();
    }
    _viewModel.dismissSuggestion();
    _showMessage('Suggestions added. Review before posting.');
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final titleContext = _titleKey.currentContext;
      if (!mounted || titleContext == null || !titleContext.mounted) {
        return;
      }
      await Scrollable.ensureVisible(
        titleContext,
        duration: const Duration(milliseconds: 200),
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      );
      if (mounted) {
        _titleFocus.requestFocus();
      }
    });
  }

  Future<void> _pickDeadline() async {
    final now = widget.clock();
    final today = DateTime(now.year, now.month, now.day);
    final lastDate = today.add(const Duration(days: 7));
    final fallback = now.add(const Duration(hours: 2));
    final current = _activeUntil ?? fallback;
    final initialDate = current.isAfter(lastDate) ? lastDate : current;

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: today,
      lastDate: lastDate,
    );
    if (date == null || !mounted) {
      _restoreDeadlineFocus();
      return;
    }

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (time == null || !mounted) {
      _restoreDeadlineFocus();
      return;
    }

    final selected = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    setState(() => _activeUntil = selected);
    _deadlineKey.currentState?.didChange(selected);
    if (_showValidation) {
      _deadlineKey.currentState?.validate();
    }
    _restoreDeadlineFocus();
  }

  void _restoreDeadlineFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _deadlineFocus.requestFocus();
      }
    });
  }

  Future<void> _submit() async {
    setState(() => _showValidation = true);
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid ||
        _category == null ||
        _area == null ||
        _contactPreference == null ||
        _activeUntil == null) {
      _showMessage('Check the highlighted fields.');
      await _focusFirstInvalidField();
      return;
    }

    final listing = await _viewModel.create(
      ListingDraft(
        kind: _kind,
        title: _titleController.text,
        description: _descriptionController.text,
        category: _category!,
        approximateArea: _area!,
        contactPreference: _contactPreference!,
        activeUntil: _activeUntil!,
      ),
    );
    if (!mounted) {
      return;
    }
    if (listing != null) {
      Navigator.of(context).pop(listing);
      return;
    }
    _showMessage(
      _viewModel.failureMessage ?? CreateListingViewModel.createFailureMessage,
    );
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) {
      _submitFocus.requestFocus();
    }
  }

  Future<void> _focusFirstInvalidField() async {
    final invalidFields = <({
      BuildContext? context,
      FocusNode? focusNode,
      bool hasError,
    })>[
      (
        context: _titleKey.currentContext,
        focusNode: _titleFocus,
        hasError: _titleKey.currentState?.hasError ?? false,
      ),
      (
        context: _descriptionKey.currentContext,
        focusNode: _descriptionFocus,
        hasError: _descriptionKey.currentState?.hasError ?? false,
      ),
      (
        context: _categoryKey.currentContext,
        focusNode: _categoryFocus,
        hasError: _categoryKey.currentState?.hasError ?? false,
      ),
      (
        context: _areaKey.currentContext,
        focusNode: _areaFocus,
        hasError: _areaKey.currentState?.hasError ?? false,
      ),
      (
        context: _contactKey.currentContext,
        focusNode: _contactFocus,
        hasError: _contactKey.currentState?.hasError ?? false,
      ),
      (
        context: _deadlineKey.currentContext,
        focusNode: _deadlineFocus,
        hasError: _deadlineKey.currentState?.hasError ?? false,
      ),
    ];

    await WidgetsBinding.instance.endOfFrame;
    for (final field in invalidFields) {
      if (!field.hasError) {
        continue;
      }
      final context = field.context;
      if (context != null && context.mounted) {
        await Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 200),
          alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
        );
      }
      if (mounted) {
        field.focusNode?.requestFocus();
      }
      return;
    }
  }

  String _formatDeadline(BuildContext context, DateTime value) {
    final localizations = MaterialLocalizations.of(context);
    return '${localizations.formatMediumDate(value)} at '
        '${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(value))}';
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }
}

class _SuggestionPreview extends StatelessWidget {
  const _SuggestionPreview({
    required this.suggestion,
    required this.onApply,
    required this.onDismiss,
  });

  final ListingSuggestion suggestion;
  final VoidCallback onApply;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AccessibleHeading(
              level: 3,
              child: Text(
                'Suggested details',
                style: textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 12),
            _SuggestionRow(label: 'Type', value: suggestion.kind.label),
            _SuggestionRow(label: 'Title', value: suggestion.title),
            _SuggestionRow(
              label: 'Category',
              value: suggestion.category.label,
            ),
            _SuggestionRow(label: 'Source', value: suggestion.source.label),
            const SizedBox(height: 8),
            const Text(
              'Review these suggestions before adding them to the form. '
              'Nothing is posted until you tap Post.',
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  key: const Key('draft-assist-apply'),
                  onPressed: onApply,
                  icon: const Icon(Icons.check),
                  label: const Text('Use suggestions'),
                ),
                TextButton(
                  key: const Key('draft-assist-dismiss'),
                  onPressed: onDismiss,
                  child: const Text('Dismiss'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionRow extends StatelessWidget {
  const _SuggestionRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Semantics(
        container: true,
        label: '$label: $value',
        child: ExcludeSemantics(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
