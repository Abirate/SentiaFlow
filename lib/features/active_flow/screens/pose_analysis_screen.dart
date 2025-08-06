import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

// Imports depuis la structure de votre projet
import 'package:sentia_flow/features/active_flow/models/exercise_model.dart';
import 'package:sentia_flow/utils/angle_calculator.dart';
import 'package:sentia_flow/utils/pose_painter.dart';

// Imports pour la logique de feedback
import 'package:sentia_flow/features/nourish_flow/screens/result_screen.dart';
import 'package:sentia_flow/services/gemma_service.dart';
import 'package:sentia_flow/widgets/primary_button.dart';
import 'package:sentia_flow/widgets/spacing_widget.dart';


class PoseAnalysisScreen extends StatefulWidget {
  final Exercise exercise;
  const PoseAnalysisScreen({super.key, required this.exercise});

  @override
  State<PoseAnalysisScreen> createState() => _PoseAnalysisScreenState();
}

class _PoseAnalysisScreenState extends State<PoseAnalysisScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  final PoseDetector _poseDetector = PoseDetector(
    options: PoseDetectorOptions(),
  );

  File? _imageFile;
  ui.Image? _decodedImage;
  List<Pose> _poses = [];
  Map<String, double> _angles = {};
  bool _isProcessingImage = false;

  @override
  void dispose() {
    _poseDetector.close();
    super.dispose();
  }

  Future<void> _pickAndAnalyzeImage(ImageSource source) async {
    final pickedFile = await _imagePicker.pickImage(source: source);
    if (pickedFile == null) return;

    setState(() {
      _isProcessingImage = true;
      _angles = {};
      _poses = [];
      _decodedImage = null;
    });

    _imageFile = File(pickedFile.path);
    final inputImage = InputImage.fromFilePath(_imageFile!.path);
    final poses = await _poseDetector.processImage(inputImage);
    final decodedImage = await decodeImageFromList(
      _imageFile!.readAsBytesSync(),
    );
    final angles = AngleCalculator.getAngles(
      poses.firstOrNull,
      widget.exercise.keyAngles,
    );

    setState(() {
      _decodedImage = decodedImage;
      _poses = poses;
      _angles = angles;
      _isProcessingImage = false;
    });
  }

  Future<void> _getGemmaFeedback() async {
    if (_imageFile == null || _angles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please analyze an image first.')),
      );
      return;
    }

    final gemmaService = Provider.of<GemmaService>(context, listen: false);

    final anglesString = _angles.entries
        .map((e) => '- ${e.key}: ${e.value.toStringAsFixed(1)}°')
        .join('\n');

    final prompt =
        """
      **New Request: Ignore all previous context.**
      As an AI personal trainer, analyze the user's '${widget.exercise.name}' in the image, using these angles as reference:
      $anglesString

      Give one short, insightful tip to improve their form. Be encouraging. Respond in concise Markdown.
    """;

    try {
      final Uint8List imageBytes = await _imageFile!.readAsBytes();

      final Stream<String> resultStream = gemmaService
          .generateFeatureResponseStream(
            prompt: prompt,
            imageBytes: imageBytes,
          );

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultScreen(
            title: '${widget.exercise.name} Feedback',
            resultStream: resultStream,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to get response from Gemma: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // On récupère le thème une seule fois pour le réutiliser
    final theme = Theme.of(context);
    final gemmaService = Provider.of<GemmaService>(context);
    final bool canGetFeedback = _angles.isNotEmpty && !_isProcessingImage;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.exercise.name), // Pas besoin de style, il hérite de appBarTheme
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: 20.h),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Column(
            children: [
              const HeightSpace(20),
              Container(
                height: 400.h,
                width: double.infinity,
                decoration: BoxDecoration(
                  // MODIFIÉ : Utilisation d'une couleur plus douce pour la bordure
                  border: Border.all(color: theme.dividerColor),
                  borderRadius: BorderRadius.circular(15.r),
                ),
                child: _buildImageDisplay(theme),
              ),
              const HeightSpace(20),
              _buildResultsDisplay(theme),
              const HeightSpace(20),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: ValueListenableBuilder<bool>(
            valueListenable: gemmaService.isGenerating,
            builder: (context, isLoading, child) {
              return PrimaryButton(
                text: 'Get AI Feedback',
                icon: Icons.smart_toy_outlined,
                isLoading: isLoading,
                onPressed: canGetFeedback ? _getGemmaFeedback : null,
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildImageDisplay(ThemeData theme) {
    if (_isProcessingImage) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_decodedImage == null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // MODIFIÉ : L'icône et le texte utilisent la couleur secondaire du thème
              Icon(Icons.upload_file, size: 80.sp, color: theme.textTheme.bodyMedium?.color),
              const HeightSpace(16),
              Text(
                'Press a button below to start',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(fontSize: 18.sp),
              ),
            ],
          ),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(14.r),
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: _decodedImage!.width.toDouble(),
          height: _decodedImage!.height.toDouble(),
          child: CustomPaint(
            painter: PosePainter(image: _decodedImage!, poses: _poses),
          ),
        ),
      ),
    );
  }

  Widget _buildResultsDisplay(ThemeData theme) {
    if (_angles.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Angle Analysis',
          // MODIFIÉ : Le style est pris depuis le thème pour une bonne lisibilité
          style: theme.textTheme.headlineSmall,
        ),
        const HeightSpace(12),
        SizedBox(
          height: 90.h,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: _angles.entries.map((entry) {
              // MODIFIÉ : La carte utilise maintenant le cardTheme
              return Card(
                // SUPPRIMÉ : color: Colors.white.withAlpha(26),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 8.h,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        entry.key,
                        // MODIFIÉ : Le style est pris du thème (texte secondaire)
                        style: theme.textTheme.bodyMedium,
                      ),
                      const HeightSpace(8),
                      Text(
                        '${entry.value.toStringAsFixed(1)}°',
                        // C'ÉTAIT DÉJÀ CORRECT : Utilise la couleur primaire
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: theme.primaryColor,
                          fontSize: 18.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildButton(
            onPressed: () => _pickAndAnalyzeImage(ImageSource.gallery),
            icon: Icons.photo_library,
            label: 'Gallery',
          ),
        ),
        const WidthSpace(16),
        Expanded(
          child: _buildButton(
            onPressed: () => _pickAndAnalyzeImage(ImageSource.camera),
            icon: Icons.camera_alt,
            label: 'Camera',
          ),
        ),
      ],
    );
  }

  Widget _buildButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
  }) {
    // Ce widget était déjà bien codé, il utilise le thème !
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: Theme.of(context).primaryColor,
        side: BorderSide(color: Theme.of(context).primaryColor, width: 1.5),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        textStyle: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
      ),
    );
  }
}

// class PoseAnalysisScreen extends StatefulWidget {
//   final Exercise exercise;
//   const PoseAnalysisScreen({super.key, required this.exercise});

//   @override
//   State<PoseAnalysisScreen> createState() => _PoseAnalysisScreenState();
// }

// class _PoseAnalysisScreenState extends State<PoseAnalysisScreen> {
//   final ImagePicker _imagePicker = ImagePicker();
//   final PoseDetector _poseDetector = PoseDetector(
//     options: PoseDetectorOptions(),
//   );

//   File? _imageFile;
//   ui.Image? _decodedImage;
//   List<Pose> _poses = [];
//   Map<String, double> _angles = {};
//   bool _isProcessingImage = false;

//   @override
//   void dispose() {
//     _poseDetector.close();
//     super.dispose();
//   }

//   Future<void> _pickAndAnalyzeImage(ImageSource source) async {
//     final pickedFile = await _imagePicker.pickImage(source: source);
//     if (pickedFile == null) return;

//     setState(() {
//       _isProcessingImage = true;
//       _angles = {};
//       _poses = [];
//       _decodedImage = null;
//     });

//     _imageFile = File(pickedFile.path);
//     final inputImage = InputImage.fromFilePath(_imageFile!.path);
//     final poses = await _poseDetector.processImage(inputImage);
//     final decodedImage = await decodeImageFromList(
//       _imageFile!.readAsBytesSync(),
//     );
//     final angles = AngleCalculator.getAngles(
//       poses.firstOrNull,
//       widget.exercise.keyAngles,
//     );

//     setState(() {
//       _decodedImage = decodedImage;
//       _poses = poses;
//       _angles = angles;
//       _isProcessingImage = false;
//     });
//   }

//   Future<void> _getGemmaFeedback() async {
//     if (_imageFile == null || _angles.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please analyze an image first.')),
//       );
//       return;
//     }

//     final gemmaService = Provider.of<GemmaService>(context, listen: false);

//     final anglesString = _angles.entries
//         .map((e) => '- ${e.key}: ${e.value.toStringAsFixed(1)}°')
//         .join('\n');

//     final prompt =
//         """
//       As an AI personal trainer, analyze the user's '${widget.exercise.name}' in the image, using these angles as reference:
//       $anglesString

//       Give one short, insightful tip to improve their form. Be encouraging. Respond in concise Markdown.
//     """;

//     try {
//       final Uint8List imageBytes = await _imageFile!.readAsBytes();

//       final Stream<String> resultStream = gemmaService
//           .generateFeatureResponseStream(
//             prompt: prompt,
//             imageBytes: imageBytes,
//           );

//       if (!mounted) return;

//       Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (context) => ResultScreen(
//             title: '${widget.exercise.name} Feedback',
//             resultStream: resultStream,
//           ),
//         ),
//       );
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to get response from Gemma: $e')),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final gemmaService = Provider.of<GemmaService>(context);
//     final bool canGetFeedback = _angles.isNotEmpty && !_isProcessingImage;

//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           widget.exercise.name,
//           style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
//         ),
//         centerTitle: true,
//       ),
//       body: SingleChildScrollView(
//         padding: EdgeInsets.only(bottom: 20.h),
//         child: Padding(
//           padding: EdgeInsets.symmetric(horizontal: 16.w),
//           child: Column(
//             children: [
//               const HeightSpace(20),
//               Container(
//                 height: 400.h,
//                 width: double.infinity,
//                 decoration: BoxDecoration(
//                   border: Border.all(color: Colors.grey.shade800),
//                   borderRadius: BorderRadius.circular(15.r),
//                 ),
//                 child: _buildImageDisplay(),
//               ),
//               const HeightSpace(20),
//               _buildResultsDisplay(),
//               const HeightSpace(20),
//               _buildActionButtons(),
//             ],
//           ),
//         ),
//       ),
//       bottomNavigationBar: SafeArea(
//         child: Padding(
//           padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
//           child: ValueListenableBuilder<bool>(
//             valueListenable: gemmaService.isGenerating,
//             builder: (context, isLoading, child) {
//               return PrimaryButton(
//                 text: 'Get AI Feedback',
//                 icon: Icons.smart_toy_outlined,
//                 isLoading: isLoading,
//                 onPressed: canGetFeedback ? _getGemmaFeedback : null,
//               );
//             },
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildImageDisplay() {
//     if (_isProcessingImage) {
//       return const Center(child: CircularProgressIndicator());
//     }
//     if (_decodedImage == null) {
//       return Center(
//         child: Padding(
//           padding: EdgeInsets.symmetric(horizontal: 20.w),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(Icons.upload_file, size: 80.sp, color: Colors.grey),
//               const HeightSpace(16),
//               Text(
//                 'Press a button below to start',
//                 textAlign: TextAlign.center,
//                 style: TextStyle(fontSize: 18.sp, color: Colors.grey),
//               ),
//             ],
//           ),
//         ),
//       );
//     }
//     return ClipRRect(
//       borderRadius: BorderRadius.circular(14.r),
//       child: FittedBox(
//         fit: BoxFit.contain,
//         child: SizedBox(
//           width: _decodedImage!.width.toDouble(),
//           height: _decodedImage!.height.toDouble(),
//           child: CustomPaint(
//             painter: PosePainter(image: _decodedImage!, poses: _poses),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildResultsDisplay() {
//     if (_angles.isEmpty) {
//       return const SizedBox.shrink();
//     }
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.stretch,
//       children: [
//         Text(
//           'Angle Analysis',
//           style: TextStyle(
//             fontSize: 18.sp,
//             fontWeight: FontWeight.bold,
//             color: Colors.white,
//           ),
//         ),
//         const HeightSpace(12),
//         SizedBox(
//           height: 90.h,
//           child: ListView(
//             scrollDirection: Axis.horizontal,
//             children: _angles.entries.map((entry) {
//               return Card(
//                 color: Colors.white.withAlpha(26),
//                 child: Padding(
//                   padding: EdgeInsets.symmetric(
//                     horizontal: 16.w,
//                     vertical: 8.h,
//                   ),
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Text(
//                         entry.key,
//                         style: TextStyle(
//                           fontSize: 14.sp,
//                           color: Colors.white70,
//                         ),
//                       ),
//                       const HeightSpace(8),
//                       Text(
//                         '${entry.value.toStringAsFixed(1)}°',
//                         style: TextStyle(
//                           fontSize: 18.sp,
//                           fontWeight: FontWeight.bold,
//                           color: Theme.of(context).primaryColor,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               );
//             }).toList(),
//           ),
//         ),
//       ],
//     );
//   }

//   // MODIFIÉ : La méthode qui construit les boutons d'action
//   Widget _buildActionButtons() {
//     return Row(
//       children: [
//         // J'ai enveloppé chaque bouton dans un widget Expanded.
//         Expanded(
//           child: _buildButton(
//             onPressed: () => _pickAndAnalyzeImage(ImageSource.gallery),
//             icon: Icons.photo_library,
//             label: 'Gallery',
//           ),
//         ),
//         const WidthSpace(16), // Un peu d'espace entre les boutons
//         Expanded(
//           child: _buildButton(
//             onPressed: () => _pickAndAnalyzeImage(ImageSource.camera),
//             icon: Icons.camera_alt,
//             label: 'Camera',
//           ),
//         ),
//       ],
//     );
//   }

//   // Dans pose_analysis_screen.dart
//   // Dans pose_analysis_screen.dart

//   Widget _buildButton({
//     required VoidCallback onPressed,
//     required IconData icon,
//     required String label,
//   }) {
//     // On utilise OutlinedButton pour un style plus léger
//     return OutlinedButton.icon(
//       onPressed: onPressed,
//       icon: Icon(icon),
//       label: Text(label),
//       style: OutlinedButton.styleFrom(
//         // Le texte et l'icône prendront la couleur primaire du thème (Teal)
//         foregroundColor: Theme.of(context).primaryColor,
//         // On ajoute une bordure de la même couleur
//         side: BorderSide(color: Theme.of(context).primaryColor, width: 1.5),
//         padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
//         // Un radius plus subtil et cohérent avec le reste de votre design
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(12.r),
//         ),
//         textStyle: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
//       ),
//     );
//   }
// }
