import 'dart:async';

import 'package:flutter/services.dart';

/// User Consent status 
/// 
/// This is for GDPR Users
enum UserConsentStatus {
  Accepted,
  Denied,
}


typedef void OnInitilizeListener();

typedef void OnAdPlayableListener(String placementId, bool playable);

typedef void OnAdStartedListener(String placementId);

typedef void OnAdFinishedListener(
    String placementId, bool isCTAClicked, bool isCompletedView);

class Vungle {
  static const MethodChannel _channel = const MethodChannel('flutter_vungle');

  static OnInitilizeListener onInitilizeListener;

  static OnAdPlayableListener onAdPlayableListener;

  static OnAdStartedListener onAdStartedListener;

  static OnAdFinishedListener onAdFinishedListener;

  /// Initialize the flutter plugin for Vungle SDK.
  /// 
  /// Please go to the http://www.vungle.com to apply a publisher account and register your apps.
  /// Then You will get an [appId] for each of you apps. You need pass it to plugin when call this method.
  /// Note: If you want to use flutter to develop an app for both iOS and Android, you need register two apps for each platform on vungle dashboard.
  /// And use following code to initialize the plugin:
  /// ```dart
  /// if(Platform.isAndroid) {
  ///   Vungle.init('<Your-Android-AppId>');
  /// } else if(Platform.isIOS) {
  ///   Vungle.init('<Your-iOS-AppId>');
  /// }
  /// 
  /// Vungle.onInitilizeListener = () {
  ///   //SDK has initialized, could load ads now 
  /// }
  /// ```
  static void init(String appId) {
    //register callback method handler
    _channel.setMethodCallHandler(_handleMethod);

    _channel.invokeMethod('init', <String, dynamic>{
      'appId': appId,
    });
  }

  /// Load Ad by a [placementId]
  /// 
  /// After you registered your apps on the vungle dashboard, you will get a default placement with an id for each app.
  /// You could create more placements as you want. And You need call this method to load the ads for the placement.
  /// You could use [onAdPlayableListener] to know when the ad loaded.
  /// ```dart
  /// if(Platform.isAndroid) {
  ///   Vungle.loadAd('<Your-Android-placementId>')
  /// } else if(Platform.isIOS) {
  ///   Vungle.loadAd('<Your-IOS-placementId>')
  /// }
  /// 
  /// Vungle.onAdPlayableListener = (playable, placementId) {
  ///   if(playable) {
  ///     //the ad is loaded, could play ad for now.
  ///   }
  /// }
  /// ```
  static void loadAd(String placementId) {
    _channel.invokeMethod('loadAd', <String, dynamic>{
      'placementId': placementId,
    });
  }

  /// Play ad by a [placementId]
  /// 
  /// When ad is loaded, you could call this method to play ad
  /// ```dart
  /// Vungle.onAdPlayableListener = (playable, placementId) {
  ///   if(playable) {
  ///     Vungle.playAd(placementId);
  ///   }
  /// }
  /// 
  /// Vungle.onAdStartedListener = (placementId) {
  ///   //ad started to play
  /// }
  /// 
  /// Vungle.onAdFinishedListener = (placementId, isCTAClicked, isCompletedView) {
  ///   if(isCTAClicked) {
  ///     //User has clicked the download button
  ///   }
  ///   if(isCompletedView) {
  ///     //User has viewed the ad completely
  ///   }
  /// }
  /// ```
  static void playAd(String placementId) {
    _channel.invokeMethod('playAd', <String, dynamic>{
      'placementId': placementId,
    });
  }


  /// Check if ad playable by a [placementId]
  /// 
  /// Sometimes, you may not cared about when ad is ready to play, you just cared if there is avaiable ads when you want to show them.
  /// You can use following code to do this:
  /// ```dart
  /// if(await Vungle.isAdPlayable('<placementId>')) {
  ///   Vungle.playAd('<placementId>');
  /// }
  /// ```
  static Future<bool> isAdPlayable(String placementId) async {
    final bool isAdAvailable =
        await _channel.invokeMethod('isAdPlayable', <String, dynamic>{
      'placementId': placementId,
    });
    return isAdAvailable;
  }


  /// Update Consent Status
  /// 
  /// For GDPR users, you may need show a consent dialog to them, and you need call this method to pass the user's decision to the SDK,
  /// "Accepted" or "Denied". That SDK could follow the GDPR policy correctly. 
  static void updateConsentStatus(
      UserConsentStatus status, String consentMessageVersion) {
    _channel.invokeMethod('updateConsentStatus', <String, dynamic>{
      'consentStatus': status.toString(),
      'consentMessageVersion': consentMessageVersion,
    });
  }

  /// Get Consent Status
  static Future<UserConsentStatus> getConsentStatus() async {
    final String status = await _channel.invokeMethod('getConsentStatus', null);
    return _statusStringToUserConsentStatus[status];
  }

  /// Get Consent Message version
  static Future<String> getConsentMessageVersion() async {
    final String version =
        await _channel.invokeMethod('getConsentMessageVersion', null);
    return version;
  }

  static const Map<String, UserConsentStatus> _statusStringToUserConsentStatus =
      {
    'Accepted': UserConsentStatus.Accepted,
    'Denied': UserConsentStatus.Denied,
  };

  static Future<dynamic> _handleMethod(MethodCall call) {
    print('_handleMethod: ${call.method}, ${call.arguments}');
    final Map<dynamic, dynamic> arguments = call.arguments;
    final String method = call.method;

    if (method == 'onInitialize') {
      if (onInitilizeListener != null) {
        onInitilizeListener();
      }
    } else {
      final String placementId = arguments['placementId'];
      if (method == 'onAdPlayable') {
        final bool playable = arguments['playable'];
        if (onAdPlayableListener != null) {
          onAdPlayableListener(placementId, playable);
        }
      } else if (method == 'onAdStarted') {
        if (onAdStartedListener != null) {
          onAdStartedListener(placementId);
        }
      } else if (method == 'onAdFinished') {
        final bool isCTAClicked = arguments['isCTAClicked'];
        final bool isCompletedView = arguments['isCompletedView'];
        onAdFinishedListener(placementId, isCTAClicked, isCompletedView);
      } else {
        throw new MissingPluginException("Method not implemented, $method");
      }
    }
    return Future<dynamic>.value(null);
  }
}
