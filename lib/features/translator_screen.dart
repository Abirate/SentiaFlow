// import 'dart:typed_data';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:flutter_gemma/core/message.dart';
// import 'package:flutter_gemma/pigeon.g.dart';
// import 'package:sentia_flow/services/gemma_service.dart';
// import 'package:sentia_flow/widgets/chat_input_area.dart';
// import 'package:sentia_flow/widgets/chat_message_widget.dart';
// import 'package:sentia_flow/widgets/state_views.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:provider/provider.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:connectivity_plus/connectivity_plus.dart';

// enum ScreenState {
//   configuring, // On vérifie le token et initialise (L'écran est en train de se configurer.)
//   ready, // Tout est prêt, on affiche l'app (L'écran est prêt à être utilisé.)
//   configFailed, // L'utilisateur n'a pas fourni de token (La configurat
//   offlineNeedsSetup, // NOUVEAU : Hors ligne et la configuration/token est nécessaire
// }

// class TranslatorScreen extends StatefulWidget {
//   const TranslatorScreen({super.key});

//   @override
//   State<TranslatorScreen> createState() => _TranslatorScreenState();
// }

// class _TranslatorScreenState extends State<TranslatorScreen> {
//   // Déclaration du service
//   // late final GemmaService _gemmaService;
//   // On supprime la ligne : late final GemmaService _gemmaService;
//   // car le service est maintenant fourni par le Provider.

//   // Contrôleurs et variables d'état de l'UI
//   final ImagePicker _imagePicker = ImagePicker();
//   final _textController = TextEditingController();
//   Uint8List? _selectedImage;
//   ScreenState _screenState = ScreenState.configuring;

//   @override
//   void initState() {
//     super.initState();
//     // On lance le processus de configuration au démarrage.
//     _initializeGemma();
//   }

//   @override
//   void dispose() {
//     // Le dispose est maintenant géré par le Provider dans main.dart,
//     // mais on garde celui du textController.
//     _textController.dispose();
//     super.dispose();
//   }

//   /// Gère la configuration et l'initialisation du service fourni.
//   /// VERSION CORRIGÉE : Gère la validation du token de manière plus robuste en ligne et hors ligne
//   // dans lib/features/translator_screen.dart

//   Future<void> _initializeGemma() async {

//     // --- DÉBUT DE LA CORRECTION ---
//     // On réinitialise l'état du service IMMÉDIATEMENT
//     // pour éviter de ré-afficher l'ancien message d'erreur.(quand on reduit l'ecran au moment de téléch)
//     // On utilise 'await' car la fonction "resetState" est maintenant asynchrone.
//     //await Provider.of<GemmaService>(context, listen: false).resetState();

//     // 1. On récupère le service AVANT la pause 'await'.
//     // on le récupère UNE SEULE FOIS et on le met dans une variable
//     final gemmaService = Provider.of<GemmaService>(context, listen: false);
    
//     // 2. On exécute l'opération asynchrone sur la variable.
//     // On utilise cette variable pour réinitialiser l'état.
//     await gemmaService.resetState();
//     // --- FIN DE LA CORRECTION ---

//     // MODIFICATION 1 : S'assurer qu'on repasse en état de configuration si on réessaie
//     // (par exemple, depuis le bouton "Retry" de l'écran "OfflineSetupView").

//     if (_screenState != ScreenState.configuring) {
//       // On utilise 'mounted' pour éviter d'appeler setState si le widget n'est plus affiché.
//       if (mounted) {
//         setState(() => _screenState = ScreenState.configuring);
//       }
//     }

//     final prefs = await SharedPreferences.getInstance();

//     final modelPath = await GemmaService.getModelPath();
//     final modelFile = File(modelPath);
//     final bool modelExists = await modelFile.exists();
//     final String? userToken = prefs.getString('user_hf_token');

//     // Cas idéal : le modèle existe ET on a un token. On démarre en mode hors-ligne.
//     if (modelExists && userToken != null && userToken.isNotEmpty) {
//       debugPrint(
//         "Model and token found locally. Starting in offline-first mode.",
//       );

//       final savedBackend = prefs.getString('preferred_backend') ?? 'cpu';
//       final backend = savedBackend == 'gpu'
//           ? PreferredBackend.gpu
//           : PreferredBackend.cpu;

//       if (mounted) {
//         setState(() => _screenState = ScreenState.ready);
//       }
//       gemmaService.configureAndInitialize(
//         huggingFaceToken: userToken,
//         preferredBackend: backend,
//         skipOnlineCheck: true,
//       );
//       return;
//     }

//     // --- FLUX DE CONFIGURATION EN LIGNE ---
//     // Ce bloc est exécuté si le modèle manque OU si le token est manquant/réinitialisé.
//     debugPrint("Entering online setup flow (model missing or token reset).");

//     // --- MODIFICATION 2 : VÉRIFICATION DE LA CONNEXION INTERNET ROBUSTE (LA CORRECTION DU BUG) ---
//     final connectivityResult = await (Connectivity().checkConnectivity());

//     // On vérifie si on est vraiment hors ligne.
//     // Si la liste est vide, ou si elle ne contient que des connexions sans internet (comme Bluetooth).
//     // Note: connectivity_plus renvoie maintenant une List<ConnectivityResult>.
//     bool isOffline =
//         connectivityResult.isEmpty ||
//         connectivityResult.every(
//           (element) =>
//               element == ConnectivityResult.none ||
//               element == ConnectivityResult.bluetooth ||
//               element == ConnectivityResult.other,
//         );

//     if (isOffline) {
//       debugPrint("No internet connection detected during setup flow.");

//       // MODIFICATION CLÉ : Au lieu de ConfigFailed (qui crée la boucle vue sur l'image), on utilise le nouvel état spécifique.
//       // Cela affichera OfflineSetupView.
//       if (mounted) {
//         setState(() => _screenState = ScreenState.offlineNeedsSetup);
//       }
//       return; // On arrête tout ici.
//     }
//     // --- FIN DE LA MODIFICATION ---

//     // Si on est en ligne, on continue la procédure de validation/demande du token.
//     String? tokenForSetup = userToken;
//     bool isTokenValid = false;
//     if (tokenForSetup != null && tokenForSetup.isNotEmpty) {
//       // On tente de valider le token existant puisqu'on est en ligne.
//       isTokenValid = await GemmaService.validateToken(tokenForSetup);
//     }

//     // Si le token n'est pas valide (ou absent), on le demande à l'utilisateur.
//     if (!isTokenValid) {
//       while (true) {
//         if (mounted) {
//           tokenForSetup = await _showTokenDialog(context);
//         } else {
//           return;
//         }

//         // Si l'utilisateur annule la saisie du token.
//         if (tokenForSetup == null || tokenForSetup.isEmpty) {
//           if (mounted) {
//             setState(() => _screenState = ScreenState.configFailed);
//           }
//           return;
//         }

//         // Validation du nouveau token saisi.
//         isTokenValid = await GemmaService.validateToken(tokenForSetup);
//         if (isTokenValid) break;

//         // Affichage d'une erreur si le token est invalide.
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//               content: Text('Invalid or unauthorized token. Please try again.'),
//               backgroundColor: Colors.red,
//             ),
//           );
//         }
//       }
//     }

//     // Sauvegarde du token validé et configuration finale.
//     await prefs.setString('user_hf_token', tokenForSetup!);
//     final savedBackend = prefs.getString('preferred_backend') ?? 'cpu';
//     final backend = savedBackend == 'gpu'
//         ? PreferredBackend.gpu
//         : PreferredBackend.cpu;

//     if (mounted) {
//       setState(() => _screenState = ScreenState.ready);
//     }

//     // Lancement de l'initialisation (qui inclura le téléchargement si nécessaire).
//     gemmaService.configureAndInitialize(
//       huggingFaceToken: tokenForSetup,
//       preferredBackend: backend,
//       skipOnlineCheck:
//           false, // On s'assure que le téléchargement peut se lancer
//     );
//   }

//   /// Affiche une boîte de dialogue pour demander le token à l'utilisateur.
//   Future<String?> _showTokenDialog(BuildContext context) {
//     final textController = TextEditingController();

//     return showDialog<String>(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) {
//         return AlertDialog(
//           title: const Text('Hugging Face Token Required'),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               const Text(
//                 'Please enter your Hugging Face access token with read permissions to download the model.',
//               ),
//               const SizedBox(height: 16),
//               TextField(
//                 controller: textController,
//                 decoration: InputDecoration(
//                   labelText: 'Access Token',
//                   hintText: 'Enter your HF read token',
//                   hintStyle: TextStyle(
//                     color: const Color.fromRGBO(
//                       0,
//                       0,
//                       0,
//                       0.5,
//                     ), // teinte plus transparente
//                     fontStyle: FontStyle.italic,
//                   ),
//                   border: OutlineInputBorder(),
//                 ),
//               ),
//             ],
//           ),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 final token = textController.text.trim();
//                 if (token.isNotEmpty) {
//                   Navigator.of(context).pop(token);
//                 }
//               },
//               child: const Text('Save and Continue'),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   /// Affiche la boîte de dialogue pour choisir le backend et réinitialiser le token.
//   /// Dans bouton settings
//   Future<void> _showSettingsDialog() async {
//     final prefs = await SharedPreferences.getInstance();
//     final currentBackend = prefs.getString('preferred_backend') ?? 'cpu';

//     if (!mounted) return;

//     final result = await showDialog<String>(
//       context: context,
//       builder: (dialogContext) => SimpleDialog(
//         title: const Text('Settings'),
//         children: [
//           // Option pour le CPU
//           SimpleDialogOption(
//             onPressed: () => Navigator.pop(dialogContext, 'cpu'),
//             child: Row(
//               children: [
//                 Radio<String>(
//                   value: 'cpu',
//                   groupValue: currentBackend,
//                   onChanged: (v) => Navigator.pop(dialogContext, 'cpu'),
//                 ),
//                 // CORRECTION ICI
//                 const Flexible(child: Text('CPU (Slower, Compatible)')),
//               ],
//             ),
//           ),
//           // Option pour le GPU
//           SimpleDialogOption(
//             onPressed: () => Navigator.pop(dialogContext, 'gpu'),
//             child: Row(
//               children: [
//                 Radio<String>(
//                   value: 'gpu',
//                   groupValue: currentBackend,
//                   onChanged: (v) => Navigator.pop(dialogContext, 'gpu'),
//                 ),
//                 // CORRECTION ICI
//                 const Flexible(child: Text('GPU (Faster, Recommended)')),
//               ],
//             ),
//           ),
//           const Divider(),
//           // Option pour réinitialiser le token
//           // Attention: reset token HF (1)
//           SimpleDialogOption(
//             onPressed: () => Navigator.pop(dialogContext, 'reset_token'),
//             child: const Row(
//               children: [
//                 Icon(Icons.refresh, color: Colors.orange),
//                 SizedBox(width: 8),
//                 Text('Reset HF Token'),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );

//     if (!mounted || result == null) return;

//     // Attention : ici aussi concerne token_reset de HF (2)
//     // **LA CORRECTION EST ICI**
//     // On utilise le même context pour tous les SnackBar, donc on le capture
//     // **LA CORRECTION EST ICI**
//     // On utilise le même context pour tous les SnackBar, donc on le capture

//     final scaffoldMessenger = ScaffoldMessenger.of(context);
//     // Dans ce cas en bas : le token a été supprimé des SharedPreferences
//     // Au lieu d'afficher juste le SnackBar "Please restart", nous allons appeler
//     // à nouveau la  méthode _initializeGemma(), qui verra que le token est manquant et affichera
//     // la boîte de dialogue pour en entrer un nouveau.
//     // L'expérience est plus fluide et moins sujette à erreur.
//     if (result == 'reset_token') {
//       await prefs.remove('user_hf_token');
//       if (!mounted) return;

//       // On utilise la variable
//       scaffoldMessenger.showSnackBar(
//         const SnackBar(
//           content: Text(
//             'Token has been removed. Please provide a new one to continue.',
//           ),
//           backgroundColor: Colors.orange,
//         ),
//       );
//       // C'est la ligne clé : on relance le processus de configuration.
//       // L'écran passera à l'état "configuring" puis demandera le token.
//       _initializeGemma();
//     } else if (result != currentBackend) {
//       await prefs.setString('preferred_backend', result);
//       if (mounted) {
//         // Et on la réutilise ici
//         scaffoldMessenger.showSnackBar(
//           const SnackBar(
//             content: Text(
//               'Setting saved. Please restart the app for changes to take effect.',
//             ),
//           ),
//         );
//       }
//     }
//   }

//   /// Logique pour envoyer un message au Service Gemma
//   void _sendMessage() {
//     // CORRECTION : On récupère le service depuis le Provider.
//     final gemmaService = Provider.of<GemmaService>(context, listen: false);

//     final text = _textController.text.trim();
//     final image = _selectedImage;
//     if (text.isEmpty && image == null) return;
//     if (gemmaService.isAwaitingResponse.value) return;
//     gemmaService.sendMessage(text: text, imageBytes: image);

//     _textController.clear();
//     setState(() {
//       _selectedImage = null;
//     });
//     FocusScope.of(context).unfocus();
//   }

//   /// Logique pour choisir une image dans la galerie.
//   Future<void> _pickImage() async {
//     final scaffoldMessenger = ScaffoldMessenger.of(context);
//     try {
//       final pickedFile = await _imagePicker.pickImage(
//         source: ImageSource.gallery,
//         maxWidth: 1024,
//         maxHeight: 1024,
//         imageQuality: 85,
//       );
//       if (pickedFile != null) {
//         final bytes = await pickedFile.readAsBytes();
//         setState(() {
//           _selectedImage = bytes;
//         });
//       }
//     } catch (e) {
//       scaffoldMessenger.showSnackBar(
//         SnackBar(content: Text('Image selection error: $e')),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Offline Menu Translator 🍜'),
//         backgroundColor: Colors.white,
//         foregroundColor: Colors.black,
//         elevation: 1,
//         centerTitle: true,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.settings_outlined),
//             onPressed: _showSettingsDialog, // L'appel est bien ici
//             tooltip: 'Settings',
//           ),
//         ],
//       ),
//       body: switch (_screenState) {
//         ScreenState.configuring => const ConfiguringView(),
//         ScreenState.configFailed => ConfigFailedView(onRetry: _initializeGemma),
//         // AJOUT DU CAS MANQUANT
//         ScreenState.offlineNeedsSetup => OfflineSetupView(
//           onRetry: _initializeGemma,
//         ),
//         ScreenState.ready => _buildGemmaServiceView(),
//       },
//     );
//   }

//   /// Construit la vue principale une fois que le service Gemma est prêt à être utilisé.
//   Widget _buildGemmaServiceView() {
//     // CORRECTION : On récupère le service ici pour que l'UI puisse l'écouter.
//     final gemmaService = Provider.of<GemmaService>(context);

//     return Container(
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//           colors: [Colors.blue.shade50, Colors.blue.shade100],
//         ),
//       ),
//       child: ValueListenableBuilder<GemmaState>(
//         valueListenable: gemmaService.state, // On écoute l'état du service
//         builder: (context, gemmaState, child) {
//           switch (gemmaState) {
//             case GemmaState.uninitialized:
//             case GemmaState.initializing:
//               return const GemmaLoadingView(text: 'Initializing...');
//             case GemmaState.loadingModel:
//               return const GemmaLoadingView(
//                 text: 'Preparing model from device...',
//               );
//             case GemmaState.downloading:
//               return ValueListenableBuilder<double?>(
//                 valueListenable: gemmaService.downloadProgress,
//                 builder: (context, progress, child) {
//                   return GemmaDownloadingView(progress: progress);
//                 },
//               );
//             // NOUVEAU : On gère l'erreur de token de manière spécifique.
//             case GemmaState.tokenError:
//               return GemmaTokenErrorView(
//                 errorMessage: gemmaService.errorMessage.value,
//                 onGoToSettings:
//                     _showSettingsDialog, // On passe la fonction pour ouvrir les paramètres
//               );
//             case GemmaState.error:
//               return GemmaErrorView(
//                 errorMessage: gemmaService.errorMessage.value,
//                 // On passe la fonction pour réessayer.
//                 onRetry: _initializeGemma,
//               );
//             case GemmaState.ready:
//               return Column(
//                 children: [
//                   Expanded(
//                     child: ValueListenableBuilder<List<Message>>(
//                       valueListenable: gemmaService.messages,
//                       builder: (context, messages, child) {
//                         return ListView.builder(
//                           reverse: true,
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 8.0,
//                             vertical: 16.0,
//                           ),
//                           itemCount: messages.length,
//                           itemBuilder: (context, index) {
//                             final message =
//                                 messages[messages.length - 1 - index];
//                             return ChatMessageWidget(message: message);
//                           },
//                         );
//                       },
//                     ),
//                   ),
//                   ValueListenableBuilder<bool>(
//                     valueListenable: gemmaService.isAwaitingResponse,
//                     builder: (context, isAwaiting, child) {
//                       if (isAwaiting) {
//                         return const Padding(
//                           padding: EdgeInsets.all(8.0),
//                           child: Row(
//                             children: [
//                               SizedBox.square(
//                                 dimension: 24,
//                                 child: CircularProgressIndicator(
//                                   strokeWidth: 2,
//                                 ),
//                               ),
//                               SizedBox(width: 12),
//                               Text('Gemma is thinking...'),
//                             ],
//                           ),
//                         );
//                       }
//                       return const SizedBox.shrink();
//                     },
//                   ),
//                   ChatInputArea(
//                     textController: _textController,
//                     selectedImage: _selectedImage,
//                     isAwaitingResponse: gemmaService.isAwaitingResponse,
//                     onPickImage: _pickImage,
//                     onSendMessage: _sendMessage,
//                     onClearImage: () => setState(() => _selectedImage = null),
//                   ),
//                 ],
//               );
//           }
//         },
//       ),
//     );
//   }
// }
