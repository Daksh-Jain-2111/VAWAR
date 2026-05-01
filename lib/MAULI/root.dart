import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'dart:math';

// Knowledge Base
const Map<String, Map<String, String>> knowledgeBase = {
  "Plant Disease Detection": {
    "What causes leaf spot in plants?":
        "Leaf spot is caused by fungi or bacteria infecting the leaf tissue.",
    "How do I identify powdery mildew?":
        "Powdery mildew appears as white powdery spots on leaves and stems.",
    "What is root rot?":
        "Root rot is a fungal disease caused by overwatering and poor drainage.",
    "Can plant diseases spread to other plants?":
        "Yes, many diseases are contagious and spread via air, water, or contact.",
    "How do I treat fungal infections in plants?":
        "Use fungicides and remove infected parts to prevent spread.",
    "What are signs of bacterial wilt?":
        "Sudden wilting, yellowing, and brown streaks in stems are common signs.",
    "How can I prevent viral diseases in crops?":
        "Control insect vectors and use virus-resistant varieties.",
    "What is blight?":
        "Blight causes rapid browning and death of plant tissues, often due to fungi.",
    "Are there natural remedies for plant diseases?":
        "Neem oil, baking soda, and garlic sprays can help control some diseases.",
    "How does humidity affect plant diseases?":
        "High humidity promotes fungal and bacterial growth.",
    "What is damping-off disease?":
        "It affects seedlings, causing them to collapse due to fungal infection.",
    "Can soil transmit plant diseases?":
        "Yes, pathogens in soil can infect roots and lower stems.",
    "How do I disinfect gardening tools?":
        "Use bleach or alcohol to clean tools after use.",
    "What is anthracnose?":
        "A fungal disease causing dark lesions on leaves, stems, and fruits.",
    "How do I detect rust disease?":
        "Rust appears as orange or brown pustules on leaves.",
    "What is mosaic virus?":
        "It causes mottled, distorted leaves and stunted growth.",
    "Can insects spread plant diseases?":
        "Yes, aphids, whiteflies, and beetles are common vectors.",
    "How do I improve plant immunity?":
        "Use balanced fertilizers and avoid stress conditions.",
    "What is downy mildew?":
        "It causes yellow patches and fuzzy growth on leaf undersides.",
    "How do I manage nematodes?":
        "Use crop rotation and nematicides to reduce nematode populations.",
    "What is the role of crop rotation in disease prevention?":
        "It disrupts pathogen life cycles and reduces buildup.",
    "Can compost spread disease?":
        "If not properly decomposed, compost can harbor pathogens.",
    "What are systemic fungicides?":
        "They are absorbed by plants and protect from internal fungal infections.",
    "How do I identify canker disease?":
        "Cankers are sunken, dead areas on stems or branches.",
    "What is phytophthora?":
        "A water mold causing root and crown rot in many plants.",
    "How do I prevent black spot on roses?":
        "Ensure good air circulation and apply fungicides regularly.",
    "What is bacterial leaf streak?":
        "It causes translucent streaks on leaves, often in cereals.",
    "Can pruning help control disease?":
        "Yes, removing infected parts reduces spread.",
    "What is fusarium wilt?":
        "A soil-borne fungus causing yellowing and wilting.",
    "How do I identify viral infections?":
        "Look for mosaic patterns, leaf curling, and stunted growth.",
    "What is clubroot?":
        "A disease causing swollen, deformed roots in brassicas.",
    "Can weather changes trigger disease outbreaks?":
        "Yes, sudden humidity or temperature shifts can promote disease.",
    "What is scab disease?":
        "It causes rough, scabby lesions on fruits and tubers.",
    "How do I prevent disease in seedlings?":
        "Use sterile soil and avoid overwatering.",
    "What is bacterial soft rot?":
        "It causes mushy, foul-smelling decay in vegetables.",
    "Can mulch help prevent disease?":
        "Yes, it reduces soil splash and maintains moisture balance.",
    "What is verticillium wilt?":
        "A fungal disease causing leaf yellowing and branch dieback.",
    "How do I identify crown gall?":
        "Look for tumor-like growths near the soil line.",
    "What is the role of resistant varieties?":
        "They reduce susceptibility to specific diseases.",
    "Can overfertilization cause disease?":
        "Yes, excess nitrogen can promote soft growth prone to infection.",
  },
  "Market Price Prediction": {
    "What is the current price of wheat?":
        "The current price of wheat is \$250 per 10kg.",
    "How do market trends affect prices?":
        "Market trends influence supply and demand, affecting prices.",
    "What factors influence crop prices?":
        "Weather, demand, global markets, and government policies.",
    "How does inflation impact agricultural prices?":
        "Inflation raises input costs, which can increase crop prices.",
    "What is price volatility?":
        "Frequent and unpredictable changes in market prices.",
    "How do international markets affect local prices?":
        "Global supply and demand can influence domestic pricing.",
    "What is futures trading in agriculture?":
        "Contracts to buy/sell crops at a future date at a set price.",
    "How do subsidies affect crop prices?":
        "Subsidies can stabilize or distort market prices.",
    "What is MSP (Minimum Support Price)?":
        "A government-set price to protect farmers from market fluctuations.",
    "How does weather forecasting help price prediction?":
        "It helps anticipate supply changes due to climate impacts.",
    "What is demand forecasting?":
        "Predicting future consumer demand to guide pricing.",
    "How do pests affect market prices?":
        "Crop damage reduces supply, increasing prices.",
    "What is supply chain disruption?":
        "Interruptions in transport or logistics that affect availability.",
    "How do fuel prices affect crop pricing?":
        "Higher fuel costs increase transportation and production expenses.",
    "What is seasonal pricing?":
        "Prices fluctuate based on harvest cycles and availability.",
    "How do exports influence domestic prices?":
        "Increased exports can reduce local supply, raising prices.",
    "What is price elasticity?": "How sensitive demand is to changes in price.",
    "How do storage facilities affect pricing?":
        "Better storage reduces spoilage and stabilizes prices.",
    "What is a price index?":
        "A statistical measure of price changes over time.",
    "How do government policies affect pricing?":
        "Tariffs, quotas, and regulations can shift market dynamics.",
    "What is crop insurance?":
        "Protection against losses due to price drops or disasters.",
    "How do labor costs affect crop prices?":
        "Higher wages increase production costs and final prices.",
    "What is market equilibrium?": "The price point where supply meets demand.",
    "How do digital platforms affect pricing?":
        "They improve transparency and reduce middlemen.",
    "What is price forecasting software?":
        "Tools that use data to predict future prices.",
    "How do consumer preferences affect prices?":
        "Shifts in demand for organic or local produce impact pricing.",
    "What is hedging in agriculture?":
        "Using financial tools to protect against price fluctuations.",
    "How do natural disasters affect prices?":
        "They reduce supply, often causing price spikes.",
    "What is real-time pricing?":
        "Live updates of market prices based on current data.",
    "How do interest rates affect agricultural pricing?":
        "They influence borrowing costs and investment in farming.",
    "What is a commodity exchange?":
        "A marketplace for trading agricultural goods.",
    "How do crop yields affect pricing?":
        "Higher yields increase supply, often lowering prices.",
    "What is predictive analytics?":
        "Using data models to forecast future trends.",
    "How do import restrictions affect pricing?":
        "They limit supply and can raise prices.",
    "What is market saturation?": "Too much supply leading to falling prices.",
    "How do climate patterns affect pricing?":
        "Droughts or floods can disrupt supply and raise prices.",
    "What is price arbitrage?":
        "Buying low in one market and selling high in another.",
    "How do taxes affect agricultural pricing?":
        "They add to production costs and influence final prices.",
    "What is the role of middlemen in pricing?":
        "They can inflate prices between producers and consumers.",
    "How do crop diseases affect market prices?":
        "Reduced yields lead to scarcity and higher prices.",
  },
  "Crop Recommendation System": {
    "Which crops grow best in sandy soil?":
        "Crops like carrots, peanuts, and watermelon thrive in sandy soil.",
    "What crops are suitable for clay soil?":
        "Rice, soybean, and wheat perform well in clay-rich soils.",
    "How do I choose crops for acidic soil?":
        "Sweet potatoes, blueberries, and tea tolerate acidic conditions.",
    "What crops are ideal for loamy soil?":
        "Loamy soil supports maize, pulses, and vegetables like tomatoes.",
    "Which crops are drought-resistant?":
        "Millets, sorghum, and chickpeas are known for drought tolerance.",
    "What crops grow well in high rainfall areas?":
        "Rice, jute, and rubber are suited for regions with heavy rainfall.",
    "Which crops are best for summer season?":
        "Groundnut, sunflower, and maize are good summer crops.",
    "What crops are suitable for winter season?":
        "Wheat, mustard, and peas grow well in cooler climates.",
    "How does soil pH affect crop selection?":
        "Neutral pH favors most crops; acidic or alkaline soils need specific crops.",
    "Which crops are profitable for small farms?":
        "Tomatoes, mushrooms, and herbs offer high returns on small land.",
    "What crops are good for organic farming?":
        "Legumes, leafy greens, and turmeric adapt well to organic methods.",
    "How do I select crops for crop rotation?":
        "Alternate deep-rooted and shallow-rooted crops to balance nutrients.",
    "Which crops fix nitrogen in soil?":
        "Legumes like beans and peas enrich soil with nitrogen.",
    "What crops are suitable for saline soil?":
        "Barley, sugar beet, and cotton tolerate saline conditions.",
    "Which crops grow well in hilly regions?":
        "Tea, coffee, and cardamom are ideal for slopes and altitude.",
    "What crops are best for flood-prone areas?":
        "Rice and taro can survive waterlogged conditions.",
    "How do I choose crops based on market demand?":
        "Analyze local consumption trends and price fluctuations.",
    "Which crops are climate-resilient?":
        "Pearl millet, pigeon pea, and cowpea adapt to climate variability.",
    "What crops are suitable for greenhouse farming?":
        "Tomatoes, cucumbers, and bell peppers thrive in greenhouses.",
    "Which crops require minimal water?":
        "Millets, sesame, and cluster beans need less irrigation.",
    "What crops are ideal for hydroponics?":
        "Lettuce, spinach, and strawberries grow well in hydroponic systems.",
    "Which crops are good for intercropping?":
        "Maize with beans or sugarcane with pulses are common combinations.",
    "How do I choose crops for mixed farming?":
        "Select crops that complement livestock feed and farm needs.",
    "What crops are suitable for vertical farming?":
        "Leafy greens like kale, basil, and arugula are ideal.",
    "Which crops are best for export markets?":
        "Spices, basmati rice, and mangoes have high export value.",
    "How do I choose crops for dryland farming?":
        "Opt for hardy crops like bajra, ragi, and pulses.",
    "What crops are good for cover cropping?":
        "Clover, rye, and vetch protect soil and suppress weeds.",
    "Which crops are suitable for agroforestry?":
        "Banana, turmeric, and ginger grow well under tree cover.",
    "How do I select crops for sustainable farming?":
        "Choose crops that require fewer inputs and improve soil health.",
    "What crops are ideal for terrace farming?":
        "Rice, maize, and beans are commonly grown on terraces.",
    "Which crops are good for biofuel production?":
        "Sugarcane, maize, and jatropha are used for biofuels.",
    "How do I choose crops for pest resistance?":
        "Select varieties bred for resistance to local pests.",
    "What crops are suitable for coastal regions?":
        "Coconut, cashew, and rice grow well in coastal climates.",
    "Which crops are good for medicinal use?":
        "Aloe vera, tulsi, and ashwagandha have medicinal properties.",
    "How do I choose crops for high altitude?":
        "Barley, buckwheat, and potatoes are suited for cold climates.",
    "What crops are ideal for urban farming?":
        "Microgreens, lettuce, and cherry tomatoes are popular in cities.",
    "Which crops are good for pollinator support?":
        "Sunflowers, lavender, and clover attract bees and butterflies.",
    "How do I choose crops for soil conservation?":
        "Grasses, legumes, and cover crops help prevent erosion.",
    "What crops are suitable for rainfed agriculture?":
        "Sorghum, finger millet, and pigeon pea perform well without irrigation.",
  },
  "Weather Forecasting": {
    "What is weather forecasting?":
        "It is the prediction of atmospheric conditions such as temperature, rainfall, and wind over a specific period.",
    "How is weather different from climate?":
        "Weather refers to short-term atmospheric conditions, while climate is the long-term average of weather patterns.",
    "What are the main components of weather?":
        "Temperature, humidity, wind speed, precipitation, and atmospheric pressure.",
    "What causes rainfall?":
        "Rainfall occurs when moist air rises, cools, and condenses into water droplets that fall due to gravity.",
    "How does temperature affect crop growth?":
        "Extreme temperatures can stunt growth, reduce yield, or damage crops.",
    "What is humidity and why is it important?":
        "Humidity is the amount of moisture in the air; it affects plant transpiration and disease development.",
    "What is atmospheric pressure?":
        "It is the force exerted by the weight of the air above a surface, influencing weather patterns.",
    "What is the dew point?":
        "The temperature at which air becomes saturated and dew forms.",
    "How does wind affect agriculture?":
        "Wind influences pollination, seed dispersal, and can cause physical damage to crops.",
    "What is a weather alert?":
        "A warning issued to inform about severe weather conditions like storms, floods, or droughts.",
    "How do satellites help in weather forecasting?":
        "They monitor cloud movement, temperature, and precipitation from space.",
    "What is radar used for in meteorology?":
        "Radar detects precipitation intensity and movement, helping track storms.",
    "What is a weather station?":
        "A facility equipped with instruments to measure and record weather data.",
    "What is a weather map?":
        "A visual representation of weather conditions across a region.",
    "What is the role of AI in weather forecasting?":
        "AI improves prediction accuracy by analyzing large datasets and patterns.",
    "How does rainfall prediction help farmers?":
        "It guides irrigation, sowing, and harvesting decisions to avoid crop loss.",
    "What is drought forecasting?":
        "Predicting prolonged dry conditions to help manage water resources.",
    "How does frost affect crops?":
        "Frost can damage plant tissues, especially in sensitive crops like tomatoes and potatoes.",
    "What is a heatwave and its impact on farming?":
        "A prolonged period of high temperatures that can stress crops and reduce yield.",
    "How does cloud cover affect agriculture?":
        "It influences sunlight availability, photosynthesis, and temperature regulation.",
    "What is microclimate forecasting?":
        "Predicting weather at a very local scale, useful for precision farming.",
    "How does weather forecasting reduce crop loss?":
        "It enables timely action against adverse conditions like storms or droughts.",
    "What is seasonal forecasting?":
        "Predicting weather trends for an entire season to guide crop planning.",
    "How does wind speed affect pollination?":
        "High winds can hinder pollination or damage flowers, reducing fruit set.",
    "What is the role of humidity in pest outbreaks?":
        "High humidity can promote fungal growth and pest proliferation.",
    "How do farmers use weather apps?":
        "They check forecasts for rainfall, temperature, and pest alerts to plan activities.",
    "What is a cyclone warning system?":
        "A system that alerts regions about approaching cyclones to minimize damage.",
    "What is a flood forecasting system?":
        "It predicts potential flooding based on rainfall and river data.",
    "What is real-time weather monitoring?":
        "Continuous tracking of weather conditions using sensors and data feeds.",
    "How does weather affect irrigation planning?":
        "Forecasts help schedule irrigation to avoid overwatering or drought stress.",
    "What is the impact of hailstorms on crops?":
        "Hail can physically damage leaves, stems, and fruits, reducing yield.",
    "How do weather forecasts help in pest control?":
        "They predict conditions favorable for pest outbreaks, enabling preventive measures.",
    "What is the role of weather in disease management?":
        "Weather influences the spread of fungal and bacterial diseases in crops.",
    "How do weather data support yield prediction?":
        "It helps model crop growth and estimate harvest outcomes.",
    "What is the importance of UV index in farming?":
        "High UV can damage crops and affect worker safety; low UV may reduce photosynthesis.",
    "How do weather balloons work?":
        "They carry instruments to measure temperature, pressure, and humidity at different altitudes.",
    "What is the role of GIS in weather forecasting?":
        "GIS maps weather data spatially to identify patterns and risks.",
    "How does cloud seeding affect rainfall?":
        "It artificially induces precipitation by dispersing substances into clouds.",
    "What is the impact of weather on soil moisture?":
        "Rainfall and evaporation rates determine soil moisture levels critical for crops.",
    "How does weather forecasting support sustainable farming?":
        "It helps optimize resource use and reduce environmental impact.",
  },
  "Chatbot Assistant": {
    "What is a chatbot assistant?":
        "It is an AI-powered tool that interacts with users through text or voice to provide support and information.",
    "How does a chatbot help farmers?":
        "It answers queries about crops, weather, pests, and market prices instantly.",
    "Can a chatbot recommend crops?":
        "Yes, based on soil type, climate, and user preferences.",
    "What is NLP in chatbot systems?":
        "Natural Language Processing enables chatbots to understand and respond to human language.",
    "How do chatbots understand user intent?":
        "They use NLP models to analyze keywords, context, and sentence structure.",
    "Can chatbots work offline?":
        "Some chatbots are designed to work via SMS or local apps without internet.",
    "How do chatbots improve farm productivity?":
        "They provide timely, accurate information for better decision-making.",
    "What platforms support agricultural chatbots?":
        "WhatsApp, Telegram, web apps, and mobile apps are commonly used.",
    "Can chatbots detect crop diseases?":
        "With image input and AI models, they can identify common plant diseases.",
    "How do chatbots handle multiple languages?":
        "They are trained in regional languages using multilingual NLP models.",
    "What is the role of machine learning in chatbots?":
        "It helps chatbots learn from interactions and improve responses over time.",
    "Can chatbots provide market price updates?":
        "Yes, they can fetch real-time data from market APIs.",
    "How do chatbots support weather alerts?":
        "They send notifications about rainfall, storms, or droughts.",
    "Can chatbots schedule farming tasks?":
        "Advanced bots can integrate with calendars and reminders.",
    "Are chatbots secure for data sharing?":
        "Yes, with proper encryption and privacy protocols.",
    "How do chatbots handle user feedback?":
        "They log responses and adapt answers based on user ratings and corrections.",
    "Can chatbots assist in fertilizer recommendations?":
        "Yes, based on soil tests and crop type.",
    "What is a conversational UI?":
        "It’s a user interface that mimics human conversation for interaction.",
    "How do chatbots manage FAQs?":
        "They use predefined responses and machine learning to answer frequently asked questions.",
    "Can chatbots be integrated with sensors?":
        "Yes, they can pull data from IoT devices for real-time updates.",
    "What is the difference between rule-based and AI chatbots?":
        "Rule-based bots follow scripts; AI bots learn and adapt from data.",
    "How do chatbots handle spelling errors?":
        "They use fuzzy matching and NLP to interpret misspelled words.",
    "Can chatbots support voice input?":
        "Yes, many modern bots accept voice commands and respond verbally.",
    "How do chatbots help in pest management?":
        "They provide alerts and solutions based on pest identification and weather conditions.",
    "What is chatbot training data?":
        "It’s the dataset used to teach the bot how to respond accurately.",
    "How do chatbots personalize responses?":
        "They use user history, preferences, and location to tailor replies.",
    "Can chatbots be used in e-commerce?":
        "Yes, they assist with product queries, orders, and customer support.",
    "What is fallback response in chatbots?":
        "A default reply when the bot doesn’t understand the query.",
    "How do chatbots handle multiple users?":
        "They manage sessions and context for each user independently.",
    "Can chatbots be used in education?":
        "Yes, they help with tutoring, FAQs, and interactive learning.",
    "What is chatbot analytics?":
        "It tracks user interactions, satisfaction, and performance metrics.",
    "How do chatbots support government schemes?":
        "They inform users about eligibility, application steps, and deadlines.",
    "Can chatbots translate languages?":
        "Yes, with integrated translation APIs or multilingual models.",
    "How do chatbots handle emotional tone?":
        "Advanced bots use sentiment analysis to adjust responses empathetically.",
    "What is chatbot onboarding?":
        "It’s the initial interaction that introduces users to the bot’s capabilities.",
    "Can chatbots be used for surveys?":
        "Yes, they collect responses and analyze feedback efficiently.",
    "How do chatbots handle image input?":
        "They use computer vision models to interpret and respond to images.",
    "What is chatbot escalation?":
        "Transferring the conversation to a human agent when needed.",
    "Can chatbots be customized for regions?":
        "Yes, they can be localized with language, crops, and cultural context.",
    "How do chatbots support sustainable farming?":
        "They promote eco-friendly practices and resource-efficient techniques.",
    "What is the future of chatbot assistants in agriculture?":
        "They will become more intelligent, multilingual, and integrated with smart farming systems.",
    "Who are you":
        "I am Mauli By VAWAR available to help and guide you through your agri- journey",
    "Who are you ":
        "I am Mauli By VAWAR available to help and guide you through your agri- journey",
    "who are you":
        "I am Mauli By VAWAR available to help and guide you through your agri- journey",
    "who are you ":
        "I am Mauli By VAWAR available to help and guide you through your agri- journey",
    "Who are you?":
        "I am Mauli By VAWAR available to help and guide you through your agri- journey",
    "Who are you ?":
        "I am Mauli By VAWAR available to help and guide you through your agri- journey",
    "who are you?":
        "I am Mauli By VAWAR available to help and guide you through your agri- journey",
    "who are you ?":
        "I am Mauli By VAWAR available to help and guide you through your agri- journey",
    "who are u":
        "I am Mauli By VAWAR available to help and guide you through your agri- journey",
    "your name":
        "I am Mauli By VAWAR available to help and guide you through your agri- journey",
    "Hii": "Hello! How can I assist you today in your agricultural journey?",
  },
};

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light
          ? ThemeMode.dark
          : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MAULI',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4CAF50), // Green for light theme
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.poppinsTextTheme().copyWith(
          bodyLarge: GoogleFonts.poppins(color: Colors.black),
          bodyMedium: GoogleFonts.poppins(color: Colors.black),
          titleLarge: GoogleFonts.poppins(color: Colors.black),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B5E20), // Dark green for dark theme
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme)
            .copyWith(
              bodyLarge: GoogleFonts.poppins(color: Colors.white),
              bodyMedium: GoogleFonts.poppins(color: Colors.white),
              titleLarge: GoogleFonts.poppins(color: Colors.white),
            ),
      ),
      themeMode: _themeMode,
      home: ChatScreen(onToggleTheme: _toggleTheme),
    );
  }
}

class ChatScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;

  const ChatScreen({super.key, required this.onToggleTheme});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _serverUrlController = TextEditingController();
  final List<Widget> _messages = [];
  late stt.SpeechToText _speech;
  String _selectedModule = "Select a Module";
  late Connectivity _connectivity;
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  bool _isOnline = true;
  late Random _random;
  List<String> _defaultQuestions = [];
  late List<String> _allQuestions;
  // Default server URL - change to your PC's IP address
  // Format: http://192.168.1.X:8080 (your computer's local IP)
  // The server IP will be auto-detected on startup
  String _ollamaBaseUrl = 'http://10.123.78.6:8080';
  bool _serverDetected = false;

  // Auto-detect server IP by fetching from the server's /ip endpoint
  Future<void> _autoDetectServerIP() async {
    print('Starting fast server IP detection...');

    // Get local network info to determine likely subnet
    // Then do a quick scan of the most likely IPs (1-20 range)
    final likelyPrefixes = [
      'http://10.116.7.',
      'http://192.168.1.',
      'http://192.168.0.',
    ];

    // Quick scan: try just the first 20 IPs (most common router setups)
    for (var prefix in likelyPrefixes) {
      // Try multiple IPs in parallel using Future.wait
      List<Future<dynamic>> futures = [];
      for (int i = 1; i <= 20; i++) {
        futures.add(_tryServer('$prefix$i:8080'));
      }

      try {
        final results = await Future.wait(futures);
        for (var result in results) {
          if (result != null) {
            setState(() {
              _ollamaBaseUrl = result;
              _serverDetected = true;
            });
            print('SUCCESS! Auto-detected server at: $_ollamaBaseUrl');
            await _verifyServerConnection();
            return;
          }
        }
      } catch (e) {
        print('Scan error: $e');
      }
    }

    // If quick scan fails, show dialog for manual input
    print('Could not auto-detect server. Showing manual input...');
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showServerUrlDialog();
      });
    }
  }

  // Try a single server IP
  Future<String?> _tryServer(String url) async {
    try {
      final response = await http
          .get(Uri.parse('$url/ip'))
          .timeout(const Duration(milliseconds: 500));
      if (response.statusCode == 200 && response.body.isNotEmpty) {
        return url;
      }
    } catch (e) {
      // Silently continue to next IP
    }
    return null;
  }

  // Verify server connection with health check
  Future<void> _verifyServerConnection() async {
    try {
      final healthUrl = Uri.parse('$_ollamaBaseUrl/api/health');
      final response = await http
          .get(healthUrl)
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Server health check: ${data['status']}');
        print('Ollama URL: ${data['ollamaUrl']}');
      }
    } catch (e) {
      print('Health check failed: $e');
    }
  }

  final List<String> _modules = [
    "Select a Module",
    "Plant Disease Detection",
    "Market Price Prediction",
    "Crop Recommendation System",
    "Weather Forecasting",
    "Chatbot Assistant",
  ];

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _connectivity = Connectivity();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _updateConnectionStatus,
    );
    _checkInitialConnectivity();
    _random = Random();
    _allQuestions = [];
    for (var module in knowledgeBase.keys) {
      _allQuestions.addAll(knowledgeBase[module]!.keys);
    }
    _allQuestions.shuffle(_random);
    _defaultQuestions = _allQuestions.take(3).toList();

    // Auto-detect server IP on startup
    _autoDetectServerIP();
  }

  void _checkInitialConnectivity() async {
    var results = await _connectivity.checkConnectivity();
    _updateConnectionStatus(results);
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    setState(() {
      _isOnline = results.any((result) => result != ConnectivityResult.none);
    });
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  String routeIntent(String text) {
    // Simple routing based on keywords
    if (text.toLowerCase().contains('disease') ||
        text.toLowerCase().contains('plant') ||
        text.toLowerCase().contains('fungus') ||
        text.toLowerCase().contains('bacteria')) {
      return "MAULI";
    } else if (text.toLowerCase().contains('price') ||
        text.toLowerCase().contains('market') ||
        text.toLowerCase().contains('cost') ||
        text.toLowerCase().contains('sell')) {
      return "MAULI";
    } else if (text.toLowerCase().contains('crop') ||
        text.toLowerCase().contains('recommend') ||
        text.toLowerCase().contains('soil') ||
        text.toLowerCase().contains('grow')) {
      return "MAULI";
    } else if (text.toLowerCase().contains('weather') ||
        text.toLowerCase().contains('forecast') ||
        text.toLowerCase().contains('rain') ||
        text.toLowerCase().contains('temperature')) {
      return "MAULI";
    } else {
      return "MAULI";
    }
  }

  String findBestAnswer(String question) {
    // First try exact match (case-insensitive, trim whitespace)
    String normalizedQuestion = question.trim().toLowerCase();

    for (var module in knowledgeBase.keys) {
      for (var kbQuestion in knowledgeBase[module]!.keys) {
        if (kbQuestion.trim().toLowerCase() == normalizedQuestion) {
          return knowledgeBase[module]![kbQuestion]!;
        }
      }
    }
    // Fallback - return empty to trigger online API
    return "";
  }

  // Store conversation history for better context
  final List<Map<String, String>> _conversationHistory = [];

  // Stream response handler for real-time response generation
  Stream<String> _streamOllamaResponse(String prompt) async* {
    try {
      // Add user message to conversation history
      _conversationHistory.add({'role': 'user', 'content': prompt});

      final url = Uri.parse('$_ollamaBaseUrl/api/chat');

      // Create a client for streaming
      final client = http.Client();

      try {
        final request = http.Request('POST', url);
        request.headers['Content-Type'] = 'application/json';
        request.body = jsonEncode({
          'model': 'phi3:mini',
          'messages': _conversationHistory,
          'stream': true,
        });

        final streamedResponse = await client
            .send(request)
            .timeout(const Duration(seconds: 180));

        if (streamedResponse.statusCode == 200) {
          String fullResponse = '';

          await for (final chunk in streamedResponse.stream.transform(
            utf8.decoder,
          )) {
            // Parse SSE format: data: {"message":...}\n\n
            final lines = chunk.split('\n');
            for (final line in lines) {
              if (line.startsWith('data: ')) {
                try {
                  final jsonStr = line.substring(6); // Remove 'data: ' prefix
                  if (jsonStr.trim().isEmpty) continue;

                  final data = jsonDecode(jsonStr);
                  final message = data['message'] ?? {};
                  final content = message['content'] ?? '';

                  if (content.isNotEmpty) {
                    fullResponse += content;
                    yield content;
                  }

                  // Check if done
                  if (data['done'] == true) {
                    break;
                  }
                } catch (e) {
                  // Skip malformed JSON
                }
              }
            }
          }

          // Add assistant response to conversation history
          _conversationHistory.add({
            'role': 'assistant',
            'content': fullResponse,
          });
        } else {
          yield 'Sorry, I\'m having trouble connecting to the server. Please try again later. (Error: ${streamedResponse.statusCode})';
        }
      } finally {
        client.close();
      }
    } catch (e) {
      // Return a user-friendly error message
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused')) {
        yield 'Unable to connect to the server. Please check if the Ollama service is running on your device.';
      } else if (e.toString().contains('TimeoutException')) {
        yield 'The request timed out. Please check your internet connection and try again.';
      } else {
        yield 'Sorry, something went wrong. Please try again later.';
      }
    }
  }

  Future<String> _callOllama(String prompt) async {
    try {
      // Add user message to conversation history
      _conversationHistory.add({'role': 'user', 'content': prompt});

      final url = Uri.parse('$_ollamaBaseUrl/api/chat');
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'model': 'phi3:mini',
              'messages': _conversationHistory,
              'stream': false,
            }),
          )
          .timeout(const Duration(seconds: 180));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final message = data['message'] ?? {};
        final responseText = message['content'] ?? 'No response';

        // Add assistant response to conversation history
        _conversationHistory.add({
          'role': 'assistant',
          'content': responseText,
        });

        return responseText;
      } else {
        return 'Sorry, I\'m having trouble connecting to the server. Please try again later. (Error: ${response.statusCode})';
      }
    } catch (e) {
      // Return a user-friendly error message
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused')) {
        return 'Unable to connect to the server. Please check if the Ollama service is running on your device.';
      } else if (e.toString().contains('TimeoutException')) {
        return 'The request timed out. Please check your internet connection and try again.';
      } else {
        return 'Sorry, something went wrong. Please try again later.';
      }
    }
  }

  void _sendMessage([String? message]) async {
    String userMessage = message ?? _controller.text;
    if (userMessage.isEmpty) return;

    String module = routeIntent(userMessage);
    String answer = findBestAnswer(userMessage);

    if (message == null) _controller.clear();

    if (answer.isNotEmpty) {
      // OFFLINE: Answer found in knowledge base - show instantly without "Typing..."
      setState(() {
        _messages.add(ChatMessage(text: userMessage, isUser: true));
        _messages.add(ChatMessage(text: answer, isUser: false, module: module));
      });
    } else {
      // ONLINE: Need to call API - create streaming message that shows "Typing..."
      // Create a streaming message widget that will be updated in real-time
      final streamingMessageKey = GlobalKey<StreamingChatMessageState>();

      setState(() {
        _messages.add(ChatMessage(text: userMessage, isUser: true));
        _messages.add(
          StreamingChatMessage(
            key: streamingMessageKey,
            isUser: false,
            module: module,
          ),
        );
      });

      // Use streaming response
      await for (final chunk in _streamOllamaResponse(userMessage)) {
        // Update the streaming message widget with the new chunk
        if (streamingMessageKey.currentState != null) {
          streamingMessageKey.currentState!.addChunk(chunk);
        }
      }
    }

    setState(() {
      // Refresh default questions after sending a message
      _allQuestions.shuffle(_random);
      _defaultQuestions = _allQuestions.take(3).toList();
    });
  }

  void _sendQuickAction(String module) {
    String message = "Tell me about $module";
    setState(() {
      _messages.add(ChatMessage(text: message, isUser: true));
      _messages.add(ChatMessage(text: '', isUser: false, isLoading: true));
    });
    _controller.clear();

    String answer = findBestAnswer(message);
    if (answer.isEmpty) {
      try {
        _sendMessageFromQuickAction(message, module);
      } catch (e) {
        setState(() {
          _messages[_messages.length - 1] = ChatMessage(
            text: 'Error: $e',
            isUser: false,
            module: module,
          );
        });
      }
    } else {
      setState(() {
        _messages[_messages.length - 1] = ChatMessage(
          text: answer,
          isUser: false,
          module: module,
        );
      });
    }
  }

  void _sendMessageFromQuickAction(String message, String module) async {
    try {
      String answer = await _callOllama(message);
      setState(() {
        _messages[_messages.length - 1] = ChatMessage(
          text: answer,
          isUser: false,
          module: module,
        );
      });
    } catch (e) {
      setState(() {
        _messages[_messages.length - 1] = ChatMessage(
          text: 'Error: $e',
          isUser: false,
          module: module,
        );
      });
    }
  }

  void _sendDefaultQuestion() {
    setState(() {
      _messages.add(
        ChatMessage(
          text: "Try asking: ${_defaultQuestions[0]}",
          isUser: false,
          module: "MAULI",
        ),
      );
    });
  }

  void _showServerUrlDialog() {
    _serverUrlController.text = _ollamaBaseUrl;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Server Settings', style: GoogleFonts.poppins()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter the IP address of your computer running Ollama:',
                style: GoogleFonts.poppins(fontSize: 14),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _serverUrlController,
                decoration: InputDecoration(
                  hintText: 'http://10.116.7.8:8080',
                  labelText: 'Server URL',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tip: Run server.dart first, then open Ollama',
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: GoogleFonts.poppins()),
            ),
            ElevatedButton(
              onPressed: () {
                String url = _serverUrlController.text.trim();
                if (url.isNotEmpty) {
                  // Add http:// if not present
                  if (!url.startsWith('http://') &&
                      !url.startsWith('https://')) {
                    url = 'http://$url';
                  }
                  setState(() {
                    _ollamaBaseUrl = url;
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Server URL updated to: $_ollamaBaseUrl'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: Text('Save', style: GoogleFonts.poppins()),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Settings', style: GoogleFonts.poppins(fontSize: 24)),
                  const SizedBox(height: 8),
                  Text(
                    'Server: $_ollamaBaseUrl',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dns),
              title: Text('Server URL', style: GoogleFonts.poppins()),
              subtitle: Text(
                _ollamaBaseUrl,
                style: GoogleFonts.poppins(fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
              onTap: _showServerUrlDialog,
            ),
            const Divider(),
            ListTile(
              title: Text('Selected Module', style: GoogleFonts.poppins()),
              subtitle: DropdownButton<String>(
                value: _selectedModule,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedModule = newValue!;
                  });
                },
                items: _modules.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value, style: GoogleFonts.poppins()),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              color: Theme.of(context).colorScheme.surface,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const CircleAvatar(backgroundImage: AssetImage('mauli.jpg')),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MAULI',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              _isOnline ? 'Online' : 'Offline',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(width: 4.0),
                            Container(
                              width: 8.0,
                              height: 8.0,
                              decoration: BoxDecoration(
                                color: _isOnline ? Colors.green : Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings),
                    onPressed: _showServerUrlDialog,
                  ),
                ],
              ),
            ),
            // Quick Actions - Server Settings Button + Module Buttons
            Container(
              height: 120.0,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  // Module Buttons
                  ..._modules.skip(1).map((module) {
                    return Container(
                      width: 100.0,
                      margin: const EdgeInsets.only(right: 12.0),
                      child: Card(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        child: InkWell(
                          onTap: () => _sendQuickAction(module),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.chat,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer,
                                ),
                                const SizedBox(height: 4.0),
                                Text(
                                  module,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onPrimaryContainer,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
            // Messages
            Expanded(
              child: ListView.builder(
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  return _messages[index];
                },
              ),
            ),
            // Custom Bottom Input
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20.0),
                  topRight: Radius.circular(20.0),
                ),
              ),
              child: Column(
                children: [
                  // Default Question Section
                  Container(
                    height: 60.0,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: _defaultQuestions.map((question) {
                        return Container(
                          width: 120.0,
                          margin: const EdgeInsets.only(right: 8.0),
                          child: Card(
                            color: Theme.of(
                              context,
                            ).colorScheme.primaryContainer,
                            child: InkWell(
                              onTap: () => _sendMessage(question),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Center(
                                  child: Text(
                                    question,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onPrimaryContainer,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.mic),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  VoiceInputScreen(onSendMessage: _sendMessage),
                            ),
                          );
                        },
                      ),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          decoration: InputDecoration(
                            hintText: 'Type your message...',
                            hintStyle: GoogleFonts.poppins(),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                            filled: true,
                            fillColor: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: _sendMessage,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatMessage extends StatelessWidget {
  final String text;
  final bool isUser;
  final String? module;
  final bool isLoading;

  const ChatMessage({
    super.key,
    required this.text,
    required this.isUser,
    this.module,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: isUser
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (module != null && !isUser)
                    Text(
                      module!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  if (isLoading)
                    const CircularProgressIndicator()
                  else
                    Text(
                      text,
                      style: TextStyle(
                        color: isUser
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).textTheme.bodyLarge!.color,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Streaming Chat Message Widget for real-time response display
class StreamingChatMessage extends StatefulWidget {
  final bool isUser;
  final String module;

  const StreamingChatMessage({
    super.key,
    required this.isUser,
    required this.module,
  });

  @override
  State<StreamingChatMessage> createState() => StreamingChatMessageState();
}

class StreamingChatMessageState extends State<StreamingChatMessage> {
  String _displayedText = '';
  String _pendingText = '';
  bool _isComplete = false;
  bool _isLoading = true;
  String? _error;
  Timer? _wordTimer;

  // Delay between each word appearing (in milliseconds)
  static const int _wordDelay = 50;

  // Add a chunk of text to the displayed text (called from streaming)
  void addChunk(String chunk) {
    if (mounted) {
      // Add the new chunk to pending text
      _pendingText += chunk;
      _isLoading = false;

      // Print debug info
      print(
        'Chunk received: ${chunk.length} chars, pending: ${_pendingText.length}',
      );

      // Start the word-by-word animation
      _startWordAnimation();
    }
  }

  // Start animating words one by one
  void _startWordAnimation() {
    // Cancel existing timer if any
    _wordTimer?.cancel();

    // Mark as not complete while animating
    _isComplete = false;

    _wordTimer = Timer.periodic(const Duration(milliseconds: _wordDelay), (
      timer,
    ) {
      if (_pendingText.isEmpty) {
        // No more pending text, check if we should stop
        timer.cancel();
        _wordTimer = null;
        if (mounted) {
          setState(() {
            _isComplete = true;
          });
        }
        return;
      }

      // Find the next word boundary (space or newline)
      int spaceIndex = _pendingText.indexOf(' ');
      int newlineIndex = _pendingText.indexOf('\n');

      // Handle case where there's no space or newline (last word)
      if (spaceIndex == -1 && newlineIndex == -1) {
        // Last word - display it and clear pending
        if (mounted) {
          setState(() {
            _displayedText += _pendingText;
            _pendingText = '';
            _isComplete = true;
          });
        }
        timer.cancel();
        _wordTimer = null;
        return;
      }

      // Determine next boundary
      int nextIndex;
      bool isNewline = false;

      if (spaceIndex == -1) {
        nextIndex = newlineIndex;
        isNewline = true;
      } else if (newlineIndex == -1) {
        nextIndex = spaceIndex;
        isNewline = false;
      } else {
        nextIndex = spaceIndex < newlineIndex ? spaceIndex : newlineIndex;
        isNewline = newlineIndex < spaceIndex;
      }

      // Get the next word including the delimiter
      String word = _pendingText.substring(0, nextIndex + (isNewline ? 1 : 1));

      if (mounted) {
        setState(() {
          _displayedText += word;
          _pendingText = _pendingText.substring(word.length);
        });
      }
    });
  }

  // Set the complete response at once (for non-streaming fallback)
  void setComplete(String fullResponse) {
    _wordTimer?.cancel();
    if (mounted) {
      setState(() {
        _displayedText = fullResponse;
        _pendingText = '';
        _isComplete = true;
        _isLoading = false;
      });
    }
  }

  // Set error message
  void setError(String errorMessage) {
    _wordTimer?.cancel();
    if (mounted) {
      setState(() {
        _error = errorMessage;
        _isLoading = false;
        _isComplete = true;
      });
    }
  }

  @override
  void dispose() {
    _wordTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
      child: Row(
        mainAxisAlignment: widget.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: widget.isUser
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!widget.isUser)
                    Text(
                      widget.module,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  if (_isLoading && !_isComplete)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Typing...',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.color?.withOpacity(0.6),
                          ),
                        ),
                      ],
                    )
                  else if (_error != null)
                    Text(
                      _error!,
                      style: TextStyle(
                        color: Colors.red,
                        fontStyle: FontStyle.italic,
                      ),
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedText(
                          text: _displayedText,
                          style: TextStyle(
                            color: widget.isUser
                                ? Theme.of(context).colorScheme.onPrimary
                                : Theme.of(context).textTheme.bodyLarge!.color,
                          ),
                        ),
                        if (!_isComplete)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 8,
                                  height: 8,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.5,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Animated text widget that shows cursor while typing
class AnimatedText extends StatefulWidget {
  final String text;
  final TextStyle? style;

  const AnimatedText({super.key, required this.text, this.style});

  @override
  State<AnimatedText> createState() => _AnimatedTextState();
}

class _AnimatedTextState extends State<AnimatedText> {
  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        text: widget.text,
        style: widget.style,
        children: const [
          TextSpan(
            text: '▋', // Cursor character
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class VoiceInputScreen extends StatefulWidget {
  final Function(String) onSendMessage;

  const VoiceInputScreen({super.key, required this.onSendMessage});

  @override
  State<VoiceInputScreen> createState() => _VoiceInputScreenState();
}

class _VoiceInputScreenState extends State<VoiceInputScreen> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _text = 'Press the mic to start speaking...';

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => print('onStatus: $val'),
        onError: (val) => print('onError: $val'),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) => setState(() {
            _text = val.recognizedWords;
          }),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  void _sendMessage() {
    if (_text.isNotEmpty && _text != 'Press the mic to start speaking...') {
      widget.onSendMessage(_text);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Voice Input', style: GoogleFonts.poppins())),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _text,
              style: GoogleFonts.poppins(fontSize: 24),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            IconButton(
              icon: Icon(
                _isListening ? Icons.mic_off : Icons.mic,
                size: 64,
                color: _isListening ? Colors.red : null,
              ),
              onPressed: _listen,
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _sendMessage,
              child: Text('Send Message', style: GoogleFonts.poppins()),
            ),
          ],
        ),
      ),
    );
  }
}
