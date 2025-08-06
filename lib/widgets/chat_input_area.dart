
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; // Import

/// A widget for the chat input area, including text field and buttons.
class ChatInputArea extends StatelessWidget {
  final TextEditingController textController;
  final Uint8List? selectedImage;
  final VoidCallback onSendMessage;
  final VoidCallback onPickImage;
  final VoidCallback onClearImage;
  final ValueListenable<bool> isAwaitingResponse;

  const ChatInputArea({
    super.key,
    required this.textController,
    required this.selectedImage,
    required this.onSendMessage,
    required this.onPickImage,
    required this.onClearImage,
    required this.isAwaitingResponse,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface, // Use theme color
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(0, 0, 0, 0.08), // Correct opacity usage
            blurRadius: 10.r,
            offset: Offset(0, -5.h),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selectedImage != null)
                Padding(
                  padding: EdgeInsets.only(bottom: 8.h),
                  child: Stack(
                    alignment: Alignment.topRight,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12.r),
                        child: Image.memory(
                          selectedImage!,
                          height: 120.h,
                          width: 120.w,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Material(
                        color: const Color.fromRGBO(0, 0, 0, 0.54), // Correct opacity usage
                        borderRadius: BorderRadius.circular(20.r),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20.r),
                          onTap: onClearImage,
                          child: Padding(
                            padding: EdgeInsets.all(4.w),
                            child: Icon(Icons.close, color: Colors.white, size: 18.sp),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.image_outlined, size: 26.sp),
                    onPressed: onPickImage,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  Expanded(
                    child: TextField(
                      controller: textController,
                      style: TextStyle(fontSize: 15.sp),
                      decoration: InputDecoration(
                        hintText: 'Send a message...',
                        filled: true,
                        fillColor: Theme.of(context).scaffoldBackgroundColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30.r),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 20.w,
                          vertical: 10.h,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  ValueListenableBuilder<bool>(
                    valueListenable: isAwaitingResponse,
                    builder: (context, isAwaiting, child) {
                      return IconButton.filled(
                        style: IconButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30.r),
                          ),
                        ),
                        icon: Icon(Icons.send, size: 22.sp, color: Colors.black),
                        onPressed: isAwaiting ? null : onSendMessage,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';

// /// Un widget pour la zone de saisie du chat, incluant le champ de texte et les boutons.
// class ChatInputArea extends StatelessWidget {
//   final TextEditingController textController;
//   final Uint8List? selectedImage;
//   final VoidCallback onSendMessage;
//   final VoidCallback onPickImage;
//   final VoidCallback onClearImage;
//   final ValueListenable<bool> isAwaitingResponse;

//   const ChatInputArea({
//     super.key,
//     required this.textController,
//     required this.selectedImage,
//     required this.onSendMessage,
//     required this.onPickImage,
//     required this.onClearImage,
//     required this.isAwaitingResponse,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         boxShadow: [
//           BoxShadow(
//             color: const Color.fromARGB(13, 0, 0, 0),
//             blurRadius: 10,
//             offset: const Offset(0, -5),
//           ),
//         ],
//       ),
//       child: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
//         child: SafeArea(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               if (selectedImage != null)
//                 Padding(
//                   padding: const EdgeInsets.only(bottom: 8.0),
//                   child: Stack(
//                     alignment: Alignment.topRight,
//                     children: [
//                       ClipRRect(
//                         borderRadius: BorderRadius.circular(12),
//                         child: Image.memory(
//                           selectedImage!,
//                           height: 120,
//                           width: 120,
//                           fit: BoxFit.cover,
//                         ),
//                       ),
//                       Material(
//                         color: Colors.black54,
//                         borderRadius: BorderRadius.circular(20),
//                         child: InkWell(
//                           borderRadius: BorderRadius.circular(20),
//                           onTap: onClearImage, // Utilise le callback
//                           child: const Padding(
//                             padding: EdgeInsets.all(4.0),
//                             child: Icon(Icons.close, color: Colors.white, size: 18),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               Row(
//                 children: [
//                   IconButton(
//                     icon: const Icon(Icons.image_outlined),
//                     onPressed: onPickImage, // Utilise le callback
//                     color: Colors.blue.shade700,
//                   ),
//                   Expanded(
//                     child: TextField(
//                       controller: textController,
//                       decoration: InputDecoration(
//                         hintText: 'Translate this menu...',
//                         filled: true,
//                         fillColor: Colors.grey.shade100,
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(30),
//                           borderSide: BorderSide.none,
//                         ),
//                         contentPadding: const EdgeInsets.symmetric(
//                           horizontal: 20,
//                           vertical: 10,
//                         ),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 8),
//                   ValueListenableBuilder<bool>(
//                     valueListenable: isAwaitingResponse,
//                     builder: (context, isAwaiting, child) {
//                       return IconButton.filled(
//                         style: IconButton.styleFrom(
//                           backgroundColor: Colors.blue.shade600,
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(30),
//                           ),
//                         ),
//                         icon: const Icon(Icons.send),
//                         onPressed: isAwaiting ? null : onSendMessage, // Utilise le callback
//                       );
//                     },
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
