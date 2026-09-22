import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mage_business/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider to manage app language
final localeProvider = StateProvider<Locale>((ref) => const Locale('en'));

class LanguageSelectionScreen extends ConsumerWidget {
  const LanguageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.selectLanguage),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(),
            _LanguageButton(
              title: 'English',
              locale: const Locale('en'),
              onPressed: () {
                ref.read(localeProvider.notifier).state = const Locale('en');
                context.go('/setup');
              },
            ),
            const SizedBox(height: 16),
            _LanguageButton(
              title: 'සිංහල',
              locale: const Locale('si'),
              onPressed: () {
                ref.read(localeProvider.notifier).state = const Locale('si');
                context.go('/setup');
              },
            ),
            const SizedBox(height: 16),
            _LanguageButton(
              title: 'தமிழ்',
              locale: const Locale('ta'),
              onPressed: () {
                ref.read(localeProvider.notifier).state = const Locale('ta');
                context.go('/setup');
              },
            ),
            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }
}

class _LanguageButton extends StatelessWidget {
  final String title;
  final Locale locale;
  final VoidCallback onPressed;

  const _LanguageButton({
    required this.title,
    required this.locale,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18),
      ),
    );
  }
}
