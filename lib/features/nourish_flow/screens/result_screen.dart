
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';
import 'package:sentia_flow/services/gemma_service.dart';
import 'package:sentia_flow/widgets/state_views.dart';

class ResultScreen extends StatefulWidget {
  final String title;
  final Stream<String> resultStream;

  const ResultScreen({
    super.key,
    required this.title,
    required this.resultStream,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late FlutterTts flutterTts;
  bool isPlaying = false;

  StreamSubscription<String>? _resultSubscription;
  final StringBuffer _fullResult = StringBuffer();
  bool _isStreamComplete = false;
  String? _streamError;

  // NOUVEAU : Un buffer pour regrouper les tokens et un timer pour décaler les mises à jour.
  final List<String> _tokenBuffer = [];
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _initTts();
    _subscribeToStream();
  }

  // MODIFIÉ : La méthode d'écoute du stream est maintenant plus robuste.
  void _subscribeToStream() {
    _resultSubscription = widget.resultStream.listen(
      (token) {
        // Au lieu de mettre à jour l'UI directement, on ajoute le token au buffer.
        _tokenBuffer.add(token);
        
        // Si un timer est déjà en cours, on l'annule.
        _debounceTimer?.cancel();
        
        // On lance un nouveau timer. S'il n'y a pas de nouveau token pendant 50ms,
        // le timer se déclenchera et mettra à jour l'UI.
        _debounceTimer = Timer(const Duration(milliseconds: 50), _updateText);
      },
      onError: (error) {
        if (mounted) setState(() => _streamError = error.toString());
      },
      onDone: () {
        // Quand le stream est terminé, on s'assure de vider le buffer une dernière fois.
        _debounceTimer?.cancel();
        _updateText();
        if (mounted) setState(() => _isStreamComplete = true);
      },
    );
  }

  // NOUVEAU : La fonction qui met à jour l'interface utilisateur.
  // Elle est appelée par le timer ou à la fin du stream.
  void _updateText() {
    if (_tokenBuffer.isNotEmpty && mounted) {
      setState(() {
        // On ajoute tout le contenu du buffer d'un seul coup.
        _fullResult.write(_tokenBuffer.join());
        // On vide le buffer pour la prochaine fois.
        _tokenBuffer.clear();
      });
    }
  }

  Future<void> _initTts() async {
    flutterTts = FlutterTts();
    
    flutterTts.setStartHandler(() {
      if (mounted) setState(() => isPlaying = true);
    });
    flutterTts.setCompletionHandler(() {
      if (mounted) setState(() => isPlaying = false);
    });
    flutterTts.setErrorHandler((msg) {
      if (mounted) setState(() => isPlaying = false);
    });

    try {
      var voices = await flutterTts.getVoices;
      var englishVoices = (voices as List<dynamic>).where((voice) => voice['locale'].toString().contains('en')).toList();
      
      if (englishVoices.isNotEmpty) {
        var selectedVoice = englishVoices.firstWhere(
          (voice) => voice['locale'] == 'en-US',
          orElse: () => englishVoices.first,
        );
        await flutterTts.setVoice({"name": selectedVoice['name'], "locale": selectedVoice['locale']});
      }
    } catch (e) {
      debugPrint("Could not set voice: $e");
    }

    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setPitch(1.0);
  }

  Future<void> _speak() async {
    if (_isStreamComplete && _streamError == null && _fullResult.isNotEmpty && !isPlaying) {
      String cleanText = _fullResult.toString().replaceAll(RegExp(r'[#*]'), '');
      await flutterTts.speak(cleanText);
    }
  }

  Future<void> _stop() async {
    await flutterTts.stop();
  }

  @override
  void dispose() {
    flutterTts.stop();
    _resultSubscription?.cancel();
    _debounceTimer?.cancel(); // On s'assure que le timer est bien annulé.
    final gemmaService = Provider.of<GemmaService>(context, listen: false);
    if (gemmaService.isGenerating.value) {
      gemmaService.isGenerating.value = false;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
        actions: [
          if (_isStreamComplete && _streamError == null)
            IconButton(
              icon: Icon(isPlaying ? Icons.stop_circle_outlined : Icons.volume_up_outlined),
              onPressed: isPlaying ? _stop : _speak,
            ),
          if (_isStreamComplete && _streamError == null)
            IconButton(
              icon: const Icon(Icons.copy_all_outlined),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _fullResult.toString()));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Result copied!')),
                );
              },
            ),
        ],
      ),
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_streamError != null) {
      return Center(child: Text('An error occurred:\n$_streamError', style: TextStyle(color: theme.colorScheme.error)));
    }

    if (_fullResult.isEmpty && !_isStreamComplete) {
      return const GemmaLoadingView(text: 'Gemma is preparing your analysis...');
    }
    
    // Cette ligne est une bonne sécurité pour éviter de passer une chaîne vide au widget Markdown.
    final safeData = _fullResult.toString().isEmpty ? '\u200B' : _fullResult.toString();

    // --- DÉBUT DE LA CORRECTION ---
  return SingleChildScrollView(
    padding: EdgeInsets.all(12.w),
    // On remplace le Container par une Card pour utiliser le thème global.
    child: Card(
      // La Card a déjà un fond blanc, une bordure et une ombre grâce à votre `cardTheme`.
      // On ajoute juste un padding intérieur pour l'esthétique.
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
        child: MarkdownBody(
          data: safeData,
          selectable: true,
          // Le style du texte va maintenant hériter correctement du thème.
          styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
            // Le style 'p' (paragraphe) sera maintenant noir, comme le reste du texte.
            // On peut garder les titres colorés pour un joli effet.
            h1: TextStyle(fontSize: 26.sp, fontWeight: FontWeight.bold, color: theme.primaryColor),
            h2: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold, color: theme.primaryColor.withAlpha(230)),
          ),
        ),
      ),
    ),
  );
  // --- FIN DE LA CORRECTION ---
  }
}
