/// Plain data models. All content in this MVP is local mock data.
library;

import 'dart:math' as math;

class TravelLeg {
  const TravelLeg(this.km, this.hours, {this.estimated = false});

  /// Approximate road distance in kilometres.
  final int km;

  /// Approximate driving time on hill roads, in hours.
  final double hours;

  /// True when computed from coordinates rather than a known road figure.
  final bool estimated;
}

class Hub {
  const Hub({
    required this.id,
    required this.name,
    required this.kind,
    required this.state,
    required this.lat,
    required this.lng,
  });

  final String id;
  final String name;

  /// e.g. "Airport · Railway"
  final String kind;
  final String state;
  final double lat;
  final double lng;
}

class Place {
  const Place({
    required this.id,
    required this.name,
    required this.district,
    required this.tagline,
    required this.description,
    required this.altitudeM,
    required this.lat,
    required this.lng,
    required this.bestMonths,
    required this.riskyMonths,
    required this.seasonNote,
    required this.riskNote,
    required this.fromHubs,
    required this.suggestedDays,
    required this.routeOrder,
    required this.howToReach,
  });

  final String id;
  final String name;
  final String district;
  final String tagline;
  final String description;
  final int altitudeM;
  final double lat;
  final double lng;

  /// Months (1–12) generally considered the best time to visit.
  final List<int> bestMonths;

  /// Months (1–12) with snow, landslides or monsoon closures.
  final List<int> riskyMonths;
  final String seasonNote;
  final String riskNote;

  /// Hub id -> approximate road leg.
  final Map<String, TravelLeg> fromHubs;
  final int suggestedDays;

  /// Natural order on a circuit (used to order the selected places).
  final int routeOrder;
  final String howToReach;

  SeasonStatus statusFor(int month) {
    if (riskyMonths.contains(month)) return SeasonStatus.risky;
    if (bestMonths.contains(month)) return SeasonStatus.best;
    return SeasonStatus.okay;
  }
}

enum SeasonStatus { best, okay, risky }

enum HostType { homestay, guide, driver }

extension HostTypeLabel on HostType {
  String get label => switch (this) {
    HostType.homestay => 'Homestay',
    HostType.guide => 'Guide',
    HostType.driver => 'Driver',
  };
}

/// Average rating plus who gave it. [womenCount] and [menCount] are the
/// raters who stated a gender; the rest of [count] chose not to say.
///
/// The split is shown everywhere a rating appears so that women travelling
/// alone can see whether other women rated a stay, guide or product highly.
class RatingBreakdown {
  const RatingBreakdown({
    required this.average,
    required this.count,
    required this.womenCount,
    required this.menCount,
  }) : assert(womenCount >= 0 && menCount >= 0),
       assert(womenCount + menCount <= count);

  /// "Women recommended" needs at least this share of women among raters
  /// who stated a gender...
  static const womenRecommendedShare = 0.60;

  /// ...and at least this average rating.
  static const womenRecommendedMinAverage = 4.0;

  final double average;
  final int count;
  final int womenCount;
  final int menCount;

  /// Raters who stated a gender; percentages are based on these.
  int get statedCount => womenCount + menCount;
  bool get hasGenderData => statedCount > 0;

  /// 0.0–1.0 share of women among raters who stated a gender (0 if none).
  double get womenShare => hasGenderData ? womenCount / statedCount : 0;

  /// 0.0–1.0 share of men among raters who stated a gender (0 if none).
  double get menShare => hasGenderData ? menCount / statedCount : 0;

  /// Whole-number percentages that always add up to 100 (or both 0).
  int get womenPercent => hasGenderData ? (womenShare * 100).round() : 0;
  int get menPercent => hasGenderData ? 100 - womenPercent : 0;

  bool get isWomenRecommended =>
      count > 0 &&
      hasGenderData &&
      womenShare >= womenRecommendedShare &&
      average >= womenRecommendedMinAverage;

  /// Screen-reader description, e.g. "Rated 4.2 by 120 people,
  /// 48 percent women, 52 percent men".
  String get semanticsLabel {
    if (count == 0) return 'No ratings yet';
    final people = count == 1 ? 'person' : 'people';
    final base = 'Rated ${average.toStringAsFixed(1)} by $count $people';
    if (!hasGenderData) return '$base, gender not stated';
    return '$base, $womenPercent percent women, $menPercent percent men'
        '${isWomenRecommended ? '. Women recommended' : ''}';
  }
}

class Host {
  const Host({
    required this.id,
    required this.name,
    required this.type,
    required this.placeId,
    required this.ratings,
    required this.price,
    required this.verified,
    required this.listedViaSms,
    required this.languages,
    required this.about,
  });

  final String id;
  final String name;
  final HostType type;
  final String placeId;

  /// Average score, review count and the women / men split of raters.
  final RatingBreakdown ratings;
  double get rating => ratings.average;
  int get reviews => ratings.count;
  final String price;
  final bool verified;

  /// Hosts with little digital experience can list by SMS; travellers then
  /// get a call/SMS-friendly contact flow.
  final bool listedViaSms;
  final List<String> languages;
  final String about;
}

class Craft {
  const Craft({
    required this.id,
    required this.name,
    required this.origin,
    required this.townIds,
    required this.fairPrice,
    required this.ratings,
    required this.description,
    this.category = ShopCategory.craft,
  });

  /// Stable id; also seeds the placeholder shop coordinates.
  final String id;
  final String name;
  final String origin;

  /// Towns ([MapTown.id]) where this craft is sold. The first is its home.
  final List<String> townIds;
  final String fairPrice;

  /// Average score, review count and the women / men split of raters.
  final RatingBreakdown ratings;
  double get rating => ratings.average;
  int get reviews => ratings.count;
  final String description;

  /// What kind of place sells it (workshop, handloom, food stall, …).
  final ShopCategory category;
}

/// Type of a craft / shop point of interest on the Explore map.
enum ShopCategory {
  craft('Craft workshop'),
  handloom('Handloom'),
  painting('Art studio'),
  woodwork('Wood carving'),
  caneBamboo('Cane & bamboo'),
  food('Local food'),
  souvenir('Souvenirs'),
  emporium('Emporium');

  const ShopCategory(this.label);
  final String label;
}

/// A traveller phrase. Text phrases carry the [local] wording and a
/// [pronunciation] hint; voice phrases carry a bundled [audioAsset] clip
/// recorded in the language. A phrase can have either or both, so any
/// tribe can get voice clips later without changing the UI.
class Phrase {
  const Phrase({
    required this.english,
    this.local = '',
    this.pronunciation = '',
    this.audioAsset,
  });

  /// A phrase that is only a recorded clip (no written local wording yet).
  const Phrase.voice({required this.english, required String asset})
    : local = '',
      pronunciation = '',
      audioAsset = asset;

  final String english;
  final String local;
  final String pronunciation;

  /// Full Flutter asset path of a bundled audio clip, e.g.
  /// `assets/audio/khamti/hello.mp3`. Null when there is no recording.
  final String? audioAsset;

  bool get hasAudio => audioAsset != null;
  bool get hasLocalText => local.isNotEmpty;
}

class PhraseLanguage {
  const PhraseLanguage({
    required this.name,
    required this.where,
    required this.phrases,
    this.needsVerification = false,
  });

  final String name;
  final String where;
  final List<Phrase> phrases;
  final bool needsVerification;
}

class CommunitySpot {
  const CommunitySpot({
    required this.name,
    required this.near,
    required this.addedBy,
    required this.confirmations,
    required this.photos,
  });

  static const requiredConfirmations = 5;

  final String name;
  final String near;
  final String addedBy;
  final int confirmations;
  final int photos;

  bool get isConfirmedReal => confirmations >= requiredConfirmations;
}

enum BookingStatus { pending, confirmed, completed, cancelled }

class Booking {
  const Booking({
    required this.id,
    required this.guest,
    required this.item,
    required this.dates,
    required this.guests,
    required this.amount,
    required this.status,
    required this.upcoming,
  });

  final String id;
  final String guest;
  final String item;
  final String dates;
  final int guests;
  final String amount;
  final BookingStatus status;
  final bool upcoming;

  Booking copyWith({BookingStatus? status}) => Booking(
    id: id,
    guest: guest,
    item: item,
    dates: dates,
    guests: guests,
    amount: amount,
    status: status ?? this.status,
    upcoming: upcoming,
  );
}

// ---------------------------------------------------------------------------
// Traveller redesign: map points, emergency info, stays, guides and tribes.
// ---------------------------------------------------------------------------

/// What a pin on the Explore map represents. The last four are emergency
/// points shown only in emergency mode, plus [pharmacy] (added last).
enum PoiKind {
  sight,
  nature,
  craft,
  food,
  stay,
  hospital,
  police,
  army,
  fire,
  pharmacy,
}

extension PoiKindInfo on PoiKind {
  bool get isEmergency => switch (this) {
    PoiKind.hospital ||
    PoiKind.police ||
    PoiKind.army ||
    PoiKind.fire ||
    PoiKind.pharmacy => true,
    _ => false,
  };

  String get label => switch (this) {
    PoiKind.sight => 'Sight',
    PoiKind.nature => 'Nature',
    PoiKind.craft => 'Crafts',
    PoiKind.food => 'Food',
    PoiKind.stay => 'Stay',
    PoiKind.hospital => 'Hospital',
    PoiKind.police => 'Police',
    PoiKind.army => 'Army post',
    PoiKind.fire => 'Fire station',
    PoiKind.pharmacy => 'Pharmacy',
  };
}

class MapPoi {
  const MapPoi({
    required this.name,
    required this.kind,
    required this.lat,
    required this.lng,
    this.note = '',
    this.phone,
    this.placeId,
  });

  final String name;
  final PoiKind kind;
  final double lat;
  final double lng;
  final String note;

  /// Optional phone for emergency points (mock).
  final String? phone;

  /// Opens this place's detail page when tapped.
  final String? placeId;
}

/// A town that can be focused on the Explore map. Most towns are [Place]s;
/// a few craft towns (e.g. Longding) are only used for shop pins.
class MapTown {
  const MapTown({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
  });

  final String id;
  final String name;
  final double lat;
  final double lng;
}

/// A shop or maker selling a [Craft] in one town, shown as a map pin.
/// All shops are SAMPLE data until the real crafts/shops API exists.
class CraftShop {
  const CraftShop({
    required this.id,
    required this.craft,
    required this.townId,
    required this.townName,
    required this.lat,
    required this.lng,
  });

  /// `<craft id>@<town id>`, unique and stable.
  final String id;
  final Craft craft;
  final String townId;
  final String townName;
  final double lat;
  final double lng;
}

class EmergencyContact {
  const EmergencyContact({
    required this.number,
    required this.label,
    required this.note,
  });

  final String number;
  final String label;
  final String note;
}

enum Amenity {
  kitchen,
  wifi,
  parking,
  laundry,
  fireplace,
  hotWater,
  breakfast,
  mountainView,
  riverView,
  bonfire,
}

extension AmenityLabel on Amenity {
  String get label => switch (this) {
    Amenity.kitchen => 'Kitchen',
    Amenity.wifi => 'Wi-Fi',
    Amenity.parking => 'Parking',
    Amenity.laundry => 'Laundry',
    Amenity.fireplace => 'Fireplace',
    Amenity.hotWater => 'Hot water',
    Amenity.breakfast => 'Breakfast',
    Amenity.mountainView => 'Mountain view',
    Amenity.riverView => 'River view',
    Amenity.bonfire => 'Bonfire',
  };
}

class Stay {
  const Stay({
    required this.id,
    required this.name,
    required this.hostName,
    required this.placeId,
    required this.location,
    required this.bedrooms,
    required this.beds,
    required this.maxGuests,
    required this.pricePerNight,
    required this.serviceFee,
    required this.ratings,
    required this.amenities,
    required this.phone,
    required this.about,
    required this.tripName,
    required this.tripDays,
    required this.palette,
    required this.verified,
  });

  final String id;
  final String name;

  /// Host / homestay name shown in the detail header, e.g. "Hage Homestay".
  final String hostName;
  final String placeId;
  final String location;
  final int bedrooms;
  final int beds;
  final int maxGuests;
  final int pricePerNight;

  /// Flat cleaning + service fee per booking (mock), included in totals.
  final int serviceFee;

  /// Average score, review count and the women / men split of raters.
  final RatingBreakdown ratings;
  double get rating => ratings.average;
  int get reviews => ratings.count;
  final List<Amenity> amenities;

  /// Sample phone number (not a real host).
  final String phone;
  final String about;

  /// Suggested trip built around the stay, e.g. "Ziro" -> "3-Day Ziro Trip".
  final String tripName;
  final int tripDays;

  /// Index into the placeholder photo palettes.
  final int palette;
  final bool verified;

  int totalFor(int nights) => pricePerNight * nights + serviceFee;
}

class GuideTrait {
  const GuideTrait(this.title, this.body);
  final String title;
  final String body;
}

class GuideScore {
  const GuideScore(this.label, this.score);
  final String label;

  /// Out of 5.
  final double score;
}

class PastTrip {
  const PastTrip(this.name, this.area, this.kind);
  final String name;
  final String area;

  /// Drives the placeholder icon: waterfall, trek, lake, valley, monastery.
  final String kind;
}

class Guide {
  const Guide({
    required this.id,
    required this.name,
    required this.tribe,
    required this.placeId,
    required this.location,
    required this.years,
    required this.languages,
    required this.specialty,
    required this.bio,
    required this.traits,
    required this.scores,
    required this.ratings,
    required this.pricePerDay,
    required this.phone,
    required this.pastTrips,
    required this.palette,
    required this.verified,
  });

  final String id;
  final String name;
  final String tribe;
  final String placeId;
  final String location;
  final int years;
  final List<String> languages;
  final String specialty;
  final String bio;
  final List<GuideTrait> traits;
  final List<GuideScore> scores;

  /// Average score, review count and the women / men split of raters.
  final RatingBreakdown ratings;
  double get rating => ratings.average;
  int get reviews => ratings.count;
  final int pricePerDay;

  /// Sample phone number (not a real guide).
  final String phone;
  final List<PastTrip> pastTrips;
  final int palette;
  final bool verified;

  String get initials => name
      .split(' ')
      .where((w) => w.isNotEmpty)
      .take(2)
      .map((w) => w[0])
      .join();
}

class Tribe {
  const Tribe({
    required this.name,
    required this.region,
    required this.description,
    required this.festivals,
    this.phraseLanguage,
    this.nearYou = false,
  });

  final String name;
  final String region;
  final String description;
  final String festivals;

  /// Name of a [PhraseLanguage] with phrases for this tribe, if any.
  final String? phraseLanguage;

  /// Suggested for the user's (mock) location.
  final bool nearYou;
}

/// Icon family for a town's best-season chip.
enum SeasonIcon { snow, flower, sun, leaf }

/// Short visitor guide for any town searchable on the Explore map (full
/// [Place]s and map-only towns): shown in the info card below the map and
/// in the expanded "Places & Guides" cards. Sample content.
class TownGuide {
  const TownGuide({
    required this.townId,
    required this.district,
    required this.description,
    required this.seasonHeadline,
    required this.seasonIcon,
    required this.bestLabel,
    required this.seasonDetail,
    required this.bestMonths,
    required this.riskyMonths,
    required this.riskNote,
    required this.reach,
    required this.typicalJanC,
    required this.typicalJulC,
    this.aliases = const [],
  });

  /// [MapTown.id]; also the [Place.id] when the town is a full place.
  final String townId;
  final String district;

  /// 2–3 sentences.
  final String description;

  /// e.g. "Tawang is best in winter".
  final String seasonHeadline;
  final SeasonIcon seasonIcon;

  /// e.g. "Nov–Feb".
  final String bestLabel;

  /// One line of nuance about the other seasons.
  final String seasonDetail;

  /// Months (1–12); for full places these match [Place.riskyMonths].
  final List<int> bestMonths;
  final List<int> riskyMonths;
  final String riskNote;

  /// Nearest hub and approximate road time, e.g. "Tezpur · ~11 h by road".
  final String reach;

  /// Typical daytime temperature (°C) in January and July; other months
  /// are interpolated (see [typicalC]). Used when no live/cached weather.
  final int typicalJanC;
  final int typicalJulC;

  /// Other names people search for (e.g. "Along" for Aalo).
  final List<String> aliases;

  /// Seasonal typical temperature for [month] (1–12), cosine-interpolated
  /// between the January low and the July high.
  int typicalC(int month) {
    final mid = (typicalJanC + typicalJulC) / 2;
    final amp = (typicalJulC - typicalJanC) / 2;
    return (mid - amp * math.cos(2 * math.pi * (month - 1) / 12)).round();
  }
}
