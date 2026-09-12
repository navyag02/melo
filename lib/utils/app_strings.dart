import '../services/language_service.dart';

/// AppStrings holds translated text for patient-facing screens.
///
/// IMPORTANT HONESTY NOTE: Hindi and Bengali translations below are
/// reasonably confident. Assamese and Manipuri translations are a
/// best-effort starting point and are marked TODO — please have a
/// native speaker verify them before relying on this for a real demo,
/// the same caution we've applied to cultural game content elsewhere.
///
/// Usage in a widget:
///   Text(AppStrings.t('welcome'))
/// Wrap the containing widget in a ListenableBuilder(listenable:
/// languageService, ...) so it rebuilds when the language changes —
/// see home_screen.dart for the pattern.
class AppStrings {
  static final Map<String, Map<String, String>> _strings = {
    // Home screen
    'welcome': {
      LanguageService.english: 'Welcome!',
      LanguageService.hindi: 'स्वागत है!',
      LanguageService.bengali: 'স্বাগতম!',
      LanguageService.assamese: 'স্বাগতম!', // TODO: verify
      LanguageService.manipuri: 'তরাম্না লাক্কৈ!', // TODO: verify
    },
    'what_to_do_today': {
      LanguageService.english: 'What would you like to do today?',
      LanguageService.hindi: 'आज आप क्या करना चाहेंगे?',
      LanguageService.bengali: 'আজ আপনি কী করতে চান?',
      LanguageService.assamese: 'আজি আপুনি কি কৰিব বিচাৰে?', // TODO: verify
      LanguageService.manipuri: 'ঙসি নহাক্না করম্না তৌবগুম্বনো?', // TODO: verify
    },
    'play_games': {
      LanguageService.english: 'Play Games',
      LanguageService.hindi: 'खेल खेलें',
      LanguageService.bengali: 'গেম খেলুন',
      LanguageService.assamese: 'খেল খেলক', // TODO: verify
      LanguageService.manipuri: 'গেম শান্নু', // TODO: verify
    },
    'reminders': {
      LanguageService.english: 'Reminders',
      LanguageService.hindi: 'रिमाइंडर',
      LanguageService.bengali: 'রিমাইন্ডার',
      LanguageService.assamese: 'মনত পেলোৱা', // TODO: verify
      LanguageService.manipuri: 'নীংশিংহনবা', // TODO: verify
    },
    'settings': {
      LanguageService.english: 'Settings',
      LanguageService.hindi: 'सेटिंग्स',
      LanguageService.bengali: 'সেটিংস',
      LanguageService.assamese: 'ছেটিংছ', // TODO: verify
      LanguageService.manipuri: 'সেটিং', // TODO: verify
    },
    'caregiver_login': {
      LanguageService.english: 'Caregiver Login',
      LanguageService.hindi: 'देखभालकर्ता लॉगिन',
      LanguageService.bengali: 'যত্নকারী লগইন',
      LanguageService.assamese: 'যত্নকাৰী লগইন', // TODO: verify
      LanguageService.manipuri: 'কেয়ারগিভার লোগিন', // TODO: verify
    },
    'select_language': {
      LanguageService.english: 'Select Language',
      LanguageService.hindi: 'भाषा चुनें',
      LanguageService.bengali: 'ভাষা নির্বাচন করুন',
      LanguageService.assamese: 'ভাষা বাছক', // TODO: verify
      LanguageService.manipuri: 'লোল খল্লু', // TODO: verify
    },

    // Game selection screen
    'select_a_game': {
      LanguageService.english: 'Select a Game',
      LanguageService.hindi: 'एक खेल चुनें',
      LanguageService.bengali: 'একটি গেম নির্বাচন করুন',
      LanguageService.assamese: 'এটা খেল বাছক', // TODO: verify
      LanguageService.manipuri: 'গেম অমা খল্লু', // TODO: verify
    },
    'choose_game_to_play': {
      LanguageService.english: 'Choose a game to play:',
      LanguageService.hindi: 'खेलने के लिए एक खेल चुनें:',
      LanguageService.bengali: 'খেলার জন্য একটি গেম বেছে নিন:',
      LanguageService.assamese: 'খেলিবলৈ এটা খেল বাছনি কৰক:', // TODO: verify
      LanguageService.manipuri: 'শাননবা গেম অমা খল্লু:', // TODO: verify
    },
    'memory_match_title': {
      LanguageService.english: 'Memory Match',
      LanguageService.hindi: 'मेमोरी मैच',
      LanguageService.bengali: 'মেমরি ম্যাচ',
      LanguageService.assamese: 'মেমৰি মেচ', // TODO: verify
      LanguageService.manipuri: 'মেমরি মেচ', // TODO: verify
    },
    'memory_match_desc': {
      LanguageService.english: 'Find matching pairs of cards',
      LanguageService.hindi: 'कार्डों के मिलते-जुलते जोड़े खोजें',
      LanguageService.bengali: 'কার্ডের মিল জোড়া খুঁজুন',
      LanguageService.assamese: 'কাৰ্ডৰ মিল থকা যোৰবোৰ বিচাৰক', // TODO: verify
      LanguageService.manipuri: 'কার্দগী মান্নবা য়ুম্ফম থিবিয়ু', // TODO: verify
    },
    'trip_itinerary_title': {
      LanguageService.english: 'Trip Itinerary',
      LanguageService.hindi: 'यात्रा कार्यक्रम',
      LanguageService.bengali: 'ভ্রমণ পরিকল্পনা',
      LanguageService.assamese: 'ভ্ৰমণ পৰিকল্পনা', // TODO: verify
      LanguageService.manipuri: 'ৱারোল থবক', // TODO: verify
    },
    'trip_itinerary_desc': {
      LanguageService.english: 'Remember your trip through the North East',
      LanguageService.hindi: 'पूर्वोत्तर की अपनी यात्रा याद रखें',
      LanguageService.bengali: 'উত্তর-পূর্বের মধ্য দিয়ে আপনার ভ্রমণ মনে রাখুন',
      LanguageService.assamese: 'উত্তৰ-পূৰ্বৰ মাজেৰে আপোনাৰ ভ্ৰমণ মনত ৰাখক', // TODO: verify
      LanguageService.manipuri: 'নর্থ ইস্তগী চৎখিবা নহাক্কী থবক নীংশিংবিয়ু', // TODO: verify
    },
    'daily_routine_title': {
      LanguageService.english: 'Daily Routine',
      LanguageService.hindi: 'दैनिक दिनचर्या',
      LanguageService.bengali: 'দৈনন্দিন রুটিন',
      LanguageService.assamese: 'দৈনন্দিন কাৰ্যসূচী', // TODO: verify
      LanguageService.manipuri: 'নুমিৎ খুদিংগী থবক', // TODO: verify
    },
    'daily_routine_desc': {
      LanguageService.english: 'Arrange your daily activities in order',
      LanguageService.hindi: 'अपनी दैनिक गतिविधियों को क्रम में व्यवस्थित करें',
      LanguageService.bengali: 'আপনার দৈনন্দিন কার্যক্রম ক্রমানুসারে সাজান',
      LanguageService.assamese: 'আপোনাৰ দৈনন্দিন কামবোৰ ক্ৰমত সজাওক', // TODO: verify
      LanguageService.manipuri: 'নুমিৎ খুদিংগী থবকশিং মান্নবা মথৌনা থম্মু', // TODO: verify
    },
    'spot_difference_title': {
      LanguageService.english: 'Spot the Difference',
      LanguageService.hindi: 'अंतर खोजें',
      LanguageService.bengali: 'পার্থক্য খুঁজুন',
      LanguageService.assamese: 'পাৰ্থক্য বিচাৰক', // TODO: verify
      LanguageService.manipuri: 'তোকহনবা থিবিয়ু', // TODO: verify
    },
    'spot_difference_desc': {
      LanguageService.english: 'Find the tile that looks different',
      LanguageService.hindi: 'अलग दिखने वाली टाइल खोजें',
      LanguageService.bengali: 'ভিন্ন দেখতে টাইলটি খুঁজুন',
      LanguageService.assamese: 'বেলেগ দেখা টাইলটো বিচাৰক', // TODO: verify
      LanguageService.manipuri: 'তোকহনবা টাইল থিবিয়ু', // TODO: verify
    },
    'personal_memories_title': {
      LanguageService.english: 'Personal Memories',
      LanguageService.hindi: 'व्यक्तिगत यादें',
      LanguageService.bengali: 'ব্যক্তিগত স্মৃতি',
      LanguageService.assamese: 'ব্যক্তিগত স্মৃতি', // TODO: verify
      LanguageService.manipuri: 'নীংশিংফম', // TODO: verify
    },
    'personal_memories_desc': {
      LanguageService.english: 'Look at personal photos and share memories',
      LanguageService.hindi: 'व्यक्तिगत तस्वीरें देखें और यादें साझा करें',
      LanguageService.bengali: 'ব্যক্তিগত ছবি দেখুন এবং স্মৃতি শেয়ার করুন',
      LanguageService.assamese: 'ব্যক্তিগত ফটো চাওক আৰু স্মৃতি ভাগ কৰক', // TODO: verify
      LanguageService.manipuri: 'নীংশিংফম য়েংবিয়ু অমসুং শেয়র তৌবিয়ু', // TODO: verify
    },
    'number_sequence_title': {
      LanguageService.english: 'Number Sequence',
      LanguageService.hindi: 'संख्या क्रम',
      LanguageService.bengali: 'সংখ্যা ক্রম',
      LanguageService.assamese: 'সংখ্যাৰ ক্ৰম', // TODO: verify
      LanguageService.manipuri: 'নম্বর মথৌ', // TODO: verify
    },
    'number_sequence_desc': {
      LanguageService.english: 'Complete the number pattern',
      LanguageService.hindi: 'संख्या पैटर्न पूरा करें',
      LanguageService.bengali: 'সংখ্যার প্যাটার্ন সম্পূর্ণ করুন',
      LanguageService.assamese: 'সংখ্যাৰ আৰ্হি সম্পূৰ্ণ কৰক', // TODO: verify
      LanguageService.manipuri: 'নম্বর মথৌ লোয়শিন্নু', // TODO: verify
    },

    // ===== Caregiver Dashboard =====
    'caregiver_dashboard_title': {
      LanguageService.english: 'Caregiver Dashboard',
      LanguageService.hindi: 'देखभालकर्ता डैशबोर्ड',
      LanguageService.bengali: 'যত্নকারী ড্যাশবোর্ড',
      LanguageService.assamese: 'যত্নকাৰী ডেছবৰ্ড', // TODO: verify
      LanguageService.manipuri: 'কেয়ারগিভার দেশবোর্দ', // TODO: verify
    },
    'patient_label': {
      LanguageService.english: 'Patient',
      LanguageService.hindi: 'मरीज़',
      LanguageService.bengali: 'রোগী',
      LanguageService.assamese: 'ৰোগী', // TODO: verify
      LanguageService.manipuri: 'লাইনা', // TODO: verify
    },
    'logged_in_as': {
      LanguageService.english: 'Logged in as',
      LanguageService.hindi: 'इस रूप में लॉग इन किया गया',
      LanguageService.bengali: 'হিসাবে লগ ইন করা হয়েছে',
      LanguageService.assamese: 'হিচাপে লগইন কৰা হৈছে', // TODO: verify
      LanguageService.manipuri: 'অসী ওইনা লোগিন তৌরে', // TODO: verify
    },
    'recommendation_label': {
      LanguageService.english: 'Recommendation',
      LanguageService.hindi: 'सिफारिश',
      LanguageService.bengali: 'সুপারিশ',
      LanguageService.assamese: 'পৰামৰ্শ', // TODO: verify
      LanguageService.manipuri: 'চেয়ারবা', // TODO: verify
    },
    'accuracy_trend': {
      LanguageService.english: 'Accuracy Trend',
      LanguageService.hindi: 'सटीकता प्रवृत्ति',
      LanguageService.bengali: 'নির্ভুলতার প্রবণতা',
      LanguageService.assamese: 'শুদ্ধতাৰ প্ৰৱণতা', // TODO: verify
      LanguageService.manipuri: 'অচুম্বা মথৌ', // TODO: verify
    },
    'session_history': {
      LanguageService.english: 'Session History',
      LanguageService.hindi: 'सत्र इतिहास',
      LanguageService.bengali: 'সেশন ইতিহাস',
      LanguageService.assamese: 'ছেছনৰ ইতিহাস', // TODO: verify
      LanguageService.manipuri: 'সেসনগী ৱারী', // TODO: verify
    },
    'no_sessions_yet': {
      LanguageService.english: 'No sessions recorded yet.',
      LanguageService.hindi: 'अभी तक कोई सत्र दर्ज नहीं किया गया है।',
      LanguageService.bengali: 'এখনও কোনো সেশন রেকর্ড করা হয়নি।',
      LanguageService.assamese: 'এতিয়ালৈকে কোনো ছেছন লিপিবদ্ধ কৰা হোৱা নাই।', // TODO: verify
      LanguageService.manipuri: 'হৌজিক ফাওবা সেসন য়াওদে।', // TODO: verify
    },
    'switch_to_patient_mode': {
      LanguageService.english: 'Switch to Patient Mode',
      LanguageService.hindi: 'मरीज़ मोड में बदलें',
      LanguageService.bengali: 'রোগী মোডে যান',
      LanguageService.assamese: 'ৰোগী ম’ডলৈ যাওক', // TODO: verify
      LanguageService.manipuri: 'লাইনা মোদদা ওন্নবিয়ু', // TODO: verify
    },
    'switch_patient_tooltip': {
      LanguageService.english: 'Switch Patient',
      LanguageService.hindi: 'मरीज़ बदलें',
      LanguageService.bengali: 'রোগী পরিবর্তন করুন',
      LanguageService.assamese: 'ৰোগী সলনি কৰক', // TODO: verify
      LanguageService.manipuri: 'লাইনা হোংদোক্কু', // TODO: verify
    },

    // ===== Reminders Screen =====
    'reminders_title': {
      LanguageService.english: 'Reminders',
      LanguageService.hindi: 'रिमाइंडर',
      LanguageService.bengali: 'রিমাইন্ডার',
      LanguageService.assamese: 'মনত পেলোৱা', // TODO: verify
      LanguageService.manipuri: 'নীংশিংহনবা', // TODO: verify
    },
    'no_reminders_yet': {
      LanguageService.english: 'No reminders yet',
      LanguageService.hindi: 'अभी तक कोई रिमाइंडर नहीं',
      LanguageService.bengali: 'এখনও কোনো রিমাইন্ডার নেই',
      LanguageService.assamese: 'এতিয়ালৈকে কোনো মনত পেলোৱা নাই', // TODO: verify
      LanguageService.manipuri: 'হৌজিক নীংশিংহনবা য়াওদে', // TODO: verify
    },
    'tap_add_reminder': {
      LanguageService.english: 'Tap "Add Reminder" below to set one up.',
      LanguageService.hindi: 'एक सेट करने के लिए नीचे "रिमाइंडर जोड़ें" पर टैप करें।',
      LanguageService.bengali: 'একটি সেট আপ করতে নীচে "রিমাইন্ডার যোগ করুন" এ আলতো চাপুন।',
      LanguageService.assamese: 'এটা ছেট আপ কৰিবলৈ তলত "মনত পেলোৱা যোগ কৰক" টিপক।', // TODO: verify
      LanguageService.manipuri: 'অমা শেমগৎনবা মখাদা "নীংশিংহনবা হাপচিনবিয়ু" অদু তেপ তৌবিয়ু।', // TODO: verify
    },
    'add_reminder_button': {
      LanguageService.english: 'Add Reminder',
      LanguageService.hindi: 'रिमाइंडर जोड़ें',
      LanguageService.bengali: 'রিমাইন্ডার যোগ করুন',
      LanguageService.assamese: 'মনত পেলোৱা যোগ কৰক', // TODO: verify
      LanguageService.manipuri: 'নীংশিংহনবা হাপচিনবিয়ু', // TODO: verify
    },

    // ===== Personal Memories (Manage) =====
    'personal_memories_manage_title': {
      LanguageService.english: 'Personal Memories',
      LanguageService.hindi: 'व्यक्तिगत यादें',
      LanguageService.bengali: 'ব্যক্তিগত স্মৃতি',
      LanguageService.assamese: 'ব্যক্তিগত স্মৃতি', // TODO: verify
      LanguageService.manipuri: 'নীংশিংফম', // TODO: verify
    },
    'add_memory_button': {
      LanguageService.english: 'Add Memory',
      LanguageService.hindi: 'याद जोड़ें',
      LanguageService.bengali: 'স্মৃতি যোগ করুন',
      LanguageService.assamese: 'স্মৃতি যোগ কৰক', // TODO: verify
      LanguageService.manipuri: 'নীংশিংফম হাপচিনবিয়ু', // TODO: verify
    },
    'add_first_memory_button': {
      LanguageService.english: 'Add First Memory',
      LanguageService.hindi: 'पहली याद जोड़ें',
      LanguageService.bengali: 'প্রথম স্মৃতি যোগ করুন',
      LanguageService.assamese: 'প্ৰথম স্মৃতি যোগ কৰক', // TODO: verify
      LanguageService.manipuri: 'অহানবা নীংশিংফম হাপচিনবিয়ু', // TODO: verify
    },
    'no_memories_yet': {
      LanguageService.english: 'No Memories Yet',
      LanguageService.hindi: 'अभी तक कोई याद नहीं',
      LanguageService.bengali: 'এখনও কোনো স্মৃতি নেই',
      LanguageService.assamese: 'এতিয়ালৈকে কোনো স্মৃতি নাই', // TODO: verify
      LanguageService.manipuri: 'হৌজিক নীংশিংফম য়াওদে', // TODO: verify
    },
    'no_patient_selected': {
      LanguageService.english: 'No Patient Selected',
      LanguageService.hindi: 'कोई मरीज़ चयनित नहीं',
      LanguageService.bengali: 'কোনো রোগী নির্বাচিত হয়নি',
      LanguageService.assamese: 'কোনো ৰোগী বাছনি কৰা হোৱা নাই', // TODO: verify
      LanguageService.manipuri: 'লাইনা খল্লবা য়াওদে', // TODO: verify
    },
    'select_patient_button': {
      LanguageService.english: 'Select Patient',
      LanguageService.hindi: 'मरीज़ चुनें',
      LanguageService.bengali: 'রোগী নির্বাচন করুন',
      LanguageService.assamese: 'ৰোগী বাছক', // TODO: verify
      LanguageService.manipuri: 'লাইনা খল্লু', // TODO: verify
    },
    'edit_button': {
      LanguageService.english: 'Edit',
      LanguageService.hindi: 'संपादित करें',
      LanguageService.bengali: 'সম্পাদনা করুন',
      LanguageService.assamese: 'সম্পাদনা কৰক', // TODO: verify
      LanguageService.manipuri: 'শেমদোক্কু', // TODO: verify
    },
    'delete_button': {
      LanguageService.english: 'Delete',
      LanguageService.hindi: 'हटाएं',
      LanguageService.bengali: 'মুছুন',
      LanguageService.assamese: 'মচি পেলাওক', // TODO: verify
      LanguageService.manipuri: 'মানথোকপিয়ু', // TODO: verify
    },

    // ===== Memory Match, Trip Itinerary, Personal Memories =====
    // NOTE: scoped to English + Assamese only, per request. Other
    // languages will fall back to English for these specific keys.
    'round_complete': {
      LanguageService.english: 'Round Complete!',
      LanguageService.assamese: 'ৰাউণ্ড সম্পূৰ্ণ!', // TODO: verify
    },
    'score_label': {
      LanguageService.english: 'Score',
      LanguageService.assamese: 'স্ক\'ৰ', // TODO: verify
    },
    'moves_label': {
      LanguageService.english: 'Moves',
      LanguageService.assamese: 'চাল', // TODO: verify
    },
    'time_label': {
      LanguageService.english: 'Time',
      LanguageService.assamese: 'সময়', // TODO: verify
    },
    'how_you_did_label': {
      LanguageService.english: 'How you did',
      LanguageService.assamese: 'আপুনি কেনেকৈ কৰিলে', // TODO: verify
    },
    'play_again_button': {
      LanguageService.english: 'Play Again',
      LanguageService.assamese: 'পুনৰ খেলক', // TODO: verify
    },
    'back_to_games_button': {
      LanguageService.english: 'Back to Games',
      LanguageService.assamese: 'খেলবোৰলৈ উভতি যাওক', // TODO: verify
    },
    'back_to_menu_button': {
      LanguageService.english: 'Back to Menu',
      LanguageService.assamese: 'মেনুলৈ উভতি যাওক', // TODO: verify
    },
    'wonderful_label': {
      LanguageService.english: 'Wonderful!',
      LanguageService.assamese: 'বঢ়ৎ সুন্দৰ!', // TODO: verify
    },
    'well_done_label': {
      LanguageService.english: 'Well Done!',
      LanguageService.assamese: 'ভাল কৰিলে!', // TODO: verify
    },
    'good_try_label': {
      LanguageService.english: 'Good Try!',
      LanguageService.assamese: 'ভাল চেষ্টা!', // TODO: verify
    },

    // Trip Itinerary specific
    'trip_itinerary_recall_title': {
      LanguageService.english: 'Trip Itinerary Recall',
      LanguageService.assamese: 'ভ্ৰমণ সূচী মনত পেলোৱা', // TODO: verify
    },
    'choose_state_to_visit': {
      LanguageService.english: 'Choose a State to Visit',
      LanguageService.assamese: 'ভ্ৰমণ কৰিবলৈ এখন ৰাজ্য বাছক', // TODO: verify
    },
    'memorize_trip_instruction': {
      LanguageService.english: 'Memorize the trip! Itinerary will disappear in',
      LanguageService.assamese: 'ভ্ৰমণটো মনত ৰাখক! সূচীখন অদৃশ্য হ\'ব',
    },
    'seconds_suffix': {
      LanguageService.english: 'seconds...',
      LanguageService.assamese: 'ছেকেণ্ডত...', // TODO: verify
    },
    'question_label': {
      LanguageService.english: 'Question',
      LanguageService.assamese: 'প্ৰশ্ন', // TODO: verify
    },
    'of_label': {
      LanguageService.english: 'of',
      LanguageService.assamese: 'ৰ', // TODO: verify
    },
    'correct_label': {
      LanguageService.english: 'Correct',
      LanguageService.assamese: 'শুদ্ধ', // TODO: verify
    },
    'trip_complete_title': {
      LanguageService.english: 'Trip Complete!',
      LanguageService.assamese: 'ভ্ৰমণ সম্পূৰ্ণ!', // TODO: verify
    },
    'correct_answers_label': {
      LanguageService.english: 'Correct Answers',
      LanguageService.assamese: 'শুদ্ধ উত্তৰ', // TODO: verify
    },
    'state_visited_label': {
      LanguageService.english: 'State Visited',
      LanguageService.assamese: 'ভ্ৰমণ কৰা ৰাজ্য', // TODO: verify
    },
    'difficulty_label': {
      LanguageService.english: 'Difficulty',
      LanguageService.assamese: 'কঠিনতা', // TODO: verify
    },
    'ai_adaptive_difficulty_label': {
      LanguageService.english: 'AI Adaptive Difficulty',
      LanguageService.assamese: 'AI অভিযোজিত কঠিনতা', // TODO: verify
    },
    'exit_game_title': {
      LanguageService.english: 'Exit Game?',
      LanguageService.assamese: 'খেল ত্যাগ কৰিবনে?', // TODO: verify
    },
    'exit_game_body': {
      LanguageService.english: 'Your progress will be lost. Are you sure you want to exit?',
      LanguageService.assamese: 'আপোনাৰ অগ্ৰগতি হেৰাই যাব। আপুনি নিশ্চিতনে ওলাব বিচাৰে?', // TODO: verify
    },
    'cancel_button': {
      LanguageService.english: 'Cancel',
      LanguageService.assamese: 'বাতিল কৰক', // TODO: verify
    },
    'exit_button': {
      LanguageService.english: 'Exit',
      LanguageService.assamese: 'বাহিৰ ওলাওক', // TODO: verify
    },
    'perfect_recall_message': {
      LanguageService.english: 'Perfect recall! You remembered the whole trip perfectly.',
      LanguageService.assamese: 'নিখুঁত স্মৃতি! আপুনি গোটেই ভ্ৰমণটো নিখুঁতভাৱে মনত ৰাখিছিল।', // TODO: verify
    },
    'great_memory_message': {
      LanguageService.english: 'Great memory! You remembered most of the trip.',
      LanguageService.assamese: 'বৰ ভাল স্মৃতি! আপুনি ভ্ৰমণৰ বেছিভাগেই মনত ৰাখিছিল।', // TODO: verify
    },
    'good_effort_message': {
      LanguageService.english: 'Good effort! A few parts of the trip were tricky.',
      LanguageService.assamese: 'ভাল প্ৰচেষ্টা! ভ্ৰমণৰ কিছুমান অংশ কঠিন আছিল।', // TODO: verify
    },
    'tough_trip_message': {
      LanguageService.english: 'That was a tough trip to remember — let\'s try an easier one next time.',
      LanguageService.assamese: 'সেইটো মনত ৰখা কঠিন ভ্ৰমণ আছিল — পিছৰবাৰ এটা সহজ চেষ্টা কৰোঁ আহক।', // TODO: verify
    },

    // Personal Memories (Play) specific
    'no_memories_added_message': {
      LanguageService.english: 'No memories added yet. Ask your caregiver to add some personal photos!',
      LanguageService.assamese: 'এতিয়ালৈকে কোনো স্মৃতি যোগ কৰা হোৱা নাই। আপোনাৰ যত্নকাৰীক কিছুমান ব্যক্তিগত ফটো যোগ কৰিবলৈ কওক!', // TODO: verify
    },
    'go_back_button': {
      LanguageService.english: 'Go Back',
      LanguageService.assamese: 'উভতি যাওক', // TODO: verify
    },
    'lets_look_at_memories': {
      LanguageService.english: "Let's look at some memories together",
      LanguageService.assamese: 'আহক একেলগে কিছুমান স্মৃতি চাওঁ', // TODO: verify
    },
    'playing_for_label': {
      LanguageService.english: 'Playing for',
      LanguageService.assamese: 'ৰ বাবে খেলি আছে', // TODO: verify
    },
    'lets_begin_button': {
      LanguageService.english: "Let's Begin",
      LanguageService.assamese: 'আৰম্ভ কৰোঁ আহক', // TODO: verify
    },
    'i_dont_remember_option': {
      LanguageService.english: "I don't remember",
      LanguageService.assamese: 'মোৰ মনত নাই', // TODO: verify
    },
    'feedback_idk': {
      LanguageService.english: "That's perfectly okay! 🤗",
      LanguageService.assamese: 'সেয়া একেবাৰে ঠিক আছে! 🤗', // TODO: verify
    },
    'feedback_correct': {
      LanguageService.english: "That's right! 🌟",
      LanguageService.assamese: 'সেয়া শুদ্ধ! 🌟', // TODO: verify
    },
    'feedback_incorrect': {
      LanguageService.english: "That's okay! 💛",
      LanguageService.assamese: 'ঠিক আছে! 💛', // TODO: verify
    },
    'the_answer_is_label': {
      LanguageService.english: 'The answer is',
      LanguageService.assamese: 'উত্তৰটো হ\'ল', // TODO: verify
    },
    'next_memory_button': {
      LanguageService.english: 'Next Memory →',
      LanguageService.assamese: 'পিছৰ স্মৃতি →', // TODO: verify
    },
    'thank_you_sharing_message': {
      LanguageService.english: 'Thank you for sharing these memories today! 💝',
      LanguageService.assamese: 'আজি এই স্মৃতিবোৰ ভাগ কৰাৰ বাবে ধন্যবাদ! 💝', // TODO: verify
    },
    'every_memory_precious_message': {
      LanguageService.english: 'Every memory is precious 🌟',
      LanguageService.assamese: 'প্ৰতিটো স্মৃতিয়েই মূল্যৱান 🌟', // TODO: verify
    },
    'done_button': {
      LanguageService.english: 'Done',
      LanguageService.assamese: 'সম্পূৰ্ণ হ\'ল', // TODO: verify
    },
  };

  /// Get the translated string for [key] in the current language.
  /// Falls back to English if the language or key is missing, so a
  /// gap in translation never shows blank text.
  static String t(String key) {
    final entry = _strings[key];
    if (entry == null) return key; // missing key — surfaces the bug loudly
    return entry[languageService.currentLanguage] ?? entry[LanguageService.english] ?? key;
  }
}
