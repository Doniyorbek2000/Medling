# Flutter deferred components ishlatilmaydi — Play Core sinflari yo'qligi haqida
# R8 ogohlantirishlarini o'chiramiz.
-dontwarn com.google.android.play.core.**

# Google Pay (Wallet API)
-keep class com.google.android.gms.wallet.** { *; }
-dontwarn com.google.android.gms.wallet.**

# WebRTC (LiveKit): JNI orqali chaqiriladi — R8 o'chirmasin.
-keep class org.webrtc.** { *; }
-dontwarn org.webrtc.**
-keep class com.cloudwebrtc.webrtc.** { *; }
