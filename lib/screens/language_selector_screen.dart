import 'package:flutter/material.dart';
import '../services/language_service.dart';
import '../utils/app_strings.dart';

/// LanguageSelectorScreen lets the patient (or caregiver, on their
/// behalf) pick the app's display language. Reachable from Home's
/// "Settings" button.
class LanguageSelectorScreen extends StatelessWidget {
  const LanguageSelectorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4CAF50),
        title: ListenableBuilder(
          listenable: languageService,
          builder: (context, _) => Text(
            AppStrings.t('select_language'),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 32),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: languageService,
          builder: (context, _) {
            return ListView(
              padding: const EdgeInsets.all(20.0),
              children: LanguageService.displayNames.entries.map((entry) {
                final code = entry.key;
                final name = entry.value;
                final isSelected = languageService.currentLanguage == code;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: isSelected ? 4 : 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: isSelected
                        ? const BorderSide(color: Color(0xFF4CAF50), width: 2)
                        : BorderSide.none,
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    title: Text(
                      name,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: const Color(0xFF333333),
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 28)
                        : null,
                    onTap: () => languageService.setLanguage(code),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }
}
