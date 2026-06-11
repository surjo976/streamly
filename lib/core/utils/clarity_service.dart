export 'clarity_service_stub.dart'
    if (dart.library.html) 'clarity_service_web.dart'
    if (dart.library.io) 'clarity_service_mobile.dart';
