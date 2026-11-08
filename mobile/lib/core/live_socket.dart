// Real vaqt ulanishi (WebSocket). Mobil platformada token `Authorization`
// sarlavhasida yuboriladi (URL'da emas — server loglariga tushmasligi
// uchun). Brauzerda sarlavha qo'yib bo'lmaydi, shuning uchun u yerda
// ulanish ochilmaydi va chat oddiy so'rovlar bilan yangilanadi.
export 'live_socket_stub.dart' if (dart.library.io) 'live_socket_io.dart';
