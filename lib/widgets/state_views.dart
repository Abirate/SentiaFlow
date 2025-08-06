
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; // Import

/// Affiche un indicateur de chargement pour la configuration initiale.
class ConfiguringView extends StatelessWidget {
  const ConfiguringView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          SizedBox(height: 16.h), // Responsive
          const Text('Awaiting user configuration...'),
        ],
      ),
    );
  }
}

/// Affiche un message d'erreur si la configuration du token échoue.
class ConfigFailedView extends StatelessWidget {
  final VoidCallback onRetry;
  const ConfigFailedView({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(16.w), // Responsive
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 60.sp), // Responsive
            SizedBox(height: 16.h), // Responsive
            Text(
              'A Hugging Face token is required to continue.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16.sp), // Responsive
            ),
            SizedBox(height: 24.h), // Responsive
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Enter Token'),
            )
          ],
        ),
      ),
    );
  }
}

/// Affiche un indicateur de chargement pour le service Gemma.
class GemmaLoadingView extends StatelessWidget {
  final String text;
  const GemmaLoadingView({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          SizedBox(height: 24.h), // Responsive
          Text(text, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 15.sp)), // Responsive
        ],
      ),
    );
  }
}

/// Affiche la progression du téléchargement du modèle.
class GemmaDownloadingView extends StatelessWidget {
  final double? progress;
  const GemmaDownloadingView({super.key, this.progress});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          SizedBox(height: 24.h), // Responsive
          Text(
            'Downloading Gemma Model...',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 15.sp), // Responsive
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 32.w, // Responsive
              vertical: 16.h, // Responsive
            ),
            child: LinearProgressIndicator(value: progress),
          ),
        ],
      ),
    );
  }
}

/// Affiche un message lorsque l'utilisateur est hors ligne et qu'une configuration est nécessaire.
class OfflineSetupView extends StatelessWidget {
  final VoidCallback onRetry;
  const OfflineSetupView({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w), // Responsive
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_outlined, color: Colors.blueGrey, size: 80.sp), // Responsive
            SizedBox(height: 24.h), // Responsive
            Text(
              'You are Offline',
              style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold), // Responsive
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h), // Responsive
            Text(
              'An internet connection is required to validate your new token and/or download the AI model. Please connect and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16.sp, height: 1.5), // Responsive
            ),
            SizedBox(height: 32.h), // Responsive
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Retry Connection'),
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h), // Responsive
              ),
            )
          ],
        ),
      ),
    );
  }
}

/// Affiche un message d'erreur venant du service Gemma.
class GemmaErrorView extends StatelessWidget {
  final String? errorMessage;
  final VoidCallback? onRetry;
  const GemmaErrorView({super.key, this.errorMessage, this.onRetry});

  @override
  Widget build(BuildContext context) {
    String displayedError = errorMessage ?? "An unknown error occurred.";
    const int maxLength = 250; 
    if (displayedError.length > maxLength) {
      displayedError = '${displayedError.substring(0, maxLength)}...';
    }

    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w), // Responsive
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 60.sp), // Responsive
            SizedBox(height: 16.h), // Responsive
            Text(
              'Error: $displayedError',
              style: TextStyle(color: Colors.red, fontSize: 16.sp), // Responsive
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              SizedBox(height: 24.h), // Responsive
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.redAccent,
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h), // Responsive
                ),
              )
            ]
          ],
        ),
      ),
    );
  }
}

/// Affiche un message d'erreur spécifique au token avec un bouton d'action.
class GemmaTokenErrorView extends StatelessWidget {
  final String? errorMessage;
  final VoidCallback onGoToSettings;
  const GemmaTokenErrorView(
      {super.key, this.errorMessage, required this.onGoToSettings});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w), // Responsive
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.key_off_outlined, color: Colors.orange, size: 60.sp), // Responsive
            SizedBox(height: 16.h), // Responsive
            Text(
              'Authentication Failed',
              style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold), // Responsive
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h), // Responsive
            Text(
              errorMessage ??
                  'Your Hugging Face token is invalid or unauthorized. Please update it in the settings.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16.sp), // Responsive
            ),
            SizedBox(height: 24.h), // Responsive
            ElevatedButton.icon(
              icon: const Icon(Icons.settings),
              label: const Text('Open Settings to Fix'),
              onPressed: onGoToSettings,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h), // Responsive
              ),
            )
          ],
        ),
      ),
    );
  }
}




// import 'package:flutter/material.dart';

// /// Affiche un indicateur de chargement pour la configuration initiale.
// class ConfiguringView extends StatelessWidget {
//   const ConfiguringView({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return const Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           CircularProgressIndicator(),
//           SizedBox(height: 16),
//           Text('Awaiting user configuration...'),
//         ],
//       ),
//     );
//   }
// }

// /// Affiche un message d'erreur si la configuration du token échoue.
// class ConfigFailedView extends StatelessWidget {
//   final VoidCallback onRetry;
//   const ConfigFailedView({super.key, required this.onRetry});

//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Icon(Icons.error_outline, color: Colors.red, size: 60),
//             const SizedBox(height: 16),
//             const Text(
//               'A Hugging Face token is required to continue.',
//               textAlign: TextAlign.center,
//               style: TextStyle(fontSize: 16),
//             ),
//             const SizedBox(height: 24),
//             ElevatedButton(
//               onPressed: onRetry,
//               child: const Text('Enter Token'),
//             )
//           ],
//         ),
//       ),
//     );
//   }
// }

// /// Affiche un indicateur de chargement pour le service Gemma.
// class GemmaLoadingView extends StatelessWidget {
//   final String text;
//   const GemmaLoadingView({super.key, required this.text});

//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           const CircularProgressIndicator(),
//           const SizedBox(height: 24),
//           Text(text, style: Theme.of(context).textTheme.bodyLarge),
//         ],
//       ),
//     );
//   }
// }

// /// Affiche la progression du téléchargement du modèle.
// class GemmaDownloadingView extends StatelessWidget {
//   final double? progress;
//   const GemmaDownloadingView({super.key, this.progress});

//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           const CircularProgressIndicator(),
//           const SizedBox(height: 24),
//           Text(
//             'Downloading Gemma Model...',
//             style: Theme.of(context).textTheme.bodyLarge,
//           ),
//           Padding(
//             padding: const EdgeInsets.symmetric(
//               horizontal: 32.0,
//               vertical: 16.0,
//             ),
//             child: LinearProgressIndicator(value: progress),
//           ),
//         ],
//       ),
//     );
//   }
// }

// /// NOUVELLE VUE : Affiche un message lorsque l'utilisateur est hors ligne et qu'une configuration (token/téléchargement) est nécessaire.
// class OfflineSetupView extends StatelessWidget {
//   final VoidCallback onRetry;
//   const OfflineSetupView({super.key, required this.onRetry});

//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(24.0),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Icon(Icons.wifi_off_outlined, color: Colors.blueGrey, size: 80),
//             const SizedBox(height: 24),
//             const Text(
//               'You are Offline',
//               style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 16),
//             const Text(
//               // Message clair expliquant la situation
//               'An internet connection is required to validate your new token and/or download the AI model. Please connect and try again.',
//               textAlign: TextAlign.center,
//               style: TextStyle(fontSize: 16, height: 1.5),
//             ),
//             const SizedBox(height: 32),
//             ElevatedButton.icon(
//               icon: const Icon(Icons.refresh),
//               label: const Text('Retry Connection'),
//               onPressed: onRetry, // Appelle _initializeGemma pour revérifier la connexion
//                style: ElevatedButton.styleFrom(
//                 padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//               ),
//             )
//           ],
//         ),
//       ),
//     );
//   }
// }


// /// Affiche un message d'erreur venant du service Gemma.
// class GemmaErrorView extends StatelessWidget {
//   final String? errorMessage;
//   final VoidCallback? onRetry;
//   const GemmaErrorView({super.key, this.errorMessage, this.onRetry});

//   @override
//   Widget build(BuildContext context) {
//     // --- DÉBUT DE LA LOGIQUE POUR TRONQUER ---
//     String displayedError = errorMessage ?? "An unknown error occurred.";
//     const int maxLength = 250; // Définir une longueur maximale pour le message.

//     if (displayedError.length > maxLength) {
//       // Si le message est trop long, on le coupe et on ajoute "..."
//       displayedError = '${displayedError.substring(0, maxLength)}...';
//     }
//     // --- FIN DE LA LOGIQUE POUR TRONQUER ---

//     // Avec cette méthode, le SingleChildScrollView n'est plus indispensable,
//     // mais vous pouvez le laisser, il ne gênera pas.
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(24.0),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Icon(Icons.error_outline, color: Colors.red, size: 60),
//             const SizedBox(height: 16),
//             Text(
//               // On utilise notre nouvelle variable qui contient le message potentiellement tronqué.
//               'Error: $displayedError',
//               style: const TextStyle(color: Colors.red, fontSize: 16),
//               textAlign: TextAlign.center,
//             ),
//             if (onRetry != null) ...[
//               const SizedBox(height: 24),
//               ElevatedButton.icon(
//                 icon: const Icon(Icons.refresh),
//                 label: const Text('Retry'),
//                 onPressed: onRetry,
//                 style: ElevatedButton.styleFrom(
//                   foregroundColor: Colors.white,
//                   backgroundColor: Colors.redAccent,
//                   padding:
//                       const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//                 ),
//               )
//             ]
//           ],
//         ),
//       ),
//     );
//   }
// }

// /// NOUVEAU : Affiche un message d'erreur spécifique au token avec un bouton d'action.
// class GemmaTokenErrorView extends StatelessWidget {
//   final String? errorMessage;
//   final VoidCallback onGoToSettings;
//   const GemmaTokenErrorView({super.key, this.errorMessage, required this.onGoToSettings});

//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(24.0),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Icon(Icons.key_off_outlined, color: Colors.orange, size: 60),
//             const SizedBox(height: 16),
//             const Text(
//               'Authentication Failed',
//               style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 8),
//             Text(
//               errorMessage ?? 'Your Hugging Face token is invalid or unauthorized. Please update it in the settings.',
//               textAlign: TextAlign.center,
//               style: const TextStyle(fontSize: 16),
//             ),
//             const SizedBox(height: 24),
//             ElevatedButton.icon(
//               icon: const Icon(Icons.settings),
//               label: const Text('Open Settings to Fix'),
//               onPressed: onGoToSettings,
//               style: ElevatedButton.styleFrom(
//                 padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//               ),
//             )
//           ],
//         ),
//       ),
//     );
//   }
// }


