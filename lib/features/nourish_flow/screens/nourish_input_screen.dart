
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:sentia_flow/features/nourish_flow/models/health_profile_model.dart';
import 'package:sentia_flow/features/nourish_flow/models/nourish_feature_model.dart';
import 'package:sentia_flow/features/nourish_flow/screens/result_screen.dart';
import 'package:sentia_flow/services/gemma_service.dart';
import 'package:sentia_flow/widgets/custom_text_field.dart';
import 'package:sentia_flow/widgets/primary_button.dart';
import 'package:sentia_flow/widgets/spacing_widget.dart';

class NourishInputScreen extends StatefulWidget {
  final NourishFeature feature;
  const NourishInputScreen({super.key, required this.feature});

  @override
  State<NourishInputScreen> createState() => _NourishInputScreenState();
}

class _NourishInputScreenState extends State<NourishInputScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();

  // Controllers
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _systolicController = TextEditingController();
  final _diastolicController = TextEditingController();
  final _glucoseController = TextEditingController();
  final _calorieTargetController = TextEditingController();
  final _mealTypeController = TextEditingController();

  final Set<DietaryPreference> _selectedPreferences = {};
  File? _imageFile;

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _systolicController.dispose();
    _diastolicController.dispose();
    _glucoseController.dispose();
    _calorieTargetController.dispose();
    _mealTypeController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;
    setState(() {
      _imageFile = File(pickedFile.path);
    });
  }

  Future<void> _performAnalysis() async {
    final bool isMealPlanner = widget.feature.type == FeatureType.mealPlanner;

    // 1. On valide le formulaire. La logique est maintenant dans CustomTextField.
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields.')),
      );
      return;
    }

    // 2. On vérifie que l'image est sélectionnée.
    if (_imageFile == null) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image to analyze.')),
      );
      return;
    }

    FocusScope.of(context).unfocus();

    final gemmaService = Provider.of<GemmaService>(context, listen: false);
    
    String detailedPrompt;

    // if (isMealPlanner) {
    //   detailedPrompt = """
    //     You are an expert nutritionist and chef. Your tone is encouraging, professional, and easy to understand.
        
    //     **Your PRIMARY TASK is to identify the ingredients in the provided image and create a healthy meal plan based on them.** You MUST use the ingredients from the image as the foundation for the meal.

    //     Then, adapt this meal plan to fit the user's health profile provided below for context.
    //     ---
    //     **User Health Profile (for context):**
    //     - Weight: ${_weightController.text} kg
    //     - Height: ${_heightController.text} cm
    //     - Blood Pressure: ${_systolicController.text}/${_diastolicController.text}
    //     - Blood Glucose: ${_glucoseController.text} mg/dL
    //     - Dietary Preferences: ${_selectedPreferences.map((p) => p.name).join(', ')}
    //     - Meal Type: ${_mealTypeController.text.isNotEmpty ? _mealTypeController.text : 'Not specified'}
    //     - Target calories for this specific meal: ${_calorieTargetController.text.isNotEmpty ? _calorieTargetController.text : 'Not specified'}
    //     ---
    //     The response should be formatted in Markdown and include:
    //     1.  **Recipe Name**: A creative name for the dish based on the image's ingredients.
    //     2.  **Ingredients List**: A list of the ingredients you identified in the image, plus any simple optional additions.
    //     3.  **Step-by-Step Instructions**: Clear cooking instructions.
    //     4.  **Nutritional Estimation**: An estimated calorie count and macronutrient breakdown (proteins, carbs, fats).
    //   """;
    // } else { // Meal Analyzer
    //   detailedPrompt = """
    //     You are an expert nutritionist. Your tone should be helpful, clear, and scientific yet easy to understand.

    //     First, start your response with a section titled "User Context Summary" that repeats the following data in a clear, readable format.
    //     ---
    //     - Dietary Preferences: ${_selectedPreferences.isNotEmpty ? _selectedPreferences.map((p) => p.name).join(', ') : 'None'}
    //     - Meal Type: ${_mealTypeController.text.isNotEmpty ? _mealTypeController.text : 'Not specified'}
    //     - Calorie Target for this meal: ${_calorieTargetController.text.isNotEmpty ? _calorieTargetController.text : 'Not specified'}
    //     ---
    //     After the summary, analyze the meal in the provided image.
    //     Provide a detailed analysis of the meal. The response should be formatted in Markdown and include:
    //     1.  **Meal Identification**: What dish do you think this is?
    //     2.  **Calorie & Macronutrient Estimation**: Provide an estimated calorie, protein, carbohydrate, and fat count.
    //     3.  **Healthiness Score**: Give a score from 1 (unhealthy) to 10 (very healthy) with a brief justification.
    //     4.  **Healthy Alternative Suggestions**: Suggest one or two healthier alternatives or modifications.
    //   """;
    // }
    if (isMealPlanner) {
      // **PROMPT CONCIS ET DIRECTIF**
      detailedPrompt = """
        **New Request: Ignore all previous context.**
        You are a nutritionist. Based on the ingredients in the image and the user's health data, create a simple meal idea.
        **Respond in Markdown, and keep the total response under 70 words.**

        Health Data:
        - W: ${_weightController.text}kg, H: ${_heightController.text}cm, BP: ${_systolicController.text}/${_diastolicController.text}, Glucose: ${_glucoseController.text}mg/dL
        - Prefs: ${_selectedPreferences.map((p) => p.name).join(', ')}
        
        Provide:
        1. **Meal Idea**:
        2. **Main Ingredients**:
        3. **Quick Tip**:
        4. **Est. Calories**:
      """;
    } else { 
      // **PROMPT CONCIS ET DIRECTIF**
      detailedPrompt = """
        **New Request: Ignore all previous context.**
        You are a nutritionist. Analyze the meal in the image.
        **Respond in Markdown, and keep the total response under 60 words.**

        Context:
        - Prefs: ${_selectedPreferences.isNotEmpty ? _selectedPreferences.map((p) => p.name).join(', ') : 'None'}
        - Meal Type: ${_mealTypeController.text.isNotEmpty ? _mealTypeController.text : 'Not specified'}
        
        Provide:
        1. **Meal ID**:
        2. **Est. Calories/Macros**:
        3. **Health Score (1-10)**:
      """;
    }

    try {
      final Uint8List imageBytes = await _imageFile!.readAsBytes();
      
      // await gemmaService.clearChatHistory();
      
      final Stream<String> resultStream = gemmaService.generateFeatureResponseStream(
        prompt: detailedPrompt,
        imageBytes: imageBytes,
      );

      if (!mounted) return;

       Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultScreen(
            title: widget.feature.name,
            resultStream: resultStream,
          ),
        ),
      );

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to get response: $e')),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final gemmaService = Provider.of<GemmaService>(context);
    final bool isMealPlanner = widget.feature.type == FeatureType.mealPlanner;
    final bool hasImage = _imageFile != null;

    String buttonText;
    IconData buttonIcon;

    if (!hasImage) {
      buttonText = 'Select Image';
      buttonIcon = Icons.add_photo_alternate_outlined;
    } else {
      buttonText = isMealPlanner ? 'Create Healthy Plan' : 'Analyze Meal';
      buttonIcon = isMealPlanner ? Icons.kitchen_outlined : Icons.analytics_outlined;
    }

    // --- DÉBUT DE LA CORRECTION ---
    // On enveloppe le Scaffold avec PopScope pour gérer la navigation "Retour".
  
    return PopScope(
      canPop: true,
      // Utilisation de la nouvelle méthode `onPopInvokedWithResult`
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        // La logique reste la même : on cache le clavier quand la navigation "Retour" se produit.
        if (didPop) { // On s'assure que la navigation a bien eu lieu
          FocusScope.of(context).unfocus();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.feature.name, style: TextStyle(fontSize: 20.sp)),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isMealPlanner) ...[
                            _buildSectionTitle('1. Your Health Profile'),
                            Row(
                              children: [
                                Expanded(child: CustomTextField(controller: _weightController, label: 'Weight (kg)', icon: Icons.monitor_weight_outlined)),
                                const WidthSpace(12),
                                Expanded(child: CustomTextField(controller: _heightController, label: 'Height (cm)', icon: Icons.height_outlined)),
                              ],
                            ),
                            Row(
                              children: [
                                Expanded(child: CustomTextField(controller: _systolicController, label: 'Systolic BP', icon: Icons.favorite_border)),
                                const WidthSpace(12),
                                Expanded(child: CustomTextField(controller: _diastolicController, label: 'Diastolic BP', icon: Icons.favorite)),
                              ],
                            ),
                            CustomTextField(controller: _glucoseController, label: 'Blood Glucose (mg/dL)', icon: Icons.bloodtype_outlined),
                            const HeightSpace(12),
                            _buildSectionTitle('2. Dietary Preferences'),
                          ] else ...[
                            _buildSectionTitle('1. Additional Information (Optional)'),
                          ],
                          Wrap(
                            spacing: 8.w,
                            runSpacing: 4.h,
                            children: DietaryPreference.values.map((preference) {
                              final isSelected = _selectedPreferences.contains(preference);
                              return FilterChip(
                                label: Text(preference.name),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) { _selectedPreferences.add(preference); } else { _selectedPreferences.remove(preference); }
                                  });
                                },
                                selectedColor: Theme.of(context).primaryColor.withAlpha(100),
                                checkmarkColor: Theme.of(context).primaryColor,
                              );
                            }).toList(),
                          ),
                          const HeightSpace(12),
                          CustomTextField(controller: _calorieTargetController, label: 'Target Calories for this Meal (opt.)', icon: Icons.local_fire_department_outlined, isNumeric: true, isRequired: false),
                          CustomTextField(controller: _mealTypeController, label: 'Meal Type (e.g., Breakfast)', icon: Icons.restaurant_outlined, isNumeric: false, isRequired: false),
                          const HeightSpace(20),
                          _buildSectionTitle(isMealPlanner ? '3. Image of Your Ingredients' : '2. Take a Picture of Your Meal'),
                          _buildImagePicker(),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 8.h, bottom: 8.h),
                  child: ValueListenableBuilder<bool>(
                    valueListenable: gemmaService.isGenerating,
                    builder: (context, isLoading, child) {
                      return PrimaryButton(
                        text: buttonText,
                        icon: buttonIcon,
                        isLoading: isLoading,
                        onPressed: hasImage ? _performAnalysis : _pickImage,
                      );
                    }
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Text(title, style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 150.h,
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade800),
          borderRadius: BorderRadius.circular(15.r),
          color: Colors.black.withAlpha(50),
        ),
        child: _imageFile != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(14.r),
                child: Image.file(_imageFile!, fit: BoxFit.cover),
              )
            : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt_outlined, color: Colors.grey, size: 40.sp),
                    const HeightSpace(8),
                    Text(
                      'Tap here to select an image',
                      style: TextStyle(color: Colors.grey, fontSize: 16.sp),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}



