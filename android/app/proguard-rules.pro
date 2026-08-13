# just_audio / ExoPlayer
-keep class com.google.android.exoplayer2.** { *; }
-dontwarn com.google.android.exoplayer2.**

# audio_service media session + notification classes
-keep class com.ryanheise.audioservice.** { *; }

# Keep annotation defaults used by media/session classes
-keepattributes *Annotation*, Signature, InnerClasses, EnclosingMethod
