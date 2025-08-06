import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppTheme {
  // Vous pouvez garder votre darkTheme ici si vous le souhaitez, ou le supprimer.
  // static final ThemeData darkTheme = ... ;

  // NOUVEAU THEME CLAIR
  static final ThemeData lightTheme = ThemeData.light().copyWith(
    // Couleurs principales basées sur votre palette
    scaffoldBackgroundColor: const Color(
      0xFFF5F5F5,
    ), // Gris très clair pour le fond
    primaryColor: const Color(0xFFB39DDB), // Teal (votre couleur principale)

    colorScheme: const ColorScheme.light().copyWith(
      primary: const Color(0xFF9575CD),
      secondary: const Color(0xFFF9A826), // Orange
      surface: Colors.white, // Cartes, Dialogues en blanc pur
      onPrimary: Colors.black, // Texte sur les boutons primaires
      onSecondary: Colors.black,
      onSurface: const Color(
        0xFF16172D,
      ), // Texte principal : Votre ancien violet foncé (très lisible)
      error: Colors.red,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFB39DDB),
      elevation: 1, // Légère ombre pour séparer l'AppBar
      titleTextStyle: TextStyle(
        fontFamily: 'Poppins',
        color: Color(0xFF16172D), // Texte foncé
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      iconTheme: IconThemeData(color: Color(0xFF16172D)), // Icônes foncées
    ),

    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: const Color(0xFF9575CD),
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,

      // --- AJOUTEZ CES LIGNES ---
      selectedIconTheme: const IconThemeData(
        size: 28, // Taille de l'icône active
        weight:
            700, // Épaisseur de l'icône (plus la valeur est élevée, plus c'est gras)
      ),
      unselectedIconTheme: const IconThemeData(
        size: 24, // Taille de l'icône inactive
        weight: 400, // Épaisseur normale
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        // --- C'est ici que vous changez les couleurs ---

        // Couleur de fond du bouton (votre couleur primaire)
        backgroundColor: Color(0xFFB39DDB),

        // Couleur du texte et de l'icône (le blanc est souvent plus joli sur le teal)
        foregroundColor: Colors.white,

        // --- Autres options de style ---
        elevation: 2, // Ombre légère
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        padding: EdgeInsets.symmetric(vertical: 16.h),
        textStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 16.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
    // Les boutons restent similaires à votre design original
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF9575CD),
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        padding: EdgeInsets.symmetric(vertical: 16.h),
        textStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 16.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),

    // Application de la police et de la couleur du texte
    textTheme: ThemeData.light().textTheme.apply(
      fontFamily: 'Poppins',
      bodyColor: const Color(0xFF16172D),
      displayColor: const Color(0xFF16172D),
    ),
  );
}



// For dark theme
// class AppTheme {
//   // --- CHANGEMENT MAJEUR ICI ---
//   // On utilise ThemeData.dark() comme base solide, puis on applique nos personnalisations avec copyWith.
//   static final ThemeData darkTheme = ThemeData.dark().copyWith(
    
//     // 'brightness' est déjà 'dark'.
//     // 'fontFamily' sera appliqué via textTheme.apply() plus bas.

//     scaffoldBackgroundColor: const Color(0xFF16172D),
//     primaryColor: const Color(0xFF29D6B6),

//     // On personnalise le ColorScheme.dark par défaut.
//     colorScheme: const ColorScheme.dark().copyWith(
//       primary: const Color(0xFF29D6B6),
//       secondary: const Color(0xFFF9A826),
//       surface: const Color(0xFF212340),
//       onPrimary: Colors.black, // Texte sur les boutons primaires
//       onSecondary: Colors.black,
//       onSurface: const Color(0xFFEAEAF5), // Couleur principale du texte (très important)
//       error: Colors.redAccent,
//       onError: Colors.white,
//     ),

//     appBarTheme: const AppBarTheme(
//       backgroundColor: Color(0xFF212340),
//       elevation: 0,
//       titleTextStyle: TextStyle(
//         fontFamily: 'Poppins',
//         color: Color(0xFFEAEAF5),
//         fontSize: 20,
//         fontWeight: FontWeight.bold,
//       ),
//       iconTheme: IconThemeData(color: Color(0xFFEAEAF5)),
//     ),

//     bottomNavigationBarTheme: const BottomNavigationBarThemeData(
//       backgroundColor: Color(0xFF212340),
//       selectedItemColor: Color(0xFF29D6B6),
//       unselectedItemColor: Colors.grey,
//       type: BottomNavigationBarType.fixed,
//       showUnselectedLabels: true,
//     ),

//     // inputDecorationTheme, dialogTheme, cardTheme, filledButtonTheme restent similaires 
//     // mais sont maintenant des modifications appliquées sur la base sombre.
//     inputDecorationTheme: InputDecorationTheme(
//       filled: true,
//       fillColor: const Color(0xFF16172D),
//       hintStyle: TextStyle(color: Colors.grey[600]),
//       contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
//       border: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(12.r),
//         borderSide: const BorderSide(color: Colors.transparent),
//       ),
//       enabledBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(12.r),
//         borderSide: BorderSide(color: Colors.grey.withAlpha(50)),
//       ),
//       focusedBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(12.r),
//         borderSide: const BorderSide(color: Color(0xFF29D6B6), width: 1.5),
//       ),
//     ),
    
//     dialogTheme: DialogThemeData(
//       backgroundColor: const Color(0xFF212340),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
//       titleTextStyle: TextStyle(
//         fontFamily: 'Poppins',
//         color: const Color(0xFFEAEAF5),
//         fontSize: 20.sp,
//         fontWeight: FontWeight.bold,
//       ),
//       contentTextStyle: TextStyle(
//         fontFamily: 'Poppins',
//         color: const Color(0xFFEAEAF5),
//         fontSize: 15.sp,
//       ),
//     ),

//     // Ceci garantit que la SnackBar (qui était vide aussi) aura le bon thème.
//     snackBarTheme: SnackBarThemeData(
//       backgroundColor: const Color(0xFF212340),
//       contentTextStyle: TextStyle(
//         fontFamily: 'Poppins',
//         color: const Color(0xFFEAEAF5),
//         fontSize: 14.sp,
//       ),
//       actionTextColor: const Color(0xFF29D6B6),
//     ),
    
//     cardTheme: CardThemeData(
//       elevation: 0,
//       color: const Color(0xFF212340),
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12.r),
//         side: BorderSide(color: Colors.grey.withAlpha(50)),
//       ),
//     ),

//     filledButtonTheme: FilledButtonThemeData(
//       style: FilledButton.styleFrom(
//         backgroundColor: const Color(0xFF29D6B6),
//         foregroundColor: Colors.black,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
//         padding: EdgeInsets.symmetric(vertical: 16.h),
//         textStyle: TextStyle(
//           fontFamily: 'Poppins',
//           fontSize: 16.sp,
//           fontWeight: FontWeight.bold,
//         ),
//       ),
//     ),

//     // --- CORRECTION CRUCIALE DU TEXTTHEME ---
//     // On prend le TextTheme sombre par défaut (qui a déjà des couleurs claires)
//     // et on applique nos personnalisations (tailles, poids).
//     textTheme: ThemeData.dark().textTheme.copyWith(
//       // On applique vos styles personnalisés
//       headlineSmall: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold, color: const Color(0xFFEAEAF5)),
//       bodyLarge: TextStyle(fontSize: 15.sp, color: const Color(0xFFEAEAF5)),
//       bodyMedium: TextStyle(fontSize: 14.sp, color: Colors.grey[400]),
//     ).apply(
//       // On applique la police globale à tous les styles.
//       fontFamily: 'Poppins',
//       // Par sécurité, on force la couleur globale du texte.
//       bodyColor: const Color(0xFFEAEAF5),
//       displayColor: const Color(0xFFEAEAF5),
//     ),
//   );
// }

