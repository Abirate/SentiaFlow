
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool isNumeric;
  // **NOUVEAU PARAMÈTRE** : Pour marquer un champ comme optionnel.
  final bool isRequired;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.isNumeric = true,
    // Par défaut, tous les champs sont obligatoires pour la sécurité.
    this.isRequired = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 13.h),
      child: TextFormField(
        controller: controller,
        style: TextStyle(fontSize: 13.sp, color: Colors.black),
        keyboardType: isNumeric
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        inputFormatters: isNumeric
            ? [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*'))]
            : [],
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.black,fontSize: 13.sp),
          prefixIcon: Icon(icon, color: Theme.of(context).primaryColor.withAlpha(200)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide(color: Colors.grey.shade800),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide(color: Theme.of(context).primaryColor),
          ),
          filled: true,
          fillColor: Colors.white10,
        ),
        // **LOGIQUE DE VALIDATION CORRIGÉE**
        validator: (value) {
          // On vérifie si le champ est vide UNIQUEMENT s'il est requis.
          if (isRequired && (value == null || value.isEmpty)) {
            return 'This field is required';
          }
          // On vérifie si c'est un nombre valide UNIQUEMENT s'il n'est pas vide.
          if (isNumeric && value != null && value.isNotEmpty && double.tryParse(value) == null) {
            return 'Please enter a valid number';
          }
          return null;
        },
      ),
    );
  }
}




// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';

// class CustomTextField extends StatelessWidget {
//   final TextEditingController controller;
//   final String label;
//   final IconData icon;
//   final bool isNumeric;

//   const CustomTextField({
//     super.key,
//     required this.controller,
//     required this.label,
//     required this.icon,
//     this.isNumeric = true,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: EdgeInsets.only(bottom: 13.h),
//       child: TextFormField(
//         controller: controller,
//         // AJOUT : Pour contrôler la taille du texte que l'utilisateur tape
//         style: TextStyle(fontSize: 13.sp, color: Colors.white),
//         keyboardType: isNumeric
//             ? const TextInputType.numberWithOptions(decimal: true)
//             : TextInputType.text,
//         inputFormatters: isNumeric
//             ? [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*'))]
//             : [],
//         decoration: InputDecoration(
//           labelText: label,
//           labelStyle: TextStyle(color: Colors.grey[400],fontSize: 13.sp), // Optionnel : pour ajuster la couleur du label
//           prefixIcon: Icon(icon, color: Theme.of(context).primaryColor.withAlpha(180)),
//           border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
//           enabledBorder: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(12.r),
//             borderSide: BorderSide(color: Colors.grey.shade800),
//           ),
//           focusedBorder: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(12.r),
//             borderSide: BorderSide(color: Theme.of(context).primaryColor),
//           ),
//           filled: true,
//           fillColor: Colors.white.withAlpha(15),
//         ),
//         validator: (value) {
//           if (value == null || value.isEmpty) {
//             return 'This field is required';
//           }
//           if (isNumeric && double.tryParse(value) == null) {
//             return 'Please enter a valid number';
//           }
//           return null;
//         },
//       ),
//     );
//   }
// }