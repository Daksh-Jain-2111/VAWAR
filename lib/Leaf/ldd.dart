import 'package:flutter/material.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:image/image.dart' as img;

class LeafDiseaseDetectionScreen extends StatelessWidget {
  const LeafDiseaseDetectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const HomePage();
  }
}

class HomePage extends StatefulWidget {
  final VoidCallback? onToggleTheme;

  const HomePage({super.key, this.onToggleTheme});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Interpreter? _interpreter;
  List<String> _labels = [];
  bool _isModelLoaded = false;
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  String? _diagnosisResult;
  bool _isProcessing = false;
  String? _selectedDisease;
  double? _confidence;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadModel();
  }

  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('leaf_disease_model.tflite');
      _labels = [
        'Apple scab',
        'Apple Black rot',
        'Cedar apple rust',
        'Apple healthy',
        'Blueberry healthy',
        'Cherry healthy',
        'Cherry Powdery mildew',
        'Corn (maize) Cercospora leaf spot , Gray leaf spot',
        'Corn (maize) Common rust',
        'Corn (maize) healthy',
        'Corn (maize) Northern Leaf Blight',
        'Cotton Healthy',
        'Cotton Unhealthy',
        'Grape Black rot',
        'Grape Esca (Black Measles)',
        'Grape healthy',
        'Grape Leaf blight (Isariopsis Leaf Spot)',
        'Orange Haunglongbing (Citrus greening)',
        'Peach Bacterial spot',
        'Peach healthy',
        'Pepper bell Bacterial spot',
        'Pepper bell healthy',
        'Potato Early blight',
        'Potato healthy',
        'Potato Late_blight',
        'Raspberry healthy',
        'Soybean healthy',
        'Squash Powdery mildew',
        'Strawberry healthy',
        'Strawberry Leaf scorch',
        'Sugarcane Healthy',
        'Sugarcane Mosaic',
        'Sugarcane RedRot',
        'Sugarcane Rust',
        'Sugarcane Yellow',
        'Tomato Bacterial spot',
        'Tomato Early blight',
        'Tomato healthy',
        'Tomato Late blight',
        'Tomato Leaf Mold',
        'Tomato Septoria leaf spot',
        'Tomato Spider mites Two-spotted spider mite',
        'Tomato Target Spot',
        'Tomato mosaic virus',
        'Tomato Yellow Leaf Curl Virus',
      ];
      setState(() {
        _isModelLoaded = true;
        _selectedDisease = _labels.isNotEmpty ? _labels[0] : null;
      });
    } catch (e) {
      print('Error loading model: $e');
    }
  }

  Future<List<List<List<List<double>>>>> _preprocessImage(
    File imageFile,
  ) async {
    final imageBytes = await imageFile.readAsBytes();
    final decodedImage = img.decodeImage(imageBytes);

    if (decodedImage == null) {
      throw Exception('Failed to decode image');
    }

    // Resize to 224x224 (assuming model expects this size)
    final resizedImage = img.copyResize(decodedImage, width: 224, height: 224);

    // Convert to RGB if needed
    final rgbImage = img.copyResize(resizedImage, width: 224, height: 224);

    // Prepare input as [1, 224, 224, 3] normalized to [0, 1]
    final input = List.generate(
      1,
      (batch) => List.generate(
        224,
        (y) => List.generate(224, (x) {
          final pixel = rgbImage.getPixel(x, y);
          return [
            pixel.r / 255.0, // Normalize to [0, 1]
            pixel.g / 255.0,
            pixel.b / 255.0,
          ];
        }),
      ),
    );

    return input;
  }

  Future<Map<String, dynamic>> _runInference(
    List<List<List<List<double>>>> input,
  ) async {
    if (_interpreter == null) {
      throw Exception('Model not loaded');
    }

    // Prepare output tensor (assuming 45 classes)
    final outputShape = [1, 45];
    final output = List.filled(45, 0.0).reshape(outputShape);

    // Run inference
    _interpreter!.run(input, output);

    // Find the class with highest probability
    final probabilities = output[0] as List<double>;
    print('Probabilities: $probabilities');
    final maxIndex = probabilities.indexWhere(
      (prob) => prob == probabilities.reduce((a, b) => a > b ? a : b),
    );
    print('Max index: $maxIndex');

    return {
      'prediction': _labels[maxIndex],
      'confidence': probabilities[maxIndex],
      'allProbabilities': probabilities,
    };
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);
      if (image != null) {
        await _processImage(File(image.path));
      }
    } catch (e) {
      print('Error picking image from camera: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error accessing camera')));
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        await _processImage(File(image.path));
      }
    } catch (e) {
      print('Error picking image from gallery: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error accessing gallery')));
    }
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence > 0.85) {
      return Colors.green;
    } else if (confidence >= 0.60) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  Future<void> _processImage(File imageFile) async {
    setState(() {
      _isProcessing = true;
      _selectedImage = imageFile;
      _diagnosisResult = null;
      _confidence = null;
    });

    try {
      final input = await _preprocessImage(imageFile);
      final result = await _runInference(input);

      setState(() {
        _diagnosisResult = result['prediction'];
        _confidence = result['confidence'];
      });
    } catch (e) {
      print('Error processing image: $e');
      setState(() {
        _diagnosisResult = 'Error processing image. Please try again.';
        _confidence = null;
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  void dispose() {
    _interpreter?.close();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // App Logo
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.eco,
                      color: Theme.of(context).colorScheme.onPrimary,
                      size: 24,
                    ),
                  ),
                  // Greeting Text
                  Text(
                    'VAWAR',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  // Profile and Theme Toggle
                  Row(
                    children: [
                      // Theme Toggle Button
                      IconButton(
                        onPressed: widget.onToggleTheme,
                        icon: Icon(
                          Theme.of(context).brightness == Brightness.light
                              ? Icons.dark_mode
                              : Icons.light_mode,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        tooltip: 'Toggle theme',
                      ),
                      const SizedBox(width: 8),
                      // User Profile Icon
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceVariant,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.person,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Main Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                'Leaf Diagnosis',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),

            // Tabs
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(
                      context,
                    ).colorScheme.shadow.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Theme.of(context).colorScheme.onPrimary,
                unselectedLabelColor: Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant,
                tabs: const [
                  Tab(text: 'Scan Leaf'),
                  Tab(text: 'Treatment'),
                ],
              ),
            ),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Scan Leaf Tab
                  _buildScanTab(),
                  // Treatment Tab
                  _buildTreatmentTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 40),
          // Main Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Camera Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.camera_alt,
                    size: 40,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 24),
                // Card Text
                Text(
                  'Capture or Upload Leaf Image',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                // Description
                Text(
                  'Take a clear photo of the affected leaf for accurate diagnosis',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),

          // Primary Button
          ElevatedButton.icon(
            onPressed: _isModelLoaded && !_isProcessing
                ? _pickImageFromCamera
                : null,
            icon: const Icon(Icons.camera_alt, size: 24),
            label: const Text(
              'Take Photo',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
              shadowColor: Theme.of(
                context,
              ).colorScheme.shadow.withOpacity(0.3),
            ),
          ),

          const SizedBox(height: 20),

          // Secondary Option
          TextButton(
            onPressed: _isModelLoaded && !_isProcessing
                ? _pickImageFromGallery
                : null,
            child: Text(
              'Upload from Gallery',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // Processing Indicator
          if (_isProcessing) ...[
            const SizedBox(height: 20),
            const CircularProgressIndicator(),
            const SizedBox(height: 10),
            const Text('Processing image...'),
          ],

          // Selected Image Display
          if (_selectedImage != null) ...[
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: FileImage(_selectedImage!),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],

          // Diagnosis Result
          if (_diagnosisResult != null) ...[
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(
                      context,
                    ).colorScheme.shadow.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Diagnosis Result:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _diagnosisResult!,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color:
                                _diagnosisResult!.toLowerCase().contains(
                                  'healthy',
                                )
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_confidence != null)
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 80,
                          height: 80,
                          child: CircularProgressIndicator(
                            value: _confidence,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _getConfidenceColor(_confidence!),
                            ),
                            strokeWidth: 8,
                          ),
                        ),
                        Text(
                          '${(_confidence! * 100).toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Treatment for Diagnosed Disease
            Builder(
              builder: (context) {
                final parts = _diagnosisResult!.split(' (');
                final disease = parts[0];
                final treatments = _getTreatments(disease);
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(
                          context,
                        ).colorScheme.shadow.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recommended Treatment:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...treatments.entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.key,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...entry.value.map(
                                (item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '• ',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          item,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurface,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Map<String, List<String>> _getTreatments(String disease) {
    final Map<String, Map<String, List<String>>> treatmentMap = {
      'Apple scab': {
        'Chemical Treatment': [
          'Spray protective fungicides like mancozeb (0.25%) or captan (0.2%) starting at green tip stage before symptoms appear.',
          'Use systemic fungicides such as myclobutanil (0.04%), difenoconazole (0.03%), or tebuconazole for curative action during early infection.',
          'Apply combination fungicides (e.g., trifloxystrobin + tebuconazole) during high disease pressure for better control.',
          'Follow a 7–10 day spray interval during rainy periods; extend to 14 days in dry conditions.',
          'Rotate fungicides with different FRAC codes to prevent resistance development.',
          'Stop spraying 15–20 days before harvest (observe pre-harvest interval on label).',
        ],

        'Organic Treatment': [
          'Spray neem oil (0.5–1%) at 7–10 day intervals during early season infection pressure.',
          'Apply Bordeaux mixture (1% solution) before bud break and after leaf fall.',
          'Use sulfur-based fungicides (wettable sulfur 0.3%) during early infection stage (avoid when temperature exceeds 28°C to prevent leaf burn).',
          'Apply potassium bicarbonate sprays (5 g/L water) as a preventive foliar spray.',
          'Introduce biological fungicides like Bacillus subtilis–based formulations for preventive suppression.',
        ],

        'Prevention Techniques': [
          'Plant scab-resistant varieties such as Liberty, Enterprise, or Prima.',
          'Collect and destroy fallen leaves in autumn to reduce overwintering spores.',
          'Apply urea (5%) spray on fallen leaves before leaf drop to accelerate decomposition and kill spores.',
          'Prune trees annually to improve sunlight penetration and air circulation.',
          'Maintain proper tree spacing to reduce humidity within canopy.',
          'Avoid overhead irrigation; prefer drip irrigation to reduce leaf wetness.',
          'Monitor weather forecasts — infection risk increases after 6+ hours of leaf wetness.',
          'Ensure balanced fertilization; excessive nitrogen promotes tender, susceptible growth.',
        ],
      },
      'Apple Black rot': {
        'Chemical Treatment': [
          'Spray captan (0.2%) or mancozeb (0.25%) from pink bud stage and repeat every 10–14 days during wet periods.',
          'Use systemic fungicides like thiophanate-methyl (0.1%) or difenoconazole (0.03%) for curative control at early infection stage.',
          'Apply pyraclostrobin or trifloxystrobin during high disease pressure, especially in warm humid conditions.',
          'After pruning infected limbs, apply copper-based fungicide paste or carbendazim paste on cut surfaces.',
          'Follow strict fungicide rotation to prevent resistance buildup.',
          'Maintain spray coverage on fruits and inner canopy — poor coverage = poor control.',
        ],

        'Organic Treatment': [
          'Apply Bordeaux mixture (1%) during dormant stage and again after leaf fall.',
          'Use copper oxychloride (0.3%) sprays at early season stages (avoid repeated heavy copper use to prevent phytotoxicity).',
          'Apply neem oil (0.5–1%) as preventive spray during early infection periods.',
          'Use Bacillus subtilis–based biofungicides as preventive applications every 7–10 days.',
          'Remove and destroy infected fruits ("mummies") immediately to stop spore spread.',
        ],

        'Prevention Techniques': [
          'Prune and destroy all cankered branches at least 15–20 cm below visible infection.',
          'Disinfect pruning tools with 10% bleach or alcohol between cuts.',
          'Remove and burn fallen fruits and mummified fruits from trees and ground.',
          'Maintain proper tree spacing and annual canopy thinning for air movement.',
          'Avoid mechanical injuries to bark (fungus enters through wounds).',
          'Control insect pests like borers that create entry wounds.',
          'Avoid excessive nitrogen fertilization — promotes soft, susceptible tissue.',
          'Improve drainage; waterlogged soil increases stress and susceptibility.',
        ],
      },
      'Cedar apple rust': {
        'Chemical Treatment': [
          'Begin protective sprays at pink bud stage using mancozeb (0.25%) or captan (0.2%).',
          'Apply systemic fungicides such as myclobutanil (0.04%), tebuconazole (0.03%), or propiconazole at 7–10 day intervals during spore release period.',
          'Critical spray window: from pink stage through 2–3 weeks after petal fall — missing this window = infection.',
          'During heavy spring rains, shorten spray interval to 7 days.',
          'Rotate fungicides with different FRAC groups to prevent resistance.',
          'Ensure thorough coverage of new leaves and developing fruits — rust infects young tissue only.',
        ],

        'Organic Treatment': [
          'Apply wettable sulfur (0.3%) preventively before and during early infection period (avoid above 28°C).',
          'Use Bordeaux mixture (1%) at dormant stage before bud break.',
          'Spray neem oil (0.5–1%) at early leaf emergence as preventive suppression.',
          'Apply Bacillus subtilis–based biofungicide at 7–10 day intervals during wet spring weather.',
          'Manually remove visible rust galls from nearby juniper trees before spring rains.',
        ],

        'Prevention Techniques': [
          'Remove nearby juniper/cedar trees within 300–500 meters if possible (they are primary spore source).',
          'Prune and destroy rust galls on junipers before rainy spring season.',
          'Plant resistant apple varieties such as Liberty, Enterprise, Freedom, or Redfree.',
          'Maintain open canopy through pruning to reduce leaf wetness duration.',
          'Avoid overhead irrigation during spring infection period.',
          'Monitor weather — infection risk rises after 4+ hours of leaf wetness at mild temperatures.',
          'Avoid excessive nitrogen fertilization which promotes tender susceptible growth.',
        ],
      },
      'Apple healthy': {
        'Chemical Treatment': [
          'No fungicide or pesticide application required if no disease or pest symptoms are present.',
          'Apply preventive fungicide spray (mancozeb 0.25% or captan 0.2%) only during high-risk weather (cool, wet spring).',
          'Use micronutrient spray (zinc sulfate 0.5%, boron 0.1%) at pre-flowering stage if deficiency symptoms are observed.',
          'Apply balanced NPK fertilizer based on soil test results — avoid blind fertilizer application.',
          'Use insecticides strictly based on economic threshold levels (do not spray “just in case”).',
        ],

        'Organic Treatment': [
          'Apply well-decomposed farmyard manure (20–25 kg per mature tree annually).',
          'Use neem cake in soil (1–2 kg per tree) for root health and natural pest suppression.',
          'Spray seaweed extract or panchagavya during vegetative growth for plant vigor enhancement.',
          'Apply compost tea or Trichoderma-enriched compost to improve soil microbial activity.',
          'Use biofertilizers like Azotobacter and PSB for nutrient availability improvement.',
        ],

        'Prevention Techniques': [
          'Conduct annual pruning to maintain open canopy and good air circulation.',
          'Remove fallen leaves and mummified fruits after harvest.',
          'Maintain proper tree spacing to reduce humidity inside canopy.',
          'Avoid overhead irrigation; use drip irrigation to control moisture levels.',
          'Perform soil testing every 2–3 years to maintain correct nutrient balance.',
          'Monitor orchard weekly for early signs of pests or disease — early detection saves money.',
          'Avoid excessive nitrogen — too much vegetative growth increases disease susceptibility.',
          'Ensure proper drainage to prevent root stress and fungal infections.',
        ],
      },
      'Blueberry healthy': {
        'Chemical Treatment': [
          'No fungicide or insecticide application required when plants show no symptoms — avoid preventive overuse.',
          'Apply sulfur soil amendment if soil pH rises above 5.5 (ideal pH: 4.5–5.2).',
          'Use micronutrient foliar spray (iron chelate, 0.1–0.2%) if chlorosis symptoms appear.',
          'Apply balanced fertilizer formulated for acid-loving crops (e.g., ammonium sulfate-based nitrogen source).',
          'Use insecticides only when pest population crosses economic threshold level.',
        ],

        'Organic Treatment': [
          'Apply pine bark mulch or pine needle mulch to maintain acidic soil conditions.',
          'Incorporate composted organic matter annually (avoid high-pH compost).',
          'Use neem cake in soil for root health and mild pest suppression.',
          'Apply compost tea to improve beneficial microbial activity.',
          'Use fish emulsion or seaweed extract during vegetative growth to boost plant vigor.',
        ],

        'Prevention Techniques': [
          'Maintain soil pH strictly between 4.5–5.2 — most blueberry problems start with wrong pH.',
          'Ensure excellent drainage; blueberries are highly sensitive to waterlogging and root rot.',
          'Use drip irrigation; avoid overhead irrigation to reduce leaf wetness.',
          'Prune annually to remove weak, old, and crossing canes for better air circulation.',
          'Maintain 5–8 cm mulch layer year-round to protect shallow roots.',
          'Avoid excessive nitrogen; too much vegetative growth reduces fruit quality.',
          'Monitor weekly for early signs of mummy berry, anthracnose, or root rot.',
          'Plant certified disease-free planting material.',
        ],
      },
      'Cherry healthy': {
        'Chemical Treatment': [
          'No fungicide or bactericide application needed when no symptoms are present — avoid routine spraying without risk.',
          'Apply dormant copper spray (copper oxychloride 0.3%) before bud break in high rainfall regions to prevent bacterial canker.',
          'Use balanced NPK fertilizer based strictly on soil test results.',
          'Apply calcium spray (calcium chloride 0.3–0.5%) during fruit development to improve firmness and reduce cracking.',
          'Use insecticides only when pest population crosses economic threshold levels (e.g., aphids, fruit flies).',
        ],

        'Organic Treatment': [
          'Apply well-decomposed compost (15–20 kg per mature tree annually).',
          'Use neem cake around root zone for soil health and natural pest suppression.',
          'Spray seaweed extract during vegetative growth to enhance stress tolerance.',
          'Apply Trichoderma-enriched compost to prevent soil-borne fungal pathogens.',
          'Use mulching (organic straw or bark) to conserve soil moisture and regulate temperature.',
        ],

        'Prevention Techniques': [
          'Maintain proper pruning annually to improve air circulation and light penetration.',
          'Avoid overhead irrigation during flowering and fruiting to reduce fungal risk.',
          'Ensure excellent drainage — cherries are sensitive to waterlogging.',
          'Remove and destroy fallen fruits and pruned infected twigs immediately.',
          'Avoid excessive nitrogen fertilization; promotes soft tissue susceptible to disease.',
          'Protect trunks from mechanical injury; wounds invite bacterial infections.',
          'Install bird nets during fruiting stage to prevent fruit damage.',
          'Monitor weekly during flowering for early signs of brown rot or bacterial canker.',
        ],
      },
      'Cherry Powdery mildew': {
        'Chemical Treatment': [
          'Start fungicide application at early leaf emergence or pre-bloom if history of infection exists.',
          'Spray systemic fungicides like myclobutanil (0.04%), tebuconazole (0.03%), or hexaconazole at 10–14 day intervals.',
          'Use strobilurin fungicides such as trifloxystrobin or azoxystrobin during active disease pressure.',
          'Apply wettable sulfur (0.3%) in early stage infection (avoid temperatures above 30°C to prevent leaf burn).',
          'Rotate fungicides with different FRAC groups to prevent resistance — powdery mildew develops resistance quickly.',
          'Ensure full canopy coverage, especially young shoots and underside of leaves.',
        ],

        'Organic Treatment': [
          'Spray potassium bicarbonate (5–7 g/L water) at first visible symptom; repeat every 7–10 days.',
          'Apply neem oil (0.5–1%) as preventive spray during warm dry periods.',
          'Use sulfur-based organic fungicide at early infection stage.',
          'Apply Bacillus subtilis–based biofungicides preventively during vegetative growth.',
          'Prune infected shoots immediately and destroy them to reduce spore load.',
        ],

        'Prevention Techniques': [
          'Maintain open canopy through regular pruning to improve sunlight penetration and airflow.',
          'Avoid excessive nitrogen fertilization — lush growth increases susceptibility.',
          'Space trees properly to reduce humidity buildup.',
          'Remove and destroy infected plant parts immediately.',
          'Avoid planting in shaded, poorly ventilated areas.',
          'Monitor orchard weekly during warm dry periods — early detection is critical.',
          'Select resistant or tolerant cherry varieties where available.',
        ],
      },
      'Corn (maize) Cercospora leaf spot , Gray leaf spot': {
        'Chemical Treatment': [
          'Scout fields from V6 stage onward; fungicide is economically justified when lesions are present on lower leaves before tasseling.',
          'Apply triazole fungicides such as propiconazole (0.1%) or tebuconazole (0.1%) at VT (tasseling) to R1 (silking) stage for best yield protection.',
          'Use strobilurin fungicides like azoxystrobin or pyraclostrobin during moderate to high disease pressure.',
          'Combination products (e.g., azoxystrobin + propiconazole) provide broader and longer protection under heavy infection.',
          'Maintain spray interval of 14 days if weather remains warm and humid.',
          'Ensure proper spray coverage of middle and upper canopy — these leaves contribute most to grain filling.',
          'Rotate fungicide groups (FRAC codes) to prevent resistance development.',
        ],

        'Organic Treatment': [
          'Apply Bacillus subtilis–based biofungicides preventively at early vegetative stages (V4–V6).',
          'Spray neem-based formulations (0.5–1%) as supportive measure — effective only at early mild infection.',
          'Use compost tea sprays to enhance leaf microbial competition (supportive, not curative).',
          'Incorporate Trichoderma into soil before sowing to reduce initial fungal inoculum from residues.',
          'Remove heavily infected lower leaves in small-scale cultivation to reduce spore load.',
        ],

        'Prevention Techniques': [
          'Practice crop rotation (at least 1–2 years with non-host crops like soybean or legumes). Continuous maize = high risk.',
          'Deep plough or properly incorporate infected crop residue after harvest to reduce overwintering spores.',
          'Plant resistant or tolerant maize hybrids — this is the most cost-effective control method.',
          'Maintain optimal plant spacing to improve air movement within canopy.',
          'Avoid excessive nitrogen fertilization which promotes dense canopy and humidity.',
          'Ensure good field drainage; waterlogged fields increase humidity and stress.',
          'Monitor weather — disease risk increases after 12+ hours of leaf wetness with warm nights.',
          'Scout regularly from V6 to R3 stage; early detection determines spray timing.',
        ],
      },
      'Corn (maize) Common rust': {
        'Chemical Treatment': [
          'Fungicide is economically justified only when rust appears before tasseling and spreads to upper leaves.',
          'Apply triazole fungicides such as propiconazole (0.1%) or tebuconazole (0.1%) at VT (tasseling) stage if infection is moderate to severe.',
          'Use strobilurin fungicides like azoxystrobin or pyraclostrobin for broader protection and improved leaf health.',
          'Combination fungicides (e.g., azoxystrobin + propiconazole) are preferred under high disease pressure.',
          'Maintain 14-day spray interval if cool, humid conditions persist.',
          'Ensure full coverage of upper canopy leaves, especially before silking stage.',
          'Avoid repeated use of same FRAC group to prevent resistance development.',
        ],

        'Organic Treatment': [
          'Apply neem-based formulations (0.5–1%) at early infection stage for mild suppression.',
          'Use sulfur-based fungicide in early infection (effective in cooler conditions; avoid high temperatures).',
          'Apply Bacillus subtilis–based biofungicides as preventive spray during vegetative stage.',
          'Improve plant nutrition with balanced potassium to enhance natural resistance.',
          'Remove severely infected leaves in small-scale cultivation to reduce spore spread.',
        ],

        'Prevention Techniques': [
          'Plant rust-resistant or tolerant maize hybrids — most effective long-term solution.',
          'Avoid very early planting in regions with cool, humid conditions.',
          'Maintain optimal plant spacing to reduce humidity buildup within canopy.',
          'Avoid excessive nitrogen fertilization which promotes lush susceptible growth.',
          'Rotate crops to reduce residual inoculum (though rust spores can travel long distances by wind).',
          'Scout fields weekly from V6 stage to tasseling for early detection.',
          'Maintain good field sanitation after harvest.',
        ],
      },
      'Corn (maize) healthy': {
        'Chemical Treatment': [
          'No fungicide application required when no disease symptoms are present — avoid prophylactic spraying.',
          'Apply soil-applied pre-emergence herbicide (e.g., atrazine or pendimethalin) based on weed pressure and label recommendations.',
          'Use seed treatment fungicide (e.g., metalaxyl + carbendazim) before sowing to prevent early seedling diseases.',
          'Apply balanced NPK fertilizer according to soil test (avoid blind high nitrogen application).',
          'Use insecticides only when pest population crosses economic threshold levels (e.g., fall armyworm).',
        ],

        'Organic Treatment': [
          'Treat seeds with Trichoderma or Pseudomonas fluorescens before sowing to prevent soil-borne pathogens.',
          'Apply well-decomposed FYM or compost (5–10 tons/ha) before planting.',
          'Use neem cake (250–500 kg/ha) to improve soil health and reduce root pests.',
          'Apply biofertilizers like Azotobacter and PSB at sowing for improved nutrient uptake.',
          'Use mulching in small-scale cultivation to conserve soil moisture.',
        ],

        'Prevention Techniques': [
          'Use certified, disease-resistant hybrid seeds suited to local climate.',
          'Maintain proper spacing (generally 60–75 cm row spacing depending on hybrid).',
          'Practice crop rotation with legumes to improve soil fertility and reduce disease carryover.',
          'Ensure proper drainage — waterlogging reduces root oxygen and increases disease risk.',
          'Avoid excessive nitrogen; balanced nutrition improves natural disease resistance.',
          'Scout field weekly from V3 stage onward for early signs of leaf spots, rust, or pests.',
          'Manage crop residue properly after harvest to reduce future disease inoculum.',
          'Irrigate at critical stages: knee-high, tasseling, silking, and grain filling.',
        ],
      },
      'Corn (maize) Northern Leaf Blight': {
        'Chemical Treatment': [
          'Scout from V6 stage onward; economic spray decision depends on lesion presence on leaves below the ear before tasseling.',
          'Apply triazole fungicides such as propiconazole (0.1%) or tebuconazole (0.1%) at VT (tasseling) to R1 (silking) stage for maximum yield protection.',
          'Use strobilurin fungicides like azoxystrobin or pyraclostrobin under moderate to high disease pressure.',
          'Combination products (e.g., azoxystrobin + propiconazole) provide longer residual control under humid conditions.',
          'Maintain 14-day interval if favorable weather persists.',
          'Ensure thorough spray coverage of upper canopy, especially ear leaf and leaves above it.',
          'Rotate fungicide groups (FRAC codes) to avoid resistance development.',
        ],

        'Organic Treatment': [
          'Apply Bacillus subtilis–based biofungicides preventively during early vegetative stages (V4–V6).',
          'Use neem-based formulations (0.5–1%) for early mild infection suppression.',
          'Incorporate Trichoderma into soil before planting to reduce residue-borne inoculum.',
          'Spray compost tea to enhance leaf microbial competition (supportive, not curative).',
          'Remove severely infected lower leaves in small-scale plots to reduce spore spread.',
        ],

        'Prevention Techniques': [
          'Plant NLB-resistant or tolerant maize hybrids — most reliable long-term solution.',
          'Practice crop rotation (1–2 years with non-host crops such as soybean or pulses).',
          'Deep plough or properly incorporate infected crop residue after harvest.',
          'Maintain optimal plant spacing to reduce canopy humidity.',
          'Avoid excessive nitrogen fertilization which promotes dense canopy growth.',
          'Ensure good field drainage to minimize prolonged leaf wetness.',
          'Monitor weather — disease risk increases after extended cloudy, humid conditions.',
          'Scout regularly from V6 to R3 stage; early detection determines economic spray timing.',
        ],
      },
      'Cotton Healthy': {
        'Chemical Treatment': [
          'No fungicide or insecticide required if no disease or pest symptoms are present — avoid calendar-based spraying.',
          'Use seed treatment (imidacloprid or thiamethoxam + fungicide mix) before sowing to protect against early sucking pests and seedling diseases.',
          'Apply balanced NPK fertilizer as per soil test (typical recommendation ~100–120 kg N/ha depending on variety).',
          'Use plant growth regulator (mepiquat chloride) only if excessive vegetative growth is observed.',
          'Apply insecticides strictly based on economic threshold levels (e.g., whitefly, aphids, jassids, bollworms).',
        ],

        'Organic Treatment': [
          'Treat seeds with Trichoderma or Pseudomonas fluorescens before sowing.',
          'Apply well-decomposed FYM or compost (5–10 tons/ha) before planting.',
          'Use neem cake (250–500 kg/ha) in soil for root health and mild pest suppression.',
          'Spray neem oil (0.5–1%) during vegetative stage for preventive sucking pest control.',
          'Encourage natural predators (ladybird beetles, lacewings) by avoiding broad-spectrum insecticides.',
        ],

        'Prevention Techniques': [
          'Use certified Bt or non-Bt hybrid seeds suited to local agro-climatic conditions.',
          'Maintain recommended spacing (e.g., 90 x 45 cm depending on hybrid).',
          'Avoid excessive nitrogen — promotes vegetative growth and attracts sucking pests.',
          'Ensure proper drainage; cotton is sensitive to waterlogging.',
          'Perform regular field scouting twice weekly during vegetative and flowering stages.',
          'Remove alternate host weeds around field borders.',
          'Avoid late sowing — increases pest pressure and reduces yield potential.',
          'Irrigate at critical stages: square formation, flowering, and boll development.',
        ],
      },
      'Cotton Unhealthy': {
        'Chemical Treatment': [
          'If yellowing with interveinal chlorosis: Apply foliar spray of 1% urea + 0.5% magnesium sulfate + 0.5% zinc sulfate.',
          'If sucking pests (whitefly, aphids, jassids) present: Spray imidacloprid or thiamethoxam as per label dose.',
          'If suspected fungal root rot: Drench soil with carbendazim (0.1%) or copper oxychloride around root zone.',
          'If leaf curl virus suspected: No cure — immediately control whitefly vector using recommended systemic insecticide.',
          'Apply balanced NPK top dressing based on soil test; avoid blind nitrogen boosting.',
          'Use micronutrient mixture (commercial cotton grade) at early deficiency stage.',
        ],

        'Organic Treatment': [
          'Apply neem oil (0.5–1%) spray if sucking pests are observed in early stage.',
          'Apply Trichoderma-enriched compost near root zone to suppress soil-borne pathogens.',
          'Use neem cake (250–500 kg/ha) to improve root health and reduce nematodes.',
          'Apply fermented compost tea to improve leaf microbial balance.',
          'Correct soil pH naturally using organic amendments if imbalance is confirmed.',
        ],

        'Prevention Techniques': [
          'Conduct soil testing before every season — most “unhealthy” crops are nutrient mismanagement cases.',
          'Avoid excessive nitrogen; it increases pest pressure and delays boll formation.',
          'Maintain proper irrigation — both drought stress and waterlogging reduce plant vigor.',
          'Control sucking pests early; they are the main cause of viral transmission.',
          'Use certified, region-adapted hybrid seeds.',
          'Maintain weed-free field borders to reduce alternate pest hosts.',
          'Ensure proper drainage to avoid root diseases.',
          'Scout field twice weekly — early detection prevents major losses.',
        ],
      },
      'Grape Black rot': {
        'Chemical Treatment': [
          'Start protective fungicide spray at 3–5 leaf stage if disease history exists in vineyard.',
          'Apply mancozeb (0.25%) or captan (0.2%) as protective fungicides during early growth.',
          'Use systemic fungicides such as myclobutanil (0.04%), tebuconazole (0.03%), or difenoconazole during pre-bloom to post-bloom stage.',
          'Critical protection window: from pre-bloom through 4–5 weeks after bloom — this is when fruit is highly susceptible.',
          'Under high disease pressure, use combination fungicides (e.g., trifloxystrobin + tebuconazole).',
          'Maintain 7–10 day spray interval during rainy periods.',
          'Rotate fungicide groups (FRAC codes) to prevent resistance development.',
        ],

        'Organic Treatment': [
          'Apply Bordeaux mixture (1%) before bud break (dormant stage).',
          'Use copper-based fungicide (0.3%) early season; avoid repeated heavy use to prevent phytotoxicity.',
          'Apply wettable sulfur (0.3%) as preventive spray (less effective once berries are infected).',
          'Use Bacillus subtilis–based biofungicides at 7–10 day intervals during humid conditions.',
          'Remove and destroy mummified berries and infected clusters immediately.',
        ],

        'Prevention Techniques': [
          'Prune and destroy infected canes during dormancy.',
          'Remove all mummified berries from vines and vineyard floor — major inoculum source.',
          'Maintain open canopy through proper training and pruning to improve airflow.',
          'Avoid overhead irrigation; use drip system.',
          'Maintain proper vine spacing to reduce humidity buildup.',
          'Avoid excessive nitrogen which promotes dense canopy growth.',
          'Ensure good drainage; waterlogged soil increases plant stress.',
          'Scout vineyard weekly from early vegetative stage to fruit set.',
        ],
      },
      'Grape Esca (Black Measles)': {
        'Chemical Treatment': [
          'No fully curative fungicide available once vine is infected internally.',
          'Apply pruning wound protectants immediately after pruning (e.g., thiophanate-methyl paste or tebuconazole-based wound sealant).',
          'Use boron or phosphonate-based trunk injections in high-value vineyards to slow disease progression (specialized practice).',
          'Apply copper-based fungicide on pruning wounds in regions with high rainfall.',
          'Remove and destroy severely affected vines to prevent spread.',
          'Avoid sodium arsenite (historically effective but banned due to toxicity).',
        ],

        'Organic Treatment': [
          'Apply Trichoderma-based biological wound protectants immediately after pruning.',
          'Use biofungicide pastes on fresh pruning cuts.',
          'Improve soil organic matter to strengthen root system and reduce stress.',
          'Apply seaweed extract during stress periods to improve plant resilience.',
          'Remove and burn infected wood during dormancy.',
        ],

        'Prevention Techniques': [
          'Prune during dry weather to reduce fungal infection risk.',
          'Avoid large pruning wounds; adopt double pruning technique (pre-prune early, final prune late).',
          'Disinfect pruning tools between vines (70% alcohol or bleach solution).',
          'Protect all pruning wounds immediately — infection enters through fresh cuts.',
          'Avoid excessive water stress; maintain balanced irrigation.',
          'Maintain balanced nutrition — avoid excess nitrogen.',
          'Replace heavily infected vines early before full vineyard spread.',
          'Monitor vines annually for tiger-stripe leaf symptoms.',
        ],
      },
      'Grape healthy': {
        'Chemical Treatment': [
          'No fungicide required if no disease pressure — avoid calendar spraying without scouting.',
          'Apply preventive fungicide only during high-risk periods (downy mildew, powdery mildew, black rot).',
          'Use balanced fertigation program based on soil and leaf analysis.',
          'Apply micronutrient spray (zinc, boron) before flowering if deficiency detected.',
          'Use insecticides strictly based on economic threshold levels (thrips, mealybugs, flea beetles).',
          'Apply growth regulators only if variety requires berry size improvement (e.g., GA in table grapes).',
        ],

        'Organic Treatment': [
          'Apply well-decomposed compost annually to improve soil structure.',
          'Use Trichoderma in soil to prevent root and trunk pathogens.',
          'Apply neem cake to support soil microbial balance.',
          'Spray seaweed extract during vegetative stage for stress tolerance.',
          'Use biofungicides preventively during humid conditions.',
          'Maintain organic mulching to conserve moisture and moderate soil temperature.',
        ],

        'Prevention Techniques': [
          'Maintain proper canopy management (shoot thinning, leaf removal, pruning).',
          'Ensure good air circulation to reduce humidity-related diseases.',
          'Avoid excessive nitrogen — promotes dense canopy and fungal risk.',
          'Use drip irrigation; avoid wetting foliage.',
          'Conduct leaf tissue analysis once per season.',
          'Protect pruning wounds immediately after pruning.',
          'Remove weak or diseased canes during dormancy.',
          'Monitor vineyard weekly during growing season.',
          'Maintain proper bunch load to avoid overcropping stress.',
        ],
      },
      'Grape Leaf blight (Isariopsis Leaf Spot)': {
        'Chemical Treatment': [
          'Begin protective fungicide spray at first appearance of leaf spots, especially during humid weather.',
          'Apply mancozeb (0.25%) or chlorothalonil (0.2%) as protective contact fungicides.',
          'Use systemic fungicides such as carbendazim (0.1%), difenoconazole (0.03%), or tebuconazole (0.03%) during active spread.',
          'Under high disease pressure, apply combination fungicides (e.g., azoxystrobin + difenoconazole).',
          'Maintain 10–14 day spray interval during rainy season.',
          'Ensure full coverage of lower canopy leaves where infection usually starts.',
          'Rotate fungicide groups to prevent resistance development.',
        ],

        'Organic Treatment': [
          'Apply Bordeaux mixture (1%) before and during early rainy season.',
          'Use copper oxychloride (0.3%) at early infection stage.',
          'Spray neem oil (0.5–1%) for mild early-stage suppression.',
          'Apply Bacillus subtilis–based biofungicide preventively during humid periods.',
          'Remove and destroy severely infected leaves to reduce spore load.',
        ],

        'Prevention Techniques': [
          'Maintain proper canopy management to reduce humidity and improve air circulation.',
          'Avoid overhead irrigation; use drip system.',
          'Remove fallen infected leaves from vineyard floor.',
          'Avoid excessive nitrogen fertilization that increases canopy density.',
          'Ensure proper vine spacing and training system.',
          'Conduct regular scouting during monsoon or high humidity periods.',
          'Improve drainage to prevent prolonged leaf wetness.',
        ],
      },
      'Orange Haunglongbing (Citrus greening)': {
        'Chemical Treatment': [
          'Immediately remove and destroy confirmed infected trees to prevent spread.',
          'Control Asian citrus psyllid using systemic insecticides such as imidacloprid or thiamethoxam as per label dose.',
          'Use foliar insecticides like lambda-cyhalothrin or dimethoate during active psyllid outbreaks.',
          'Apply trunk injection or soil drench with systemic insecticides in high-value orchards.',
          'Maintain continuous psyllid monitoring and apply insecticides based on threshold levels.',
          'Follow insecticide rotation to prevent resistance development.',
        ],

        'Organic Treatment': [
          'Use neem oil (0.5–1%) spray regularly to suppress psyllid population in early stages.',
          'Release biological control agents such as Tamarixia radiata (parasitoid of psyllid).',
          'Apply horticultural oil sprays to reduce psyllid egg and nymph survival.',
          'Maintain strong tree nutrition using organic compost and micronutrients.',
          'Remove infected trees immediately — no organic cure exists.',
        ],

        'Prevention Techniques': [
          'Plant certified HLB-free nursery stock only.',
          'Regularly scout orchard for psyllids and early mottling symptoms.',
          'Install yellow sticky traps for psyllid monitoring.',
          'Maintain strict border control — nearby unmanaged citrus trees are infection sources.',
          'Implement area-wide psyllid management (community-level control works better than individual effort).',
          'Avoid moving infected plant material between regions.',
          'Maintain balanced nutrition to prolong productive life of infected but mildly symptomatic trees.',
        ],
      },
      'Peach Bacterial spot': {
        'Chemical Treatment': [
          'Apply copper-based bactericides (copper oxychloride 0.3%) during dormant season and early bud swell.',
          'Use oxytetracycline sprays (where permitted) during high-risk periods in early growing season.',
          'Apply copper + mancozeb combination during early leaf development to improve protection.',
          'Repeat sprays at 7–10 day intervals during rainy periods.',
          'Reduce copper concentration after full leaf expansion to avoid phytotoxicity.',
          'Avoid excessive copper applications which may cause leaf burn and resistance issues.',
        ],

        'Organic Treatment': [
          'Apply Bordeaux mixture (1%) during dormant stage.',
          'Use fixed copper formulations carefully at early growth stages.',
          'Apply Bacillus-based biological bactericides as preventive sprays.',
          'Improve soil organic matter to enhance plant vigor and tolerance.',
          'Remove and destroy heavily infected twigs during pruning.',
        ],

        'Prevention Techniques': [
          'Plant bacterial spot–tolerant peach varieties.',
          'Avoid overhead irrigation; use drip irrigation to minimize leaf wetness.',
          'Prune to maintain open canopy and good airflow.',
          'Avoid excessive nitrogen fertilization — promotes susceptible soft growth.',
          'Remove infected leaves and fruit from orchard floor.',
          'Disinfect pruning tools regularly.',
          'Ensure good drainage to reduce plant stress.',
          'Avoid mechanical injury to trees which increases infection risk.',
        ],
      },
      'Peach healthy': {
        'Chemical Treatment': [
          'Apply dormant copper spray (copper oxychloride 0.3%) before bud swell to prevent leaf curl and bacterial spot.',
          'Use lime sulfur spray during full dormancy where leaf curl history exists.',
          'Apply preventive fungicide (captan 0.2% or chlorothalonil 0.2%) during bloom if brown rot risk is high.',
          'Spray calcium chloride (0.3–0.5%) during fruit development to improve firmness and reduce cracking.',
          'Use insecticides strictly based on economic threshold levels (e.g., peach fruit borer, aphids).',
          'Follow soil-test-based NPK application — typical nitrogen split between pre-bloom and post-fruit set.',
          'Avoid excessive nitrogen after fruit set; it reduces fruit quality and increases disease risk.',
        ],

        'Organic Treatment': [
          'Apply well-decomposed compost (15–20 kg per mature tree annually).',
          'Use neem cake in root zone to improve soil microbial balance.',
          'Apply Trichoderma-enriched compost to suppress soil-borne pathogens.',
          'Spray seaweed extract during vegetative stage to improve stress tolerance.',
          'Use biofungicides preventively during humid periods.',
          'Maintain organic mulching to conserve moisture and regulate soil temperature.',
        ],

        'Prevention Techniques': [
          'Maintain annual open-center pruning system to improve light penetration.',
          'Remove mummified fruits and diseased twigs during dormancy.',
          'Avoid overhead irrigation during flowering and fruiting.',
          'Ensure excellent drainage — peach roots are highly sensitive to waterlogging.',
          'Conduct leaf tissue analysis annually to detect micronutrient deficiencies.',
          'Thin fruits properly 30–40 days after bloom to maintain fruit size and tree balance.',
          'Monitor twice weekly during flowering for brown rot risk.',
          'Protect trunks from borers using trunk guards or monitoring traps.',
        ],
      },
      'Pepper bell Bacterial spot': {
        'Chemical Treatment': [
          'Use certified, pathogen-free seed; treat seed with hot water (50°C for 25–30 min) before sowing to reduce seed-borne infection.',
          'Start preventive copper-based bactericide (copper hydroxide or copper oxychloride 0.2–0.3%) at early vegetative stage if disease history exists.',
          'Tank-mix copper with mancozeb (0.2%) to improve efficacy and reduce resistance pressure.',
          'Spray at 7-day intervals during rainy or highly humid conditions.',
          'Use streptomycin-based bactericides only where legally permitted and rotate carefully to avoid resistance.',
          'Avoid excessive copper concentration after full canopy development to prevent phytotoxicity.',
          'Ensure thorough spray coverage of lower leaf surface where infection often begins.',
        ],

        'Organic Treatment': [
          'Apply Bordeaux mixture (1%) at early infection stage (use cautiously to avoid leaf burn).',
          'Use neem oil (0.5–1%) as supportive suppression in early stages.',
          'Apply Bacillus subtilis–based bio-bactericides preventively.',
          'Remove and destroy heavily infected plants immediately.',
          'Use compost tea sprays to enhance leaf microbial competition (supportive, not curative).',
        ],

        'Prevention Techniques': [
          'Plant resistant or tolerant bell pepper varieties where available.',
          'Use drip irrigation; strictly avoid overhead irrigation.',
          'Maintain proper plant spacing to improve air circulation.',
          'Avoid field work when foliage is wet to prevent mechanical spread.',
          'Disinfect tools and hands regularly during field operations.',
          'Remove crop debris immediately after harvest.',
          'Practice crop rotation (2–3 years with non-host crops).',
          'Avoid excessive nitrogen fertilization which increases soft, susceptible growth.',
          'Scout field twice weekly during humid weather.',
        ],
      },
      'Pepper bell healthy': {
        'Chemical Treatment': [
          'No fungicide or insecticide required if no symptoms are present — avoid calendar-based spraying.',
          'Treat seeds before sowing with fungicide (metalaxyl + carbendazim) to prevent damping-off in nursery.',
          'Apply balanced NPK through fertigation based on soil test; typical ratio during vegetative stage favors nitrogen, shifting to higher potassium during fruiting.',
          'Spray calcium nitrate (0.5%) during fruit development to prevent blossom-end rot.',
          'Apply micronutrient mix (Zn, B, Mg) if deficiency symptoms appear.',
          'Use insecticides only when pests cross economic threshold levels (thrips, whitefly, aphids).',
        ],

        'Organic Treatment': [
          'Treat seeds with Trichoderma before sowing.',
          'Apply well-decomposed compost (8–10 tons/ha) before transplanting.',
          'Use neem cake (250–500 kg/ha) to improve soil health.',
          'Apply seaweed extract during vegetative stage to improve stress tolerance.',
          'Spray neem oil (0.5–1%) preventively for sucking pest suppression.',
          'Apply biofertilizers (Azotobacter, PSB) at transplanting.',
        ],

        'Prevention Techniques': [
          'Use certified disease-free seedlings.',
          'Maintain proper spacing (45–60 cm depending on variety).',
          'Use drip irrigation — avoid overhead watering.',
          'Ensure raised beds and good drainage to prevent root rot.',
          'Avoid excessive nitrogen; too much vegetative growth reduces fruit set.',
          'Scout twice weekly during flowering and fruiting stages.',
          'Remove lower yellowing leaves to improve air circulation.',
          'Practice 2–3 year crop rotation with non-solanaceous crops.',
          'Maintain mulching to reduce soil splash and weed competition.',
        ],
      },
      'Potato Early blight': {
        'Chemical Treatment': [
          'Start protective fungicide at first appearance of lower leaf lesions, especially after canopy closure.',
          'Apply mancozeb (0.25%) or chlorothalonil (0.2%) as contact protectant fungicides.',
          'Use systemic fungicides such as azoxystrobin, difenoconazole, or tebuconazole under moderate to high disease pressure.',
          'Combination products (azoxystrobin + difenoconazole) provide extended protection.',
          'Maintain 7–10 day spray interval during warm, humid weather.',
          'Ensure thorough coverage of lower canopy where infection begins.',
          'Rotate fungicides by FRAC group to prevent resistance development.',
        ],

        'Organic Treatment': [
          'Apply copper-based fungicide (0.3%) at early infection stage.',
          'Use Bacillus subtilis–based biofungicides preventively.',
          'Apply neem oil (0.5–1%) as supportive measure in early stages.',
          'Use compost tea sprays to improve leaf microbial balance.',
          'Incorporate Trichoderma into soil before planting to reduce inoculum load.',
        ],

        'Prevention Techniques': [
          'Practice 2–3 year crop rotation with non-solanaceous crops.',
          'Remove and destroy infected plant debris after harvest.',
          'Maintain balanced nitrogen fertilization — avoid deficiency and excess.',
          'Ensure proper plant spacing to improve airflow.',
          'Avoid overhead irrigation during late evening.',
          'Use certified disease-free seed tubers.',
          'Irrigate consistently to avoid drought stress.',
          'Hill soil properly to protect tubers from exposure.',
        ],
      },
      'Potato healthy': {
        'Chemical Treatment': [
          'No fungicide needed if no disease and dry weather conditions — avoid unnecessary preventive spraying.',
          'In late blight–prone regions, apply protective fungicide (mancozeb 0.25%) once canopy closes and humidity increases.',
          'Use certified disease-free seed tubers treated with fungicide (metalaxyl + mancozeb) before planting.',
          'Apply balanced NPK as per soil test; split nitrogen (50% at planting, 50% at earthing up).',
          'Spray calcium nitrate (0.5%) if deficiency symptoms appear.',
          'Use insecticides only when pests (aphids, leaf miners) cross economic threshold levels.',
        ],

        'Organic Treatment': [
          'Treat seed tubers with Trichoderma before planting.',
          'Apply well-decomposed FYM (10–15 tons/ha) before planting.',
          'Use neem cake (250–400 kg/ha) to improve soil health.',
          'Apply biofertilizers (Azotobacter, PSB) at planting.',
          'Spray seaweed extract during vegetative stage to improve stress tolerance.',
          'Maintain straw mulching in small-scale farming to conserve soil moisture.',
        ],

        'Prevention Techniques': [
          'Use certified, disease-free seed tubers.',
          'Practice 2–3 year crop rotation with non-solanaceous crops.',
          'Ensure proper spacing to improve airflow and reduce humidity.',
          'Avoid overhead irrigation late in the evening.',
          'Irrigate consistently — avoid drought stress during tuber initiation and bulking.',
          'Perform timely earthing up to protect developing tubers.',
          'Monitor twice weekly during humid weather for late blight signs.',
          'Avoid excessive nitrogen after canopy closure — it delays tuber maturity.',
          'Ensure proper drainage; waterlogging increases disease risk.',
        ],
      },
      'Potato Late blight': {
        'Chemical Treatment': [
          'Start preventive spray when weather forecast predicts cool, humid conditions — do not wait for heavy symptoms.',
          'Apply protectant fungicides like mancozeb (0.25%) or chlorothalonil (0.2%) before disease appearance in high-risk regions.',
          'At first sign of infection, use systemic fungicides such as metalaxyl + mancozeb, cymoxanil + mancozeb, or dimethomorph.',
          'Under high disease pressure, use combination fungicides (e.g., ametoctradin + dimethomorph or mandipropamid-based products).',
          'Maintain 5–7 day spray interval during active outbreak conditions.',
          'Ensure thorough coverage of lower canopy and underside of leaves.',
          'Rotate fungicides strictly by FRAC group to prevent resistance development (metalaxyl resistance is common).',
          'Stop irrigation temporarily during active outbreak if possible.',
        ],

        'Organic Treatment': [
          'Apply copper-based fungicide (0.3%) as preventive measure.',
          'Use Bordeaux mixture (1%) before and during early infection stages.',
          'Apply Bacillus subtilis–based biofungicides as preventive support.',
          'Remove and destroy infected foliage immediately in small plots.',
          'Improve drainage and avoid prolonged leaf wetness.',
        ],

        'Prevention Techniques': [
          'Use certified disease-free seed tubers.',
          'Destroy volunteer potato plants before planting season.',
          'Practice 2–3 year crop rotation.',
          'Ensure good spacing and air circulation.',
          'Avoid overhead irrigation, especially during evening.',
          'Monitor weather forecasts closely — infection risk rises after 2 consecutive cool, humid days.',
          'Avoid dense canopy caused by excessive nitrogen.',
          'Harvest only after vines are fully dead and skin is set to reduce tuber infection.',
        ],
      },
      'Raspberry healthy': {
        'Chemical Treatment': [
          'No fungicide required if no disease pressure — avoid routine spraying.',
          'Apply dormant copper spray before bud break in high rainfall regions to prevent cane blight and anthracnose.',
          'Use preventive fungicide (captan 0.2% or mancozeb 0.25%) during prolonged wet weather.',
          'Apply balanced NPK fertilizer based on soil test; avoid heavy nitrogen after flowering.',
          'Use insecticides only when pests (aphids, spider mites, fruit worms) cross economic threshold levels.',
          'Apply calcium spray during fruit development if fruit softening is observed.',
        ],

        'Organic Treatment': [
          'Apply well-decomposed compost annually (5–8 tons/ha equivalent).',
          'Use neem cake around root zone for soil health.',
          'Apply Trichoderma in soil to reduce root rot risk.',
          'Spray seaweed extract during vegetative growth to improve stress tolerance.',
          'Use biofungicides during humid periods as preventive measure.',
          'Maintain organic mulch to regulate soil moisture and suppress weeds.',
        ],

        'Prevention Techniques': [
          'Remove and destroy old fruited canes immediately after harvest.',
          'Maintain proper spacing to reduce humidity within canopy.',
          'Use trellis system to keep canes upright and improve airflow.',
          'Avoid overhead irrigation; use drip irrigation.',
          'Ensure excellent drainage — raspberries are sensitive to root rot.',
          'Conduct annual soil and leaf nutrient analysis.',
          'Scout weekly during humid weather for early signs of leaf spot or cane blight.',
          'Avoid excessive nitrogen which promotes soft, disease-prone growth.',
        ],
      },
      'Soybean healthy': {
        'Chemical Treatment': [
          'No fungicide required in dry conditions with no disease symptoms.',
          'Apply seed treatment before sowing (carbendazim + thiram or metalaxyl-based mix) to prevent early seedling diseases.',
          'Use Rhizobium inoculation at sowing for proper nodulation.',
          'Apply balanced fertilizer as per soil test; phosphorus is critical at early stage.',
          'Spray foliar nutrient mix (0.5% potassium nitrate) during flowering if deficiency observed.',
          'Use insecticides only when pests (whitefly, aphids, stem fly, pod borer) cross economic threshold levels.',
        ],

        'Organic Treatment': [
          'Treat seeds with Rhizobium and PSB before sowing.',
          'Apply well-decomposed FYM or compost (5–10 tons/ha).',
          'Use neem cake to improve soil microbial balance.',
          'Spray seaweed extract during vegetative stage for stress tolerance.',
          'Apply Trichoderma in soil to reduce root disease risk.',
          'Maintain mulching in small-scale cultivation to conserve moisture.',
        ],

        'Prevention Techniques': [
          'Use certified disease-resistant soybean varieties suited to your region.',
          'Practice 2–3 year crop rotation with cereals.',
          'Maintain recommended spacing (usually 30–45 cm rows depending on variety).',
          'Avoid excessive nitrogen — soybean fixes its own nitrogen when nodulation is healthy.',
          'Ensure good drainage; soybean is sensitive to waterlogging.',
          'Monitor crop weekly during vegetative and flowering stages.',
          'Control weeds early (first 30–40 days are critical).',
          'Irrigate at critical stages: flowering (R1–R2) and pod filling (R3–R5) if rainfed conditions fail.',
        ],
      },
      'Squash Powdery mildew': {
        'Chemical Treatment': [
          'Begin fungicide application at first visible white spots — do not wait for heavy coverage.',
          'Apply systemic fungicides such as myclobutanil (0.04%), tebuconazole (0.03%), or hexaconazole.',
          'Use strobilurin fungicides like azoxystrobin or trifloxystrobin under moderate to high disease pressure.',
          'Alternate with contact fungicides like sulfur (0.3%) to slow resistance development.',
          'Maintain 7–10 day spray interval during active disease conditions.',
          'Rotate fungicides strictly by FRAC group — powdery mildew develops resistance quickly.',
          'Ensure full coverage of both upper and lower leaf surfaces.',
        ],

        'Organic Treatment': [
          'Spray wettable sulfur (0.3%) at early infection stage (avoid temperatures above 32°C).',
          'Apply potassium bicarbonate (5–7 g/L water) at first sign of infection.',
          'Use neem oil (0.5–1%) as preventive spray.',
          'Apply Bacillus subtilis–based biofungicides at 7-day intervals.',
          'Remove heavily infected leaves to reduce spore load (in small-scale production).',
        ],

        'Prevention Techniques': [
          'Plant resistant or tolerant squash varieties.',
          'Maintain proper plant spacing to improve airflow.',
          'Avoid excessive nitrogen fertilization — promotes dense canopy.',
          'Use drip irrigation; avoid wetting foliage.',
          'Start preventive sprays when vines begin to run in high-risk regions.',
          'Rotate crops annually; avoid continuous cucurbit planting.',
          'Scout field twice weekly once canopy develops.',
        ],
      },
      'Strawberry healthy': {
        'Chemical Treatment': [
          'No fungicide required if dry weather and no disease symptoms are present.',
          'Apply preventive fungicide (captan 0.2% or mancozeb 0.25%) before prolonged rainy periods.',
          'During flowering in humid regions, protect against botrytis using appropriate fungicides (e.g., fenhexamid or iprodione as per label).',
          'Apply calcium nitrate (0.5%) during fruit development to improve firmness and shelf life.',
          'Use balanced fertigation — reduce nitrogen during fruiting to avoid soft berries.',
          'Apply insecticides only when pests (thrips, mites, aphids) cross economic threshold levels.',
        ],

        'Organic Treatment': [
          'Apply well-decomposed compost before planting.',
          'Use Trichoderma in soil to prevent root diseases.',
          'Spray neem oil (0.5–1%) for early pest suppression.',
          'Apply Bacillus subtilis–based biofungicides during humid conditions.',
          'Use organic mulch (straw or plastic mulch) to prevent fruit-soil contact.',
          'Apply seaweed extract during vegetative stage to improve stress tolerance.',
        ],

        'Prevention Techniques': [
          'Use certified disease-free runners or transplants.',
          'Ensure raised beds with proper drainage — strawberries are highly sensitive to waterlogging.',
          'Use drip irrigation; avoid overhead watering especially during flowering.',
          'Maintain proper plant spacing to reduce humidity.',
          'Remove old, damaged leaves regularly.',
          'Avoid excessive nitrogen — leads to soft fruit and fungal risk.',
          'Harvest fruits regularly to reduce rot pressure.',
          'Scout field twice weekly during flowering and fruiting stages.',
        ],
      },
      'Strawberry Leaf scorch': {
        'Chemical Treatment': [
          'Begin protective fungicide spray at first appearance of small purple spots.',
          'Apply captan (0.2%) or mancozeb (0.25%) as protective fungicides.',
          'Use systemic fungicides such as difenoconazole or myclobutanil under moderate infection pressure.',
          'Maintain 7–10 day spray interval during humid or rainy conditions.',
          'Rotate fungicide groups (FRAC codes) to prevent resistance development.',
          'Ensure good coverage of lower and inner canopy leaves.',
        ],

        'Organic Treatment': [
          'Apply Bordeaux mixture (1%) during early infection stage.',
          'Use copper-based fungicides (0.3%) carefully to avoid phytotoxicity.',
          'Apply Bacillus subtilis–based biofungicides preventively.',
          'Remove and destroy heavily infected leaves immediately.',
          'Improve air circulation through thinning and pruning.',
        ],

        'Prevention Techniques': [
          'Use certified disease-free planting material.',
          'Avoid overhead irrigation; use drip irrigation.',
          'Maintain proper spacing between plants.',
          'Remove old infected leaves after harvest.',
          'Practice crop rotation (avoid continuous strawberry planting).',
          'Ensure raised beds with good drainage.',
          'Avoid excessive nitrogen which increases soft, susceptible foliage.',
          'Scout regularly during humid weather.',
        ],
      },
      'Sugarcane Healthy': {
        'Chemical Treatment': [
          'No fungicide required in absence of disease symptoms.',
          'Use treated seed setts (carbendazim 0.1% dip for 10 minutes) before planting to prevent sett rot.',
          'Apply recommended NPK dose based on soil test (typical N split into 2–3 applications).',
          'Use pre-emergence herbicide (e.g., atrazine) for early weed control if needed.',
          'Apply insecticides only when pests (early shoot borer, top borer, pyrilla) cross economic threshold levels.',
          'Apply potassium during grand growth stage to improve stalk strength and sugar content.',
        ],

        'Organic Treatment': [
          'Treat seed setts with Trichoderma before planting.',
          'Apply well-decomposed FYM (10–20 tons/ha) before planting.',
          'Use press mud compost to improve soil structure.',
          'Apply biofertilizers (Azotobacter, PSB) during planting.',
          'Incorporate neem cake in soil to improve root health.',
          'Use trash mulching after planting to conserve moisture.',
        ],

        'Prevention Techniques': [
          'Use certified disease-free seed setts.',
          'Select region-specific high-yielding, disease-resistant varieties.',
          'Maintain recommended spacing for better aeration.',
          'Ensure proper drainage — waterlogging reduces tillering.',
          'Avoid excessive nitrogen after grand growth stage.',
          'Irrigate at critical stages: germination, tillering, grand growth.',
          'Remove and destroy clumps showing early red rot or smut symptoms.',
          'Practice crop rotation or proper ratoon management.',
          'Monitor field weekly for early borer and sucking pest activity.',
        ],
      },
      'Sugarcane Mosaic': {
        'Chemical Treatment': [
          'Immediately rogue (remove and destroy) infected clumps showing mosaic symptoms.',
          'Control aphid vectors using systemic insecticides such as imidacloprid or thiamethoxam as per recommended dose.',
          'Apply foliar insecticides during active aphid outbreaks (e.g., dimethoate where permitted).',
          'Treat seed setts before planting with hot water treatment (50–52°C for 30 minutes) to reduce viral load.',
          'Avoid repeated use of the same insecticide group to prevent resistance.',
          'Maintain strict field sanitation during planting and ratooning.',
        ],

        'Organic Treatment': [
          'Use only certified virus-free seed material.',
          'Encourage natural predators of aphids (ladybird beetles, lacewings).',
          'Spray neem oil (0.5–1%) to suppress aphid population at early stage.',
          'Apply neem cake in soil to improve plant vigor.',
          'Remove and destroy infected clumps immediately.',
        ],

        'Prevention Techniques': [
          'Use resistant or tolerant sugarcane varieties suited to your region.',
          'Plant only certified healthy seed setts.',
          'Avoid ratooning from infected fields.',
          'Maintain proper plant nutrition to reduce stress.',
          'Monitor field weekly for mosaic pattern on young leaves.',
          'Control alternate grass hosts around field borders.',
          'Avoid mechanical transfer during cutting operations.',
          'Implement area-wide aphid management if outbreak is regional.',
        ],
      },
      'Sugarcane RedRot': {
        'Chemical Treatment': [
          'Immediately uproot and destroy infected clumps; do not leave in field.',
          'Treat seed setts before planting by dipping in carbendazim (0.1%) solution for 10–15 minutes.',
          'Use hot water treatment (50–52°C for 30 minutes) for seed setts.',
          'Avoid planting ratoon crop from infected fields.',
          'Drench nearby healthy clumps with carbendazim solution to limit spread (limited effectiveness).',
          'Avoid overuse of same fungicide season after season to prevent resistance.',
        ],

        'Organic Treatment': [
          'Treat seed setts with Trichoderma before planting.',
          'Apply Trichoderma-enriched compost in furrows during planting.',
          'Use press mud compost to improve soil microbial balance.',
          'Remove and burn infected canes immediately.',
          'Improve drainage to reduce soil moisture stress.',
        ],

        'Prevention Techniques': [
          'Plant only certified red-rot-resistant varieties suitable for your region.',
          'Avoid continuous ratooning; rotate crop periodically.',
          'Ensure proper drainage — waterlogging increases severity.',
          'Remove and destroy infected stubbles after harvest.',
          'Maintain balanced fertilization; avoid excessive nitrogen.',
          'Select healthy seed setts from disease-free fields.',
          'Practice crop rotation with non-host crops if infection was severe.',
          'Monitor field regularly for early drying of top leaves.',
        ],
      },
      'Sugarcane Rust': {
        'Chemical Treatment': [
          'Begin fungicide application when rust pustules appear on lower to mid leaves and weather remains humid.',
          'Apply triazole fungicides such as propiconazole (0.1%) or tebuconazole (0.1%).',
          'Use strobilurin fungicides like azoxystrobin under moderate to high disease pressure.',
          'Combination fungicides (e.g., azoxystrobin + propiconazole) provide broader protection.',
          'Maintain 14-day spray interval during favorable conditions.',
          'Ensure thorough coverage of entire canopy, especially middle leaves.',
          'Rotate fungicide groups (FRAC codes) to prevent resistance development.',
        ],

        'Organic Treatment': [
          'Apply neem oil (0.5–1%) for early-stage suppression (limited effectiveness).',
          'Use Bacillus-based biofungicides preventively.',
          'Improve plant nutrition with balanced potassium to strengthen leaf tissue.',
          'Remove severely infected leaves in small-scale cultivation.',
          'Apply compost and organic amendments to reduce plant stress.',
        ],

        'Prevention Techniques': [
          'Plant rust-resistant sugarcane varieties suited to your region.',
          'Avoid continuous ratooning if rust incidence is high.',
          'Maintain proper spacing to improve air circulation.',
          'Avoid excessive nitrogen fertilization which increases susceptibility.',
          'Monitor field weekly during humid seasons.',
          'Ensure proper drainage to reduce prolonged leaf wetness.',
          'Destroy volunteer sugarcane plants that may harbor spores.',
        ],
      },
      'Sugarcane Yellow': {
        'Chemical Treatment': [
          'If nitrogen deficiency: Apply urea as top dressing (split application recommended).',
          'If iron deficiency: Spray 0.5% ferrous sulfate + 0.25% lime solution.',
          'If zinc deficiency suspected: Spray 0.5% zinc sulfate.',
          'If aphids present (possible virus spread): Apply systemic insecticide like imidacloprid as per label.',
          'If waterlogging present: Improve drainage immediately — chemical spray won’t fix root suffocation.',
          'If Yellow Leaf Virus suspected: Remove heavily infected clumps; no chemical cure exists.',
        ],

        'Organic Treatment': [
          'Apply well-decomposed FYM to improve soil structure.',
          'Use compost enriched with micronutrients.',
          'Apply neem cake to improve root health.',
          'Encourage natural predators to control aphids.',
          'Improve drainage naturally using raised ridges if soil is heavy.',
        ],

        'Prevention Techniques': [
          'Conduct soil testing before fertilizer application.',
          'Use certified virus-free seed setts.',
          'Maintain proper irrigation schedule — avoid prolonged standing water.',
          'Avoid excessive nitrogen which causes weak growth.',
          'Monitor field weekly for aphid infestation.',
          'Plant resistant varieties for Yellow Leaf Disease where common.',
          'Rotate crop if viral incidence is high.',
        ],
      },
      'Tomato Bacterial spot': {
        'Chemical Treatment': [
          'Use certified disease-free seed; treat seed with hot water (50°C for 25–30 minutes) before sowing.',
          'Start preventive copper-based bactericide (copper hydroxide or copper oxychloride 0.2–0.3%) early if disease history exists.',
          'Tank-mix copper with mancozeb (0.2%) to improve suppression and delay resistance.',
          'Spray at 5–7 day intervals during rainy or highly humid conditions.',
          'Use streptomycin-based bactericides only where legally permitted and rotate carefully to prevent resistance.',
          'Ensure complete spray coverage, especially lower leaf surface.',
          'Avoid excessive copper concentration to prevent phytotoxicity.',
        ],

        'Organic Treatment': [
          'Apply Bordeaux mixture (1%) early in infection stage.',
          'Use neem oil (0.5–1%) for mild early suppression.',
          'Apply Bacillus subtilis–based bio-bactericides preventively.',
          'Remove and destroy severely infected plants immediately.',
          'Avoid working in field when foliage is wet to reduce spread.',
        ],

        'Prevention Techniques': [
          'Use raised beds with drip irrigation; strictly avoid overhead watering.',
          'Maintain proper plant spacing for airflow.',
          'Disinfect tools and hands during pruning or harvesting.',
          'Remove lower leaves touching soil.',
          'Practice 2–3 year crop rotation with non-solanaceous crops.',
          'Destroy crop debris immediately after harvest.',
          'Avoid excessive nitrogen which increases soft, susceptible growth.',
          'Scout field twice weekly during humid weather.',
        ],
      },
      'Tomato Early blight': {
        'Chemical Treatment': [
          'Begin protective spray at first sign of lower leaf lesions.',
          'Apply contact fungicides such as mancozeb (0.25%) or chlorothalonil (0.2%).',
          'Under moderate to high pressure, use systemic fungicides like azoxystrobin, difenoconazole, or tebuconazole.',
          'Use combination products (e.g., azoxystrobin + difenoconazole) for extended protection.',
          'Maintain 7–10 day spray interval during warm, humid weather.',
          'Ensure thorough spray coverage of lower canopy where infection starts.',
          'Rotate fungicide groups (FRAC codes) to prevent resistance.',
        ],

        'Organic Treatment': [
          'Apply copper-based fungicide (0.3%) during early infection stage.',
          'Use Bacillus subtilis–based biofungicides preventively.',
          'Apply neem oil (0.5–1%) for mild suppression.',
          'Remove and destroy heavily infected lower leaves.',
          'Incorporate Trichoderma into soil before planting to reduce inoculum.',
        ],

        'Prevention Techniques': [
          'Practice 2–3 year crop rotation (avoid continuous tomato).',
          'Use disease-free seedlings.',
          'Maintain proper plant spacing for airflow.',
          'Avoid overhead irrigation, especially in evening.',
          'Provide balanced nitrogen — deficiency increases susceptibility.',
          'Stake or trellis plants to reduce soil splash.',
          'Mulch to prevent soil-borne spores from splashing onto leaves.',
          'Scout twice weekly during humid weather.',
        ],
      },
      'Tomato healthy': {
        'Chemical Treatment': [
          'No fungicide required if no disease symptoms and dry weather conditions persist.',
          'Use preventive fungicide (mancozeb 0.25% or chlorothalonil 0.2%) only during prolonged humid or rainy periods.',
          'Apply balanced NPK based on soil test; increase potassium during flowering and fruiting.',
          'Spray calcium nitrate (0.5%) during early fruit development to prevent blossom-end rot.',
          'Apply micronutrient mix (Zn, B, Mg) if deficiency symptoms appear.',
          'Use insecticides only when pests (whitefly, thrips, aphids, fruit borer) cross economic threshold levels.',
        ],

        'Organic Treatment': [
          'Treat seedlings with Trichoderma before transplanting.',
          'Apply well-decomposed compost (8–10 tons/ha) before planting.',
          'Use neem cake in soil for root health.',
          'Spray neem oil (0.5–1%) preventively against sucking pests.',
          'Apply Bacillus-based biofungicides during humid periods.',
          'Use organic mulching to reduce soil splash and moisture fluctuation.',
        ],

        'Prevention Techniques': [
          'Use certified disease-free seedlings.',
          'Maintain proper plant spacing to improve airflow.',
          'Use drip irrigation; avoid overhead watering.',
          'Stake or trellis plants to prevent soil contact.',
          'Remove lower leaves touching soil once canopy develops.',
          'Avoid excessive nitrogen — promotes vegetative growth at expense of fruit.',
          'Scout twice weekly during flowering and fruiting stages.',
          'Practice 2–3 year crop rotation.',
        ],
      },
      'Tomato Late blight': {
        'Chemical Treatment': [
          'Start preventive spray when weather forecast predicts cool, humid conditions — do not wait for severe symptoms.',
          'Apply protectant fungicides such as mancozeb (0.25%) or chlorothalonil (0.2%) before disease appears in high-risk regions.',
          'At first sign of infection, switch to systemic fungicides like metalaxyl + mancozeb, cymoxanil + mancozeb, dimethomorph, or mandipropamid.',
          'Under active outbreak, spray at 5–7 day intervals.',
          'Use combination fungicides (e.g., ametoctradin + dimethomorph) for stronger control under heavy pressure.',
          'Ensure complete coverage of entire canopy, especially underside of leaves.',
          'Rotate fungicide groups strictly — resistance to metalaxyl is common.',
          'Temporarily stop overhead irrigation during outbreak.',
        ],

        'Organic Treatment': [
          'Apply copper-based fungicide (0.3%) as preventive measure.',
          'Use Bordeaux mixture (1%) early in infection stage.',
          'Apply Bacillus subtilis–based biofungicides preventively.',
          'Remove and destroy severely infected plants immediately.',
          'Improve air circulation by pruning lower leaves.',
        ],

        'Prevention Techniques': [
          'Use certified disease-free seedlings.',
          'Avoid overhead irrigation; use drip irrigation only.',
          'Maintain adequate plant spacing.',
          'Remove volunteer tomato and potato plants nearby.',
          'Avoid dense canopy caused by excessive nitrogen.',
          'Monitor weather — two consecutive cool, humid days increase risk dramatically.',
          'Mulch to reduce soil splash.',
          'Practice crop rotation with non-solanaceous crops.',
        ],
      },
      'Tomato Leaf Mold': {
        'Chemical Treatment': [
          'Begin fungicide application at first appearance of yellow leaf spots.',
          'Apply protectant fungicides like chlorothalonil (0.2%) or mancozeb (0.25%).',
          'Use systemic fungicides such as difenoconazole, tebuconazole, or azoxystrobin under moderate to severe pressure.',
          'Maintain 7–10 day spray interval in high humidity conditions.',
          'Rotate fungicide groups (FRAC codes) to prevent resistance.',
          'Ensure thorough coverage of underside of leaves.',
          'Reduce spray interval to 5–7 days in polyhouse outbreaks.',
        ],

        'Organic Treatment': [
          'Apply copper-based fungicide (0.3%) early in infection stage.',
          'Use Bacillus subtilis–based biofungicides preventively.',
          'Apply neem oil (0.5–1%) as supportive suppression.',
          'Remove and destroy heavily infected lower leaves immediately.',
          'Increase ventilation and reduce humidity aggressively.',
        ],

        'Prevention Techniques': [
          'Maintain polyhouse humidity below 80% whenever possible.',
          'Ensure strong cross-ventilation and avoid overnight condensation.',
          'Use resistant tomato varieties suitable for protected cultivation.',
          'Avoid overhead irrigation inside greenhouse.',
          'Maintain proper plant spacing and prune excess foliage.',
          'Avoid excessive nitrogen which increases dense canopy.',
          'Remove lower leaves once fruit sets to improve airflow.',
          'Scout twice weekly in humid seasons.',
        ],
      },
      'Tomato Septoria leaf spot': {
        'Chemical Treatment': [
          'Start fungicide spray at first appearance of lower leaf spots.',
          'Apply protectant fungicides like mancozeb (0.25%) or chlorothalonil (0.2%).',
          'Under moderate to severe pressure, use systemic fungicides such as azoxystrobin, difenoconazole, or tebuconazole.',
          'Maintain 7–10 day spray interval during rainy or humid conditions.',
          'Rotate fungicide groups (FRAC codes) to prevent resistance.',
          'Ensure complete coverage of lower and inner canopy.',
          'Remove heavily infected lower leaves before spraying to reduce inoculum load.',
        ],

        'Organic Treatment': [
          'Apply copper-based fungicide (0.3%) at early infection stage.',
          'Use Bacillus subtilis–based biofungicides preventively.',
          'Remove and destroy infected lower leaves immediately.',
          'Apply neem oil (0.5–1%) as mild suppressive measure.',
          'Use mulching to reduce soil splash transmission.',
        ],

        'Prevention Techniques': [
          'Use certified disease-free seedlings.',
          'Practice 2–3 year crop rotation (avoid continuous tomato).',
          'Avoid overhead irrigation; use drip irrigation.',
          'Maintain proper spacing to improve airflow.',
          'Stake or trellis plants to reduce soil contact.',
          'Remove crop debris immediately after harvest.',
          'Avoid working in field when foliage is wet.',
          'Scout twice weekly during humid weather.',
        ],
      },
      'Tomato Spider mites Two-spotted spider mite': {
        'Chemical Treatment': [
          'Apply miticides at early infestation (before heavy webbing).',
          'Use specific acaricides such as abamectin, spiromesifen, propargite, or fenazaquin as per label dose.',
          'Repeat spray after 5–7 days if population persists.',
          'Rotate miticide groups to prevent resistance (mites develop resistance quickly).',
          'Ensure thorough spray coverage on underside of leaves.',
          'Avoid repeated use of broad-spectrum insecticides which kill natural predators.',
        ],

        'Organic Treatment': [
          'Spray neem oil (0.5–1%) at early stage infestation.',
          'Use insecticidal soap on lower leaf surface.',
          'Release predatory mites (e.g., Phytoseiulus persimilis) in protected cultivation.',
          'Increase humidity slightly in polyhouse (mites prefer dry conditions).',
          'Remove heavily infested leaves in small-scale production.',
        ],

        'Prevention Techniques': [
          'Avoid excessive nitrogen fertilization.',
          'Maintain proper irrigation to reduce plant stress.',
          'Control dust in field (dust favors mite outbreaks).',
          'Encourage natural predators by minimizing unnecessary insecticide use.',
          'Scout weekly during hot, dry weather.',
          'Remove weeds that serve as alternate hosts.',
          'Avoid water stress during flowering and fruiting.',
        ],
      },
      'Tomato Target Spot': {
        'Chemical Treatment': [
          'Begin fungicide application at first appearance of lower canopy lesions.',
          'Apply protectant fungicides such as chlorothalonil (0.2%) or mancozeb (0.25%).',
          'Under moderate to high disease pressure, use systemic fungicides like azoxystrobin, difenoconazole, or boscalid-based products.',
          'Use combination fungicides (e.g., azoxystrobin + difenoconazole) for stronger protection.',
          'Maintain 7-day spray interval during warm, humid weather.',
          'Ensure thorough spray coverage of lower and inner canopy.',
          'Rotate fungicide groups strictly to avoid resistance development.',
        ],

        'Organic Treatment': [
          'Apply copper-based fungicide (0.3%) at early stage infection.',
          'Use Bacillus subtilis–based biofungicides preventively.',
          'Remove and destroy heavily infected lower leaves.',
          'Improve airflow through pruning and staking.',
          'Use mulching to reduce soil splash.',
        ],

        'Prevention Techniques': [
          'Practice 2–3 year crop rotation with non-solanaceous crops.',
          'Maintain proper plant spacing.',
          'Avoid overhead irrigation, especially in evening.',
          'Stake or trellis plants to reduce soil contact.',
          'Remove crop debris immediately after harvest.',
          'Avoid excessive nitrogen which promotes dense canopy.',
          'Scout field twice weekly during humid weather.',
        ],
      },
      'Tomato mosaic virus': {
        'Chemical Treatment': [
          'There is NO curative chemical treatment for mosaic virus.',
          'Immediately remove and destroy infected plants.',
          'Disinfect tools and hands with 1% bleach or milk solution before handling healthy plants.',
          'Use virus-free certified seed or seedlings only.',
          'Avoid tobacco use while handling plants (TMV can spread from tobacco products).',
          'Control any secondary insect vectors if present (aphids may spread related viruses).',
        ],

        'Organic Treatment': [
          'Remove infected plants immediately.',
          'Disinfect tools with hot water or organic-approved sanitizers.',
          'Encourage plant vigor using compost and balanced nutrition.',
          'Apply neem oil to control aphids if present (supportive only).',
          'Avoid working in field when plants are wet.',
        ],

        'Prevention Techniques': [
          'Use certified virus-free seed and resistant varieties.',
          'Practice strict field hygiene and tool sanitation.',
          'Avoid pruning or handling when plants are wet.',
          'Remove weeds that can act as alternate virus hosts.',
          'Rotate crops (avoid continuous tomato or solanaceous crops).',
          'Do not reuse contaminated nursery trays without sterilization.',
          'Train workers on sanitation practices.',
        ],
      },
      'Tomato Yellow Leaf Curl Virus': {
        'Chemical Treatment': [
          'There is NO chemical cure for infected plants.',
          'Immediately remove and destroy infected plants to prevent virus spread.',
          'Control whitefly aggressively using systemic insecticides such as imidacloprid, thiamethoxam, or dinotefuran (as per label).',
          'Use foliar insecticides (e.g., spiromesifen, pyriproxyfen) to control nymph stages.',
          'Rotate insecticide groups to prevent whitefly resistance.',
          'Install yellow sticky traps for monitoring and suppression.',
          'Apply insect-proof netting in nursery and polyhouse production.',
        ],

        'Organic Treatment': [
          'Spray neem oil (0.5–1%) regularly to suppress whitefly population.',
          'Release biological control agents such as Encarsia formosa in protected cultivation.',
          'Use reflective mulches (silver mulch) to repel whiteflies.',
          'Remove infected plants immediately.',
          'Maintain strong plant nutrition to delay decline (does not cure virus).',
        ],

        'Prevention Techniques': [
          'Plant TYLCV-resistant or tolerant tomato varieties.',
          'Use certified virus-free seedlings.',
          'Protect nursery with insect-proof netting.',
          'Control weeds around field — many are alternate virus hosts.',
          'Avoid overlapping tomato crops in same area.',
          'Start whitefly control immediately after transplanting.',
          'Avoid excessive nitrogen — promotes whitefly attraction.',
          'Practice crop-free period to break virus cycle.',
        ],
      },
    };
    return treatmentMap[disease] ??
        {
          'General Advice': [
            'Consult local agricultural extension for specific treatment.',
            'Identify the exact cause of the disease for proper treatment.',
            'For more infromation see the treatment tab given alongside',
          ],
        };
  }

  Widget _buildTreatmentTab() {
    if (!_isModelLoaded || _selectedDisease == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final treatments = _getTreatments(_selectedDisease!);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Dropdown for disease selection
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: DropdownButton<String>(
              value: _selectedDisease,
              isExpanded: true,
              underline: const SizedBox(),
              items: _labels.map((String disease) {
                return DropdownMenuItem<String>(
                  value: disease,
                  child: Text(
                    disease.replaceAll('___', ' - ').replaceAll('_', ' '),
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedDisease = newValue;
                });
              },
            ),
          ),
          const SizedBox(height: 20),
          // Treatment sections
          ...treatments.entries.map((entry) {
            return Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(
                      context,
                    ).colorScheme.shadow.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.key,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...entry.value.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '• ',
                            style: TextStyle(
                              fontSize: 16,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              item,
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
