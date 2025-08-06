


import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemma/pigeon.g.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sentia_flow/features/nourish_flow/screens/nourish_home_screen.dart';
import 'package:sentia_flow/features/active_flow/screens/home_screen_active_flow.dart';
import 'package:sentia_flow/services/gemma_service.dart';
import 'package:sentia_flow/widgets/state_views.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppInitState { configuring, ready, configFailed, offlineNeedsSetup }

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  AppInitState _appInitState = AppInitState.configuring;
  int _selectedIndex = 0;

  // Les écrans n'ont plus besoin de leur propre AppBar.
  // Va à build method et Appbar, je l'ai rendue dynamaique pour toujours afficher le settings (CPU,GPU, resettoken)
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
    if (!mounted) return;

    final gemmaService = Provider.of<GemmaService>(context, listen: false);
    await gemmaService.resetState();

    if (_appInitState != AppInitState.configuring) {
      setState(() => _appInitState = AppInitState.configuring);
    }

    final prefs = await SharedPreferences.getInstance();
    final modelPath = await GemmaService.getModelPath();
    final modelFile = File(modelPath);
    final bool modelExists = await modelFile.exists();
    final String? userToken = prefs.getString('user_hf_token');

    if (modelExists && userToken != null && userToken.isNotEmpty) {
      debugPrint(
        "Model and token found locally. Starting in offline-first mode.",
      );
      // final savedBackend = prefs.getString('preferred_backend') ?? 'cpu';
      // final backend =
      //     savedBackend == 'gpu' ? PreferredBackend.gpu : PreferredBackend.cpu;
      // On force le CPU ici, peu importe ce qui est sauvegardé.
      final backend = PreferredBackend.cpu;
      if (mounted) setState(() => _appInitState = AppInitState.ready);
      gemmaService.configureAndInitialize(
        huggingFaceToken: userToken,
        preferredBackend: backend,
        skipOnlineCheck: true,
      );
      return;
    }

    debugPrint("Entering online setup flow (model missing or token reset).");
    final connectivityResult = await (Connectivity().checkConnectivity());
    bool isOffline =
        connectivityResult.isEmpty ||
        connectivityResult.every(
          (e) =>
              e == ConnectivityResult.none || e == ConnectivityResult.bluetooth,
        );

    if (isOffline) {
      debugPrint("No internet connection detected during setup flow.");
      if (mounted) {
        setState(() => _appInitState = AppInitState.offlineNeedsSetup);
      }
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
          if (mounted) {
            setState(() => _appInitState = AppInitState.configFailed);
          }
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
    // final savedBackend = prefs.getString('preferred_backend') ?? 'cpu';
    // final backend = savedBackend == 'gpu'
    // ? PreferredBackend.gpu
    // : PreferredBackend.cpu;
    final backend = PreferredBackend.cpu;
    if (mounted) setState(() => _appInitState = AppInitState.ready);

    gemmaService.configureAndInitialize(
      huggingFaceToken: tokenForSetup,
      preferredBackend: backend,
      skipOnlineCheck: false,
    );
  }

  Future<String?> _showTokenDialog(BuildContext context) {
    final textController = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
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
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final token = textController.text.trim();
                if (token.isNotEmpty) {
                  Navigator.of(context).pop(token);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // Dans main_shell.dart

  Future<void> _showSettingsDialog() async {
    // On capture le ScaffoldMessenger AVANT l'attente pour plus de sécurité.
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final wantsToReset = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Settings'),
          content: ListTile(
            leading: const Icon(Icons.refresh, color: Colors.orangeAccent),
            title: const Text('Reset HF Token'),
            onTap: () {
              // On ferme le dialogue en confirmant l'action.
              Navigator.pop(dialogContext, true);
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                // On ferme le dialogue en annulant l'action.
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );

    // On vérifie si l'utilisateur a bien confirmé ET si l'écran est toujours visible.
    // C'est la garde de sécurité la plus importante.
    if (wantsToReset != true || !mounted) {
      return;
    }

    // Si la garde est passée, on peut continuer en toute sécurité.
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_hf_token');
    
    // On utilise la variable capturée au début pour afficher le message.
    scaffoldMessenger.showSnackBar(const SnackBar(
      content: Text('Token removed. A new token will be requested on restart.'),
      backgroundColor: Colors.orange,
    ));
    
    // On relance l'initialisation pour demander le nouveau token.
    _initializeGemma();
  }

  // **DÉBUT DE LA CORRECTION : BOÎTE DE DIALOGUE DES PARAMÈTRES RECONSTRUITE**
  // C avec optiosn CPU, GPU et reset token
  // Future<void> _showSettingsDialog() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   String selectedBackend = prefs.getString('preferred_backend') ?? 'cpu';

  //   if (!mounted) return;

  //   final result = await showDialog<String>(
  //     context: context,
  //     builder: (dialogContext) {
  //       // On utilise un StatefulBuilder pour gérer l'état des boutons radio
  //       // à l'intérieur de la boîte de dialogue, ce qui est plus robuste.
  //       return StatefulBuilder(
  //         builder: (context, setState) {
  //           return AlertDialog(
  //             title: const Text('Settings'),
  //             content: Column(
  //               mainAxisSize: MainAxisSize.min,
  //               children: [
  //                 RadioListTile<String>(
  //                   title: const Text('CPU (Slower, Compatible)'),
  //                   value: 'cpu',
  //                   groupValue: selectedBackend,
  //                   onChanged: (value) {
  //                     if (value != null)
  //                       setState(() => selectedBackend = value);
  //                   },
  //                 ),
  //                 RadioListTile<String>(
  //                   title: const Text('GPU (Faster, Recommended)'),
  //                   value: 'gpu',
  //                   groupValue: selectedBackend,
  //                   onChanged: (value) {
  //                     if (value != null)
  //                       setState(() => selectedBackend = value);
  //                   },
  //                 ),
  //                 const Divider(),
  //                 ListTile(
  //                   leading: const Icon(
  //                     Icons.refresh,
  //                     color: Colors.orangeAccent,
  //                   ),
  //                   title: const Text('Reset HF Token'),
  //                   onTap: () => Navigator.pop(dialogContext, 'reset_token'),
  //                 ),
  //               ],
  //             ),
  //             actions: [
  //               TextButton(
  //                 onPressed: () => Navigator.pop(dialogContext),
  //                 child: const Text('Cancel'),
  //               ),
  //               FilledButton(
  //                 onPressed: () =>
  //                     Navigator.pop(dialogContext, selectedBackend),
  //                 child: const Text('Apply'),
  //               ),
  //             ],
  //           );
  //         },
  //       );
  //     },
  //   );

  //   if (!mounted || result == null) return;
  //   final scaffoldMessenger = ScaffoldMessenger.of(context);
  //   final currentBackend = prefs.getString('preferred_backend') ?? 'cpu';

  //   if (result == 'reset_token') {
  //     await prefs.remove('user_hf_token');
  //     scaffoldMessenger.showSnackBar(
  //       const SnackBar(
  //         content: Text('Token removed. A new token will be requested.'),
  //         backgroundColor: Colors.orange,
  //       ),
  //     );
  //     _initializeGemma();
  //   } else if (result != currentBackend) {
  //     await prefs.setString('preferred_backend', result);
  //     scaffoldMessenger.showSnackBar(
  //       const SnackBar(
  //         content: Text('Setting saved. Restart the app to apply.'),
  //       ),
  //     );
  //   }
  // }
  // **FIN DE LA CORRECTION**

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // L'AppBar est maintenant gérée ici, de manière centralisée.
      appBar: AppBar(
        // Le titre change en fonction de l'onglet sélectionné.
        title: Text(_selectedIndex == 0 ? 'ActiveFlow' : 'NourishFlow'),
        centerTitle: true,
        actions: [
          // Le bouton des paramètres s'affiche uniquement quand l'app est prête.
          if (_appInitState == AppInitState.ready)
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: _showSettingsDialog,
              tooltip: 'Settings',
            ),
        ],
      ),
      body: switch (_appInitState) {
        AppInitState.configuring => const ConfiguringView(),
        AppInitState.configFailed => ConfigFailedView(
          onRetry: _initializeGemma,
        ),
        AppInitState.offlineNeedsSetup => OfflineSetupView(
          onRetry: _initializeGemma,
        ),
        AppInitState.ready => _buildReadyStateBody(),
      },
      bottomNavigationBar: _appInitState == AppInitState.ready
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
  }

  Widget _buildReadyStateBody() {
    final gemmaService = Provider.of<GemmaService>(context);

    return ValueListenableBuilder<GemmaState>(
      valueListenable: gemmaService.state,
      builder: (context, gemmaState, child) {
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
            return IndexedStack(
              index: _selectedIndex,
              children: _widgetOptions,
            );
        }
      },
    );
  }
}

//===============================================================================================
//===============================================================================================
// ancienne mais statfulbuilder qui marchait avec bouton on les voi au debut

// import 'dart:io';
// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_gemma/pigeon.g.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:sentia_flow/features/active_flow/active_flow_screen.dart';
// import 'package:sentia_flow/features/nourish_flow/screens/nourish_home_screen.dart';
// import 'package:sentia_flow/services/gemma_service.dart';
// import 'package:sentia_flow/widgets/state_views.dart';
// import 'package:provider/provider.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// enum AppInitState {
//   configuring,
//   ready,
//   configFailed,
//   offlineNeedsSetup,
// }

// class MainShell extends StatefulWidget {
//   const MainShell({super.key});

//   @override
//   State<MainShell> createState() => _MainShellState();
// }

// class _MainShellState extends State<MainShell> {
//   AppInitState _appInitState = AppInitState.configuring;
//   int _selectedIndex = 0;

//   // Les écrans n'ont plus besoin de leur propre AppBar.
//   // Va à build method et Appbar, je l'ai rendue dynamaique pour toujours afficher le settings (CPU,GPU, resettoken)
//   static const List<Widget> _widgetOptions = <Widget>[
//     ActiveFlowScreen(),
//     NourishHomeScreen(),
//   ];

//   @override
//   void initState() {
//     super.initState();
//     _initializeGemma();
//   }

//   Future<void> _initializeGemma() async {
//     if (!mounted) return;
    
//     final gemmaService = Provider.of<GemmaService>(context, listen: false);
//     await gemmaService.resetState();

//     if (_appInitState != AppInitState.configuring) {
//       setState(() => _appInitState = AppInitState.configuring);
//     }
    
//     final prefs = await SharedPreferences.getInstance();
//     final modelPath = await GemmaService.getModelPath();
//     final modelFile = File(modelPath);
//     final bool modelExists = await modelFile.exists();
//     final String? userToken = prefs.getString('user_hf_token');

//     if (modelExists && userToken != null && userToken.isNotEmpty) {
//       debugPrint("Model and token found locally. Starting in offline-first mode.");
//       final savedBackend = prefs.getString('preferred_backend') ?? 'cpu';
//       final backend =
//           savedBackend == 'gpu' ? PreferredBackend.gpu : PreferredBackend.cpu;
//       if (mounted) setState(() => _appInitState = AppInitState.ready);
//       gemmaService.configureAndInitialize(
//         huggingFaceToken: userToken,
//         preferredBackend: backend,
//         skipOnlineCheck: true,
//       );
//       return;
//     }

//     debugPrint("Entering online setup flow (model missing or token reset).");
//     final connectivityResult = await (Connectivity().checkConnectivity());
//     bool isOffline = connectivityResult.isEmpty ||
//         connectivityResult.every((e) => e == ConnectivityResult.none || e == ConnectivityResult.bluetooth);

//     if (isOffline) {
//       debugPrint("No internet connection detected during setup flow.");
//       if (mounted) setState(() => _appInitState = AppInitState.offlineNeedsSetup);
//       return;
//     }

//     String? tokenForSetup = userToken;
//     bool isTokenValid = false;
//     if (tokenForSetup != null && tokenForSetup.isNotEmpty) {
//       isTokenValid = await GemmaService.validateToken(tokenForSetup);
//     }

//     if (!isTokenValid) {
//       while (true) {
//         if (!mounted) return;
//         tokenForSetup = await _showTokenDialog(context);
//         if (tokenForSetup == null || tokenForSetup.isEmpty) {
//           if (mounted) setState(() => _appInitState = AppInitState.configFailed);
//           return;
//         }
//         isTokenValid = await GemmaService.validateToken(tokenForSetup);
//         if (isTokenValid) break;
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

//     await prefs.setString('user_hf_token', tokenForSetup!);
//     final savedBackend = prefs.getString('preferred_backend') ?? 'cpu';
//     final backend =
//         savedBackend == 'gpu' ? PreferredBackend.gpu : PreferredBackend.cpu;
//     if (mounted) setState(() => _appInitState = AppInitState.ready);
    
//     gemmaService.configureAndInitialize(
//       huggingFaceToken: tokenForSetup,
//       preferredBackend: backend,
//       skipOnlineCheck: false,
//     );
//   }

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
//                 "Please enter your Hugging Face access token with read permissions to download the model.",
//               ),
//               SizedBox(height: 16.h),
//               TextField(
//                 controller: textController,
//                 decoration: const InputDecoration(
//                   labelText: 'Access Token',
//                   hintText: 'Enter your HF token here',
//                 ),
//               ),
//             ],
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.of(context).pop(),
//               child: const Text('Cancel'),
//             ),
//             FilledButton(
//               onPressed: () {
//                 final token = textController.text.trim();
//                 if (token.isNotEmpty) {
//                   Navigator.of(context).pop(token);
//                 }
//               },
//               child: const Text('Save'),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   // **DÉBUT DE LA CORRECTION : BOÎTE DE DIALOGUE DES PARAMÈTRES RECONSTRUITE**
//   Future<void> _showSettingsDialog() async {
//     final prefs = await SharedPreferences.getInstance();
//     String selectedBackend = prefs.getString('preferred_backend') ?? 'cpu';

//     if (!mounted) return;

//     final result = await showDialog<String>(
//       context: context,
//       builder: (dialogContext) {
//         // On utilise un StatefulBuilder pour gérer l'état des boutons radio
//         // à l'intérieur de la boîte de dialogue, ce qui est plus robuste.
//         return StatefulBuilder(
//           builder: (context, setState) {
//             return AlertDialog(
//               title: const Text('Settings'),
//               content: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   RadioListTile<String>(
//                     title: const Text('CPU (Slower, Compatible)'),
//                     value: 'cpu',
//                     groupValue: selectedBackend,
//                     onChanged: (value) {
//                       if (value != null) setState(() => selectedBackend = value);
//                     },
//                   ),
//                   RadioListTile<String>(
//                     title: const Text('GPU (Faster, Recommended)'),
//                     value: 'gpu',
//                     groupValue: selectedBackend,
//                     onChanged: (value) {
//                       if (value != null) setState(() => selectedBackend = value);
//                     },
//                   ),
//                   const Divider(),
//                   ListTile(
//                     leading: const Icon(Icons.refresh, color: Colors.orangeAccent),
//                     title: const Text('Reset HF Token'),
//                     onTap: () => Navigator.pop(dialogContext, 'reset_token'),
//                   ),
//                 ],
//               ),
//               actions: [
//                 TextButton(
//                   onPressed: () => Navigator.pop(dialogContext),
//                   child: const Text('Cancel'),
//                 ),
//                 FilledButton(
//                   onPressed: () => Navigator.pop(dialogContext, selectedBackend),
//                   child: const Text('Apply'),
//                 ),
//               ],
//             );
//           },
//         );
//       },
//     );

//     if (!mounted || result == null) return;
//     final scaffoldMessenger = ScaffoldMessenger.of(context);
//     final currentBackend = prefs.getString('preferred_backend') ?? 'cpu';

//     if (result == 'reset_token') {
//       await prefs.remove('user_hf_token');
//       scaffoldMessenger.showSnackBar(const SnackBar(
//         content: Text('Token removed. A new token will be requested.'),
//         backgroundColor: Colors.orange,
//       ));
//       _initializeGemma();
//     } else if (result != currentBackend) {
//       await prefs.setString('preferred_backend', result);
//       scaffoldMessenger.showSnackBar(const SnackBar(
//         content: Text('Setting saved. Restart the app to apply.'),
//       ));
//     }
//   }
//   // **FIN DE LA CORRECTION**

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       // L'AppBar est maintenant gérée ici, de manière centralisée.
//       appBar: AppBar(
//         // Le titre change en fonction de l'onglet sélectionné.
//         title: Text(_selectedIndex == 0 ? 'ActiveFlow' : 'NourishFlow'),
//         centerTitle: true,
//         actions: [
//           // Le bouton des paramètres s'affiche uniquement quand l'app est prête.
//           if (_appInitState == AppInitState.ready)
//             IconButton(
//               icon: const Icon(Icons.settings_outlined),
//               onPressed: _showSettingsDialog,
//               tooltip: 'Settings',
//             ),
//         ],
//       ),
//       body: switch (_appInitState) {
//         AppInitState.configuring => const ConfiguringView(),
//         AppInitState.configFailed => ConfigFailedView(onRetry: _initializeGemma),
//         AppInitState.offlineNeedsSetup =>
//           OfflineSetupView(onRetry: _initializeGemma),
//         AppInitState.ready => _buildReadyStateBody(),
//       },
//       bottomNavigationBar: _appInitState == AppInitState.ready
//           ? BottomNavigationBar(
//               items: const <BottomNavigationBarItem>[
//                 BottomNavigationBarItem(
//                   icon: Icon(Icons.fitness_center_outlined),
//                   activeIcon: Icon(Icons.fitness_center),
//                   label: 'ActiveFlow',
//                 ),
//                 BottomNavigationBarItem(
//                   icon: Icon(Icons.restaurant_menu_outlined),
//                   activeIcon: Icon(Icons.restaurant_menu),
//                   label: 'NourishFlow',
//                 ),
//               ],
//               currentIndex: _selectedIndex,
//               onTap: (index) => setState(() => _selectedIndex = index),
//             )
//           : null,
//     );
//   }

//   Widget _buildReadyStateBody() {
//     final gemmaService = Provider.of<GemmaService>(context);

//     return ValueListenableBuilder<GemmaState>(
//       valueListenable: gemmaService.state,
//       builder: (context, gemmaState, child) {
//         switch (gemmaState) {
//           case GemmaState.uninitialized:
//           case GemmaState.initializing:
//             return const GemmaLoadingView(text: 'Initializing...');
//           case GemmaState.loadingModel:
//             return const GemmaLoadingView(text: 'Preparing model...');
//           case GemmaState.downloading:
//             return ValueListenableBuilder<double?>(
//               valueListenable: gemmaService.downloadProgress,
//               builder: (context, progress, child) {
//                 return GemmaDownloadingView(progress: progress);
//               },
//             );
//           case GemmaState.tokenError:
//             return GemmaTokenErrorView(
//               errorMessage: gemmaService.errorMessage.value,
//               onGoToSettings: _showSettingsDialog,
//             );
//           case GemmaState.error:
//             return GemmaErrorView(
//               errorMessage: gemmaService.errorMessage.value,
//               onRetry: _initializeGemma,
//             );
//           case GemmaState.ready:
//             return IndexedStack(
//               index: _selectedIndex,
//               children: _widgetOptions,
//             );
//         }
//       },
//     );
//   }
// }
//==================================================================================================
//==================================================================================================
// Cele-ci est la première sans statefulbuild
// import 'dart:io';
// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_gemma/pigeon.g.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:sentia_flow/features/active_flow/active_flow_screen.dart';
// import 'package:sentia_flow/features/nourish_flow/screens/nourish_home_screen.dart';
// import 'package:sentia_flow/services/gemma_service.dart';
// import 'package:sentia_flow/widgets/state_views.dart';
// import 'package:provider/provider.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// enum AppInitState {
//   configuring,
//   ready,
//   configFailed,
//   offlineNeedsSetup,
// }

// class MainShell extends StatefulWidget {
//   const MainShell({super.key});

//   @override
//   State<MainShell> createState() => _MainShellState();
// }

// class _MainShellState extends State<MainShell> {
//   AppInitState _appInitState = AppInitState.configuring;
//   int _selectedIndex = 0;

//   // Les écrans n'ont plus besoin de leur propre AppBar.
//   // Va à build method et Appbar, je l'ai rendue dynamaique pour toujours afficher le settings (CPU,GPU, resettoken)
//   static const List<Widget> _widgetOptions = <Widget>[
//     ActiveFlowScreen(),
//     NourishHomeScreen(),
//   ];

//   @override
//   void initState() {
//     super.initState();
//     _initializeGemma();
//   }

//   Future<void> _initializeGemma() async {
//     if (!mounted) return;
    
//     final gemmaService = Provider.of<GemmaService>(context, listen: false);
//     await gemmaService.resetState();

//     if (_appInitState != AppInitState.configuring) {
//       setState(() => _appInitState = AppInitState.configuring);
//     }
    
//     final prefs = await SharedPreferences.getInstance();
//     final modelPath = await GemmaService.getModelPath();
//     final modelFile = File(modelPath);
//     final bool modelExists = await modelFile.exists();
//     final String? userToken = prefs.getString('user_hf_token');

//     if (modelExists && userToken != null && userToken.isNotEmpty) {
//       debugPrint("Model and token found locally. Starting in offline-first mode.");
//       final savedBackend = prefs.getString('preferred_backend') ?? 'cpu';
//       final backend =
//           savedBackend == 'gpu' ? PreferredBackend.gpu : PreferredBackend.cpu;
//       if (mounted) setState(() => _appInitState = AppInitState.ready);
//       gemmaService.configureAndInitialize(
//         huggingFaceToken: userToken,
//         preferredBackend: backend,
//         skipOnlineCheck: true,
//       );
//       return;
//     }

//     debugPrint("Entering online setup flow (model missing or token reset).");
//     final connectivityResult = await (Connectivity().checkConnectivity());
//     bool isOffline = connectivityResult.isEmpty ||
//         connectivityResult.every((e) => e == ConnectivityResult.none || e == ConnectivityResult.bluetooth);

//     if (isOffline) {
//       debugPrint("No internet connection detected during setup flow.");
//       if (mounted) setState(() => _appInitState = AppInitState.offlineNeedsSetup);
//       return;
//     }

//     String? tokenForSetup = userToken;
//     bool isTokenValid = false;
//     if (tokenForSetup != null && tokenForSetup.isNotEmpty) {
//       isTokenValid = await GemmaService.validateToken(tokenForSetup);
//     }

//     if (!isTokenValid) {
//       while (true) {
//         if (!mounted) return;
//         tokenForSetup = await _showTokenDialog(context);
//         if (tokenForSetup == null || tokenForSetup.isEmpty) {
//           if (mounted) setState(() => _appInitState = AppInitState.configFailed);
//           return;
//         }
//         isTokenValid = await GemmaService.validateToken(tokenForSetup);
//         if (isTokenValid) break;
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

//     await prefs.setString('user_hf_token', tokenForSetup!);
//     final savedBackend = prefs.getString('preferred_backend') ?? 'cpu';
//     final backend =
//         savedBackend == 'gpu' ? PreferredBackend.gpu : PreferredBackend.cpu;
//     if (mounted) setState(() => _appInitState = AppInitState.ready);
    
//     gemmaService.configureAndInitialize(
//       huggingFaceToken: tokenForSetup,
//       preferredBackend: backend,
//       skipOnlineCheck: false,
//     );
//   }

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
//                 "Please enter your Hugging Face access token with read permissions to download the model.",
//               ),
//               SizedBox(height: 16.h),
//               TextField(
//                 controller: textController,
//                 decoration: const InputDecoration(
//                   labelText: 'Access Token',
//                   hintText: 'Enter your HF token here',
//                 ),
//               ),
//             ],
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.of(context).pop(),
//               child: const Text('Cancel'),
//             ),
//             FilledButton(
//               onPressed: () {
//                 final token = textController.text.trim();
//                 if (token.isNotEmpty) {
//                   Navigator.of(context).pop(token);
//                 }
//               },
//               child: const Text('Save'),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   Future<void> _showSettingsDialog() async {
//     final prefs = await SharedPreferences.getInstance();
//     final currentBackend = prefs.getString('preferred_backend') ?? 'cpu';

//     if (!mounted) return;

//     final result = await showDialog<String>(
//       context: context,
//       builder: (dialogContext) => SimpleDialog(
//         title: const Text('Settings'),
//         children: [
//           SimpleDialogOption(
//             onPressed: () => Navigator.pop(dialogContext, 'cpu'),
//             child: Row(children: [
//               Radio<String>(
//                   value: 'cpu',
//                   groupValue: currentBackend,
//                   onChanged: (v) => Navigator.pop(dialogContext, 'cpu')),
//               const Flexible(child: Text('CPU (Slower, Compatible)')),
//             ]),
//           ),
//           SimpleDialogOption(
//             onPressed: () => Navigator.pop(dialogContext, 'gpu'),
//             child: Row(children: [
//               Radio<String>(
//                   value: 'gpu',
//                   groupValue: currentBackend,
//                   onChanged: (v) => Navigator.pop(dialogContext, 'gpu')),
//               const Flexible(child: Text('GPU (Faster, Recommended)')),
//             ]),
//           ),
//           const Divider(),
//           SimpleDialogOption(
//             onPressed: () => Navigator.pop(dialogContext, 'reset_token'),
//             child: Row(children: [
//               const Icon(Icons.refresh, color: Colors.orangeAccent),
//               SizedBox(width: 8.w),
//               const Text('Reset HF Token'),
//             ]),
//           ),
//         ],
//       ),
//     );

//     if (!mounted || result == null) return;
//     final scaffoldMessenger = ScaffoldMessenger.of(context);

//     if (result == 'reset_token') {
//       await prefs.remove('user_hf_token');
//       scaffoldMessenger.showSnackBar(const SnackBar(
//         content: Text('Token removed. A new token will be requested.'),
//         backgroundColor: Colors.orange,
//       ));
//       _initializeGemma();
//     } else if (result != currentBackend) {
//       await prefs.setString('preferred_backend', result);
//       scaffoldMessenger.showSnackBar(const SnackBar(
//         content: Text('Setting saved. Restart the app to apply.'),
//       ));
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       // L'AppBar est maintenant gérée ici, de manière centralisée.
//       appBar: AppBar(
//         // Le titre change en fonction de l'onglet sélectionné.
//         title: Text(_selectedIndex == 0 ? 'ActiveFlow' : 'NourishFlow'),
//         centerTitle: true,
//         actions: [
//           // Le bouton des paramètres s'affiche uniquement quand l'app est prête.
//           if (_appInitState == AppInitState.ready)
//             IconButton(
//               icon: const Icon(Icons.settings_outlined),
//               onPressed: _showSettingsDialog,
//               tooltip: 'Settings',
//             ),
//         ],
//       ),
//       body: switch (_appInitState) {
//         AppInitState.configuring => const ConfiguringView(),
//         AppInitState.configFailed => ConfigFailedView(onRetry: _initializeGemma),
//         AppInitState.offlineNeedsSetup =>
//           OfflineSetupView(onRetry: _initializeGemma),
//         AppInitState.ready => _buildReadyStateBody(),
//       },
//       bottomNavigationBar: _appInitState == AppInitState.ready
//           ? BottomNavigationBar(
//               items: const <BottomNavigationBarItem>[
//                 BottomNavigationBarItem(
//                   icon: Icon(Icons.fitness_center_outlined),
//                   activeIcon: Icon(Icons.fitness_center),
//                   label: 'ActiveFlow',
//                 ),
//                 BottomNavigationBarItem(
//                   icon: Icon(Icons.restaurant_menu_outlined),
//                   activeIcon: Icon(Icons.restaurant_menu),
//                   label: 'NourishFlow',
//                 ),
//               ],
//               currentIndex: _selectedIndex,
//               onTap: (index) => setState(() => _selectedIndex = index),
//             )
//           : null,
//     );
//   }

//   Widget _buildReadyStateBody() {
//     final gemmaService = Provider.of<GemmaService>(context);

//     return ValueListenableBuilder<GemmaState>(
//       valueListenable: gemmaService.state,
//       builder: (context, gemmaState, child) {
//         switch (gemmaState) {
//           case GemmaState.uninitialized:
//           case GemmaState.initializing:
//             return const GemmaLoadingView(text: 'Initializing...');
//           case GemmaState.loadingModel:
//             return const GemmaLoadingView(text: 'Preparing model...');
//           case GemmaState.downloading:
//             return ValueListenableBuilder<double?>(
//               valueListenable: gemmaService.downloadProgress,
//               builder: (context, progress, child) {
//                 return GemmaDownloadingView(progress: progress);
//               },
//             );
//           case GemmaState.tokenError:
//             return GemmaTokenErrorView(
//               errorMessage: gemmaService.errorMessage.value,
//               onGoToSettings: _showSettingsDialog,
//             );
//           case GemmaState.error:
//             return GemmaErrorView(
//               errorMessage: gemmaService.errorMessage.value,
//               onRetry: _initializeGemma,
//             );
//           case GemmaState.ready:
//             return IndexedStack(
//               index: _selectedIndex,
//               children: _widgetOptions,
//             );
//         }
//       },
//     );
//   }
// }


