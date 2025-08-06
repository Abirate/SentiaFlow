
# Règles pour Google ML Kit et MediaPipe (utilisés par gemma et pose_detection)
# Empêche R8 de supprimer les classes nécessaires à la réflexion.
-keep class com.google.mediapipe.** { *; }
-keep class com.google.protobuf.** { *; }
-keep class com.google.mlkit.** { *; }

# Garde les classes nécessaires aux processeurs d'annotations (souvent une dépendance cachée)
-keep class javax.lang.model.** { *; }
-keep class autovalue.shaded.com.squareup.javapoet.** { *; }