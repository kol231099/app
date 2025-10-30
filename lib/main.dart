// === main.dart (完整貼上) ===
import 'dart:convert';
import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gm;
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart'
    as gmfpi;
import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';
import 'package:http/http.dart' as http;

// === 語言翻譯類（新增）===
class AppTranslations {
  static const Map<String, Map<String, String>> _translations = {
    'zh': {
      'app_title': '附近清真地點',
      'search_hint': '搜尋什麼都可以',
      'view_more': '查看更多',
      'nearby_top5': '附近 TOP 5',
      'search_results': '搜尋結果 TOP 5',
      'show_on_map': '在地圖中顯示',
      'my_location': '我的位置',
      'driving': '開車',
      'transit': '大眾運輸',
      'walking': '步行',
      'route_title': '到餐廳的方式',
      'language': '語言',
      'clear': '清除',
      'send': '送出',
      'chat_with_gpt': '和 ChatGPT 聊天',
      'input_message': '輸入訊息…',
      'map_search': '地圖搜尋',
      'chat': '聊天',
      'minimize': '縮小',
      'expand': '展開',
      'clear_route': '清除路線',
      'getting_nearby': '正在取得附近店家…',
      'need_restaurant': '您需要尋找什麼樣的餐廳？',
      'filter_halal': '清真',
      'filter_vegetarian': '素食',
      'filter_gender_friendly': '性別友善',
      'filter_family_friendly': '親子友善',
      'scenic': '景點',
      'chat_local_found_with_distance': '我在本地資料找到這些餐廳（依距離由近到遠）：',
      'chat_local_found_plain': '我在本地資料找到這些餐廳：',
      'chat_comment_sorted_by_distance': '（以下依你目前距離由近到遠）',
      'chat_recommend_list': '推薦清單：',
      'chat_no_results': '暫時找不到符合的結果。',
      'chat_server_error': '伺服器錯誤',
    },
    'en': {
      'app_title': 'Nearby Halal Places',
      'search_hint': 'Search anything',
      'view_more': 'View More',
      'nearby_top5': 'Nearby TOP 5',
      'search_results': 'Search Results TOP 5',
      'show_on_map': 'Show on Map',
      'my_location': 'My Location',
      'driving': 'Driving',
      'transit': 'Transit',
      'walking': 'Walking',
      'route_title': 'Ways to Restaurant',
      'language': 'Language',
      'clear': 'Clear',
      'send': 'Send',
      'chat_with_gpt': 'Chat with ChatGPT',
      'input_message': 'Type a message…',
      'map_search': 'Map Search',
      'chat': 'Chat',
      'minimize': 'Minimize',
      'expand': 'Expand',
      'clear_route': 'Clear Route',
      'getting_nearby': 'Getting nearby places…',
      'need_restaurant': 'What kind of restaurant are you looking for?',
      'filter_halal': 'Halal',
      'filter_vegetarian': 'Vegetarian',
      'filter_gender_friendly': 'Gender Friendly',
      'filter_family_friendly': 'Family Friendly',
      'scenic': 'Scenic',
      'chat_local_found_with_distance':
          'I found these nearby places (sorted by distance):',
      'chat_local_found_plain': 'I found these places from the local database:',
      'chat_comment_sorted_by_distance': '(Sorted by your current distance)',
      'chat_recommend_list': 'Recommended list:',
      'chat_no_results': 'No matching results right now.',
      'chat_server_error': 'Server error',
    },
    'id': {
      'app_title': 'Tempat Halal Terdekat',
      'search_hint': 'Cari apa saja',
      'view_more': 'Lihat Lebih',
      'nearby_top5': 'Terdekat TOP 5',
      'search_results': 'Hasil Pencarian TOP 5',
      'show_on_map': 'Tampilkan di Peta',
      'my_location': 'Lokasi Saya',
      'driving': 'Mengemudi',
      'transit': 'Transit',
      'walking': 'Jalan Kaki',
      'route_title': 'Cara ke Restoran',
      'language': 'Bahasa',
      'clear': 'Hapus',
      'send': 'Kirim',
      'chat_with_gpt': 'Obrolan dengan ChatGPT',
      'input_message': 'Ketik pesan…',
      'map_search': 'Pencarian Peta',
      'chat': 'Obrolan',
      'minimize': 'Perkecil',
      'expand': 'Perluas',
      'clear_route': 'Hapus Rute',
      'getting_nearby': 'Mendapatkan tempat terdekat…',
      'need_restaurant': 'Restoran seperti apa yang Anda cari?',
      'filter_halal': 'Halal',
      'filter_vegetarian': 'Vegetarian',
      'filter_gender_friendly': 'Ramah Gender',
      'filter_family_friendly': 'Ramah Keluarga',
      'scenic': 'Tempat Wisata',
      'chat_local_found_with_distance':
          'Saya menemukan tempat terdekat (urut berdasarkan jarak):',
      'chat_local_found_plain': 'Saya menemukan tempat dari basis data lokal:',
      'chat_comment_sorted_by_distance':
          '(Diurutkan berdasarkan jarak Anda saat ini)',
      'chat_recommend_list': 'Daftar rekomendasi:',
      'chat_no_results': 'Belum ada hasil yang cocok.',
      'chat_server_error': 'Kesalahan server',
    },
  };

  static String currentLang = 'zh';

  static String get(String key) {
    return _translations[currentLang]?[key] ?? key;
  }
}
/// ===== 新增 1：可位移的 FAB 位置類別（只加一次即可）=====
class OffsetFabLocation extends FloatingActionButtonLocation {
  final FloatingActionButtonLocation base;
  final Offset offset;
  const OffsetFabLocation(this.base, this.offset);

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry geometry) {
    final baseOffset = base.getOffset(geometry);
    return Offset(baseOffset.dx + offset.dx, baseOffset.dy + offset.dy);
  }
}

/// === Chat -> Map 的輕量資料 ===
class ShowPlace {
  final String name;
  final String address;
  final String tel;
  final String tag;
  final String nameEn;
  final String nameId;
  final String addressEn;
  final String addressId;
  final String tagEn;
  final String tagId;
  final double lat, lon;
  ShowPlace({
    required this.name,
    required this.address,
    required this.tel,
    required this.tag,
    required this.lat,
    required this.lon,
    this.nameEn = '',
    this.nameId = '',
    this.addressEn = '',
    this.addressId = '',
    this.tagEn = '',
    this.tagId = '',
  });
}

/// === 地圖控制器：讓別的頁面可以把清單丟給 Map 畫 ===
class MapScreenController {
  _MapScreenState? _state;
  void _attach(_MapScreenState s) => _state = s;

  void showPlaces(List<ShowPlace> places, {String? comment}) {
    _state?._showPlacesFromChat(places, comment: comment);
  }
}

///預熱
class AppWarmUp {
  static List<_Place>? cachedPlaces;

  static Future<void> warmUp() async {
    if (cachedPlaces != null) return;
    final csvStr =
        await rootBundle.loadString('assets/cleaned_restaurants.csv');
    final rows = const CsvToListConverter(
            eol: '\n', shouldParseNumbers: false)
        .convert(csvStr);
    final header = rows.first.map((e) => e.toString().trim()).toList();
    final nameIdx = header.indexOf('Name');
    final addrIdx = header.indexOf('Address');
    final telIdx = header.indexOf('Tel');
    final latIdx = header.indexOf('lat');
    final lonIdx = header.indexOf('lon');
    final tagIdx = header.indexOf('tag');
    final nameEnIdx = header.indexOf('Name_en');
    final addrEnIdx = header.indexOf('Address_en');
    final tagEnIdx = header.indexOf('Tag_en');
    final nameIdIdx = header.indexOf('Name_id');
    final addrIdIdx = header.indexOf('Address_id');
    final tagIdIdx = header.indexOf('Tag_id');

    final list = <_Place>[];
    for (int i = 1; i < rows.length; i++) {
      final r = rows[i];
      if (r.length <= lonIdx) continue;
      final lat = double.tryParse(r[latIdx].toString());
      final lon = double.tryParse(r[lonIdx].toString());
      if (lat == null || lon == null) continue;
      list.add(_Place(
        name: (r[nameIdx] ?? '').toString().trim(),
        address: (r[addrIdx] ?? '').toString().trim(),
        tel: (r[telIdx] ?? '').toString().trim(),
        tag: (r[tagIdx] ?? '').toString().trim(),
        nameEn: nameEnIdx >= 0 ? (r[nameEnIdx] ?? '').toString().trim() : '',
        addressEn: addrEnIdx >= 0 ? (r[addrEnIdx] ?? '').toString().trim() : '',
        tagEn: tagEnIdx >= 0 ? (r[tagEnIdx] ?? '').toString().trim() : '',
        nameId: nameIdIdx >= 0 ? (r[nameIdIdx] ?? '').toString().trim() : '',
        addressId: addrIdIdx >= 0 ? (r[addrIdIdx] ?? '').toString().trim() : '',
        tagId: tagIdIdx >= 0 ? (r[tagIdIdx] ?? '').toString().trim() : '',
        latLng: gm.LatLng(lat, lon),
        distanceMeters: 0,
      ));
    }
    cachedPlaces = list;
  }
}

const String kSearchEndpoint = 'http://157.245.146.82/search';
const String kSearchCosEndpoint = 'http://157.245.146.82/search_cos';

class Place {
  final String name;
  final String address;
  final String tel;
  final String tag;
  final double? lat;
  final double? lon;
  final double? score;
  Place({
    required this.name,
    required this.address,
    required this.tel,
    required this.tag,
    required this.lat,
    required this.lon,
    required this.score,
  });
  factory Place.fromJson(Map<String, dynamic> j) {
    double? toD(v) => (v == null) ? null : (v as num).toDouble();
    return Place(
      name: (j['Name'] ?? j['name'] ?? '').toString(),
      address: (j['Address'] ?? j['address'] ?? '').toString(),
      tel: (j['Tel'] ?? j['tel'] ?? '').toString(),
      tag: (j['tag'] ?? j['Tag'] ?? '').toString(),
      lat: toD(j['lat'] ?? j['latitude']),
      lon: toD(j['lon'] ?? j['longitude']),
      score: toD(j['score']),
    );
  }
}

const String kOpenAIKey = String.fromEnvironment('OPENAI_API_KEY');
const String kGoogleMapsKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY');

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LottieEarthPage(),
    );
  }
}

class LottieEarthPage extends StatefulWidget {
  const LottieEarthPage({super.key});

  @override
  State<LottieEarthPage> createState() => _LottieEarthPageState();
}

class _LottieEarthPageState extends State<LottieEarthPage>
    with TickerProviderStateMixin {
  late final AnimationController _lottieCtrl;
  late final AnimationController _zoomCtrl;
  late final Animation<double> _zoomAnim;
  late final Animation<double> _fadeAnim;
  bool _showButton = false;
  bool _lockedToAsia = false;

  bool _zoomScheduled = false;

  @override
  void initState() {
    super.initState();
    _lottieCtrl = AnimationController(vsync: this);
    _zoomCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _zoomAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.25)
            .chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.25, end: 5.0)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 65,
      ),
    ]).animate(_zoomCtrl);

    _fadeAnim = CurvedAnimation(
      parent: _zoomCtrl,
      curve: const Interval(0.48, 1.0, curve: Curves.easeOut),
    );

    AppWarmUp.warmUp();
  }

  @override
  void dispose() {
    _lottieCtrl.dispose();
    _zoomCtrl.dispose();
    super.dispose();
  }

  void _scheduleZoomOnce(Duration delay) {
    if (_zoomScheduled) return;
    _zoomScheduled = true;
    Future.delayed(delay, () {
      if (!mounted) return;
      if (_zoomCtrl.status == AnimationStatus.dismissed ||
          _zoomCtrl.status == AnimationStatus.reverse) {
        _zoomCtrl.forward();
      }
    });
  }

  Future<void> _spinToWithLead(
    double target, {
    Duration total = const Duration(milliseconds: 1900),
    double leadFraction = 0.20,
  }) async {
    final v = _lottieCtrl.value;
    double delta = target - v;
    if (delta < 0) delta += 1.0;

    final totalMs = total.inMilliseconds;

    if (target >= v) {
      final d = Duration(milliseconds: (totalMs * delta).round());
      final cut = (d.inMilliseconds * 0.85).round();
      final d1 = Duration(milliseconds: cut);
      final d2 = Duration(milliseconds: d.inMilliseconds - cut);

      _scheduleZoomOnce(Duration(
          milliseconds: (d.inMilliseconds * (1 - leadFraction)).round()));

      await _lottieCtrl.animateTo(v + (target - v) * 0.85,
          duration: d1, curve: Curves.linear);
      await _lottieCtrl.animateTo(target,
          duration: d2, curve: Curves.easeOutCubic);
    } else {
      final ratioA = (1.0 - v) / delta;
      final ratioB = target / delta;
      final dA = Duration(milliseconds: (totalMs * ratioA).round());
      final dB = Duration(milliseconds: (totalMs * ratioB).round());

      await _lottieCtrl.animateTo(1.0, duration: dA, curve: Curves.linear);
      _lottieCtrl.value = 0.001;

      final cutB = (dB.inMilliseconds * 0.85).round();
      final dB1 = Duration(milliseconds: cutB);
      final dB2 = Duration(milliseconds: dB.inMilliseconds - cutB);

      _scheduleZoomOnce(Duration(
          milliseconds: dA.inMilliseconds +
              (dB.inMilliseconds * (1 - leadFraction)).round()));

      final mid = target * 0.85;
      await _lottieCtrl.animateTo(mid,
          duration: dB1, curve: Curves.linear);
      await _lottieCtrl.animateTo(target,
          duration: dB2, curve: Curves.easeOutCubic);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 650,
              height: 650,
              child: FadeTransition(
                opacity: ReverseAnimation(_fadeAnim),
                child: ScaleTransition(
                  scale: _zoomAnim,
                  child: Lottie.asset(
                    'assets/Globe.json',
                    controller: _lottieCtrl,
                    onLoaded: (comp) {
                      _lottieCtrl
                        ..duration = comp.duration
                        ..repeat();
                      if (!_showButton) setState(() => _showButton = true);
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            if (_showButton)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 14),
                ),
                onPressed: () async {
                  if (_lockedToAsia) return;
                  setState(() => _lockedToAsia = true);

                  _zoomScheduled = false;
                  await _spinToWithLead(
                    0.10,
                    total: const Duration(milliseconds: 1600),
                    leadFraction: 0.22,
                  );

                  _zoomCtrl.forward();

                  Future.delayed(const Duration(milliseconds: 1250), () async {
                    if (!mounted) return;
                    await Navigator.of(context).push(
                      _SharedAxisFadeZoomRoute(child: const HomeTabs()),
                    );
                    if (!mounted) return;
                    _zoomCtrl.reset();
                    setState(() => _lockedToAsia = false);
                    _lottieCtrl.repeat();
                  });
                },
                child: const Text(
                  'START',
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SharedAxisFadeZoomRoute<T> extends PageRouteBuilder<T> {
  _SharedAxisFadeZoomRoute({required Widget child})
      : super(
          transitionDuration: const Duration(milliseconds: 600),
          reverseTransitionDuration:
              const Duration(milliseconds: 420),
          pageBuilder: (_, __, ___) => child,
          transitionsBuilder:
              (context, animation, secondary, child) {
            final fade = CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOutCubicEmphasized,
            );
            final scale =
                Tween<double>(begin: 0.985, end: 1.0).animate(fade);
            return FadeTransition(
              opacity: fade,
              child: ScaleTransition(scale: scale, child: child),
            );
          },
        );
}

class HomeTabs extends StatefulWidget {
  const HomeTabs({super.key});

  @override
  State<HomeTabs> createState() => _HomeTabsState();
}

class _HomeTabsState extends State<HomeTabs> {
  int _index = 0;

  final MapScreenController _mapCtrl = MapScreenController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          MapScreen(controller: _mapCtrl),
          ChatGPTPage(
            onShowOnMap:
                (List<ShowPlace> places, {String? comment}) {
              setState(() => _index = 0);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _mapCtrl.showPlaces(places, comment: comment);
              });
            },
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.map_outlined),
            selectedIcon: const Icon(Icons.map),
            label: AppTranslations.get('map_search'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.chat_bubble_outline),
            selectedIcon: const Icon(Icons.chat_bubble),
            label: AppTranslations.get('chat'),
          ),
        ],
      ),
    );
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key, required this.controller});
  final MapScreenController controller;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _RouteOption {
  final String mode;
  final String distanceText;
  final String durationText;
  final List<gm.LatLng> path;
  final List<gm.LatLng> primaryPath;
  final bool isPartial;
  final String polylineId;
  _RouteOption({
    required this.mode,
    required this.distanceText,
    required this.durationText,
    required this.path,
    required this.primaryPath,
    required this.isPartial,
    required this.polylineId,
  });

  String get modeLabel {
    switch (mode) {
      case 'driving':
        return AppTranslations.get('driving');
      case 'transit':
        return AppTranslations.get('transit');
      case 'walking':
        return AppTranslations.get('walking');
      default:
        return mode;
    }
  }

  IconData get modeIcon {
    switch (mode) {
      case 'driving':
        return Icons.directions_car_filled;
      case 'transit':
        return Icons.directions_transit_filled;
      case 'walking':
        return Icons.directions_walk;
      default:
        return Icons.alt_route;
    }
  }
}

class _MapScreenState extends State<MapScreen> {
  Future<void> _fitBoundsToPolyline(List<gm.LatLng> pts) async {
    if (_mapCtrl == null || pts.isEmpty) return;
    double minLat = pts.first.latitude, maxLat = minLat;
    double minLng = pts.first.longitude, maxLng = minLng;
    for (final p in pts) {
      if (p.latitude  < minLat) minLat = p.latitude;
      if (p.latitude  > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    final bounds = gm.LatLngBounds(
      southwest: gm.LatLng(minLat, minLng),
      northeast: gm.LatLng(maxLat, maxLng),
    );
    await _mapCtrl!.animateCamera(gm.CameraUpdate.newLatLngBounds(bounds, 60));
  }

  gm.GoogleMapController? _mapCtrl;
  gm.LatLng? _myLatLng;

  bool _collapsed = true;

  final Size _chipSize = const Size(160, 48);
  Offset _chipOffset = const Offset(12, 140);

  final List<_Place> _allPlaces = [];
  List<_Place> _top5 = [];
  final Set<gm.Marker> _markers = <gm.Marker>{};

  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  List<_Place> _visiblePlaces = [];

  static const List<String> _quickFilterKeys = [
    'filter_halal',
    'filter_vegetarian',
    'filter_gender_friendly',
    'filter_family_friendly',
  ];
  String? _selectedQuickFilterKey;

  _Place? _activeRoutePlace;
  bool _scenicEnabled = false;
  bool _loadingScenic = false;
  final List<_ScenicPlace> _scenicPlaces = [];
  final Map<String, List<_ScenicPlace>> _scenicCache = {};
  final Set<gm.Marker> _scenicMarkers = <gm.Marker>{};
  final Map<String, gm.BitmapDescriptor> _scenicIconCache = {};
  final Map<String, gm.BitmapDescriptor> _scenicLabelIconCache = {};
  final Set<gm.Polyline> _scenicOverlayPolylines = <gm.Polyline>{};
  gm.BitmapDescriptor? _selectionRingIcon;
  String? _focusedScenicId;

  String? _llmComment;
  bool _searching = false;

  Timer? _debounce;

  bool _didZoomToMyLoc = false;

  static const gm.LatLng _twCenter = gm.LatLng(23.7, 120.9);

  final Set<gm.Polyline> _polylines = <gm.Polyline>{};
  final Set<gm.Circle> _walkDots = <gm.Circle>{};
  List<_RouteOption> _routeOptions = [];
  String? _selectedRouteId;
  bool _routePanelMinimized = false;

  @override
  void initState() {
    super.initState();
    widget.controller._attach(this);
    _initLocation();
    _prepareSelectionRingIcon();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _initLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) _snack('請開啟定位服務（設定→定位服務）');
      return;
    }
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      if (mounted) _snack('未授權定位，請到設定開啟權限');
      return;
    }

    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.best,
    );
    _myLatLng = gm.LatLng(pos.latitude, pos.longitude);
    if (mounted) setState(() {});

    await _loadPlacesFromCsv();
    await _rankAndMark();

    _flyTaiwanThenMyLoc();
  }

  Future<void> _loadPlacesFromCsv() async {
    _allPlaces
      ..clear()
      ..addAll(AppWarmUp.cachedPlaces ?? []);
  }

  Future<void> _rankAndMark() async {
    if (_myLatLng == null || _allPlaces.isEmpty) return;

    await Future.delayed(const Duration(milliseconds: 1));

    for (final p in _allPlaces) {
      p.distanceMeters = Geolocator.distanceBetween(
        _myLatLng!.latitude,
        _myLatLng!.longitude,
        p.latLng.latitude,
        p.latLng.longitude,
      );
    }

    _allPlaces.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
    _visiblePlaces = List<_Place>.from(_allPlaces);

    _top5 = _visiblePlaces.take(5).toList();

    _rebuildMarkersFrom(_visiblePlaces);

    if (mounted) setState(() {});
  }

  void _rebuildMarkersFrom(List<_Place> list) {
    final markers = <gm.Marker>{};
    final ringIcon = _selectionRingIcon;

    for (final e in list) {
      final markerId = gm.MarkerId(
          '${e.name}-${e.latLng.latitude}-${e.latLng.longitude}');
      markers.add(gm.Marker(
        markerId: markerId,
        position: e.latLng,
        infoWindow: gm.InfoWindow(
          title: e.name,
          snippet: e.address,
          onTap: () => _onPlaceTappedForRoutes(e),
        ),
        onTap: () => _onPlaceTappedForRoutes(e),
      ));

      if (ringIcon != null && _activeRoutePlace != null &&
          _isSamePlace(e, _activeRoutePlace!)) {
        markers.add(gm.Marker(
          markerId: gm.MarkerId('ring-${markerId.value}'),
          position: e.latLng,
          icon: ringIcon,
          anchor: const Offset(0.5, 1.0),
          consumeTapEvents: false,
          zIndex: 1.2,
        ));
      }
    }

    if (_scenicEnabled && _scenicMarkers.isNotEmpty) {
      markers.addAll(_scenicMarkers);
    }

    _markers
      ..clear()
      ..addAll(markers);
  }

  bool _isSamePlace(_Place a, _Place b) {
    return (a.latLng.latitude - b.latLng.latitude).abs() < 1e-6 &&
        (a.latLng.longitude - b.latLng.longitude).abs() < 1e-6;
  }

  Future<void> _zoomToPlace(gm.LatLng target, {double zoom = 17.2}) async {
    if (_mapCtrl == null) return;
    await _mapCtrl!
        .animateCamera(gm.CameraUpdate.newLatLngZoom(target, zoom));
  }

  Future<void> _centerOn(gm.LatLng target, {double zoom = 18}) async {
    if (_mapCtrl == null) return;
    final cam =
        gm.CameraPosition(target: target, zoom: zoom, tilt: 0, bearing: 0);
    await _mapCtrl!.animateCamera(
        gm.CameraUpdate.newCameraPosition(cam));
  }

  gm.LatLng _lerpLatLng(gm.LatLng a, gm.LatLng b, double t) {
    return gm.LatLng(
      a.latitude + (b.latitude - a.latitude) * t,
      a.longitude + (b.longitude - a.longitude) * t,
    );
  }

  double _easeInOut(double t) {
    t = t.clamp(0.0, 1.0);
    final t3 = t * t * t, t4 = t3 * t, t5 = t4 * t;
    return 6 * t5 - 15 * t4 + 10 * t3;
  }

  Future<void> _flyTaiwanThenMyLoc() async {
    if (_didZoomToMyLoc) return;
    if (_mapCtrl == null || _myLatLng == null) return;
    _didZoomToMyLoc = true;

    await _mapCtrl!.animateCamera(
      gm.CameraUpdate.newCameraPosition(
        const gm.CameraPosition(
            target: _twCenter, zoom: 5.6, tilt: 0, bearing: 0),
      ),
    );
    await Future.delayed(const Duration(milliseconds: 700));

    final ts = <double>[
      0.08, 0.16, 0.24, 0.32, 0.40, 0.50, 0.60, 0.72, 0.84, 0.92, 1.00
    ];
    final zooms = <double>[
      6.8, 7.8, 8.8, 9.8, 10.8, 11.8, 12.6, 13.6, 14.6, 15.6, 16.6
    ];
    const pauses = <int>[60, 60, 65, 70, 70, 75, 80, 85, 90, 90, 0];

    for (var i = 0; i < ts.length; i++) {
      final t = _easeInOut(ts[i]).clamp(0.0, 1.0);
      final mid = _lerpLatLng(_twCenter, _myLatLng!, t);

      if (i >= ts.length - 2) {
        final tilt = (i == ts.length - 2) ? 20.0 : 24.0;
        await _mapCtrl!.animateCamera(
          gm.CameraUpdate.newCameraPosition(
            gm.CameraPosition(
                target: mid, zoom: zooms[i], tilt: tilt, bearing: 0),
          ),
        );
      } else {
        await _mapCtrl!
            .animateCamera(gm.CameraUpdate.newLatLngZoom(mid, zooms[i]));
      }

      if (pauses[i] > 0) {
        await Future.delayed(Duration(milliseconds: pauses[i]));
      }
    }

    await _mapCtrl!.animateCamera(
      gm.CameraUpdate.newCameraPosition(
        gm.CameraPosition(
          target: _lerpLatLng(
              _twCenter, _myLatLng!, _easeInOut(1.02).clamp(0.0, 1.0)),
          zoom: 17.2,
          tilt: 28,
          bearing: 0,
        ),
      ),
    );
    await Future.delayed(const Duration(milliseconds: 120));
    await _centerOn(_myLatLng!, zoom: 18);
  }

  Future<void> _fitBoundsTo(List<_Place> list) async {
    if (_mapCtrl == null || list.isEmpty) return;
    double minLat = list.first.latLng.latitude, maxLat = minLat;
    double minLng = list.first.latLng.longitude, maxLng = minLng;
    for (final p in list) {
      if (p.latLng.latitude < minLat) minLat = p.latLng.latitude;
      if (p.latLng.latitude > maxLat) maxLat = p.latLng.latitude;
      if (p.latLng.longitude < minLng) minLng = p.latLng.longitude;
      if (p.latLng.longitude > maxLng) maxLng = p.latLng.longitude;
    }
    final bounds = gm.LatLngBounds(
      southwest: gm.LatLng(minLat, minLng),
      northeast: gm.LatLng(maxLat, maxLng),
    );
    await _mapCtrl!.animateCamera(
        gm.CameraUpdate.newLatLngBounds(bounds, 70));
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  void _dragChip(Offset delta, BuildContext context) {
    final size = MediaQuery.of(context).size;
    final minX = 8.0;
    final maxX = size.width - _chipSize.width - 8.0;
    final minY = kToolbarHeight + 8.0;
    final maxY = size.height - _chipSize.height - 24.0;

    final next =
        Offset(_chipOffset.dx + delta.dx, _chipOffset.dy + delta.dy);
    setState(() {
      _chipOffset = Offset(
        next.dx.clamp(minX, maxX),
        next.dy.clamp(minY, maxY),
      );
    });
  }

  Widget _collapsedChip() {
    return Material(
      color: Colors.transparent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        width: _chipSize.width,
        height: _chipSize.height,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.94),
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [BoxShadow(blurRadius: 8, color: Colors.black26)],
        ),
        alignment: Alignment.center,
        child: Text(
          AppTranslations.get('view_more'),
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
    );
  }

  void _applySearchLocal(String raw) {
    final trimmed = raw.trim();
    final q = trimmed.toLowerCase();
    final qNorm = q.replaceAll('臺', '台');
    if (q.isEmpty) {
      _visiblePlaces = List<_Place>.from(_allPlaces);
    } else {
      _visiblePlaces = _allPlaces.where((p) {
        final candidates = <String>[
          p.name.toLowerCase(),
          p.address.toLowerCase(),
          p.tag.toLowerCase(),
          p.nameEn.toLowerCase(),
          p.addressEn.toLowerCase(),
          p.tagEn.toLowerCase(),
          p.nameId.toLowerCase(),
          p.addressId.toLowerCase(),
          p.tagId.toLowerCase(),
        ].map((s) => s.replaceAll('臺', '台')).toList();
        return candidates.any((c) => c.contains(qNorm));
      }).toList();
    }

    _visiblePlaces
        .sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
    final selectedKey = _quickFilterKeys.firstWhere(
      (key) => AppTranslations.get(key) == trimmed,
      orElse: () => '',
    );
    setState(() {
      _top5 = _visiblePlaces.take(5).toList();
      _selectedQuickFilterKey = selectedKey.isEmpty ? null : selectedKey;
      _activeRoutePlace = null;
      if (_scenicEnabled || _scenicMarkers.isNotEmpty || _loadingScenic) {
        _clearScenicData();
      }
      _rebuildMarkersFrom(_visiblePlaces);
    });
  }

  Future<Map<String, dynamic>> fetchCosResults(String query,
      {int topK = 25}) async {
    final uri = Uri.parse(kSearchCosEndpoint);
    final resp = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'query': query, 'top_k': topK}),
        )
        .timeout(const Duration(seconds: 15));

    if (resp.statusCode != 200) {
      throw Exception('HTTP ${resp.statusCode}: ${resp.body}');
    }
    final data = jsonDecode(utf8.decode(resp.bodyBytes));
    String? natural;
    List items = [];

    if (data is Map<String, dynamic>) {
      natural =
          (data['natural'] ?? data['natural_language'])?.toString();
      final rawItems =
          data['items'] ?? data['json'] ?? data['json_block'];
      if (rawItems is String) {
        try {
          items = jsonDecode(rawItems);
        } catch (_) {
          items = [];
        }
      } else if (rawItems is List) {
        items = rawItems;
      }
    }
    return {'natural': natural, 'items': items};
  }

  Future<bool> _applySearchServer(String raw) async {
    final q = raw.trim();
    if (q.isEmpty) return false;
    final selectedKey = _quickFilterKeys.firstWhere(
      (key) => AppTranslations.get(key) == q,
      orElse: () => '',
    );
    setState(() {
      _searching = true;
      _llmComment = null;
    });

    try {
      final result = await fetchCosResults(q, topK: 50);
      final items = (result['items'] as List?) ?? [];
      _llmComment = _trimToFirstItem(result['natural'] as String?);

      if (items.isEmpty) return false;

      final List<_Place> list = [];
      for (final e in items) {
        if (e is! Map) continue;
        final name = (e['Name'] ?? e['name'] ?? '').toString();
        final addr = (e['Address'] ?? e['address'] ?? '').toString();
        final tel = (e['Tel'] ?? e['tel'] ?? '').toString();
        final tag = (e['tag'] ?? e['Tag'] ?? '').toString();
        final nameEn = (e['Name_en'] ?? e['name_en'] ?? '').toString();
        final addrEn = (e['Address_en'] ?? e['address_en'] ?? '').toString();
        final tagEn = (e['Tag_en'] ?? e['tag_en'] ?? '').toString();
        final nameId = (e['Name_id'] ?? e['name_id'] ?? '').toString();
        final addrId = (e['Address_id'] ?? e['address_id'] ?? '').toString();
        final tagId = (e['Tag_id'] ?? e['tag_id'] ?? '').toString();
        final lat = double.tryParse(
            (e['lat'] ?? e['latitude'] ?? '').toString());
        final lon = double.tryParse(
            (e['lon'] ?? e['longitude'] ?? '').toString());
        if (lat == null || lon == null) continue;
        list.add(_Place(
          name: name,
          address: addr,
          tel: tel,
          tag: tag,
          nameEn: nameEn,
          addressEn: addrEn,
          tagEn: tagEn,
          nameId: nameId,
          addressId: addrId,
          tagId: tagId,
          latLng: gm.LatLng(lat, lon),
          distanceMeters: (_myLatLng == null)
              ? 0
              : Geolocator.distanceBetween(
                  _myLatLng!.latitude,
                  _myLatLng!.longitude,
                  lat,
                  lon,
                ),
        ));
      }

      if (list.isEmpty) return false;

      list.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
      setState(() {
        _visiblePlaces = list;
        _top5 = list.take(5).toList();
        _activeRoutePlace = null;
        _selectedQuickFilterKey = selectedKey.isEmpty ? null : selectedKey;
        if (_scenicEnabled || _scenicMarkers.isNotEmpty || _loadingScenic) {
          _clearScenicData();
        }
        _rebuildMarkersFrom(list);
      });
      await _fitBoundsTo(list);
      return true;
    } catch (e) {
      _snack('伺服器錯誤：$e');
      return false;
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _applySearch(String raw) async {
    final trimmedRaw = raw.trim();
    final q = trimmedRaw.toLowerCase();
    final selectedKey = _quickFilterKeys.firstWhere(
      (key) => AppTranslations.get(key) == trimmedRaw,
      orElse: () => '',
    );

    List<_Place> localHits;
    if (q.isEmpty) {
      localHits = List<_Place>.from(_allPlaces);
    } else {
      localHits = _allPlaces.where((p) {
        final name = p.name.toLowerCase();
        final addr = p.address.toLowerCase();
        final tag = p.tag.toLowerCase();
        return name.contains(q) || addr.contains(q) || tag.contains(q);
      }).toList();
    }
    localHits.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));

    if (localHits.isNotEmpty) {
      setState(() {
        _llmComment = null;
        _visiblePlaces = localHits;
        _top5 = localHits.take(5).toList();
        _activeRoutePlace = null;
        _selectedQuickFilterKey = selectedKey.isEmpty ? null : selectedKey;
        if (_scenicEnabled || _scenicMarkers.isNotEmpty || _loadingScenic) {
          _clearScenicData();
        }
        _rebuildMarkersFrom(localHits);
      });
      return;
    }

    final ok = await _applySearchServer(raw);
    if (!ok) {
      setState(() {
        _llmComment = null;
        _visiblePlaces = <_Place>[];
        _top5 = const [];
        _activeRoutePlace = null;
        _selectedQuickFilterKey = selectedKey.isEmpty ? null : selectedKey;
        _clearScenicData();
        _rebuildMarkersFrom(_visiblePlaces);
      });
    }
  }

  // === 語言選擇對話框（新增）===
  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppTranslations.get('language')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _languageOption(context, '中文', 'zh'),
            _languageOption(context, 'English', 'en'),
            _languageOption(context, 'Bahasa Indonesia', 'id'),
          ],
        ),
      ),
    );
  }

  Widget _languageOption(BuildContext context, String name, String code) {
    return ListTile(
      title: Text(name),
      trailing: AppTranslations.currentLang == code
          ? const Icon(Icons.check, color: Colors.green)
          : null,
      onTap: () {
        setState(() {
          AppTranslations.currentLang = code;
        });
        Navigator.pop(context);
      },
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Positioned(
      top: 12,
      left: 12,
      right: 72,
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(12),
              color: const Color.fromARGB(149, 255, 255, 255),
              child: SizedBox(
                height: 48,
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    const Icon(Icons.search, size: 20, color: Colors.black54),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        focusNode: _searchFocus,
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          hintText: AppTranslations.get('search_hint'),
                          border: InputBorder.none,
                        ),
                        onChanged: (v) {
                          _debounce?.cancel();
                          _debounce =
                              Timer(const Duration(milliseconds: 300), () {
                            _applySearchLocal(v);
                          });
                        },
                        onSubmitted: (v) => _applySearch(v),
                      ),
                    ),
                    if (_searching)
                      const Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8.0),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    IconButton(
                      tooltip: AppTranslations.get('clear'),
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        _searchCtrl.clear();
                        _applySearchLocal('');
                        _searchFocus.requestFocus();
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            _buildQuickFilters(),
          ],
        ),
      ),
    );
  }

  bool get _canShowScenicToggle =>
      _activeRoutePlace != null && _routeOptions.isNotEmpty;

  Widget _buildScenicToggle() {
    final bool enabled = _scenicEnabled;
    final bool loading = _loadingScenic;
    final bool canTap = _canShowScenicToggle && !loading;
    final String scenicLabel = AppTranslations.get('scenic');
    final bool isIndonesian = AppTranslations.currentLang == 'id';
    final String displayLabel =
        isIndonesian ? scenicLabel.replaceAll(' ', '\n') : scenicLabel;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: canTap ? _toggleScenic : null,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 56,
          height: 54,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: enabled ? Colors.blueAccent : Colors.black26,
              width: enabled ? 1.8 : 1,
            ),
            boxShadow: const [
              BoxShadow(
                  blurRadius: 6, offset: Offset(0, 3), color: Colors.black12)
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (loading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Icon(
                    enabled ? Icons.check_box : Icons.check_box_outline_blank,
                    size: 28,
                    color: enabled ? Colors.blueAccent : Colors.black45,
                  ),
                const SizedBox(height: 3),
                Text(
                  displayLabel,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isIndonesian ? 15 : 13,
                    fontWeight: FontWeight.w600,
                    height: isIndonesian ? 1.05 : 1.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickFilters() {
    return SizedBox(
      width: double.infinity,
      child: Material(
        elevation: 3,
        borderRadius: BorderRadius.circular(12),
        color: const Color.fromARGB(170, 255, 255, 255),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: _quickFilterKeys.map((key) {
                final label = AppTranslations.get(key);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    labelStyle: const TextStyle(fontSize: 12),
                    visualDensity:
                        const VisualDensity(horizontal: -2, vertical: -3),
                    label: Text(label),
                    labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                    selected: _selectedQuickFilterKey == key,
                    onSelected: (_) => _onQuickFilterTap(key),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  void _onQuickFilterTap(String key) {
    FocusScope.of(context).unfocus();
    _debounce?.cancel();
    final label = AppTranslations.get(key);
    if (_searchCtrl.text != label) {
      _searchCtrl.text = label;
    }
    setState(() {
      _selectedQuickFilterKey = key;
    });
    _applySearchLocal(label);
    _applySearch(label);
  }

  Future<void> _toggleScenic() async {
    final target = _activeRoutePlace;
    if (target == null) return;

    if (_scenicEnabled) {
      setState(() {
        _clearScenicData();
        _rebuildMarkersFrom(_visiblePlaces);
      });
      return;
    }

    if (kGoogleMapsKey.isEmpty) {
      _snack('尚未設定 GOOGLE_MAPS_API_KEY，無法搜尋景點');
      return;
    }

    setState(() {
      _loadingScenic = true;
      _focusedScenicId = null;
      if (_scenicMarkers.isNotEmpty) {
        _scenicMarkers.clear();
        _scenicPlaces.clear();
        _rebuildMarkersFrom(_visiblePlaces);
      }
    });

    try {
      final scenic = await _fetchScenicPlaces(target);
      if (scenic.isEmpty) {
        if (mounted) {
          setState(() {
            _loadingScenic = false;
            _scenicEnabled = false;
            _focusedScenicId = null;
          });
        }
        _snack('附近 800 公尺內暫時找不到景點');
        return;
      }

      if (!mounted) return;
      _focusedScenicId = null;
      final markerList = await _buildScenicMarkers(scenic);
      if (!mounted) return;
      setState(() {
        _scenicPlaces
          ..clear()
          ..addAll(scenic);
        _scenicMarkers
          ..clear()
          ..addAll(markerList);
        _scenicEnabled = true;
        _loadingScenic = false;
        _focusedScenicId = null;
        _rebuildMarkersFrom(_visiblePlaces);
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingScenic = false;
          _clearScenicData();
        });
      }
      _snack('景點搜尋失敗：$e');
    }
  }

  void _clearScenicData() {
    _scenicEnabled = false;
    _scenicPlaces.clear();
    _scenicMarkers.clear();
    _scenicOverlayPolylines.clear();
    _loadingScenic = false;
    _focusedScenicId = null;
  }

  String _scenicCacheKeyFor(_Place p) =>
      '${p.latLng.latitude.toStringAsFixed(5)},${p.latLng.longitude.toStringAsFixed(5)}';

  Future<List<_ScenicPlace>> _fetchScenicPlaces(_Place base) async {
    final key = _scenicCacheKeyFor(base);
    final cached = _scenicCache[key];
    if (cached != null && cached.isNotEmpty) {
      return List<_ScenicPlace>.from(cached);
    }

    final language = () {
      switch (AppTranslations.currentLang) {
        case 'en':
          return 'en';
        case 'id':
          return 'id';
        default:
          return 'zh-TW';
      }
    }();

    final params = {
      'location':
          '${base.latLng.latitude.toStringAsFixed(6)},${base.latLng.longitude.toStringAsFixed(6)}',
      'radius': '2000',
      'type': 'tourist_attraction',
      'language': language,
      'key': kGoogleMapsKey,
    };
    final uri = Uri.https(
        'maps.googleapis.com', '/maps/api/place/nearbysearch/json', params);

    final resp =
        await http.get(uri).timeout(const Duration(seconds: 15));
    if (resp.statusCode != 200) {
      throw Exception('HTTP ${resp.statusCode}');
    }

    final data = jsonDecode(utf8.decode(resp.bodyBytes));
    final status = data['status']?.toString() ?? 'UNKNOWN';
    if (status != 'OK' && status != 'ZERO_RESULTS') {
      final err = data['error_message'] ?? status;
      throw Exception(err);
    }

    final results = data['results'];
    if (results is! List) return [];

    final scenic = <_ScenicPlace>[];
    for (final item in results) {
      if (item is! Map) continue;
      final geom = item['geometry'];
      final loc = (geom is Map) ? geom['location'] : null;
      final lat = (loc is Map) ? loc['lat'] : null;
      final lng = (loc is Map) ? loc['lng'] : null;
      if (lat == null || lng == null) continue;
      final double? rating =
          (item['rating'] is num) ? (item['rating'] as num).toDouble() : null;
      final int? ratingCount = (item['user_ratings_total'] is num)
          ? (item['user_ratings_total'] as num).toInt()
          : null;
      scenic.add(_ScenicPlace(
        placeId: (item['place_id'] ?? '${lat}_$lng').toString(),
        name: (item['name'] ?? '').toString(),
        address:
            (item['vicinity'] ?? item['formatted_address'] ?? '').toString(),
        rating: rating,
        ratingCount: ratingCount,
        latLng: gm.LatLng(
          (lat as num).toDouble(),
          (lng as num).toDouble(),
        ),
      ));
    }

    scenic.sort((a, b) {
      final ratingCompare =
          (b.rating ?? 0).compareTo(a.rating ?? 0);
      if (ratingCompare != 0) return ratingCompare;
      return (b.ratingCount ?? 0).compareTo(a.ratingCount ?? 0);
    });

    final top = scenic.take(5).toList();
    _scenicCache[key] = List<_ScenicPlace>.from(top);
    return top;
  }

  Future<gm.BitmapDescriptor> _scenicIconFor(_ScenicPlace spot) async {
    const String cacheKey = 'default_blue_pin';
    final cached = _scenicIconCache[cacheKey];
    if (cached != null) return cached;
    final gm.BitmapDescriptor icon =
        gm.BitmapDescriptor.defaultMarkerWithHue(
            gm.BitmapDescriptor.hueAzure);
    _scenicIconCache[cacheKey] = icon;
    return icon;
  }

  Future<gm.BitmapDescriptor> _scenicLabelIconFor(String label) async {
    final String key = label;
    final cached = _scenicLabelIconCache[key];
    if (cached != null) return cached;

    final String text = label.isEmpty ? AppTranslations.get('scenic') : label;
    const double paddingH = 14;
    const double paddingV = 6;
    const double bubbleRadius = 18;
    const double bottomPadding = 35; // ↑ increase to place text higher above the pin
    const double maxTextWidth = 200;

    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1A73E8),
        ),
      ),
      textAlign: TextAlign.center,
      maxLines: 2,
      ellipsis: '…',
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxTextWidth - paddingH * 2);

    final double textWidth = painter.width;
    final double textHeight = painter.height;
    final double bubbleWidth = textWidth + paddingH * 2;
    final double bubbleHeight = textHeight + paddingV * 2;
    final double totalWidth = bubbleWidth;
    final double totalHeight = bubbleHeight + bottomPadding;

    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    final double dpr = ui.window.devicePixelRatio;
    canvas.scale(dpr);

    final RRect bubble = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, bubbleWidth, bubbleHeight),
      const Radius.circular(bubbleRadius),
    );
    final ui.Path bubblePath = ui.Path()..addRRect(bubble);
    canvas.drawShadow(
      bubblePath,
      const Color(0x1A000000),
      3,
      false,
    );

    final Paint fill = Paint()..color = const Color(0xFFFFFFFF);
    final Paint stroke = Paint()
      ..color = const Color(0xFF1A73E8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawPath(bubblePath, fill);
    canvas.drawPath(bubblePath, stroke);

    painter.paint(
      canvas,
      Offset((bubbleWidth - textWidth) / 2, paddingV),
    );

    final ui.Picture picture = recorder.endRecording();
    final ui.Image image = await picture.toImage(
      (totalWidth * dpr).ceil(),
      (totalHeight * dpr).ceil(),
    );
    final ByteData? bytes =
        await image.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) {
      return gm.BitmapDescriptor.defaultMarker;
    }

    final descriptor =
        gm.BitmapDescriptor.fromBytes(bytes.buffer.asUint8List());
    _scenicLabelIconCache[key] = descriptor;
    return descriptor;
  }

  Future<void> _prepareSelectionRingIcon() async {
    final icon = await _createSelectionRingIcon();
    if (!mounted) return;
    setState(() {
      _selectionRingIcon = icon;
      _rebuildMarkersFrom(_visiblePlaces);
    });
  }

  Future<gm.BitmapDescriptor> _createSelectionRingIcon() async {
    const double outerRadius = 10;
    const double ringThickness = 4.0;
    const double topOffset = 6;
    const double bottomPadding = 13.7;

    final double width = outerRadius * 2 + 12;
    final double height = topOffset + outerRadius * 2 + bottomPadding;

    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    final double dpr = ui.window.devicePixelRatio;
    canvas.scale(dpr);

    final Offset center = Offset(width / 2, topOffset + outerRadius);
    final Rect layerBounds = Rect.fromLTWH(0, 0, width, height);

    canvas.saveLayer(layerBounds, Paint());
    final Paint outer = Paint()
      ..color = Colors.white
      ..isAntiAlias = true;
    canvas.drawCircle(center, outerRadius, outer);

    final Paint inner = Paint()
      ..blendMode = BlendMode.clear
      ..isAntiAlias = true;
    canvas.drawCircle(center, outerRadius - ringThickness, inner);
    canvas.restore();

    final ui.Picture picture = recorder.endRecording();
    final ui.Image image = await picture.toImage(
      (width * dpr).ceil(),
      (height * dpr).ceil(),
    );
    final ByteData? bytes =
        await image.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) {
      return gm.BitmapDescriptor.defaultMarker;
    }
    return gm.BitmapDescriptor.fromBytes(bytes.buffer.asUint8List());
  }


  void _drawScenicOverlay(List<gm.LatLng> path) {
    if (path.isEmpty) return;
    final outline = gm.Polyline(
      polylineId: const gm.PolylineId('scenic_overlay_outline'),
      points: path,
      width: 10,
      color: const Color(0xFFFFC107).withOpacity(0.95),
      geodesic: true,
      zIndex: 48,
    );
    final face = gm.Polyline(
      polylineId: const gm.PolylineId('scenic_overlay_face'),
      points: path,
      width: 6,
      color: _colorForMode('driving', selected: true),
      geodesic: true,
      zIndex: 49,
    );
    setState(() {
      _scenicOverlayPolylines
        ..clear()
        ..add(outline)
        ..add(face);
    });
  }

  Future<List<gm.Marker>> _buildScenicMarkers(List<_ScenicPlace> scenic,
      {String? focusId}) async {
    final List<_ScenicPlace> source;
    if (focusId != null) {
      final filtered =
          scenic.where((s) => s.placeId == focusId).toList();
      source = filtered.isEmpty ? scenic : filtered;
    } else {
      source = scenic;
    }

    final markers = <gm.Marker>[];
    for (final spot in source) {
      final icon = await _scenicIconFor(spot);
      final labelIcon = await _scenicLabelIconFor(spot.name);
      markers.add(
        gm.Marker(
          markerId: gm.MarkerId('scenic-${spot.placeId}'),
          position: spot.latLng,
          icon: icon,
          anchor: const Offset(0.5, 1.0),
          consumeTapEvents: true,
          zIndex: 1,
          infoWindow: gm.InfoWindow(
            title: spot.name,
            snippet: spot.address.isEmpty ? null : spot.address,
          ),
          onTap: () => _onScenicPlaceTapped(spot),
        ),
      );
      markers.add(
        gm.Marker(
          markerId: gm.MarkerId('scenic-label-${spot.placeId}'),
          position: spot.latLng,
          icon: labelIcon,
          anchor: const Offset(0.5, 1.0),
          consumeTapEvents: true,
          zIndex: 2,
          onTap: () => _onScenicPlaceTapped(spot),
        ),
      );
      final ringIcon = _selectionRingIcon;
      if (ringIcon != null &&
          (_focusedScenicId != null && _focusedScenicId == spot.placeId)) {
        markers.add(
          gm.Marker(
            markerId: gm.MarkerId('scenic-ring-${spot.placeId}'),
            position: spot.latLng,
            icon: ringIcon,
            anchor: const Offset(0.5, 1.0),
            consumeTapEvents: false,
            zIndex: 1.3,
          ),
        );
      }
    }
    return markers;
  }

  @override
  Widget build(BuildContext context) {
    final initialCamera = const gm.CameraPosition(
        target: gm.LatLng(23.5, 121.0), zoom: 5);
    final hasQuery = _searchCtrl.text.trim().isNotEmpty;
    final panelTitle = hasQuery 
        ? AppTranslations.get('search_results')
        : AppTranslations.get('nearby_top5');

    return Scaffold(
      appBar: AppBar(
        title: Text(AppTranslations.get('app_title')),
        backgroundColor: Colors.black,
      ),
      body: Stack(
        children: [
          gm.GoogleMap(
            initialCameraPosition: initialCamera,
            onMapCreated: (c) async {
              _mapCtrl = c;
              Future.delayed(const Duration(milliseconds: 300),
                  _flyTaiwanThenMyLoc);
            },
            onTap: (_) => FocusScope.of(context).unfocus(),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            compassEnabled: true,
            mapType: gm.MapType.normal,
            padding: EdgeInsets.zero,
            markers: _markers,
            polylines: {..._polylines, ..._scenicOverlayPolylines},
            circles: _walkDots,
          ),

          if (_routeOptions.isNotEmpty)
            Positioned(
              left: 3,
              bottom: kBottomNavigationBarHeight -54,
              child: SafeArea(child: _buildRouteOptionsPanel()),
            ),

          if (_collapsed)
            Positioned(
              left: _chipOffset.dx,
              top: _chipOffset.dy,
              child: GestureDetector(
                onPanUpdate: (d) => _dragChip(d.delta, context),
                onTap: () {
                  FocusScope.of(context).unfocus();
                  setState(() {
                    _collapsed = false;
                    _chipOffset = Offset(12, _chipOffset.dy);
                  });
                },
                child: _collapsedChip(),
              ),
            )
          else
            SafeArea(
              child: Align(
                alignment: Alignment.centerLeft,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 380),
                  curve: Curves.fastOutSlowIn,
                  width: 300,
                  height: 420,
                  margin: const EdgeInsets.only(left: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.94),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(blurRadius: 8, color: Colors.black26)
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      InkWell(
                        onTap: () => setState(() => _collapsed = true),
                        child: Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          alignment: Alignment.centerLeft,
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(panelTitle,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16)),
                              ),
                              const Icon(Icons.expand_more),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.stretch,
                            children: [
                              if (_llmComment != null &&
                                  _llmComment!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                      12, 4, 12, 8),
                                  child: Text(_llmComment!,
                                      style:
                                          const TextStyle(fontSize: 13)),
                                ),
                              if (_top5.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Center(
                                      child: Text(AppTranslations.get('getting_nearby'))),
                                )
                              else
                                ...List.generate(_top5.length, (i) {
                                  final p = _top5[i];
                                  final km =
                                      (p.distanceMeters / 1000);
                                  return Column(
                                    children: [
                                      ListTile(
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 12),
                                        title: Text(p.name,
                                            maxLines: 1,
                                            overflow:
                                                TextOverflow.ellipsis,
                                            style: const TextStyle(
                                                fontWeight:
                                                    FontWeight.w600)),
                                        subtitle: Text(p.address,
                                            maxLines: 1,
                                            overflow:
                                                TextOverflow.ellipsis),
                                        trailing: Text(
                                          '${km.toStringAsFixed(1)} km',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.deepPurple),
                                        ),
                                        onTap: () =>
                                            _onPlaceTappedForRoutes(p),
                                      ),
                                      const Divider(
                                          height: 1, thickness: 0.6),
                                    ],
                                  );
                                }),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          _buildSearchBar(context),

          // === 語言按鈕（新增）===
          Positioned(
            top: 12,
            right: 12,
            child: SafeArea(
              child: FloatingActionButton.small(
                heroTag: 'language_btn',
                onPressed: () => _showLanguageDialog(context),
                backgroundColor: Colors.white,
                child: const Icon(Icons.language, color: Colors.black87),
              ),
            ),
          ),
          if (_loadingScenic || _canShowScenicToggle)
            Positioned(
              top: 62,
              right: 8,
              child: SafeArea(
                top: false,
                left: false,
                bottom: false,
                child: _buildScenicToggle(),
              ),
            ),
        ],
      ),

      floatingActionButtonLocation:
          const OffsetFabLocation(FloatingActionButtonLocation.endFloat, Offset(25, 19.8)),

      floatingActionButton: (_myLatLng == null)
    ? null
    : SizedBox(
        width: 150,
        child: Transform.scale(
          scale: 0.8,
          child: FloatingActionButton.extended(
            heroTag: 'my_location_btn',
            onPressed: () => _centerOn(_myLatLng!),
            icon: const Icon(Icons.my_location),
            label: Text(AppTranslations.get('my_location')),
          ),
        ),
      ),
    );
  }

  String? _trimToFirstItem(String? s) {
    if (s == null) return null;
    final m = RegExp(r'(^|\n)\s*1\.').firstMatch(s);
    if (m == null) return s;
    final idx = s.indexOf('1.', m.start);
    return (idx < 0) ? s : s.substring(idx);
  }

  Future<void> _showPlacesFromChat(List<ShowPlace> places,
      {String? comment}) async {
    final list = <_Place>[];
    for (final e in places.take(5)) {
      final double dist = (_myLatLng == null)
          ? 0.0
          : Geolocator.distanceBetween(
              _myLatLng!.latitude,
              _myLatLng!.longitude,
              e.lat,
              e.lon);
      list.add(_Place(
        name: e.name,
        address: e.address,
        tel: e.tel,
        tag: e.tag,
        nameEn: e.nameEn,
        addressEn: e.addressEn,
        tagEn: e.tagEn,
        nameId: e.nameId,
        addressId: e.addressId,
        tagId: e.tagId,
        latLng: gm.LatLng(e.lat, e.lon),
        distanceMeters: dist,
      ));
    }

    if (list.isEmpty) return;

    setState(() {
      _llmComment = _trimToFirstItem(comment);
      _collapsed = false;
      _visiblePlaces = list;
      _top5 = list.take(5).toList();
      _activeRoutePlace = null;
      if (_scenicEnabled || _scenicMarkers.isNotEmpty || _loadingScenic) {
        _clearScenicData();
      }
      _rebuildMarkersFrom(list);
      _clearRoutes();
    });

    await _fitBoundsTo(list);
  }

  Future<void> _onPlaceTappedForRoutes(_Place p) async {
    FocusScope.of(context).unfocus();

    setState(() {
      _collapsed = true;
      _chipOffset = Offset(12, _chipOffset.dy);
      _routeOptions.clear();
      _selectedRouteId = null;
      _polylines.clear();
      _walkDots.clear();
      _scenicOverlayPolylines.clear();
      _activeRoutePlace = p;
      if (_scenicEnabled || _scenicMarkers.isNotEmpty || _loadingScenic) {
        _clearScenicData();
      }
      _rebuildMarkersFrom(_visiblePlaces);
    });

    await _zoomToPlace(p.latLng);

    if (_myLatLng == null) {
      _snack('無法規劃路線：尚未取得你的定位');
      return;
    }
    if (kGoogleMapsKey.isEmpty) {
      _snack('尚未設定 GOOGLE_MAPS_API_KEY（請用 --dart-define 傳入）');
      return;
    }

    final modes = ['driving', 'transit', 'walking'];
    try {
      final futures = modes
          .map((m) => _fetchDirections(_myLatLng!, p.latLng, m))
          .toList();
      final results = await Future.wait(futures);
      final opts = results.whereType<_RouteOption>().toList();

      if (opts.isEmpty) {
        _snack('目前拿不到路線，稍後再試或換個目的地');
        return;
      }

      setState(() {
        _routeOptions = opts;
      });

      if (opts.isNotEmpty) {
        await _selectRoute(opts.first, adjustCamera: false);
      }

      // await _fitBoundsTo([
      //   _Place(
      //       name: 'me',
      //       address: '',
      //       tel: '',
      //       tag: '',
      //       latLng: _myLatLng!,
      //       distanceMeters: 0),
      //   _Place(
      //       name: 'dest',
      //       address: '',
      //       tel: '',
      //       tag: '',
      //       latLng: p.latLng,
      //       distanceMeters: 0),
      // ]);
    } catch (e) {
      _snack('路線規劃失敗：$e');
    }
  }

  Future<void> _onScenicPlaceTapped(_ScenicPlace spot) async {
    final base = _activeRoutePlace;
    if (_myLatLng == null) {
      _snack('無法規劃路線：尚未取得你的定位');
      return;
    }
    if (base == null) {
      _snack('請先選擇餐廳再查看景點路線');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _collapsed = true;
      _chipOffset = Offset(12, _chipOffset.dy);
    });
    final String focusId = spot.placeId;

    final markers = await _buildScenicMarkers(
      _scenicPlaces.isEmpty ? [spot] : _scenicPlaces,
      focusId: focusId,
    );
    if (!mounted) return;
    setState(() {
      _scenicMarkers
        ..clear()
        ..addAll(markers);
      _focusedScenicId = focusId;
      _rebuildMarkersFrom(_visiblePlaces);
    });

    await _zoomToPlace(spot.latLng);

    final modes = ['driving', 'transit', 'walking'];
    try {
      final futures = modes
          .map((m) => _fetchDirections(
                _myLatLng!,
                spot.latLng,
                m,
                waypoints: [base.latLng],
              ))
          .toList();
      final results = await Future.wait(futures);
      final opts = results.whereType<_RouteOption>().toList();

      if (opts.isEmpty) {
        _snack('目前拿不到景點路線，稍後再試');
        setState(() => _scenicOverlayPolylines.clear());
        return;
      }

      final driving = opts.firstWhere(
        (e) => e.mode == 'driving',
        orElse: () => opts.first,
      );
      final overlayOpt = await _fetchDirections(
        base.latLng,
        spot.latLng,
        'driving',
      );
      if (overlayOpt != null) {
        _drawScenicOverlay(overlayOpt.path);
      } else {
        _drawScenicOverlay(driving.path);
      }

      setState(() {
        _routeOptions = opts;
      });

      if (opts.isNotEmpty) {
        await _selectRoute(opts.first, adjustCamera: false);
      }

      // await _fitBoundsTo([
      //   _Place(
      //       name: 'me',
      //       address: '',
      //       tel: '',
      //       tag: '',
      //       latLng: _myLatLng!,
      //       distanceMeters: 0),
      //   _Place(
      //       name: base.name,
      //       address: base.address,
      //       tel: base.tel,
      //       tag: base.tag,
      //       latLng: base.latLng,
      //       distanceMeters: 0),
      //   _Place(
      //       name: spot.name,
      //       address: spot.address,
      //       tel: '',
      //       tag: 'scenic',
      //       latLng: spot.latLng,
      //       distanceMeters: 0),
      // ]);
    } catch (e) {
      _snack('景點路線規劃失敗：$e');
    }
  }

  Future<_RouteOption?> _fetchDirections(
      gm.LatLng origin, gm.LatLng dest, String mode,
      {List<gm.LatLng>? waypoints}) async {
    final o = '${origin.latitude},${origin.longitude}';
    final d = '${dest.latitude},${dest.longitude}';
    final directionsLang = () {
      switch (AppTranslations.currentLang) {
        case 'en':
          return 'en';
        case 'id':
          return 'id';
        default:
          return 'zh-TW';
      }
    }();
    final params = <String, String>{
      'origin': o,
      'destination': d,
      'mode': mode,
      'region': 'tw',
      'language': directionsLang,
      'alternatives': 'false',
      'departure_time': 'now',
      'key': kGoogleMapsKey,
    };
    if (waypoints != null && waypoints.isNotEmpty) {
      params['waypoints'] = waypoints
          .map((w) =>
              'via:${w.latitude.toStringAsFixed(6)},${w.longitude.toStringAsFixed(6)}')
          .join('|');
    }
    final uri = Uri.https(
        'maps.googleapis.com', '/maps/api/directions/json', params);

    final resp =
        await http.get(uri).timeout(const Duration(seconds: 15));
    if (resp.statusCode != 200) return null;

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    if ((data['status'] ?? '') != 'OK' ||
        (data['routes'] as List).isEmpty) {
      return null;
    }

    final route =
        (data['routes'] as List).first as Map<String, dynamic>;
    final poly =
        (route['overview_polyline']?['points'] ?? '') as String;
    if (poly.isEmpty) return null;

    final legs =
        (route['legs'] as List).cast<Map<String, dynamic>>();
    if (legs.isEmpty) return null;
    final leg0 = legs.first;
    final distanceText = (leg0['distance']?['text'] ?? '') as String;

    String durationText;
    if (mode == 'driving' && leg0['duration_in_traffic'] != null) {
      durationText =
          (leg0['duration_in_traffic']?['text'] ?? '') as String;
    } else {
      durationText = (leg0['duration']?['text'] ?? '') as String;
    }

    final coords = _decodePolyline(poly);
    final wp = waypoints;
    bool hasWaypoint = false;
    List<gm.LatLng> primary = coords;
    if (wp != null && wp.isNotEmpty) {
      hasWaypoint = true;
      final trimmed = _clipPathAtWaypoint(coords, wp.first);
      if (trimmed.length >= 2) {
        primary = trimmed;
      }
    }
    return _RouteOption(
      mode: mode,
      distanceText: distanceText,
      durationText: durationText,
      path: coords,
      primaryPath: primary,
      isPartial: hasWaypoint && (primary.length != coords.length ||
          primary.last.latitude != coords.last.latitude ||
          primary.last.longitude != coords.last.longitude),
      polylineId:
          'route_${mode}_${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  List<gm.LatLng> _decodePolyline(String encoded) {
    List<gm.LatLng> poly = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat =
          ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng =
          ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      final latD = lat / 1e5;
      final lngD = lng / 1e5;
        poly.add(gm.LatLng(latD, lngD));
    }
    return poly;
  }

  double _distanceMeters(gm.LatLng a, gm.LatLng b) {
    const double earthRadius = 6371000.0;
    final double dLat = _degToRad(b.latitude - a.latitude);
    final double dLng = _degToRad(b.longitude - a.longitude);
    final double lat1 = _degToRad(a.latitude);
    final double lat2 = _degToRad(b.latitude);
    final double h = math.pow(math.sin(dLat / 2), 2) +
        math.cos(lat1) * math.cos(lat2) * math.pow(math.sin(dLng / 2), 2);
    return 2 * earthRadius * math.asin(math.sqrt(h));
  }

  double _degToRad(double deg) => deg * (math.pi / 180.0);

  List<gm.LatLng> _clipPathAtWaypoint(List<gm.LatLng> path, gm.LatLng waypoint) {
    if (path.isEmpty) return path;
    int nearestIdx = 0;
    double nearestDist = double.infinity;
    for (int i = 0; i < path.length; i++) {
      final d = _distanceMeters(path[i], waypoint);
      if (d < nearestDist) {
        nearestDist = d;
        nearestIdx = i;
      }
    }
    if (nearestIdx == path.length - 1 && nearestDist > 50) {
      return path;
    }
    final List<gm.LatLng> clipped =
        List<gm.LatLng>.from(path.take(nearestIdx + 1));
    final gm.LatLng last = clipped.last;
    if (_distanceMeters(last, waypoint) > 5) {
      clipped.add(waypoint);
    }
    return clipped;
  }

  Color _colorForMode(String mode, {required bool selected}) {
    switch (mode) {
      case 'driving':
        return selected
            ? const Color(0xFF1A73E8)
            : const Color(0xFF8AB4F8);
      case 'transit':
        return selected
            ? const Color(0xFFF6C445)
            : const Color(0xFFF9E3A3);
      case 'walking':
        return selected
            ? const Color(0xFF4285F4)
            : const Color(0x804285F4);
      default:
        return selected ? Colors.deepPurple : Colors.deepPurple.shade200;
    }
  }

  List<gm.LatLng> _pathToDrawFor(_RouteOption opt) => opt.primaryPath;

  Future<void> _selectRoute(_RouteOption opt, {bool adjustCamera = true}) async {
    setState(() {
      _selectedRouteId = opt.polylineId;
      _polylines.clear();
      _walkDots.clear();
    });

    _RouteOption? driving = _routeOptions.firstWhere(
      (e) => e.mode == 'driving',
      orElse: () => opt,
    );
    _RouteOption? transit = _routeOptions.firstWhere(
      (e) => e.mode == 'transit',
      orElse: () => opt,
    );
    if (driving.mode != 'driving') driving = null;
    if (transit.mode != 'transit') transit = null;

    if (opt.mode == 'walking') {
      final walkPath = _pathToDrawFor(opt);
      if (Platform.isAndroid) {
        final face = gm.Polyline(
          polylineId: gm.PolylineId('${opt.polylineId}_walk_face'),
          points: walkPath,
          width: 6,
          color: _colorForMode('walking', selected: true),
          geodesic: true,
          patterns: <gmfpi.PatternItem>[
            gmfpi.PatternItem.dash(24),
            gmfpi.PatternItem.gap(18),
          ],
          zIndex: 10,
        );
        setState(() => _polylines.add(face));
      } else {
        final dots =
            _buildWalkingDots(walkPath, gapMeters: 80, radiusMeters: 28);
        setState(() => _walkDots.addAll(dots));
      }

      if (driving != null) _addDashedAltPolyline(driving, baseZ: 1);
      if (transit != null) _addDashedAltPolyline(transit, baseZ: 1);

      final allShown = <gm.LatLng>[];
      for (final pl in _polylines) {
        allShown.addAll(pl.points);
      }
      if (opt.isPartial) {
        allShown.addAll(opt.path);
      }
      if (adjustCamera && allShown.isNotEmpty) await _fitBoundsToPolyline(allShown);
      return;
    }

    _addOutlinedMainPolyline(opt);

    if (opt.mode == 'driving' && transit != null) {
      _addDashedAltPolyline(transit, baseZ: 2);
    } else if (opt.mode == 'transit' && driving != null) {
      _addDashedAltPolyline(driving, baseZ: 2);
    }

    final allShown = <gm.LatLng>[];
    for (final pl in _polylines) {
      allShown.addAll(pl.points);
    }
    if (opt.isPartial) {
      allShown.addAll(opt.path);
    }
    if (adjustCamera && allShown.isNotEmpty) {
      await _fitBoundsToPolyline(allShown);
    }
  }

  void _addOutlinedMainPolyline(_RouteOption opt) {
    final faceColor = _colorForMode(opt.mode, selected: true);
    final drawPath = _pathToDrawFor(opt);

    final Color outlineColor = (opt.mode == 'transit')
        ? Colors.black.withValues(alpha: 0.9)
        : const Color(0xFF003366).withValues(alpha: 0.85);

    final outline = gm.Polyline(
      polylineId: gm.PolylineId('${opt.polylineId}_outline'),
      points: drawPath,
      width: 10,
      color: outlineColor,
      geodesic: true,
      zIndex: 5,
    );

    final face = gm.Polyline(
      polylineId: gm.PolylineId('${opt.polylineId}_face'),
      points: drawPath,
      width: 6,
      color: faceColor,
      geodesic: true,
      zIndex: 6,
    );

    setState(() {
      _polylines
        ..add(outline)
        ..add(face);
    });
  }

  void _addDashedAltPolyline(_RouteOption opt, {int baseZ = 0}) {
    final drawPath = _pathToDrawFor(opt);
    if (Platform.isAndroid) {
      final dashed = gm.Polyline(
        polylineId: gm.PolylineId('${opt.polylineId}_alt_dash'),
        points: drawPath,
        width: 5,
        color: _colorForMode(opt.mode, selected: false),
        geodesic: true,
        patterns: <gmfpi.PatternItem>[
          gmfpi.PatternItem.dash(24),
          gmfpi.PatternItem.gap(14),
        ],
        zIndex: baseZ + 1,
      );
      setState(() => _polylines.add(dashed));
    } else {
      final faint = gm.Polyline(
        polylineId: gm.PolylineId('${opt.polylineId}_alt_faint'),
        points: drawPath,
        width: 4,
        color:
            _colorForMode(opt.mode, selected: false).withOpacity(0.7),
        geodesic: true,
        zIndex: baseZ + 1,
      );
      setState(() => _polylines.add(faint));
    }
  }

  Iterable<gm.Circle> _buildWalkingDots(
    List<gm.LatLng> path, {
    double gapMeters = 120,
    double radiusMeters = 28,
  }) sync* {
    if (path.length < 2) return;

    final fill =
        _colorForMode('walking', selected: true).withOpacity(0.95);
    final stroke = Colors.white.withOpacity(0.9);

    double acc = 0.0;
    gm.LatLng? prev;

    for (final p in path) {
      if (prev == null) {
        prev = p;
        continue;
      }
      final seg = Geolocator.distanceBetween(
          prev.latitude, prev.longitude, p.latitude, p.longitude);

      double t = (gapMeters - acc) / seg;
      while (seg > 0 && t <= 1.0) {
        final pt = gm.LatLng(
          prev.latitude + (p.latitude - prev.latitude) * t,
          prev.longitude + (p.longitude - prev.longitude) * t,
        );
        yield gm.Circle(
          circleId: gm.CircleId(
              'walkdot_${pt.latitude}_${pt.longitude}_${gapMeters}_$radiusMeters'),
          center: pt,
          radius: radiusMeters,
          strokeWidth: 2,
          strokeColor: stroke,
          fillColor: fill,
          zIndex: 10,
        );
        t += gapMeters / seg;
      }

      acc = (seg + acc) % gapMeters;
      prev = p;
    }
  }

  void _clearRoutes() {
    setState(() {
      _routeOptions.clear();
      _selectedRouteId = null;
      _polylines.clear();
      _walkDots.clear();
      _scenicOverlayPolylines.clear();
    });
  }

  Widget _buildRouteOptionsPanel() {
    final bool isMini = _routePanelMinimized;

    if (isMini) {
      return Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withOpacity(0.96),
        clipBehavior: Clip.hardEdge,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 260),
          child: SizedBox(
            height: 44,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  const Icon(Icons.route, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      AppTranslations.get('route_title'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    tooltip: AppTranslations.get('expand'),
                    onPressed: () => setState(() => _routePanelMinimized = false),
                    icon: const Icon(Icons.unfold_more),
                    iconSize: 18,
                    visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                    constraints: const BoxConstraints.tightFor(width: 32, height: 32),
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(width: 2),
                  IconButton(
                    tooltip: AppTranslations.get('clear_route'),
                    onPressed: _clearRoutes,
                    icon: const Icon(Icons.close),
                    iconSize: 18,
                    visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                    constraints: const BoxConstraints.tightFor(width: 32, height: 32),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(12),
      color: Colors.white.withOpacity(0.96),
      clipBehavior: Clip.hardEdge,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 260),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.route, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      AppTranslations.get('route_title'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    tooltip: AppTranslations.get('minimize'),
                    onPressed: () => setState(() => _routePanelMinimized = true),
                    icon: const Icon(Icons.unfold_less),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    tooltip: AppTranslations.get('clear_route'),
                    onPressed: _clearRoutes,
                    icon: const Icon(Icons.close),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              for (final opt in _routeOptions)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: ElevatedButton.icon(
                    icon: Icon(opt.modeIcon, size: 18),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: (_selectedRouteId == opt.polylineId)
                          ? Colors.deepPurple
                          : Colors.white,
                      foregroundColor: (_selectedRouteId == opt.polylineId)
                          ? Colors.white
                          : Colors.black87,
                      side: BorderSide(
                        color: (_selectedRouteId == opt.polylineId)
                            ? Colors.deepPurple
                            : Colors.black26,
                      ),
                    ),
                    onPressed: () => _selectRoute(opt, adjustCamera: true),
                    label: Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            opt.modeLabel,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${opt.durationText}｜${opt.distanceText}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              if (kGoogleMapsKey.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    '未設定 GOOGLE_MAPS_API_KEY，無法呼叫路線服務',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScenicPlace {
  const _ScenicPlace({
    required this.placeId,
    required this.name,
    required this.address,
    required this.latLng,
    this.rating,
    this.ratingCount,
  });
  final String placeId;
  final String name;
  final String address;
  final gm.LatLng latLng;
  final double? rating;
  final int? ratingCount;
}

class _Place {
  _Place({
    required this.name,
    required this.address,
    required this.tel,
    required this.tag,
    required this.latLng,
    required this.distanceMeters,
    this.nameEn = '',
    this.nameId = '',
    this.addressEn = '',
    this.addressId = '',
    this.tagEn = '',
    this.tagId = '',
  });
  final String name;
  final String address;
  final String tel;
  final String tag;
  final gm.LatLng latLng;
  final String nameEn;
  final String nameId;
  final String addressEn;
  final String addressId;
  final String tagEn;
  final String tagId;
  double distanceMeters;
}

class ChatGPTPage extends StatefulWidget {
  const ChatGPTPage({super.key, this.onShowOnMap});
  final void Function(List<ShowPlace> places, {String? comment})?
      onShowOnMap;

  @override
  State<ChatGPTPage> createState() => _ChatGPTPageState();
}

class _ChatGPTPageState extends State<ChatGPTPage> {
  final List<_ChatMsg> _messages = [];
  final TextEditingController _input = TextEditingController();
  bool _busy = false;
  bool _languageSelected = false; // 新增：是否已選擇語言

  static const double kTypingNudgeLeft = -60;
  static const double kTypingNudgeUp = -25;

  gm.LatLng? _chatMyLatLng;
  bool _csvLoadedForChat = false;
  List<_Place> _csvPlacesForChat = [];

  static const Map<String, List<String>> _chatKeywordSynonyms = {
    'taipei': ['台北', '臺北', '台北市', '臺北市'],
    'taipei city': ['台北', '臺北', '台北市', '臺北市'],
    'new taipei': ['新北', '新北市'],
    'taiwan': ['台灣', '臺灣'],
    'taoyuan': ['桃園', '桃園市'],
    'hsinchu': ['新竹', '新竹市'],
    'miaoli': ['苗栗', '苗栗縣'],
    'taichung': ['台中', '臺中', '台中市', '臺中市'],
    'changhua': ['彰化', '彰化縣'],
    'nantou': ['南投', '南投縣'],
    'yunlin': ['雲林', '雲林縣'],
    'chiayi': ['嘉義', '嘉義市'],
    'tainan': ['台南', '臺南', '台南市', '臺南市'],
    'kaohsiung': ['高雄', '高雄市'],
    'pingtung': ['屏東', '屏東縣'],
    'yilan': ['宜蘭', '宜蘭縣'],
    'hualien': ['花蓮', '花蓮縣'],
    'taitung': ['台東', '臺東', '台東縣', '臺東縣'],
    'penghu': ['澎湖', '澎湖縣'],
    'keelung': ['基隆', '基隆市'],
    'halal': ['清真'],
    'muslim': ['清真'],
    'muslim friendly': ['清真'],
    'halalan': ['清真'],
    'vegetarian': ['素食', '蔬食'],
    'vegan': ['素食', '蔬食'],
    'veg': ['素食', '蔬食'],
    'veggie': ['素食', '蔬食'],
    'plant-based': ['素食', '蔬食'],
    'gender friendly': ['性別友善'],
    'lgbt friendly': ['性別友善'],
    'lgbtq friendly': ['性別友善'],
    'family friendly': ['親子友善'],
    'kid friendly': ['親子友善'],
    'child friendly': ['親子友善'],
    'ramah gender': ['性別友善'],
    'ramah keluarga': ['親子友善'],
    'ramah anak': ['親子友善'],
    'keluarga': ['親子'],
    'anak': ['親子'],
  };

  String _normalizeForChatSearch(String input) {
    return input.toLowerCase().replaceAll('臺', '台').trim();
  }

  Set<String> _expandChatSearchTerms(String raw) {
    final base = _normalizeForChatSearch(raw);
    final terms = <String>{};
    if (base.isNotEmpty) {
      terms.add(base);
    }
    final tokens = base
        .split(RegExp(r'[\\s,;]+'))
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();
    terms.addAll(tokens);

    for (final entry in _chatKeywordSynonyms.entries) {
      final key = entry.key;
      final matchKey = key.trim();
      if (matchKey.isEmpty) continue;
      if (base.contains(matchKey) || tokens.contains(matchKey)) {
        for (final val in entry.value) {
          final normalizedVal = _normalizeForChatSearch(val);
          if (normalizedVal.isNotEmpty) {
            terms.add(normalizedVal);
          }
        }
      }
    }
    terms.removeWhere((t) => t.isEmpty);
    return terms;
  }

  Future<void> _ensureLocationForChat() async {
    try {
      final serviceEnabled =
          await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
      _chatMyLatLng = gm.LatLng(pos.latitude, pos.longitude);
    } catch (_) {}
  }

  Future<void> _ensureCsvLoadedForChat() async {
    if (_csvLoadedForChat) return;
    _csvPlacesForChat =
        List<_Place>.from(AppWarmUp.cachedPlaces ?? []);
    _csvLoadedForChat = true;
  }

  List<_Place> _csvSearchForChat(String raw) {
    final terms = _expandChatSearchTerms(raw);
    final hasTerms = terms.isNotEmpty;

    for (final p in _csvPlacesForChat) {
      if (_chatMyLatLng != null) {
        p.distanceMeters = Geolocator.distanceBetween(
          _chatMyLatLng!.latitude,
          _chatMyLatLng!.longitude,
          p.latLng.latitude,
          p.latLng.longitude,
        );
      } else {
        p.distanceMeters = double.infinity;
      }
    }

    final list = _csvPlacesForChat.where((p) {
      if (!hasTerms) return true;
      final sources = <String>{
        _normalizeForChatSearch(p.name),
        _normalizeForChatSearch(p.address),
        _normalizeForChatSearch(p.tag),
        _normalizeForChatSearch(p.nameEn),
        _normalizeForChatSearch(p.addressEn),
        _normalizeForChatSearch(p.tagEn),
        _normalizeForChatSearch(p.nameId),
        _normalizeForChatSearch(p.addressId),
        _normalizeForChatSearch(p.tagId),
      }..removeWhere((s) => s.isEmpty);
      if (sources.isEmpty) return false;
      return terms.any((term) =>
          sources.any((candidate) => candidate.contains(term)));
    }).toList();

    if (_chatMyLatLng != null) {
      list.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
    } else {
      list.sort((a, b) => a.name.compareTo(b.name));
    }
    return list;
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _busy) return;

    setState(() {
      _messages.add(_ChatMsg(role: 'user', text: text));
      _busy = true;
    });
    _input.clear();

    try {
      await _ensureLocationForChat();
      await _ensureCsvLoadedForChat();

      final localHits = _csvSearchForChat(text);

      if (localHits.isNotEmpty) {
        final top = localHits.take(5).toList();
        final buf = StringBuffer();
        final headerKey = _chatMyLatLng != null
            ? 'chat_local_found_with_distance'
            : 'chat_local_found_plain';
        buf.writeln(AppTranslations.get(headerKey));

        for (int i = 0; i < top.length; i++) {
          final p = top[i];
          final tel = p.tel.isEmpty ? '' : ' (${p.tel})';
          final tag = p.tag.isEmpty ? '' : ' | ${p.tag}';
          final dist = (_chatMyLatLng == null || p.distanceMeters.isInfinite)
              ? ''
              : ' | ${(p.distanceMeters / 1000).toStringAsFixed(1)} km';
          buf.writeln(
              '${i + 1}. ${p.name}$tag$dist\n   ${p.address}$tel');
        }

        final topShowPlaces = <ShowPlace>[
          for (final p in top)
            ShowPlace(
              name: p.name,
              address: p.address,
              tel: p.tel,
              tag: p.tag,
              lat: p.latLng.latitude,
              lon: p.latLng.longitude,
              nameEn: p.nameEn,
              addressEn: p.addressEn,
              tagEn: p.tagEn,
              nameId: p.nameId,
              addressId: p.addressId,
              tagId: p.tagId,
            )
        ];

        setState(() {
          _messages.add(_ChatMsg(
            role: 'assistant',
            text: buf.toString(),
            places: topShowPlaces,
            comment: _chatMyLatLng != null
                ? AppTranslations.get('chat_comment_sorted_by_distance')
                : null,
          ));
        });
        return;
      }

      final uri = Uri.parse('http://157.245.146.82/chat_route');
      final resp = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'chat_history': _messages
                  .map((m) => '${m.role}: ${m.text}')
                  .join('\n'),
              'last': text,
              'lat': _chatMyLatLng?.latitude,
              'lon': _chatMyLatLng?.longitude,
              'radius': 6000,
              'lang': AppTranslations.currentLang,
            }),
          )
          .timeout(const Duration(seconds: 120));

      if (resp.statusCode != 200) {
        final errPrefix = AppTranslations.get('chat_server_error');
        setState(() {
          _messages.add(_ChatMsg(
            role: 'assistant',
            text: '$errPrefix: ${resp.statusCode}\n${resp.body}',
          ));
        });
        return;
      }

      final data =
          jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
      final natural = (data['natural'] ?? '').toString();
      final items = (data['items'] as List?) ?? [];

      final buf = StringBuffer();
      if (natural.isNotEmpty) {
        buf.writeln(natural);
        buf.writeln('');
      }
      if (items.isNotEmpty) {
        buf.writeln(AppTranslations.get('chat_recommend_list'));
        for (int i = 0; i < items.length && i < 5; i++) {
          final e = items[i] as Map;
          final name = (e['Name'] ?? '').toString();
          final addr = (e['Address'] ?? '').toString();
          final tel = (e['Tel'] ?? '').toString();
          final tag = (e['tag'] ?? '').toString();

          double? distKm;
          if (_chatMyLatLng != null &&
              e['lat'] != null &&
              e['lon'] != null) {
            final d = Geolocator.distanceBetween(
              _chatMyLatLng!.latitude,
              _chatMyLatLng!.longitude,
              (e['lat'] as num).toDouble(),
              (e['lon'] as num).toDouble(),
            );
            distKm = d / 1000.0;
          }
          final distStr =
              (distKm == null) ? '' : ' | ${distKm.toStringAsFixed(1)} km';
          final telStr = tel.isEmpty ? '' : ' ($tel)';
          final tagStr = tag.isEmpty ? '' : ' | $tag';

          buf.writeln(
              '${i + 1}. $name$tagStr$distStr\n   $addr$telStr');
        }
      } else {
        buf.writeln(AppTranslations.get('chat_no_results'));
      }

      final topShowPlaces = <ShowPlace>[];
      for (int i = 0; i < items.length && i < 5; i++) {
        final e = items[i] as Map;
        final lat = (e['lat'] as num?)?.toDouble();
        final lon = (e['lon'] as num?)?.toDouble();
        if (lat == null || lon == null) continue;
        topShowPlaces.add(ShowPlace(
          name: (e['Name'] ?? '').toString(),
          address: (e['Address'] ?? '').toString(),
          tel: (e['Tel'] ?? '').toString(),
          tag: (e['tag'] ?? '').toString(),
          lat: lat,
          lon: lon,
          nameEn: (e['Name_en'] ?? '').toString(),
          addressEn: (e['Address_en'] ?? '').toString(),
          tagEn: (e['Tag_en'] ?? '').toString(),
          nameId: (e['Name_id'] ?? '').toString(),
          addressId: (e['Address_id'] ?? '').toString(),
          tagId: (e['Tag_id'] ?? '').toString(),
        ));
      }

      setState(() {
        _messages.add(_ChatMsg(
          role: 'assistant',
          text: buf.toString(),
          places: topShowPlaces.isEmpty ? null : topShowPlaces,
          comment:
              (natural.isEmpty) ? null : natural,
        ));
      });
    } catch (e) {
      setState(() {
        _messages
            .add(_ChatMsg(role: 'assistant', text: '錯誤：$e'));
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // 新增：語言選擇卡片（更美觀的設計）
  Widget _buildLanguageCard(String label, String code, String flag) {
    return InkWell(
      onTap: () {
        setState(() {
          AppTranslations.currentLang = code;
          _languageSelected = true;
          // 加入第一條歡迎訊息（用選定的語言）
          _messages.add(_ChatMsg(
            role: 'assistant',
            text: AppTranslations.get('need_restaurant'),
          ));
        });
      },
      child: Container(
        width: 300,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.deepPurple.withOpacity(0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.deepPurple.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Text(
              flag,
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.deepPurple,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 如果還沒選語言，顯示語言選擇畫面
    if (!_languageSelected) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Language / 語言 / Bahasa'),
          backgroundColor: Colors.black,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.language,
                  size: 80,
                  color: Colors.deepPurple,
                ),
                const SizedBox(height: 32),
                const Text(
                  'Please select your language\n請選擇您的語言\nSilakan pilih bahasa Anda',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 48),
                _buildLanguageCard('中文（繁體）', 'zh', '🇹🇼'),
                const SizedBox(height: 16),
                _buildLanguageCard('English', 'en', '🇬🇧'),
                const SizedBox(height: 16),
                _buildLanguageCard('Bahasa Indonesia', 'id', '🇮🇩'),
              ],
            ),
          ),
        ),
      );
    }

    // 已選語言後，顯示正常的聊天介面
    final listWithTyping = [
      ..._messages,
      if (_busy) _ChatMsg(role: 'typing', text: ''),
    ];

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(AppTranslations.get('chat_with_gpt')),
        backgroundColor: Colors.black,
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          children: [
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(12),
                reverse: false,
                itemCount: listWithTyping.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: 1),
                itemBuilder: (context, i) {
                  final m = listWithTyping[i];
                  final isUser = m.role == 'user';
                  final isTyping = m.role == 'typing';

                  if (isTyping) {
                    const double bubbleMaxWidth = 320;
                    const double bubbleHPad = 12;
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                            maxWidth: bubbleMaxWidth),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                              bubbleHPad, 4, bubbleHPad, 4),
                          child: Transform.translate(
                            offset: const Offset(
                                kTypingNudgeLeft,
                                kTypingNudgeUp),
                            child: SizedBox(
                              width: 162,
                              height: 84,
                              child: Lottie.asset(
                                'assets/chat_loading.json',
                                repeat: true,
                                alignment: Alignment.centerLeft,
                                fit: BoxFit.contain,
                                delegates: LottieDelegates(values: [
                                  ValueDelegate.opacity(['Bubble'],
                                      value: 0),
                                ]),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  return Align(
                    alignment: isUser
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints:
                          const BoxConstraints(maxWidth: 320),
                      child: Column(
                        crossAxisAlignment: isUser
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isUser
                                  ? Colors.deepPurple
                                      .withOpacity(0.85)
                                  : Colors.white.withOpacity(0.75),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              m.text,
                              style: TextStyle(
                                color: isUser
                                    ? Colors.white
                                    : Colors.black87,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          if (!isUser && m.hasPlaces) ...[
                            const SizedBox(height: 6),
                            OutlinedButton.icon(
                              icon: const Icon(Icons.map),
                              label: Text(AppTranslations.get('show_on_map')),
                              onPressed: () {
                                if (widget.onShowOnMap != null) {
                                  widget.onShowOnMap!
                                      .call(m.places!, comment: m.comment);
                                }
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            SafeArea(
              top: false,
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _input,
                      minLines: 1,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: AppTranslations.get('input_message'),
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _busy ? null : _send,
                    icon: _busy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send, size: 18),
                    label: Text(AppTranslations.get('send')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _ChatMsg {
  final String role;
  final String text;
  final List<ShowPlace>? places;
  final String? comment;

  _ChatMsg({
    required this.role,
    required this.text,
    this.places,
    this.comment,
  });

  bool get hasPlaces => (places != null && places!.isNotEmpty);
}
