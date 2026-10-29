import 'models.dart';

/// SAMPLE visitor guides for every town searchable on the Explore map.
/// Seasons, travel times and typical temperatures are approximate.
/// For full places, [TownGuide.riskyMonths] mirrors [Place.riskyMonths].
abstract final class TownGuides {
  static TownGuide? byId(String? id) => id == null ? null : _byId[id];

  static final Map<String, TownGuide> _byId = {
    for (final g in all) g.townId: g,
  };

  static const all = <TownGuide>[
    TownGuide(
      townId: 'tawang',
      district: 'Tawang',
      description:
          'High Monpa town around the 17th-century Tawang Monastery, the '
          'largest in India. Prayer-flag ridges, the Sela Pass drive and '
          'lakes like Pankang Teng Tso make it the classic Arunachal trip.',
      seasonHeadline: 'Tawang is best in winter',
      seasonIcon: SeasonIcon.snow,
      bestLabel: 'Nov–Feb',
      seasonDetail:
          'Snow on Sela Pass and the lakes in winter; Mar–Jun is also '
          'pleasant. Monsoon (Jul–Sep) brings landslide risk.',
      bestMonths: [11, 12, 1, 2, 3, 4, 5, 6],
      riskyMonths: [12, 1, 2, 7, 8],
      riskNote: 'Winter snow at Sela and monsoon landslides can delay travel.',
      reach: 'Tezpur · ~11 h by road via Sela Pass',
      typicalJanC: 5,
      typicalJulC: 19,
    ),
    TownGuide(
      townId: 'ziro',
      district: 'Lower Subansiri',
      description:
          'A wide pine-ringed valley of Apatani villages and rice-fish '
          'paddies. Known for tattooed elders, bamboo homes and the Ziro '
          'Festival of Music.',
      seasonHeadline: 'Ziro is best in spring when the flowers bloom',
      seasonIcon: SeasonIcon.flower,
      bestLabel: 'Mar–May',
      seasonDetail:
          'Ziro Festival of Music is in late September; the paddy fields '
          'are bright green in Jul–Aug.',
      bestMonths: [3, 4, 5, 9],
      riskyMonths: [6, 7, 8],
      riskNote: 'Monsoon makes roads slow and slippery.',
      reach: 'Naharlagun · ~4 h by road',
      typicalJanC: 12,
      typicalJulC: 25,
    ),
    TownGuide(
      townId: 'dirang',
      district: 'West Kameng',
      description:
          'A river valley with an old stone dzong, hot springs, kiwi and '
          'apple orchards and Monpa villages. A gentle stop before Sela.',
      seasonHeadline: 'Dirang is best in spring and autumn',
      seasonIcon: SeasonIcon.leaf,
      bestLabel: 'Mar–Jun · Oct–Nov',
      seasonDetail:
          'Orchards blossom in spring and skies clear in autumn; winters '
          'are cold but usually open.',
      bestMonths: [3, 4, 5, 6, 10, 11],
      riskyMonths: [7, 8],
      riskNote: 'Heavy rain in July–August.',
      reach: 'Tezpur · ~7 h by road',
      typicalJanC: 10,
      typicalJulC: 24,
    ),
    TownGuide(
      townId: 'bomdila',
      district: 'West Kameng',
      description:
          'A calm hill town on the road to Tawang with Buddhist gompas, a '
          'government craft centre and views over the Kameng valley.',
      seasonHeadline: 'Bomdila is best in spring and autumn',
      seasonIcon: SeasonIcon.leaf,
      bestLabel: 'Mar–Jun · Oct–Nov',
      seasonDetail: 'Pleasant spring and autumn; cold, clear winters.',
      bestMonths: [3, 4, 5, 6, 10, 11],
      riskyMonths: [7, 8],
      riskNote: 'Monsoon landslides possible on the Bhalukpong road.',
      reach: 'Tezpur · ~5 h by road',
      typicalJanC: 8,
      typicalJulC: 21,
    ),
    TownGuide(
      townId: 'sela',
      district: 'Tawang / West Kameng',
      description:
          'A 4,170 m pass with a sacred lake and army tea stalls on the '
          'only road to Tawang. Often snowbound in deep winter.',
      seasonHeadline: 'Sela is best in late spring and October',
      seasonIcon: SeasonIcon.snow,
      bestLabel: 'Apr–Jun · Oct',
      seasonDetail:
          'Snow views from November, but the pass can close after heavy '
          'snowfall.',
      bestMonths: [4, 5, 6, 10],
      riskyMonths: [12, 1, 2, 3],
      riskNote: 'Snowfall can block the pass; ask locally before crossing.',
      reach: 'Tezpur · ~9 h by road',
      typicalJanC: -6,
      typicalJulC: 9,
    ),
    TownGuide(
      townId: 'itanagar',
      district: 'Papum Pare',
      description:
          'The state capital, with the Ita Fort ruins, Ganga Lake and the '
          'Jawaharlal Nehru State Museum. A good base for permits and '
          'supplies.',
      seasonHeadline: 'Itanagar is best in the cool dry months',
      seasonIcon: SeasonIcon.sun,
      bestLabel: 'Oct–Apr',
      seasonDetail: 'Warm and humid in summer; mild, dry winters.',
      bestMonths: [10, 11, 12, 1, 2, 3, 4],
      riskyMonths: [6, 7, 8],
      riskNote: 'Monsoon rain and landslides on approach roads.',
      reach: 'Naharlagun · ~30 min by road',
      typicalJanC: 19,
      typicalJulC: 31,
    ),
    TownGuide(
      townId: 'mechuka',
      district: 'Shi Yomi',
      description:
          'A remote valley near the Tibet border with the 400-year-old '
          'Samten Yongcha gompa, Memba villages and the Yargyap Chu river.',
      seasonHeadline: 'Mechuka is best from autumn to spring',
      seasonIcon: SeasonIcon.leaf,
      bestLabel: 'Oct–Apr',
      seasonDetail:
          'Clear autumn skies and snow-dusted winters; the long road is '
          'hardest in the monsoon.',
      bestMonths: [10, 11, 12, 1, 2, 3, 4],
      riskyMonths: [6, 7, 8, 12, 1],
      riskNote: 'Long drive via Aalo; landslides in monsoon, snow in winter.',
      reach: 'Dibrugarh · ~11 h by road via Aalo',
      typicalJanC: 4,
      typicalJulC: 18,
      aliases: ['Menchuka'],
    ),
    TownGuide(
      townId: 'namdapha',
      district: 'Changlang',
      description:
          'Namdapha National Park, entered from Miao, is one of the few '
          'places with four big cats. Tibetan and Lisu settlements sit '
          'near the park gate.',
      seasonHeadline: 'Namdapha is best in the dry season',
      seasonIcon: SeasonIcon.sun,
      bestLabel: 'Oct–Apr',
      seasonDetail: 'Dry trails and good birding in winter; Jan–Feb is peak.',
      bestMonths: [10, 11, 12, 1, 2, 3, 4],
      riskyMonths: [5, 6, 7, 8, 9],
      riskNote: 'Leeches, swollen rivers and closed trails in the monsoon.',
      reach: 'Dibrugarh · ~5 h by road to Miao',
      typicalJanC: 18,
      typicalJulC: 30,
      aliases: ['Miao'],
    ),
    TownGuide(
      townId: 'longding',
      district: 'Longding',
      description:
          'Hill town of the Wancho people, known for wood carving, beadwork '
          'and tattoo traditions. Villages like Pongchau keep old '
          'morungs (dormitories).',
      seasonHeadline: 'Longding is best in winter',
      seasonIcon: SeasonIcon.sun,
      bestLabel: 'Nov–Mar',
      seasonDetail: 'Dry and mild in winter; very wet in the monsoon.',
      bestMonths: [11, 12, 1, 2, 3],
      riskyMonths: [6, 7, 8],
      riskNote: 'Landslides on hill roads in the monsoon.',
      reach: 'Dibrugarh · ~5 h by road',
      typicalJanC: 16,
      typicalJulC: 28,
    ),
    TownGuide(
      townId: 'changlang',
      district: 'Changlang',
      description:
          'District town and gateway to Namdapha, home to Tangsa, Tutsa '
          'and Singpho communities. Nearby are the Pangsau Pass on the '
          'Myanmar border and the WWII Stilwell Road.',
      seasonHeadline: 'Changlang is best in the cool dry months',
      seasonIcon: SeasonIcon.sun,
      bestLabel: 'Oct–Mar',
      seasonDetail:
          'The Pangsau Pass Winter Festival is in January; summers are hot '
          'and wet.',
      bestMonths: [10, 11, 12, 1, 2, 3],
      riskyMonths: [6, 7, 8],
      riskNote: 'Heavy monsoon rain can cut hill roads.',
      reach: 'Dibrugarh · ~4 h by road',
      typicalJanC: 18,
      typicalJulC: 30,
    ),
    TownGuide(
      townId: 'roing',
      district: 'Lower Dibang Valley',
      description:
          'Idu Mishmi town at the foot of the hills, with Mehao Lake and '
          'the scenic drive up to Mayudia Pass.',
      seasonHeadline: 'Roing is best in autumn and winter',
      seasonIcon: SeasonIcon.leaf,
      bestLabel: 'Oct–Mar',
      seasonDetail: 'Snow at Mayudia in Jan–Feb; monsoon brings landslides.',
      bestMonths: [10, 11, 12, 1, 2, 3],
      riskyMonths: [6, 7, 8],
      riskNote: 'Landslides on the Mayudia road in the monsoon.',
      reach: 'Dibrugarh · ~4 h by road',
      typicalJanC: 17,
      typicalJulC: 30,
    ),
    TownGuide(
      townId: 'pasighat',
      district: 'East Siang',
      description:
          'The oldest town in Arunachal, on the banks of the Siang where it '
          'leaves the hills. Adi villages, river beaches and the Daying '
          'Ering bird sanctuary are close by.',
      seasonHeadline: 'Pasighat is best in winter',
      seasonIcon: SeasonIcon.sun,
      bestLabel: 'Nov–Mar',
      seasonDetail: 'Solung festival in September; summers are hot and wet.',
      bestMonths: [11, 12, 1, 2, 3],
      riskyMonths: [6, 7, 8],
      riskNote: 'The Siang floods in the monsoon.',
      reach: 'Dibrugarh · ~3 h by road',
      typicalJanC: 19,
      typicalJulC: 32,
    ),
    TownGuide(
      townId: 'aalo',
      district: 'West Siang',
      description:
          'Galo town (also called Along) at the meeting of the Siyom and '
          'Yomgo rivers, with orange orchards and hanging bridges. A stop '
          'on the way to Mechuka.',
      seasonHeadline: 'Aalo is best in autumn and spring',
      seasonIcon: SeasonIcon.leaf,
      bestLabel: 'Oct–Apr',
      seasonDetail: 'Mopin festival in April; oranges ripen in winter.',
      bestMonths: [10, 11, 12, 1, 2, 3, 4],
      riskyMonths: [6, 7, 8],
      riskNote: 'Monsoon landslides on the trans-Arunachal highway.',
      reach: 'Dibrugarh · ~7 h by road',
      typicalJanC: 16,
      typicalJulC: 29,
      aliases: ['Along'],
    ),
    TownGuide(
      townId: 'daporijo',
      district: 'Upper Subansiri',
      description:
          'Tagin and Hill Miri town on the Subansiri river, with rope '
          'bridges and the Sippi valley nearby. Few tourists, warm '
          'hospitality.',
      seasonHeadline: 'Daporijo is best in winter',
      seasonIcon: SeasonIcon.sun,
      bestLabel: 'Oct–Mar',
      seasonDetail: 'Si-Donyi festival in January; heavy summer rain.',
      bestMonths: [10, 11, 12, 1, 2, 3],
      riskyMonths: [6, 7, 8],
      riskNote: 'Landslides between Ziro and Daporijo in the monsoon.',
      reach: 'North Lakhimpur · ~6 h by road',
      typicalJanC: 16,
      typicalJulC: 29,
    ),
    TownGuide(
      townId: 'tezu',
      district: 'Lohit',
      description:
          'Mishmi and Khamti town on the Lohit plains, close to the '
          'Parshuram Kund pilgrimage site and the road to Walong.',
      seasonHeadline: 'Tezu is best in winter',
      seasonIcon: SeasonIcon.sun,
      bestLabel: 'Nov–Mar',
      seasonDetail: 'Parshuram Kund Mela in mid-January draws big crowds.',
      bestMonths: [11, 12, 1, 2, 3],
      riskyMonths: [6, 7, 8],
      riskNote: 'The Lohit floods and roads wash out in the monsoon.',
      reach: 'Dibrugarh · ~4 h by road',
      typicalJanC: 18,
      typicalJulC: 31,
    ),
    TownGuide(
      townId: 'khonsa',
      district: 'Tirap',
      description:
          'Hilltop town of the Nocte people, with chieftain villages, '
          'tea gardens on the slopes and views over Tirap.',
      seasonHeadline: 'Khonsa is best in winter',
      seasonIcon: SeasonIcon.sun,
      bestLabel: 'Nov–Mar',
      seasonDetail: 'Chalo Loku festival in November; wet summers.',
      bestMonths: [11, 12, 1, 2, 3],
      riskyMonths: [6, 7, 8],
      riskNote: 'Landslides on hill roads in the monsoon.',
      reach: 'Dibrugarh · ~4 h by road',
      typicalJanC: 15,
      typicalJulC: 27,
    ),
    TownGuide(
      townId: 'anini',
      district: 'Dibang Valley',
      description:
          'Remote Idu Mishmi town deep in the Dibang Valley, ringed by '
          'snowy ridges. One of the least visited district towns in India.',
      seasonHeadline: 'Anini is best in spring and autumn',
      seasonIcon: SeasonIcon.flower,
      bestLabel: 'Mar–May · Oct–Nov',
      seasonDetail: 'Winters are cold and the road can close after snow.',
      bestMonths: [3, 4, 5, 10, 11],
      riskyMonths: [6, 7, 8, 12, 1],
      riskNote: 'Long mountain road; landslides and winter snow.',
      reach: 'Dibrugarh · ~10 h by road via Roing',
      typicalJanC: 4,
      typicalJulC: 19,
    ),
    TownGuide(
      townId: 'seppa',
      district: 'East Kameng',
      description:
          'Nyishi town on the Kameng river, a quiet base for river camps '
          'and the Pakke-Kessang hills.',
      seasonHeadline: 'Seppa is best in winter',
      seasonIcon: SeasonIcon.sun,
      bestLabel: 'Oct–Mar',
      seasonDetail: 'Nyokum festival in February; very wet summers.',
      bestMonths: [10, 11, 12, 1, 2, 3],
      riskyMonths: [6, 7, 8],
      riskNote: 'Landslides on the Bhalukpong–Seppa road in the monsoon.',
      reach: 'Tezpur · ~7 h by road',
      typicalJanC: 16,
      typicalJulC: 29,
    ),
  ];
}
