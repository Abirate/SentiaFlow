
import 'package:flutter/material.dart';
import 'package:flutter_gemma/core/message.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; // Import

/// A widget that displays a single message (from user or Gemma).
class ChatMessageWidget extends StatelessWidget {
  final Message message;

  const ChatMessageWidget({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final radius = Radius.circular(16.r); // Responsive
    final isUser = message.isUser;
    final alignment = isUser ? Alignment.centerRight : Alignment.centerLeft;
    
    // Use theme colors for better consistency
    final color = isUser ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surface;
    final textColor = isUser ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurface;
    
    final borderRadius = BorderRadius.only(
      topLeft: radius,
      topRight: radius,
      bottomLeft: isUser ? radius : Radius.zero,
      bottomRight: isUser ? Radius.zero : radius,
    );

    return Align(
      alignment: alignment,
      child: Container(
        constraints: BoxConstraints(maxWidth: 0.75.sw), // Max width is 75% of screen width
        margin: EdgeInsets.symmetric(vertical: 4.h), // Responsive
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h), // Responsive
        decoration: BoxDecoration(
          color: color,
          borderRadius: borderRadius,
          boxShadow: [
            BoxShadow(
              color: const Color.fromRGBO(0, 0, 0, 0.05),
              blurRadius: 5.r, // Responsive
              offset: Offset(0, 2.h), // Responsive
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.imageBytes != null)
              Padding(
                padding: EdgeInsets.only(bottom: 8.h), // Responsive
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.r), // Responsive
                  child: Image.memory(
                    message.imageBytes!,
                    width: 200.w, // Responsive
                    // Height will be calculated based on aspect ratio
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            if (message.text.isNotEmpty)
              MarkdownBody(
                data: message.text,
                selectable: true,
                styleSheet: MarkdownStyleSheet.fromTheme(
                  Theme.of(context),
                ).copyWith(
                  p: TextStyle(color: textColor, fontSize: 15.sp), // Responsive
                ),
              ),
          ],
        ),
      ),
    );
  }
}


// import 'package:flutter/material.dart';
// import 'package:flutter_gemma/core/message.dart';
// import 'package:flutter_markdown/flutter_markdown.dart';

// /// Un widget qui affiche un seul message (de l'utilisateur ou de Gemma).
// class ChatMessageWidget extends StatelessWidget {
//   final Message message;

//   const ChatMessageWidget({super.key, required this.message});

//   @override
//   Widget build(BuildContext context) {
//     final radius = const Radius.circular(16);
//     final isUser = message.isUser;
//     final alignment = isUser ? Alignment.centerRight : Alignment.centerLeft;
//     final color = isUser ? Colors.blue.shade600 : Colors.white;
//     final textColor = isUser ? Colors.white : Colors.black87;
//     final borderRadius = BorderRadius.only(
//       topLeft: radius,
//       topRight: radius,
//       bottomLeft: isUser ? radius : Radius.zero,
//       bottomRight: isUser ? Radius.zero : radius,
//     );

//     return Align(
//       alignment: alignment,
//       child: Container(
//         margin: const EdgeInsets.symmetric(vertical: 4),
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//         decoration: BoxDecoration(
//           color: color,
//           borderRadius: borderRadius,
//           boxShadow: [
//             BoxShadow(
//               color: const Color.fromRGBO(0, 0, 0, 0.05),
//               blurRadius: 5,
//               offset: const Offset(0, 2),
//             ),
//           ],
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             if (message.imageBytes != null)
//               Padding(
//                 padding: const EdgeInsets.only(bottom: 8.0),
//                 child: ClipRRect(
//                   borderRadius: BorderRadius.circular(8),
//                   child: Image.memory(
//                     message.imageBytes!,
//                     width: 200,
//                     height: 200,
//                     fit: BoxFit.cover,
//                   ),
//                 ),
//               ),
//             if (message.text.isNotEmpty)
//               MarkdownBody(
//                 data: message.text,
//                 styleSheet: MarkdownStyleSheet.fromTheme(
//                   Theme.of(context),
//                 ).copyWith(p: TextStyle(color: textColor, fontSize: 15)),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }
