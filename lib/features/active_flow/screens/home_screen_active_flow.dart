import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sentia_flow/features/active_flow/models/exercise_model.dart';
import 'package:sentia_flow/features/active_flow/screens/pose_analysis_screen.dart';

class ActiveFlowHomeScreen extends StatelessWidget {
  const ActiveFlowHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // On récupère le thème pour accéder facilement aux styles
    final theme = Theme.of(context);

    return Scaffold(
      body: ListView.builder(
        padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 16.w),
        itemCount: exercises.length,
        itemBuilder: (context, index) {
          final exercise = exercises[index];
          // Le widget Card va maintenant utiliser le style défini dans `cardTheme` de notre AppTheme.
          return Card(
            elevation: 4,
            // SUPPRIMÉ : elevation: 4, -> Géré par cardTheme
            // SUPPRIMÉ : color: Colors.white.withAlpha(13), -> Géré par cardTheme
            margin: EdgeInsets.only(bottom: 12.h),
            // On peut garder une shape personnalisée ou la laisser au thème. Gardons-la pour l'exemple.
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
            child: ListTile(
              contentPadding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 16.w),
              leading: SizedBox(
                width: 50.w,
                height: 50.h,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.r),
                  child: Image.asset(
                    exercise.imagePath,
                    fit: BoxFit.cover,
                    // C'était déjà correct ! Utilise la couleur primaire du thème.
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(exercise.icon, color: theme.primaryColor);
                    },
                  ),
                ),
              ),
              // Le style du titre va maintenant hériter de `textTheme.bodyLarge` (noir et lisible)
              // On peut surcharger uniquement ce qui est nécessaire (taille, poids).
              title: Text(
                exercise.name,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 17.sp,
                ),
              ),
              // Le sous-titre va hériter de `textTheme.bodyMedium` (gris et plus petit)
              subtitle: Text(
                exercise.description,
                style: theme.textTheme.bodyMedium, // Parfait pour un sous-titre !
              ),
              // L'icône va prendre la couleur par défaut des icônes du thème.
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 16.sp,
                // SUPPRIMÉ : color: Colors.white38
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PoseAnalysisScreen(exercise: exercise),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}


// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:sentia_flow/features/active_flow/models/exercise_model.dart';
// import 'package:sentia_flow/features/active_flow/screens/pose_analysis_screen.dart';

// class ActiveFlowHomeScreen extends StatelessWidget {
//   const ActiveFlowHomeScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       // appBar: AppBar(
//       //   title: Text('PoseFit - Select an Exercise', style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold)),
//       //   centerTitle: true,
//       // ),
//       // CORRECTION: Ajout de Center pour aligner la liste verticalement
//       body: Center(
//         child: ListView.builder(
//           // CORRECTION: shrinkWrap permet à la liste de prendre uniquement la hauteur nécessaire
//           shrinkWrap: true,
//           padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 12.w),
//           itemCount: exercises.length,
//           itemBuilder: (context, index) {
//             final exercise = exercises[index];
//             return Card(
//               elevation: 4,
//               margin: EdgeInsets.only(bottom: 12.h),
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
//               color: Colors.white.withAlpha(13), // withOpacity(0.05)
//               child: ListTile(
//                 contentPadding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
//                 leading: SizedBox(
//                   width: 50.w,
//                   height: 50.h,
//                   child: ClipRRect(
//                     borderRadius: BorderRadius.circular(8.r),
//                     child: Image.asset(
//                       exercise.imagePath,
//                       fit: BoxFit.cover,
//                       errorBuilder: (context, error, stackTrace) {
//                         return Icon(exercise.icon, color: Theme.of(context).primaryColor);
//                       },
//                     ),
//                   ),
//                 ),
//                 title: Text(exercise.name, style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w600, color: Colors.white)),
//                 subtitle: Text(exercise.description, style: TextStyle(fontSize: 13.sp, color: Colors.white70)),
//                 trailing: Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 16.sp),
//                 onTap: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => PoseAnalysisScreen(exercise: exercise),
//                     ),
//                   );
//                 },
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }
// }