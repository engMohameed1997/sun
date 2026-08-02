import 'package:flutter/material.dart';

class ProductModel {
  final String id;
  final String name;
  final String brand;
  final String store;
  final String category;
  final String priceIQD;
  final int priceRaw;
  final double priceUSD;
  final String assetImage;
  final String rating;
  final String warranty;
  final int stock;
  final String type;
  final Map<String, String> specs;
  final bool isFeatured;
  final String? discountTag;
  final String? originalPriceIQD;

  const ProductModel({
    required this.id,
    required this.name,
    required this.brand,
    required this.store,
    required this.category,
    required this.priceIQD,
    required this.priceRaw,
    required this.priceUSD,
    required this.assetImage,
    required this.rating,
    required this.warranty,
    required this.stock,
    required this.type,
    required this.specs,
    this.isFeatured = false,
    this.discountTag,
    this.originalPriceIQD,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'store': store,
      'category': category,
      'price': priceIQD,
      'priceIQD': priceIQD,
      'price_iqd': priceRaw,
      'price_usd': priceUSD,
      'image': assetImage,
      'assetImage': assetImage,
      'rating': rating,
      'warranty': warranty,
      'stock': stock,
      'type': type,
      'specs': specs,
      'isFeatured': isFeatured,
      'discountTag': discountTag,
      'originalPriceIQD': originalPriceIQD,
    };
  }
}

class MockProductsRepository {
  static const List<ProductModel> products = [
    ProductModel(
      id: 'p1',
      name: 'لوح طاقة شمسية LONGi 550W N-Type TOPCon',
      brand: 'LONGi Solar',
      store: 'متجر بغداد للطاقة الشمولية',
      category: 'ألواح شمسية',
      priceIQD: '175,000 د.ع',
      priceRaw: 175000,
      priceUSD: 115.0,
      assetImage: 'assets/images/solar_panel_longi.jpg',
      rating: '4.9 ⭐ (128 تقييم)',
      warranty: '25 سنة كفالة كفاءة وتوليد',
      stock: 140,
      type: 'panel',
      isFeatured: true,
      specs: {
        'القدرة الاسمية': '550 Watt',
        'التكنولوجيا': 'N-Type TOPCon Dual Glass',
        'الكفاءة': '22.5%',
        'الجهد التشغيلي': '41.95V',
        'التيار التشغيلي': '13.12A',
        'درجة الحماية': 'IP68 waterproof',
        'المنشأ': 'الصين - ضمان الشركة الأُم',
      },
    ),
    ProductModel(
      id: 'p2',
      name: 'انفيرتر هجين Deye 8kW Three Phase 48V',
      brand: 'Deye',
      store: 'دجلة للحلول الشمسية الهجينة',
      category: 'انفيرترات هجينة',
      priceIQD: '1,875,000 د.ع',
      priceRaw: 1875000,
      priceUSD: 1225.0,
      assetImage: 'assets/images/inverter_deye.jpg',
      rating: '4.8 ⭐ (84 تقييم)',
      warranty: '5 سنوات كفالة استبدال فورية',
      stock: 24,
      type: 'inverter',
      isFeatured: true,
      discountTag: 'خصم 10% ⚡',
      originalPriceIQD: '2,100,000 د.ع',
      specs: {
        'القدرة القصوى': '8000W / 3-Phase 380V',
        'دعم المولدات': 'نظام التشغيل التلقائي (Auto Gen Start)',
        'شاشة اللمس': 'LCD الملونة عالية الدقة',
        'شاحن الطاقة': '190A MPPT Dual Solar Input',
        'المراقبة الذكية': 'Wi-Fi Cloud App Integration',
      },
    ),
    ProductModel(
      id: 'p3',
      name: 'بطارية ليثيوم Felicity 10.2kWh LiFePO4 48V',
      brand: 'Felicity Solar',
      store: 'البصرة سولار تك المعتمد',
      category: 'بطاريات ليثيوم',
      priceIQD: '2,175,000 د.ع',
      priceRaw: 2175000,
      priceUSD: 1420.0,
      assetImage: 'assets/images/battery_felicity.jpg',
      rating: '4.9 ⭐ (96 تقييم)',
      warranty: '10 سنوات كفالة (6000 دورة تفريغ)',
      stock: 35,
      type: 'battery',
      isFeatured: true,
      discountTag: 'خصم 15% 🔥',
      originalPriceIQD: '2,500,000 د.ع',
      specs: {
        'السعة التخزينية': '10.24 kWh',
        'الفولتية الاسمية': '51.2V 200Ah',
        'تقنية الخلايا': 'LiFePO4 الفوسفات الأمنيوم',
        'نظام BMS': 'Smart BMS مع حماية الشحن الزائد',
        'التثبيت': 'جداري / أرضي مقاوم للحرارة',
      },
    ),
    ProductModel(
      id: 'p4',
      name: 'منظومة سخان شمسي حراري 200 لتر استانلس',
      brand: 'SolarMax Ultra',
      store: 'النجف تكنولوجي للطاقة النظيفة',
      category: 'سخانات شمسية',
      priceIQD: '580,000 د.ع',
      priceRaw: 580000,
      priceUSD: 380.0,
      assetImage: 'assets/images/solar_water_heater.jpg',
      rating: '4.7 ⭐ (52 تقييم)',
      warranty: '3 سنوات كفالة عزل وهيكل',
      stock: 18,
      type: 'heater',
      isFeatured: true,
      specs: {
        'سعة خزان المياه': '200 Liters',
        'أنابيب التفريغ': '20 أنبوب زجاجي أنودايزد 58mm',
        'مادة الخزان': 'Stainless Steel 304 العراقي المقاوم للصدأ',
        'العزل الحراري': 'Polyurethane High-Density 55mm',
      },
    ),
    ProductModel(
      id: 'p5',
      name: 'جهاز مراقبة العداد الذكي SolarGuard Wi-Fi',
      brand: 'SolarGuard IoT',
      store: 'متجر بغداد للطاقة الشمولية',
      category: 'ملحقات وكيبلات',
      priceIQD: '85,000 د.ع',
      priceRaw: 85000,
      priceUSD: 55.0,
      assetImage: 'assets/images/smart_solar_meter.jpg',
      rating: '4.9 ⭐ (110 تقييم)',
      warranty: 'سنة واحدة استبدال',
      stock: 65,
      type: 'accessory',
      specs: {
        'الاتصال': 'Wi-Fi 2.4GHz + Bluetooth 5.0',
        'قراءة الجهد': '80V - 300V AC Real-time',
        'قياس الطاقة': 'كشف سحب الوطنية والمولد والشمسي',
        'التنبيهات': 'إشعارات فورية عند الانقطاع والتحميل الزائد',
      },
    ),
    ProductModel(
      id: 'p6',
      name: 'لوح طاقة Jinko Tiger Neo 575W Bifacial',
      brand: 'Jinko Solar',
      store: 'دجلة للحلول الشمسية الهجينة',
      category: 'ألواح شمسية',
      priceIQD: '185,000 د.ع',
      priceRaw: 185000,
      priceUSD: 120.0,
      assetImage: 'assets/images/solar_panel_longi.jpg',
      rating: '4.9 ⭐ (75 تقييم)',
      warranty: '30 سنة كفالة الأداء',
      stock: 95,
      type: 'panel',
      specs: {
        'القدرة الاسمية': '575 Watt Bifacial (توليد وجهين)',
        'الكفاءة الكلية': '22.8%',
        'حماية PID': 'مقاومة كاملة للتدهور والتآكل',
      },
    ),
    ProductModel(
      id: 'p7',
      name: 'انفيرتر هجين Growatt SPF 5000ES 5kW 48V',
      brand: 'Growatt',
      store: 'النجف تكنولوجي للطاقة النظيفة',
      category: 'انفيرترات هجينة',
      priceIQD: '1,150,000 د.ع',
      priceRaw: 1150000,
      priceUSD: 750.0,
      assetImage: 'assets/images/inverter_deye.jpg',
      rating: '4.8 ⭐ (63 تقييم)',
      warranty: '3 سنوات كفالة صيانة ومتابعة',
      stock: 30,
      type: 'inverter',
      specs: {
        'القدرة القصوى': '5000W 230V Single Phase',
        'جهد الألواح': '450V DC High Voltage MPPT',
        'العمل بدون بطارية': 'يدعم التشغيل المباشر من الشمس',
      },
    ),
    ProductModel(
      id: 'p8',
      name: 'باك منظومة منزلية كاملة 10kW الهجينة',
      brand: 'Iraq Solar Hybrid Pack',
      store: 'متجر بغداد للطاقة الشمولية',
      category: 'باكات كاملة',
      priceIQD: '6,300,000 د.ع',
      priceRaw: 6300000,
      priceUSD: 4120.0,
      assetImage: 'assets/images/marketing_pitch_showcase.jpg',
      rating: '5.0 ⭐ (40 تقييم)',
      warranty: 'شاملة التركيب والفحص والكفالة 5 سنوات',
      stock: 10,
      type: 'kit',
      isFeatured: true,
      discountTag: 'عروض الموسم 📦',
      originalPriceIQD: '7,000,000 د.ع',
      specs: {
        'الألواح': '18 لوح LONGi 550W TOPCon',
        'الانفيرتر': 'Deye 8kW 3-Phase Hybrid',
        'البطاريات': 'Felicity LiFePO4 10.2kWh',
        'الشمولية': 'القواعد الكوابل والحمايات والتركيب المجاني',
      },
    ),
  ];

  static List<Map<String, dynamic>> get allProductsAsMaps =>
      products.map((p) => p.toMap()).toList();
}
