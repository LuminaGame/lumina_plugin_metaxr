# Lumina Studio için MetaXR Eklentisi (`lumina_plugin_metaxr`)

Lumina oyun motoru ve Lumina Studio için Meta Quest OpenXR SDK uzantı eklentisi. Meta'ya özgü OpenXR uzantılarını (`XR_FB_*` ve `XR_META_*`) sunmak için doğrudan `lumina_plugin_openxr` üzerine inşa edilmiştir.

## Özellikler

- **Karma Gerçeklik Passthrough**: Tam renkli passthrough arka plan (underlay) ve ön plan (overlay) katmanları (`XR_FB_passthrough`), kenar çizgisi vurgulama ve renk ayarları (`LuminaMetaPassthroughComponent`).
- **26 Eklemli El Takibi**: 26 eklemli tam el iskeleti takibi (`XR_FB_hand_tracking_mesh`, `XR_FB_hand_tracking_aim`), parmak ucu kıstırma (pinch) şiddeti algılama ve prosedürel el ağı oluşturucu (`LuminaMetaHandTrackingComponent`).
- **Uzamsal Çapalar (Spatial Anchors)**: Herhangi bir Lumina aktörünü fiziksel dünyadaki kalıcı uzamsal çapalara sabitleme (`XR_FB_spatial_entity`) (`LuminaMetaSpatialAnchorComponent`).
- **Oda Sahne Algılama (Scene Perception)**: Semantik oda yüzeyi sınıflandırması (`XR_FB_scene`: Zemin, Tavan, Duvar, Masa, Kanepe, Pencere, Kapı) ve sınır düzlemleri (`LuminaMetaScenePlaneComponent`).
- **Yüz ve Göz Takibi**: MetaHuman ve karakter iskelet ağlarındaki morfları yönlendiren 63 Meta ifade ağırlığı (`XR_FB_face_tracking2`) ve sosyal bakış takibi (`XR_FB_eye_tracking_social`).
- **Quest Performansı ve Ekran**: Ekran yenileme hızı değiştirme (72Hz, 80Hz, 90Hz, 120Hz) ve foveated render seviyeleri (`MetaPerformanceController`).
- **Editör ve Simülasyon Araçları**: MetaXR ayarları formu, başlık olmadan masaüstünde el hareketlerini ve passthrough görünümünü test etmeye yarayan simülatör paneli ve yapay zeka araçları (`metaxr.get_capabilities`, `metaxr.simulate_pinch`).

## Kurulum

Projenizin `pubspec.yaml` dosyasına ekleyin veya **Plugins → Plugin Manager** üzerinden etkinleştirin:

```yaml
dependencies:
  lumina_plugin_openxr:
    path: ../openxr
  lumina_plugin_metaxr:
    path: ../metaxr
```

## Mimari

- `lib/src/meta_extensions.dart`: Meta OpenXR uzantı dizgileri kataloğu.
- `lib/src/meta_device.dart`: Donanım profilleri (Quest 2, Quest Pro, Quest 3, Quest 3S).
- `lib/src/passthrough/`: Passthrough stilleri, katmanları ve `LuminaMetaPassthroughComponent`.
- `lib/src/hand/`: 26 eklemli hiyerarşi, pinch algılayıcı, ağ üreteci ve `LuminaMetaHandTrackingComponent`.
- `lib/src/spatial/`: Uzamsal çapalar, semantik oda düzlemleri ve bileşenleri.
- `lib/src/social/`: 63 ifade morfu, bakış takibi ve `LuminaMetaFaceTrackingComponent`.
- `lib/src/performance/`: Ekran yenileme hızları ve foveated render denetleyicisi.
- `lib/src/ui/`: shadcn_flutter ayarlar ve simülasyon panelleri.

## Lisans

MIT Lisansı. Bkz: [LICENSE](file:///d:/lumina/metaxr/LICENSE).
