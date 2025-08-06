import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemma/pigeon.g.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sentia_flow/features/active_flow/screens/home_screen_active_flow.dart';
import 'package:sentia_flow/features/nourish_flow/screens/nourish_home_screen.dart';
import 'package:sentia_flow/services/gemma_service.dart';
import 'package:sentia_flow/widgets/state_views.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    ActiveFlowHomeScreen(),
    NourishHomeScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _initializeGemma();
  }

  Future<void> _initializeGemma() async {
    final gemmaService = Provider.of<GemmaService>(context, listen: false);
    await gemmaService.resetState();

    final prefs = await SharedPreferences.getInstance();
    final modelPath = await GemmaService.getModelPath();
    final bool modelExists = await File(modelPath).exists();
    final String? userToken = prefs.getString('user_hf_token');

    if (modelExists && userToken != null && userToken.isNotEmpty) {
      debugPrint("MainShell: Starting in offline-first mode.");
      final savedBackend = prefs.getString('preferred_backend') ?? 'cpu';
      final backend = savedBackend == 'gpu'
          ? PreferredBackend.gpu
          : PreferredBackend.cpu;

      gemmaService.configureAndInitialize(
        huggingFaceToken: userToken,
        preferredBackend: backend,
        skipOnlineCheck: true,
      );
      return;
    }

    debugPrint("MainShell: Entering online setup flow.");
    final connectivityResult = await (Connectivity().checkConnectivity());
    bool isOffline =
        connectivityResult.isEmpty ||
        connectivityResult.every(
          (e) =>
              e == ConnectivityResult.none || e == ConnectivityResult.bluetooth,
        );

    if (isOffline) {
      debugPrint("MainShell: No internet connection for setup.");
      gemmaService.handleOfflineSetupError();
      return;
    }

    String? tokenForSetup = userToken;
    bool isTokenValid = false;
    if (tokenForSetup != null && tokenForSetup.isNotEmpty) {
      isTokenValid = await GemmaService.validateToken(tokenForSetup);
    }

    if (!isTokenValid) {
      while (true) {
        if (!mounted) return;
        tokenForSetup = await _showTokenDialog(context);
        if (tokenForSetup == null || tokenForSetup.isEmpty) {
          gemmaService.handleTokenConfigurationFailed();
          return;
        }
        isTokenValid = await GemmaService.validateToken(tokenForSetup);
        if (isTokenValid) break;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid or unauthorized token. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }

    await prefs.setString('user_hf_token', tokenForSetup!);
    final savedBackend = prefs.getString('preferred_backend') ?? 'cpu';
    final backend = savedBackend == 'gpu'
        ? PreferredBackend.gpu
        : PreferredBackend.cpu;

    gemmaService.configureAndInitialize(
      huggingFaceToken: tokenForSetup,
      preferredBackend: backend,
      skipOnlineCheck: false,
    );
  }

  // MODIFIÉ : On force le thème ici aussi
  Future<String?> _showTokenDialog(BuildContext context) {
    final textController = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Hugging Face Token Required'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Please enter your Hugging Face access token with read permissions to download the model.",
              ),
              SizedBox(height: 16.h),
              TextField(
                controller: textController,
                decoration: const InputDecoration(
                  labelText: 'Access Token',
                  hintText: 'Enter your HF token here',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final token = textController.text.trim();
                if (token.isNotEmpty) {
                  Navigator.of(dialogContext).pop(token);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // MODIFIÉ : On force le thème ici
  Future<void> _showSettingsDialog() async {
    final prefs = await SharedPreferences.getInstance();
    String selectedBackend = prefs.getString('preferred_backend') ?? 'cpu';

    if (!mounted) return;

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Settings'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<String>(
                    title: const Text('CPU (Stable, Universal)'),
                    value: 'cpu',
                    groupValue: selectedBackend,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => selectedBackend = value);
                      }
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('GPU (Faster)'),
                    value: 'gpu',
                    groupValue: selectedBackend,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => selectedBackend = value);
                      }
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(
                      Icons.refresh,
                      color: Colors.orangeAccent,
                    ),
                    title: const Text('Reset HF Token'),
                    onTap: () => Navigator.pop(dialogContext, 'reset_token'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () =>
                      Navigator.pop(dialogContext, selectedBackend),
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );

    if (!mounted || result == null) return;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final currentBackend = prefs.getString('preferred_backend') ?? 'cpu';

    if (result == 'reset_token') {
      await prefs.remove('user_hf_token');
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Token removed. A new token will be requested.'),
        ),
      );
      _initializeGemma();
    } else if (result != currentBackend) {
      await prefs.setString('preferred_backend', result);
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Setting saved. Restart the app to apply.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final gemmaService = Provider.of<GemmaService>(context);

    return ValueListenableBuilder<GemmaState>(
      valueListenable: gemmaService.state,
      builder: (context, gemmaState, child) {
        final bool isAppReady = gemmaState == GemmaState.ready;

        return Scaffold(
          appBar: AppBar(
            title: Text(_selectedIndex == 0 ? 'ActiveFlow' : 'NourishFlow'),
            centerTitle: true,
            actions: [
              if (isAppReady)
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: _showSettingsDialog,
                  tooltip: 'Settings',
                ),
            ],
          ),
          body: _buildBody(gemmaState),
          bottomNavigationBar: isAppReady
              ? BottomNavigationBar(
                  items: const <BottomNavigationBarItem>[
                    BottomNavigationBarItem(
                      icon: Icon(Icons.fitness_center_outlined),
                      activeIcon: Icon(Icons.fitness_center),
                      label: 'ActiveFlow',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.restaurant_menu_outlined),
                      activeIcon: Icon(Icons.restaurant_menu),
                      label: 'NourishFlow',
                    ),
                  ],
                  currentIndex: _selectedIndex,
                  onTap: (index) => setState(() => _selectedIndex = index),
                )
              : null,
        );
      },
    );
  }

  Widget _buildBody(GemmaState gemmaState) {
    final gemmaService = Provider.of<GemmaService>(context, listen: false);

    switch (gemmaState) {
      case GemmaState.uninitialized:
      case GemmaState.initializing:
        return const GemmaLoadingView(text: 'Initializing...');
      case GemmaState.loadingModel:
        return const GemmaLoadingView(text: 'Preparing model...');
      case GemmaState.downloading:
        return ValueListenableBuilder<double?>(
          valueListenable: gemmaService.downloadProgress,
          builder: (context, progress, child) {
            return GemmaDownloadingView(progress: progress);
          },
        );
      case GemmaState.tokenError:
        return GemmaTokenErrorView(
          errorMessage: gemmaService.errorMessage.value,
          onGoToSettings: _showSettingsDialog,
        );
      case GemmaState.error:
        return GemmaErrorView(
          errorMessage: gemmaService.errorMessage.value,
          onRetry: _initializeGemma,
        );
      case GemmaState.ready:
        return IndexedStack(index: _selectedIndex, children: _widgetOptions);
    }
  }
}
