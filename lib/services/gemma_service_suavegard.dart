
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/core/model.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma/pigeon.g.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum GemmaState {
  uninitialized,
  initializing,
  downloading,
  loadingModel,
  ready,
  error,
  tokenError, // L'état pour une erreur d'authentification
}

// NOUVEAU : Une classe d'exception personnalisée pour le token.
class TokenException implements Exception {
  final String message;
  TokenException(this.message);
}

class GemmaService {
  late String _accessToken;
  late PreferredBackend _preferredBackend;

  InferenceModel? _inferenceModel;
  InferenceChat? _chat;


  // --- NOTIFIERS D'ÉTAT ---
  /// Notifier pour l'état général du service Gemma (initialisation, prêt, erreur).
  final ValueNotifier<GemmaState> state = ValueNotifier(
    GemmaState.uninitialized,
  );

  /// Notifier pour la progression du téléchargement du modèle.
  final ValueNotifier<double?> downloadProgress = ValueNotifier(null);

  /// Notifier pour les messages de la session de chat.
  final ValueNotifier<List<Message>> messages = ValueNotifier([]);

  /// Notifier pour l'état d'attente d'une réponse dans le chat.
  final ValueNotifier<bool> isAwaitingResponse = ValueNotifier(false);

  /// Notifier pour les messages d'erreur.
  final ValueNotifier<String?> errorMessage = ValueNotifier(null);

  /// **NOUVEAU** : Notifier pour l'état de génération d'une réponse unique (pour NourishFlow).
  final ValueNotifier<bool> isGenerating = ValueNotifier(false);

  static const _modelUrl =
      'https://huggingface.co/google/gemma-3n-E2B-it-litert-preview/resolve/main/gemma-3n-E2B-it-int4.task';

  // MODIFIÉ : On rend cette variable 'static' pour qu'elle soit accessible par la méthode statique.
  static const _modelFilename = 'gemma-3n-E2B-it-int4.task';
  static const _modelPreferenceKey = 'gemma3nE2B_installed';

  GemmaService();
  // GemmaService() {
  //   state.value = GemmaState.uninitialized;
  // }

  /// NOUVELLE MÉTHODE STATIQUE : Valide un token sans avoir besoin d'une instance du service.
  static Future<bool> validateToken(String token) async {
    try {
      final response = await http
          .head(
            Uri.parse(_modelUrl),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(
            const Duration(seconds: 10),
          ); // Ajout d'un timeout pour la robustesse

      // 200 OK signifie que le token est valide et a accès au modèle.
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Token validation request failed: $e");
      // En cas d'erreur réseau ou de timeout, on considère le token comme invalide.
      return false;
    }
  }

  // NOUVELLE MÉTHODE : Pour configurer et initialiser le service.
  Future<void> configureAndInitialize({
    required String huggingFaceToken,
    required PreferredBackend preferredBackend,
    bool skipOnlineCheck = false, // <-- AJOUTEZ CE PARAMÈTRE OPTIONNEL
  }) {
    // On assigne les valeurs reçues.
    _accessToken = huggingFaceToken;
    _preferredBackend = preferredBackend;

    // On appelle la méthode d'initialisation existante.
    // On passe le paramètre à la méthode initialize
    return initialize(skipOnlineCheck: skipOnlineCheck);
  }

  // MODIFIÉ : La méthode _getFilePath() devient publique et statique.
  // Elle peut maintenant être appelée depuis n'importe où sans instance de GemmaService.
  static Future<String> getModelPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/$_modelFilename';
  }

  /// Vérifie si le fichier local est complet en comparant sa taille avec le serveur.
  Future<bool> _isModelDownloadComplete() async {
    // MODIFIÉ : On utilise la nouvelle méthode statique.
    final filePath = await GemmaService.getModelPath();
    final file = File(filePath);

    if (!await file.exists()) {
      return false;
    }

    try {
      final localFileSize = await file.length();
      final response = await http.head(
        Uri.parse(_modelUrl),
        headers: {'Authorization': 'Bearer $_accessToken'},
      );

      if (response.statusCode == 200) {
        final remoteFileSize = int.parse(
          response.headers['content-length'] ?? '0',
        );
        return localFileSize > 0 && localFileSize == remoteFileSize;
      }
    } catch (e) {
      debugPrint("Could not verify model size: $e");
    }
    return false;
  }

  /// Télécharge le modèle avec reprise et tentatives.
  Future<void> _downloadModelWithResume() async {
    // ... (Cette méthode reste identique à la version précédente)
    // MODIFIÉ : On utilise la nouvelle méthode statique.
    final filePath = await GemmaService.getModelPath();
    final file = File(filePath);
    int downloadedBytes = 0;

    if (await file.exists()) {
      downloadedBytes = await file.length();
    }

    final request = http.Request('GET', Uri.parse(_modelUrl));
    request.headers['Authorization'] = 'Bearer $_accessToken';

    if (downloadedBytes > 0) {
      request.headers['Range'] = 'bytes=$downloadedBytes-';
    }

    http.StreamedResponse? response;
    int retryCount = 0;

    while (retryCount < 3) {
      try {
        response = await request.send().timeout(const Duration(seconds: 45));
        break;
      } catch (e) {
        retryCount++;
        debugPrint('Download request failed (attempt $retryCount): $e');
        if (retryCount >= 3) rethrow;
        await Future.delayed(const Duration(seconds: 2));
      }
    }

    if (response != null &&
        (response.statusCode == 200 || response.statusCode == 206)) {
      final totalBytes = response.contentLength ?? 0;
      final totalDownloadSize = downloadedBytes + totalBytes;

      final fileSink = file.openWrite(mode: FileMode.append);
      int receivedBytes = 0;

      await for (final chunk in response.stream) {
        fileSink.add(chunk);
        receivedBytes += chunk.length;
        if (totalDownloadSize > 0) {
          final currentProgress =
              (downloadedBytes + receivedBytes) / totalDownloadSize;
          downloadProgress.value = currentProgress.clamp(0.0, 1.0);
        }
      }
      await fileSink.close();
    } else {
      // le code fait la différence entre une erreur de réseau normale et une erreur de token invalide.
      // Si le statut est 401, on lance notre exception spéciale.
      if (response?.statusCode == 401) {
        throw TokenException('Invalid or unauthorized token.');
      }
      // Pour toutes les autres erreurs, on lance une exception générique.
      throw Exception(
        'Failed to download model. Status code: ${response?.statusCode ?? "unknown"}',
      );
    }
  }

  Future<void> initialize({bool skipOnlineCheck = false}) async {
    // if (state.value != GemmaState.uninitialized) return;
    // NOUVELLE LOGIQUE PLUS INTELLIGENTE :
    // On bloque le re-lancement uniquement si le service est DÉJÀ en train de
    // s'initialiser ou s'il est déjà prêt. On autorise le "Retry" depuis un état d'erreur
    // comme celui l'erreur quadn je reduis la fenetre et le model est en train d'être téléchargé
    final currentState = state.value;
    if (currentState == GemmaState.initializing ||
        currentState == GemmaState.downloading ||
        currentState == GemmaState.loadingModel ||
        currentState == GemmaState.ready) {
      return; // Ne fait rien si déjà en cours de travail ou prêt.
    }

    try {
      _updateState(GemmaState.initializing);
      final gemma = FlutterGemmaPlugin.instance;
      final modelManager = gemma.modelManager;
      final prefs = await SharedPreferences.getInstance();
      // MODIFIÉ : On utilise la nouvelle méthode statique.
      final filePath = await GemmaService.getModelPath();

      // 1. On utilise la vérification de taille pour une robustesse maximale
      // bool isModelReady = await _isModelDownloadComplete();
      // --- LOGIQUE MODIFIÉE ICI ---
      bool isModelReady = false;
      if (skipOnlineCheck && await File(filePath).exists()) {
        // Si on nous demande de sauter la vérification ET que le fichier existe, on considère que c'est bon.
        debugPrint(
          "Skipping online model check as requested. Model is ready for offline use.",
        );
        isModelReady = true;
      } else {
        // Sinon, on effectue la vérification en ligne complète comme avant.
        isModelReady = await _isModelDownloadComplete();
      }
      // --- Fin logique modifée

      if (!isModelReady) {
        _updateState(GemmaState.downloading);
        await _downloadModelWithResume();

        // 2. Après le téléchargement, on vérifie une dernière fois
        if (!await _isModelDownloadComplete()) {
          throw Exception(
            "Model download seems complete but size verification failed.",
          );
        }
        await prefs.setBool(_modelPreferenceKey, true);
        downloadProgress.value = null;
      }

      _updateState(GemmaState.loadingModel);
      await modelManager.setModelPath(filePath);

      _inferenceModel = await gemma.createModel(
        modelType: ModelType.gemmaIt,
        supportImage: true,
        maxTokens: 2048,
        // using CPU
        // in case of GPU:preferredBackend: PreferredBackend.gpu
        // preferredBackend: PreferredBackend.cpu,
        preferredBackend: _preferredBackend,
      );

      _chat = await _inferenceModel!.createChat(supportImage: true);

      _updateState(GemmaState.ready);
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_modelPreferenceKey, false);

      final errorString = e.toString();

      // 1. Gérer TOUTES les erreurs qui peuvent laisser un fichier corrompu.
      //    (Erreur de Zip OU Erreur réseau pendant le téléchargement)
      if (errorString.contains('Unable to open zip archive') ||
          e is http.ClientException) {
        debugPrint(
          "File corruption or network error detected. Deleting model file to ensure a clean retry.",
        );

        // On supprime le fichier pour être sûr de repartir sur de bonnes bases.
        final modelPath = await GemmaService.getModelPath();
        final corruptedFile = File(modelPath);
        if (await corruptedFile.exists()) {
          await corruptedFile.delete();
        }

        // On affiche un message clair à l'utilisateur.
        errorMessage.value =
            "A network or file error occurred, forcing a fresh download. Please press 'Retry'.";
        _updateState(GemmaState.error);
      }
      // 2. Gérer l'erreur de token séparément.
      else if (e is TokenException) {
        errorMessage.value = e.message;
        _updateState(GemmaState.tokenError);
      }
      // 3. Gérer toutes les autres erreurs imprévues.
      else {
        debugPrint("GemmaService Error: $e");
        errorMessage.value = "Failed to initialize AI model: $e";
        _updateState(GemmaState.error);
      }
    }
  }

  Stream<String> generateFeatureResponseStream({
    // celle ci use chat pas single ssssion car non focntionnelle
    // Celle-ci marche à merveille
    required String prompt,
    required Uint8List imageBytes,
  }) {
    if (state.value != GemmaState.ready || _chat == null) {
      return Stream.error(Exception('Gemma chat is not ready. Current state: ${state.value}'));
    }

    final controller = StreamController<String>();

    Future<void> runInference() async {
      isGenerating.value = true;
      try {
        await _chat!.addQueryChunk(Message.withImage(text: prompt, imageBytes: imageBytes, isUser: true));
        final responseStream = _chat!.generateChatResponseAsync();

        await for (final response in responseStream) {
          if (response is TextResponse) {
            controller.add(response.token);
          }
        }
      } catch (e) {
        debugPrint("Error during chat-based feature inference: $e");
        controller.addError(Exception('Failed to get response from Gemma: $e'));
      } finally {
        await controller.close();
        isGenerating.value = false;
      }
    }

    runInference();
    return controller.stream;
  }

  // **MÉTHODE  : Utilisation de InferenceSession: Actually does not work, needs imporvement of the flutter_gemma package**
  Stream<String> generateFeatureResponseStreamSingleSessionEssai({
    required String prompt,
    required Uint8List imageBytes,
  }) {
    // On vérifie que le MODÈLE est prêt (pas le chat).
    if (state.value != GemmaState.ready || _inferenceModel == null) {
      return Stream.error(Exception('Gemma model is not ready. Current state: ${state.value}'));
    }

    final controller = StreamController<String>();
    // On déclare la session ici pour pouvoir la fermer dans le bloc finally.
    dynamic session;
    //InferenceSession? session;

    Future<void> runInference() async {
      isGenerating.value = true;
      try {
        debugPrint("Creating new temporary inference session...");

        // 1. Création d'une NOUVELLE session pour cette interaction.
        session = await _inferenceModel!.createSession(
          // CRUCIAL : Selon la documentation, il faut activer la modalité vision pour les sessions multimodales.
          enableVisionModality: true, 
        );

        // 2. Ajout de la requête (prompt + image).
        await session!.addQueryChunk(Message.withImage(text: prompt, imageBytes: imageBytes, isUser: true));

        // 3. Récupération du stream de réponse.
        // Note: getResponseAsync() retourne directement un Stream<String> pour les sessions.
        final responseStream = session!.getResponseAsync();

        // On transfère les données du stream de la session vers notre contrôleur.
        await controller.addStream(responseStream);

      } catch (e) {
        debugPrint("Error during session-based feature inference: $e");
        if (!controller.isClosed) {
          controller.addError(Exception('Failed to get response from Gemma: $e'));
        }
      } finally {
        // 4. TRÈS IMPORTANT : Fermeture de la session pour libérer les ressources.
        // C'est ce qui empêche le blocage de l'application.
        if (session != null) {
          try {
            await session!.close();
            debugPrint("Inference session closed successfully.");
          } catch (e) {
            debugPrint("Error closing inference session: $e");
          }
        }
        // Fermeture de notre contrôleur.
        if (!controller.isClosed) {
          await controller.close();
        }
        isGenerating.value = false;
      }
    }

    runInference();
    return controller.stream;
  }



  // **MÉTHODE CRUCIALE CORRIGÉE AVEC DYNAMIC**: ne marcche pas pour le moment avec flutter_gemma package
  // Stream<String> generateFeatureResponseStream({
  //   // celle ci use single session not chat comme celle dessus
  //   // mais bloquée pur le moment
  //   required String prompt,
  //   required Uint8List imageBytes,
  // }) {
  //   if (state.value != GemmaState.ready || _inferenceModel == null) {
  //     return Stream.error(
  //       Exception('Gemma model is not ready. Current state: ${state.value}'),
  //     );
  //   }

  //   final controller = StreamController<String>();

  //   // --- CORRECTION 2 : Déclarer la session locale comme 'dynamic' ---
  //   // Au lieu de Session? session;
  //   dynamic session;

  //   Future<void> runInference() async {
  //     isGenerating.value = true;

  //     // Le bloc try...finally est ESSENTIEL pour éviter le freeze de l'app.
  //     try {
  //       debugPrint("Creating new temporary inference session...");

  //       // 1. Création de la session. Dart permet d'appeler createSession car _inferenceModel est dynamic.
  //       session = await _inferenceModel!.createSession(
  //         // CRUCIAL : Activer la vision pour le multimodal (comme dans la documentation).
  //         enableVisionModality: true,
  //       );

  //       // 2. Ajout de la requête.
  //       await session.addQueryChunk(
  //         Message.withImage(text: prompt, imageBytes: imageBytes, isUser: true),
  //       );

  //       // 3. Récupération du stream de réponse.
  //       // getResponseAsync retourne un Stream<String>.
  //       final responseStream = session.getResponseAsync();

  //       // On transfère les données.
  //       await controller.addStream(responseStream);
  //     } catch (e) {
  //       debugPrint("Error during session-based feature inference: $e");
  //       if (!controller.isClosed) {
  //         controller.addError(
  //           Exception('Failed to get response from Gemma: $e'),
  //         );
  //       }
  //     } finally {
  //       // 4. TRÈS IMPORTANT : C'est ce bloc qui résout votre problème de freeze et de performance.
  //       // Il garantit que la session est fermée et les ressources libérées.
  //       if (session != null) {
  //         try {
  //           // Dart permet d'appeler close() car session est dynamic.
  //           await session.close();
  //           debugPrint("Inference session closed successfully.");
  //         } catch (e) {
  //           debugPrint("Error closing inference session: $e");
  //         }
  //       }
  //       if (!controller.isClosed) {
  //         await controller.close();
  //       }
  //       isGenerating.value = false;
  //     }
  //   }

  //   runInference();
  //   return controller.stream;
  // }
  
  // Ici j'ai essayé àla min clear cahtHistory, en appelant une nouvelle one après chaque appel
  // voir on décalre cette method dans nourish_input_screen.dart
  // // **RÉINTRODUCTION DE LA MÉTHODE POUR NETTOYER L'HISTORIQUE**
  // Future<void> clearChatHistory() async {
  //   if (_inferenceModel != null) {
  //     try {
  //       _chat = await _inferenceModel!.createChat(supportImage: true);
  //       debugPrint("Chat history has been cleared.");
  //     } catch (e) {
  //       debugPrint("Could not clear chat history: $e");
  //     }
  //   }
  // }

  // Stream<String> generateFeatureResponseStream({
  //   required String prompt,
  //   required Uint8List imageBytes,
  // }) {
  //   if (state.value != GemmaState.ready || _chat == null) {
  //     return Stream.error(Exception('Gemma chat is not ready. Current state: ${state.value}'));
  //   }

  //   final controller = StreamController<String>();

  //   Future<void> runInference() async {
  //     isGenerating.value = true;
  //     try {
  //       await _chat!.addQueryChunk(Message.withImage(text: prompt, imageBytes: imageBytes, isUser: true));
  //       final responseStream = _chat!.generateChatResponseAsync();

  //       await for (final response in responseStream) {
  //         if (response is TextResponse) {
  //           controller.add(response.token);
  //         }
  //       }
  //     } catch (e) {
  //       debugPrint("Error during chat-based feature inference: $e");
  //       controller.addError(Exception('Failed to get response from Gemma: $e'));
  //     } finally {
  //       await controller.close();
  //       isGenerating.value = false;
  //     }
  //   }

  //   runInference();
  //   return controller.stream;
  // }

  Future<void> sendMessage({String? text, Uint8List? imageBytes}) async {
    if (state.value != GemmaState.ready || isAwaitingResponse.value) {
      return;
    }
    if ((text == null || text.isEmpty) && imageBytes == null) {
      return;
    }
    isAwaitingResponse.value = true;
    final Message userMessage;
    if (imageBytes != null) {
      userMessage = Message.withImage(
        text: text ?? "Describe this image.",
        imageBytes: imageBytes,
        isUser: true,
      );
    } else {
      userMessage = Message.text(text: text!, isUser: true);
    }
    messages.value = [...messages.value, userMessage];
    try {
      await _chat!.addQueryChunk(userMessage);
      final responsePlaceholder = Message(text: '', isUser: false);
      messages.value = [...messages.value, responsePlaceholder];

      final responseStream = _chat!.generateChatResponseAsync();
      String aggregatedResponse = '';

      await for (final response in responseStream) {
        // On vérifie que la réponse est bien du texte
        if (response is TextResponse) {
          // On utilise response.token pour obtenir le String
          aggregatedResponse += response.token;

          final currentMessages = List<Message>.from(messages.value);
          currentMessages.last = Message(
            text: aggregatedResponse,
            isUser: false,
          );
          messages.value = currentMessages;
        }
      }
    } catch (e) {
      debugPrint("Error during chat generation: $e");
      final currentMessages = List<Message>.from(messages.value);
      if (currentMessages.isNotEmpty && !currentMessages.last.isUser) {
        currentMessages.removeLast();
      }
      currentMessages.add(
        Message(text: "Sorry, an error occurred: $e", isUser: false),
      );
      messages.value = currentMessages;
    } finally {
      isAwaitingResponse.value = false;
    }
  }

  void _updateState(GemmaState newState) {
    state.value = newState;
    debugPrint("GemmaService state changed to: $newState");
  }

  Future<void> resetState() async {
    debugPrint("Resetting GemmaService state...");

    // On ferme l'ancien modèle s'il existe.
    if (_inferenceModel != null) {
      await _inferenceModel!.close();
      _inferenceModel = null;
      _chat = null; // Le chat est lié au modèle, on le supprime aussi.
      debugPrint("Existing model instance closed.");
    }

    // Puis on réinitialise les états de l'UI.
    state.value = GemmaState.uninitialized;
    errorMessage.value = null;
    debugPrint("GemmaService state has been reset to uninitialized.");
  }

  void dispose() {
    state.dispose();
    downloadProgress.dispose();
    messages.dispose();
    isAwaitingResponse.dispose();
    errorMessage.dispose();
    isGenerating.dispose(); // Ne pas oublier de disposer le nouveau notifier
  }
}
