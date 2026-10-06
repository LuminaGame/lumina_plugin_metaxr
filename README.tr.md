# MetaXR Desteği — Lumina Studio eklentisi (`lumina_plugin_metaxr`)

[Lumina](https://github.com/LuminaGame/lumina) oyun motoru ve editörü Lumina Studio için, Khronos OpenXR temel
eklentisi [`lumina_plugin_openxr`](https://github.com/LuminaGame/lumina_plugin_openxr) üzerine kurulu Meta Quest
özellikleri. Meta OpenXR uzantılarını (`XR_FB_*`) Lumina bileşenleri ve Dart türleri olarak modeller: karma gerçeklik
passthrough'u, pinch hareketleriyle 26 eklemli el izleme, uzamsal çapalar, sahne düzlemleri, yüz ve göz izleme ve
Quest ekran ve foveation ayarları; bunları gözlük olmadan benzeten bir editör paneliyle birlikte.

*English: [README.md](README.md)*

## İçindekiler

- [Durum](#durum)
- [Nereye oturur](#nereye-oturur)
- [Özellikler](#özellikler)
- [Gereksinimler ve platformlar](#gereksinimler-ve-platformlar)
- [Kurulum](#kurulum)
- [Hızlı başlangıç](#hızlı-başlangıç)
- [Kullanım](#kullanım)
- [Editör entegrasyonu](#editör-entegrasyonu)
- [Kendi sürecinde çalışır](#kendi-sürecinde-çalışır)
- [Gözlük olmadan çalışmak](#gözlük-olmadan-çalışmak)
- [Mimari](#mimari)
- [Koordinat sistemleri ve birimler](#koordinat-sistemleri-ve-birimler)
- [Testler](#testler)
- [Sorun giderme](#sorun-giderme)
- [Sınırlamalar ve yol haritası](#sınırlamalar-ve-yol-haritası)
- [Katkı](#katkı)
- [Lisans](#lisans)

## Durum

Sürüm 0.2.0. Bu sürüm **Dart katmanıdır**: uzantı kataloğu, cihaz profilleri, her özelliğin veri modeli, sahne
bileşenleri, pinch mantığı, hata ayıklama el geometrisi, editör panelleri ve MCP araçları; hepsi testli. Henüz hiçbir
`XR_FB_*` fonksiyonu çağrılmıyor: OpenXR temel eklentisi henüz bir OpenXR instance'ı ya da oturumu oluşturmuyor
(onun README'sine bakın); bu yüzden passthrough katmanları, el eklemleri, çapalar, sahne düzlemleri ve yüz
ağırlıkları başlık tarafından değil, sizin kodunuz, editörün benzetim paneli ya da MCP tarafından doldurulur.

| Alan | Veri modeli ve bileşenler | Çalışma zamanından beslenme |
|---|---|---|
| Passthrough (`XR_FB_passthrough`) | tamam | planlandı |
| El izleme, 26 eklem, pinch (`XR_EXT_hand_tracking` + `XR_FB_hand_tracking_*`) | tamam | planlandı |
| Uzamsal çapalar (`XR_FB_spatial_entity`, depolama, paylaşım) | tamam | planlandı |
| Sahne düzlemleri (`XR_FB_scene`, `XR_FB_scene_capture`) | tamam | planlandı |
| Yüz izleme, göz bakışı (`XR_FB_face_tracking2`, `XR_FB_eye_tracking_social`) | tamam | planlandı |
| Yenileme hızı ve foveation (`XR_FB_display_refresh_rate`, `XR_FB_foveation`) | tamam (cihaz profiline göre) | planlandı |
| Editör ayarları, benzetim paneli, MCP araçları | tamam | — |

## Nereye oturur

```
Lumina Studio (lumina_ui) ── eklentileri lumina_editor_api ile yükler
        │
lumina_plugin_metaxr   Meta Quest uzantıları: bileşenler, veri, editör panelleri, MCP araçları
        │ bağımlı
lumina_plugin_openxr   OpenXR çalışma zamanı keşfi, yükleyici köprüsü, oturum, XR origin/HMD/kontrolcüler, stereo, benzetim
        │ bağımlı
lumina + flutter_filament   motor (aktörler, bileşenler) ve Filament çizicisi
```

Eklentinin manifesti bağımlılığı bildirir (`"dependencies": [{"name": "lumina_plugin_openxr", "version": ">=0.1.0"}]`)
ve Plugin Manager, MetaXR Support etkinleştirilirken bunu denetler. Temel eklentideki `LuminaXRHand` gibi türler
doğrudan kullanılır; oyun kodunda iki kütüphaneyi de içe aktarın.

## Özellikler

### Uzantı kataloğu

`MetaOpenXrExtensions`, eklentinin hedeflediği uzantı adlarını Meta OpenXR SDK'nın yazdığı biçimde tutar:

| Grup | Uzantılar |
|---|---|
| Passthrough | `XR_FB_passthrough`, `XR_FB_triangle_mesh` |
| Eller | `XR_FB_hand_tracking_mesh`, `XR_FB_hand_tracking_aim`, `XR_FB_hand_tracking_capsules` |
| Uzamsal | `XR_FB_spatial_entity`, `XR_FB_spatial_entity_storage`, `XR_FB_spatial_entity_sharing`, `XR_FB_scene`, `XR_FB_scene_capture` |
| Sosyal / gövde | `XR_FB_face_tracking2`, `XR_FB_eye_tracking_social`, `XR_FB_body_tracking` |
| Performans | `XR_FB_display_refresh_rate`, `XR_FB_foveation`, `XR_FB_swapchain_update_state` |

### Cihaz profilleri

`MetaQuestDeviceModel`: `quest2`, `questPro`, `quest3`, `quest3S`; her biri `displayName` ve eklentinin kullandığı
yetenek bayraklarıyla: `hasColorPassthrough` (passthrough'u tek renkli olan Quest 2 dışında hepsi), `hasEyeTracking`
ve `hasFaceTracking` (Quest Pro), `hasSceneMesh` (Quest 3 ve 3S) ve `supportedRefreshRates` (Quest Pro 72/90 Hz,
diğerleri 72/80/90/120 Hz).

### Passthrough

- `MetaPassthroughLayer`: `purpose` (tam kamera görüntüsü için `MetaPassthroughPurpose.reconstruction`, passthrough'u
  yalnızca pencere ya da portal gibi verilen bir geometride göstermek için `projectedSurface`), `placement`
  (sanal sahnenin arkasında `MetaPassthroughPlacement.underlay`, önünde `overlay`), `style` ve bir yaşam döngüsü
  (`start`, `pause`, `resume`, `destroy`; `state`, `isRunning`).
- `MetaPassthroughStyle` (değişmez, `copyWith`): `opacity`, `enableEdgeRendering`, `edgeColorRgba` (varsayılan
  `0x00FF88FF`), `edgeContrast`, `brightness`, `contrast`, `saturation`.
- `LuminaMetaPassthroughComponent` (`LuminaSceneComponent`): bir katmana sahiptir, etkinse başlatır;
  `setEnabled(bool)` başlatır ya da duraklatır, `setStyle(style)` stilini değiştirir.

### El izleme

- `MetaHandJoint`: `XR_EXT_hand_tracking`'in 26 eklemi, onun sırasıyla — avuç, bilek, ardından başparmak, işaret,
  orta, yüzük ve serçe parmak için metakarp, proksimal, (orta,) distal ve uç; `isTip`.
- `MetaHandPose`: el başına (`LuminaXRHand`) `isTracked`, `confidence`, `jointLocations`, `jointRotations`,
  `jointRadii`, `aimOrigin` / `aimDirection` ve bir `MetaPinchState`. `computePinchFromDistances()` her parmağın
  pinch gücünü ucunun başparmak ucuna uzaklığından çıkarır: 1,5 cm ve altında 1,0, 8 cm ve üstünde 0,0, arada
  doğrusal.
- `MetaPinchState`: `indexStrength`, `middleStrength`, `ringStrength`, `littleStrength` (0..1), `pinchThreshold`
  (varsayılan 0,70), `isIndexPinching` … `isLittlePinching`, `isAnyPinching`, `update(...)`.
- `LuminaMetaHandTrackingComponent` (`LuminaSceneComponent`): bir elin `currentPose`'u; `isTracked`,
  `isIndexPinching` ve `indexPinchStrength` kısayollarıyla.
- `MetaHandMeshGenerator.generateHandDebugGeometry(pose)`: hata ayıklarken izlenen elleri çizmek için her eklemde,
  yarıçapına göre boyutlanmış bir oktahedron (konumlar, normaller, indisler; eklem başına 6 köşe ve 8 üçgen).

### Uzamsal çapalar ve sahne

- `MetaSpatialAnchor`: `uuid`, `isLocalized`, `location`, `rotation`, `createdAt`; `updatePose(location, rotation)`
  onu konumlanmış olarak işaretler.
- `LuminaMetaSpatialAnchorComponent` (`LuminaSceneComponent`): sahibini bir çapaya sabitler; `bindAnchor(anchor)`,
  `applyAnchorPose()` çapa konumlandığında pozunu kopyalar.
- `MetaScenePlane`: sınıflandırılmış bir oda yüzeyi; `id`, `label`, `center`, `size` (cm cinsinden genişlik ×
  yükseklik), `normal`, `boundaryPolygon`, `areaSquareMeters`. `MetaSemanticLabel`: `floor`, `ceiling`, `wallFace`,
  `table`, `couch`, `doorFrame`, `windowFrame`, `other`.
- `LuminaMetaScenePlaneComponent` (`LuminaSceneComponent`): kendini düzlemin merkezine yerleştirir; `label`.

### Yüz ve göz izleme

- `MetaFaceExpressionWeights`: 63 ifade ağırlığı ve güveni (0..1), `isValid`, `getWeight` / `setWeight`
  (sınırlandırılmış, aralık dışı indisler yok sayılır). `MetaFaceBlendshapes` kaşlar, gözler, yanaklar, çene, ağız ve
  dudaklar için indisleri adlandırır (`browLowererL`, `eyesClosedL`, `jawDrop`, `mouthSmileL`, …; `count` = 63).
- `LuminaMetaFaceTrackingComponent` (`LuminaActorComponent`): `expressions`, `isEnabled` ve türetilmiş
  `smileIntensity` (iki gülümseme ağırlığının ortalaması) ile `jawOpen`.
- `MetaEyeTrackingData`: `isGazeValid`, `leftGazeDirection` / `rightGazeDirection`, mm cinsinden göz bebeği çapları,
  `combinedGazeDirection`.

### Performans

`MetaPerformanceController`: hedef `deviceModel` (varsayılan Quest 3), `requestRefreshRate(hz)` (yalnızca cihaz
profili listeliyorsa kabul edilir; destekleniyorsa varsayılan 90 Hz) ve `setFoveationLevel(level, dynamic:)`;
`MetaFoveationLevel` `none`, `low`, `medium` (varsayılan), `high`, `highTop`; dinamik foveation varsayılan olarak
açık.

## Gereksinimler ve platformlar

- `lumina_plugin_openxr`'ın gerektirdiği her şey (Dart `^3.12.0` ile Flutter, Lumina paketleri, temel eklentinin
  Native Assets kancası için bir C/C++ araç zinciri). Bu eklentinin kendi yerel kodu yoktur.
- Dart katmanı Lumina'nın çalıştığı her yerde çalışır (Windows, Linux, macOS, Android); başlık gerektirmez.
- Özelliklerin ileride bir cihazdan gelmesi için: Windows'ta Quest Link üzerinden ya da bağımsız bir Android
  derlemesiyle bir Meta Quest (Quest 2, Pro, 3 ya da 3S); başlıkta ilgili özellikler açık olmalı (el izleme,
  passthrough, sahne verisi için Space Setup ve Quest Pro'da yüz/göz izleme izinleri).
- Bir Quest Android derlemesi, VR başlatıcı kategorisini ve kullandığı özellikleri `AndroidManifest.xml`'de bildirir;
  örneğin:

  ```xml
  <uses-feature android:name="android.hardware.vr.headtracking" android:required="false" />
  <uses-feature android:name="com.oculus.feature.PASSTHROUGH" android:required="false" />
  <!-- başlatıcı activity'nin intent filter'ında -->
  <category android:name="com.oculus.intent.category.VR" />
  ```

  El izleme, sahne, çapa ve yüz/göz izleme özellikleri ve izinleri, çalışma zamanı yolu hazır olduğunda her uzantı
  için Meta'nın belgelerini izler.

## Kurulum

### Lumina Studio eklentisi olarak

1. Önce [`lumina_plugin_openxr`](https://github.com/LuminaGame/lumina_plugin_openxr)'ı kurun.
2. Bu depoyu klonlayın ve `<proje>/plugins/` klasörüne ya da kullanıcı eklenti klasörüne (Linux'ta
   `~/.local/share/lumina/plugins/`, Windows'ta `%LOCALAPPDATA%\Lumina\plugins`) bağlayın ya da kopyalayın veya
   **Plugins → Plugin Manager → Import from Folder** kullanın.
3. Plugin Manager'da **MetaXR Support**'u (kategori *Virtual Reality*) etkinleştirin ve editör isterse yeniden
   başlatın.

Lumina belgelerindeki [Editör eklentileri](https://github.com/LuminaGame/lumina/blob/main/docs/tr/plugins/index.md)
sayfasına bakın.

### Bir oyunun ya da başka bir eklentinin bağımlılığı olarak

```yaml
dependencies:
  lumina_plugin_openxr:
    git:
      url: https://github.com/LuminaGame/lumina_plugin_openxr.git
      ref: <commit sha>
  lumina_plugin_metaxr:
    git:
      url: https://github.com/LuminaGame/lumina_plugin_metaxr.git
      ref: <commit sha>
```

```dart
import 'package:lumina_plugin_metaxr/lumina_plugin_metaxr.dart';
import 'package:lumina_plugin_openxr/lumina_plugin_openxr.dart';
```

Yerel checkout'lara karşı geliştirmek için gitignore'lu bir `pubspec_overrides.yaml`, `lumina_plugin_openxr`'ı
`../openxr`'a ve Lumina paketlerini `../lumina/...`, `../tools/...`'a yönlendirebilir; paylaşılan Filament derlemesini
`filament` adıyla bağlayın.

## Hızlı başlangıç

```dart
import 'package:lumina_plugin_metaxr/lumina_plugin_metaxr.dart';
import 'package:lumina_plugin_openxr/lumina_plugin_openxr.dart';
import 'package:vector_math/vector_math_64.dart'; // aşağıdaki örneklerdeki Vector3, Quaternion

final origin = LuminaXROriginActor();

final passthrough = LuminaMetaPassthroughComponent(
  placement: MetaPassthroughPlacement.underlay,
  style: const MetaPassthroughStyle(enableEdgeRendering: true, edgeContrast: 1.2),
);
final leftHand = LuminaMetaHandTrackingComponent(hand: LuminaXRHand.left);
final rightHand = LuminaMetaHandTrackingComponent(hand: LuminaXRHand.right);

void setUpXr() {
  origin
    ..addComponent(passthrough)
    ..addComponent(leftHand)
    ..addComponent(rightHand);
  leftHand.attachToComponent(origin.rootComponent);
  rightHand.attachToComponent(origin.rootComponent);
}
```

## Kullanım

### Pinch ile tutmak

```dart
void onHandUpdate(LuminaMetaHandTrackingComponent hand, Vector3 indexTip, Vector3 thumbTip) {
  final pose = hand.currentPose
    ..isTracked = true
    ..jointLocations[MetaHandJoint.indexTip] = indexTip
    ..jointLocations[MetaHandJoint.thumbTip] = thumbTip;
  pose.computePinchFromDistances();

  if (hand.isIndexPinching) {
    // pose.jointLocations[MetaHandJoint.indexTip]'e en yakın nesneyi tut
  } else if (pose.pinch.isMiddlePinching) {
    // ikinci bir hareket, ör. tutulan nesneyi bir uzamsal çapaya sabitle
  }
}
```

### Bir aktörü uzamsal çapaya sabitlemek

```dart
final anchor = MetaSpatialAnchor(uuid: 'b4c1…')
  ..updatePose(Vector3(120, 40, 95), Quaternion.identity()); // konumlandı
final pin = LuminaMetaSpatialAnchorComponent()..bindAnchor(anchor);
someActor.addComponent(pin);
```

### Odaya tepki vermek

```dart
final table = MetaScenePlane(
  id: 'plane-1',
  label: MetaSemanticLabel.table,
  center: Vector3(80, 0, 74),
  size: Vector2(120, 60),
  normal: Vector3(0, 0, 1),
);
final surface = LuminaMetaScenePlaneComponent(plane: table);
print('${surface.label.displayName}: ${table.areaSquareMeters} m²');
```

### Yüz, ekran ve foveation

```dart
final face = LuminaMetaFaceTrackingComponent();
face.expressions.setWeight(MetaFaceBlendshapes.mouthSmileL, 0.8);
face.expressions.setWeight(MetaFaceBlendshapes.mouthSmileR, 0.6);
print(face.smileIntensity); // 0.7

final perf = MetaPerformanceController(deviceModel: MetaQuestDeviceModel.quest3);
perf.requestRefreshRate(120); // Quest 3'te true
perf.setFoveationLevel(MetaFoveationLevel.high, dynamic: true);
```

## Editör entegrasyonu

| Yer | Öğe | Ne yapar |
|---|---|---|
| **Plugins → MetaXR → MetaXR Settings** | panel | Hedef cihaz (Quest 2 / Pro / 3 / 3S) ve renkli passthrough ile yüz/göz izleme desteği, yenileme hızı (yalnızca cihazın desteklediği hızlar), foveation düzeyi ve dinamik foveation. |
| **Plugins → MetaXR → Simulation Panel** | panel | Sol ya da sağ elde benzetimli hareketler — **Tap Pinch** / **Release** ve canlı yüzde ile PINCHED / Open göstergesiyle işaret, orta, yüzük ve serçe parmak pinch'i — ve kontrastıyla passthrough kenar vurgusu. |
| **Plugins → MetaXR → Calibrate Anchors** | komut | Çapalar ve oda düzlemleri için bir yeniden kalibrasyon isteğini Output Log'a yazar (kaynak `MetaXR`). |
| **Plugins → MetaXR → About MetaXR Support** | panel | Sürüm ve özet. |
| MCP | `lumina_plugin_metaxr.get_capabilities` (salt okunur) | `device_model`, `color_passthrough`, `face_tracking`, `eye_tracking`, `scene_mesh`, `refresh_rate_hz`, `foveation_level`. |
| MCP | `lumina_plugin_metaxr.simulate_pinch` (editör durumu) | Girdiler `hand` (`left`/`right`), `finger` (`index`/`middle`/`ring`/`little`), `strength` (0..1); eklentinin benzetimli elinde o pinch'i ayarlar (diğer parmaklar değerlerini korur), Simulation panelini günceller ve `is_pinching` döner. |

Üç panel de bildirimseldir (`PluginViewSpec`): eklenti süreci onları tarif eder, editör kendi widget'larıyla çizer.
Paneller, MCP araçları ve eklentinin kanalı aynı tek benzetim durumunu okur ve değiştirir. OpenXR temel eklentisi
kendi menüsünü (**Plugins → OpenXR**) ve durum çubuğu düğmesini ekler.

## Kendi sürecinde çalışır

Eklenti yalıtılmıştır (`lumina_plugin_metaxr.lmplugin` içinde `"isolation": "process"`, `"process_class":
"MetaXrProcess"`): Lumina Studio kendi çalıştırılabilir dosyasını eklentinin süreci olarak yeniden başlatır ve onunla
yerel bir bağlantı üzerinden konuşur.

- **Eklenti sürecinde (`MetaXrProcess`)**: dört menü komutu, iki MCP aracı, çapa kalibrasyonu (vekil seviye erişimi
  üzerinden yazar), Settings / Simulation / About panelleri ve paylaştıkları benzetim durumu (cihaz, yenileme hızı,
  foveation, iki elin pinch'leri, passthrough stili). Ayrıca `getState` kanal yöntemini yanıtlar ve her değişiklikten
  sonra aynı JSON ile `stateChanged` olayı yayar.
- **Editörde**: eklentinin kodundan hiçbir şey. Eklenti widget kurmadığı için süreç içi bir parçası yoktur: editör
  modülü yalnızca bir `process_class` adlandırır (`registration_class` yok) ve editör panelleri sürecin gönderdiği
  tariflerden çizer.
- Süreç parçası OpenXR temel eklentisinden yalnızca `package:lumina_plugin_openxr/xr_types.dart`'ı (el
  tanımlayıcıları, `dart:ffi` yok) içe aktarır.
- **Süreç durduğunda** (çökme, kilitlenme ya da sonlandırma): editör çalışmaya devam eder, eklentinin menü öğelerini
  soluklaştırır, panellerinde durumu **Restart** ile gösterir, Plugin Manager'da durumu, çıkış kodunu ve log
  kuyruğunu listeler ve bir eklenti çökme raporu kaydeder. Yeniden başlayan süreç varsayılan benzetim durumundan
  başlar (Quest 3, 90 Hz, açık eller).
- **Editör sürecinde hata ayıklama**: `.lmproject` içinde proje geçersiz kılmasını ayarlayın:
  `"plugin_isolation": {"lumina_plugin_metaxr": "in_process"}`; aynı süreç parçası bu durumda editörün içinde bellek
  içi bir bağlantı üzerinden çalışır ve kesme noktaları ikinci bir sürece bağlanmadan çalışır.

## Gözlük olmadan çalışmak

Her tür sade Dart durumudur; bütün bir MR etkileşimi masaüstünde kurulup test edilebilir: el pozlarını ve pinch'leri
fareden, testlerden ya da bir MCP istemcisinden `simulate_pinch` ile sürün; istediğiniz pozlarla çapa ve sahne
düzlemleri oluşturun; hangi özellikleri ve yenileme hızlarını sunduğunu görmek için ayarlarda hedef cihazı
değiştirin. Baş ve kontrolcü pozlarını temel eklentinin benzetimli başlığı sağlar.

## Mimari

```
lib/
  lumina_plugin_metaxr.dart            genel kütüphane
  src/metaxr_info.dart                 MetaXrInfo: ad, görünen ad, sürüm
  src/process/       MetaXrProcess (menüler, MCP araçları, paneller), MetaXrState, MetaXrViews (panel tarifleri)
  src/meta_extensions.dart             MetaOpenXrExtensions
  src/meta_device.dart                 MetaQuestDeviceModel
  src/passthrough/   MetaPassthroughLayer, MetaPassthroughStyle, LuminaMetaPassthroughComponent
  src/hand/          MetaHandJoint, MetaHandPose, MetaPinchState, MetaHandMeshGenerator, LuminaMetaHandTrackingComponent
  src/spatial/       MetaSpatialAnchor, MetaScenePlane, LuminaMetaSpatialAnchorComponent, LuminaMetaScenePlaneComponent
  src/social/        MetaFaceBlendshapes, MetaFaceExpressionWeights, MetaEyeTrackingData, LuminaMetaFaceTrackingComponent
  src/performance/   MetaPerformanceController, MetaFoveationLevel
```

- **Katmanlar.** Eklenti `lumina_plugin_openxr` üzerinde saf Dart'tır. Temel eklentinin köprüsü OpenXR instance'ını
  ve oturumunu oluşturduğunda Meta uzantıları orada etkinleştirilecek ve sonuçları bu aynı türlere yazılacak;
  bileşenler ve oyun kodu değişmeyecek.
- **İş parçacıkları ve kare döngüsü.** Tüm durum eşzamanlıdır ve dünyayı çalıştıran isolate'e aittir. Oyun el
  pozlarını, çapaları ve düzlemleri kendi tick'inde günceller, pinch ve bakış sonuçlarını aynı karede okur.
- **Çizim.** Passthrough bir compositor katmanıdır: `underlay` ile sanal sahne, alfasının izin verdiği yerde kamera
  görüntüsünün üzerine çizilir; `overlay` ile kamera görüntüsü sahnenin üzerine çizilir. Hata ayıklama el geometrisi,
  herhangi bir Lumina/Filament mesh'i için sade üçgen verisidir.

## Koordinat sistemleri ve birimler

Lumina dünya birimi santimetredir ve saklanan dönüşümlerde Z yukarıdır. El eklem konumları ve pinch eşikleri
(1,5 cm / 8 cm), çapa pozları ve sahne düzlemi merkezleri ve boyutları Lumina santimetresindedir;
`areaSquareMeters` düzlemin alanını çevirir. Ham OpenXR pozlarını (metre, Y yukarı) bu türlere yazmadan önce temel
eklentinin `OpenXrSpaceConverter`'ı ile çevirin. Göz bakış yönleri birim vektörlerdir; göz bebeği çapları
milimetredir.

## Testler

```bash
flutter test test/meta_extensions_and_device_test.dart
flutter test test/meta_hand_tracking_test.dart
flutter test test/meta_passthrough_test.dart
flutter test test/meta_social_and_performance_test.dart
flutter test test/meta_spatial_test.dart
flutter test test/metaxr_process_test.dart
flutter test test/metaxr_editor_integration_test.dart
flutter analyze
```

Testler uzantı adlarını, cihaz yetenek bayraklarını, 26 eklemi, pinch algılamayı (parmak başına ve eklem
uzaklıklarından), hata ayıklama geometrisini, passthrough stilini ve katman yaşam döngüsünü, yüz ölçümlerini,
yenileme hızı ve foveation pazarlığını, çapaları ve sahne düzlemlerini ve eklenti sürecini kapsar:
`metaxr_process_test.dart`, `MetaXrProcess`'i gerçek bir loopback editöre (`LoopbackHost`) karşı
`runPluginProcessMain` altında çalıştırır ve katkıları, her menü komutunu, iki MCP aracını, panel olaylarını ve
güncellemelerini ve hatalı girdinin süreç hizmet vermeyi sürdürürken bir hata yanıtı döndürdüğünü denetler;
`metaxr_editor_integration_test.dart` manifesti (süreç yalıtımı, kayıt sınıfı yok) ve eklenti kanalının sürece
ulaştığını denetler.
Başlık ya da GPU gerekmez.

## Sorun giderme

- **Eklenti görünmüyor ya da etkinleşmiyor.** Önce OpenXR Support'u kurup etkinleştirin; manifest
  `lumina_plugin_openxr` 0.1.0 ya da sonrasını ister.
- **Bir yenileme hızı reddediliyor.** `requestRefreshRate` yalnızca seçili cihaz profilinin hızlarını kabul eder
  (Quest Pro'da 80 ve 120 Hz yok).
- **Yüz ya da göz değerleri sıfırda kalıyor.** Bugün bunları sizin kodunuz ya da bir benzetim yazar; donanımda yüz/göz
  izlemesine izin verilmiş bir Quest Pro gerekecek.
- **Pinch hiç tetiklenmiyor.** Güç `pinchThreshold`'a (0,70) ulaşmalı; `computePinchFromDistances` ile başparmak ve
  parmak uçları santimetre cinsinden yaklaşık 3,5 cm içinde olmalı.

## Sınırlamalar ve yol haritası

- Henüz `XR_FB_*` çağrısı yok; tüm veriyi uygulama, benzetim paneli ya da MCP ayarlar (bkz. [Durum](#durum)).
- 63 yüz ağırlığının kaşlar, gözler, yanaklar, çene, ağız ve dudaklar için adlandırılmış indisleri var; sıraları
  eklentinin kendi sırasıdır ve yerel yüz verisi geldiğinde çalışma zamanının ifade sırasına eşlenecek
  (`XR_FB_face_tracking2` 70 ifade bildirir).
- `XR_FB_body_tracking`, `XR_FB_hand_tracking_capsules` ve `XR_FB_triangle_mesh` katalogda var ama henüz bileşenleri
  yok.
- **Calibrate Anchors** yalnızca isteği kaydeder; benzetim paneli yalnızca sağ eli sürer.
- `MetaHandPose.aimDirection` temel eklentinin ileri eksenini izleyerek varsayılan olarak +X'tir.

Sıradakiler, temel eklenti instance ve oturum oluşturmayı kazandıkça: cihazın bildirdiği uzantıları etkinleştirmek,
kareyle birlikte gönderilen passthrough katmanları, `xrLocateHandJointsEXT`'ten el eklemleri ve aim, uzamsal varlık
uzantılarıyla oluşturulan, kaydedilen ve paylaşılan çapalar, Space Setup'tan sahne düzlemleri, Quest Pro'da yüz ve göz
verisi ve cihazda uygulanan yenileme hızı ve foveation.

## Katkı

Issue ve pull request'ler memnuniyetle karşılanır. `flutter analyze`'ı temiz tutun, yeni davranış için birim testleri
ekleyin, iki README'yi (İngilizce ve Türkçe) birlikte güncel tutun ve arayüz için `shadcn_flutter` widget'larını
kullanın.

## Lisans

MIT — bkz. [LICENSE](LICENSE).

Bu depo üçüncü taraf kaynak kodu ya da ikili dosya içermez; Meta OpenXR SDK'yı ya da Khronos OpenXR SDK'yı
barındırmaz. Uzantı adları yalnızca tanımlayıcı olarak kullanılır. Meta Quest, Meta Platforms, Inc.'in ticari
markasıdır; OpenXR™, The Khronos Group Inc.'in ticari markasıdır.
