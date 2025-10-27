# skarb_plugin

## Introduction
SkarbSDK is a framework that makes you happier.
It automatically reports install event - during SDK initialization phase. 

In addition, you could enrich these events with features obtained from the traffic source by explicit call of `sendAFSource()` method. And if you're interesting in split testing inside an app take a look on `sendTest()` method.

## Getting Started

To use this plugin in Android, add this to your build.gradle file under allprojects/repositories:

```gradle
maven {
    url 'https://gitlab.com/api/v4/projects/67253583/packages/maven'
}
```

## Installation

### pubspec

To integrate skarb_plugin into your Flutter project, specify it in your `pubspec.yaml`:

```
dependencies:
  skarb_plugin:
    git:
      url: https://github.com/bitlica/SkarbSDK-Flutter.git
      ref: {version_tag} (example: 3.4.3)
```

## Usage
### Initialization 

```dart
import 'package:skarb_plugin/skarb_plugin.dart';

Future<void> main() async {
  await SkarbPlugin.initialize(
      deviceId: null,
      androidClientKey: androidClientKey,
      amplitudeApiKey: F.amplitudeKey,
      isObservable: isObservable
  );

  runApp();
}
```
#### Params:
```amplitudeApiKey``` Key for logs to amplitude.

```androidClientKey``` Key for android ```clientKey```.

```deviceId``` If you want to can use your own generated deviceId. Default value is ```null```.

```isObservable``` Automatically sends all events about purchases that are in your app if ```true```. Default value is ```false```.


### Send features 

Using for loging the attribution.

```dart
import 'package:skarb_plugin/skarb_plugin.dart';

SkarbPlugin.sendAFSource(conversionInfo, id);

```
#### Params:
```conversionInfo``` payload from ```onInstallConversionData``` of AppsflyerSdk, 
```id```. Use the unique userID for this SKBroker if you want to use postbacks. For example, for Appsflyer - getAppsFlyerUID

#### Example for Appsflyer:
In delegate mothod:

```dart
import 'package:skarb_plugin/skarb_plugin.dart';

 _appsflyerSdk.onInstallConversionData((res) async {
      appsflyerId = await _appsflyerSdk.getAppsFlyerUID();

      skarbId =
          await SkarbPlugin.sendAFSource(res['payload'], appsflyerId) ?? '';
      await _amplitudeService.setUserId(skarbId);
    });
```


### A/B testing

```dart
import 'package:skarb_plugin/skarb_plugin.dart';

SkarbPlugin.sendTest(name, group)
```
#### Params:
```name``` Name of A/B test

```group``` Group name of A/B test. For example: control group, B, etc.

### Logging
If you want to see logs, please create subclass of ```SkarbLogger``` and use it to collect logs.
```dart
import 'package:skarb_plugin/skarb_plugin.dart';

SkarbPlugin.logger = SkarbLogger();
```
