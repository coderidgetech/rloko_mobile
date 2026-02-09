import 'package:equatable/equatable.dart';

/// Site configuration matching web app SiteConfigContext.
/// Merged with defaults when loading from API.
class SiteConfig extends Equatable {
  const SiteConfig({
    required this.general,
    required this.design,
    required this.homepage,
    required this.navigation,
    required this.categories,
  });

  final GeneralConfig general;
  final DesignConfig design;
  final HomepageConfig homepage;
  final NavigationConfig navigation;
  final CategoriesConfig categories;

  @override
  List<Object?> get props => [general, design, homepage, navigation, categories];

  /// Parse from API response map and merge with defaults.
  factory SiteConfig.fromMap(Map<String, dynamic>? json) {
    final d = defaultConfig;
    if (json == null || json.isEmpty) return d;

    return SiteConfig(
      general: GeneralConfig.fromMap(
        _mergeMaps(
          d.general.toMap(),
          json['general'] is Map ? Map<String, dynamic>.from(json['general'] as Map) : null,
        ),
      ),
      design: DesignConfig.fromMap(
        _mergeMaps(
          d.design.toMap(),
          json['design'] is Map ? Map<String, dynamic>.from(json['design'] as Map) : null,
        ),
      ),
      homepage: HomepageConfig.fromMap(
        _mergeMaps(
          d.homepage.toMap(),
          json['homepage'] is Map ? Map<String, dynamic>.from(json['homepage'] as Map) : null,
        ),
      ),
      navigation: NavigationConfig.fromMap(
        _mergeMaps(
          d.navigation.toMap(),
          json['navigation'] is Map ? Map<String, dynamic>.from(json['navigation'] as Map) : null,
        ),
      ),
      categories: CategoriesConfig.fromMap(
        _mergeMaps(
          d.categories.toMap(),
          json['categories'] is Map ? Map<String, dynamic>.from(json['categories'] as Map) : null,
        ),
      ),
    );
  }

  static Map<String, dynamic> _mergeMaps(Map<String, dynamic>? base, Map<String, dynamic>? overlay) {
    if (overlay == null || overlay.isEmpty) return base ?? {};
    final result = Map<String, dynamic>.from(base ?? {});
    for (final e in overlay.entries) {
      if (e.value is Map && result[e.key] is Map) {
        result[e.key] = _mergeMaps(
          Map<String, dynamic>.from(result[e.key] as Map),
          Map<String, dynamic>.from(e.value as Map),
        );
      } else {
        result[e.key] = e.value;
      }
    }
    return result;
  }

  static SiteConfig get defaultConfig => SiteConfig(
        general: GeneralConfig(
          siteName: 'Rloco',
          tagline: 'Modern Luxury Fashion',
          description: 'Rloco is a premium fashion retailer offering curated collections.',
          email: 'hello@rloco.com',
          phone: '+1 (555) 123-4567',
          supportEmail: 'support@rloco.com',
          address: '123 Fashion Avenue, New York, NY 10001, United States',
          socialMedia: SocialMediaConfig(
            instagram: '@rloco',
            facebook: 'facebook.com/rloco',
            twitter: '@rloco',
            pinterest: 'pinterest.com/rloco',
          ),
        ),
        design: DesignConfig(
          colors: DesignColorsConfig(
            primary: '#B4770E',
            primaryLight: '#D4970E',
            primaryDark: '#8B5A0B',
            secondary: '#000000',
            secondaryGray: '#666666',
            secondaryLightGray: '#999999',
            dominant: '#FFFFFF',
            dominantOffWhite: '#F8F8F8',
            dominantLight: '#F5F5F5',
          ),
          typography: DesignTypographyConfig(
            headingFont: 'Inter',
            bodyFont: 'Inter',
            baseFontSize: '16',
            lineHeight: '1.5',
            letterSpacing: 'normal',
          ),
          layout: DesignLayoutConfig(
            borderRadius: '0',
            containerWidth: '1920',
            sectionSpacing: 'large',
          ),
          animations: DesignAnimationsConfig(
            enabled: true,
            speed: 'normal',
            hoverEffects: 'subtle',
          ),
        ),
        homepage: HomepageConfig(
          hero: HeroConfig(
            enabled: true,
            heading: 'Timeless Elegance Redefined',
            subheading: 'Discover our curated collection of luxury fashion pieces',
            primaryButtonText: 'Shop Collection',
            primaryButtonLink: '/shop',
            backgroundImage: '',
            style: 'fullscreen',
          ),
          sections: HomepageSectionsConfig(
            featuredProducts: true,
            newArrivals: true,
            shopByCategory: true,
            bestSellers: true,
            editorialFeatures: true,
            promotionalBanner: true,
            testimonials: true,
            brandStory: false,
            instagramFeed: false,
            newsletterSignup: true,
          ),
          featuredCollections: ['new', 'women', 'accessories'],
        ),
        navigation: NavigationConfig(
          header: HeaderConfig(
            style: 'transparent',
            height: '80',
            sticky: true,
            showSearch: true,
            showCurrency: true,
          ),
          footer: FooterConfig(
            style: 'multi-column',
            showNewsletter: true,
            showSocial: true,
            showPaymentIcons: true,
            copyrightText: '© 2026 Rloco. All rights reserved.',
          ),
        ),
        categories: CategoriesConfig(
          women: CategoryGenderConfig(
            clothing: ['Dresses', 'Tops', 'Bottoms', 'Outerwear', 'Knitwear'],
            accessories: ['Shoes', 'Jewelry', 'Bags'],
          ),
          men: CategoryGenderConfig(
            clothing: ['Shirts', 'Tops', 'Bottoms', 'Outerwear', 'Knitwear'],
            accessories: ['Shoes', 'Accessories'],
          ),
        ),
      );
}

class GeneralConfig extends Equatable {
  const GeneralConfig({
    required this.siteName,
    required this.tagline,
    required this.description,
    required this.email,
    required this.phone,
    required this.supportEmail,
    required this.address,
    required this.socialMedia,
  });

  final String siteName;
  final String tagline;
  final String description;
  final String email;
  final String phone;
  final String supportEmail;
  final String address;
  final SocialMediaConfig socialMedia;

  @override
  List<Object?> get props => [siteName, tagline, description, email, phone, supportEmail, address, socialMedia];

  factory GeneralConfig.fromMap(Map<String, dynamic>? m) {
    if (m == null) return const GeneralConfig(siteName: 'Rloco', tagline: '', description: '', email: '', phone: '', supportEmail: '', address: '', socialMedia: SocialMediaConfig(instagram: '', facebook: '', twitter: '', pinterest: ''));
    return GeneralConfig(
      siteName: (m['siteName'] ?? 'Rloco').toString(),
      tagline: (m['tagline'] ?? '').toString(),
      description: (m['description'] ?? '').toString(),
      email: (m['email'] ?? '').toString(),
      phone: (m['phone'] ?? '').toString(),
      supportEmail: (m['supportEmail'] ?? '').toString(),
      address: (m['address'] ?? '').toString(),
      socialMedia: SocialMediaConfig.fromMap(m['socialMedia'] is Map ? Map<String, dynamic>.from(m['socialMedia'] as Map) : null),
    );
  }

  Map<String, dynamic> toMap() => {
        'siteName': siteName,
        'tagline': tagline,
        'description': description,
        'email': email,
        'phone': phone,
        'supportEmail': supportEmail,
        'address': address,
        'socialMedia': socialMedia.toMap(),
      };
}

class SocialMediaConfig extends Equatable {
  const SocialMediaConfig({
    required this.instagram,
    required this.facebook,
    required this.twitter,
    required this.pinterest,
  });

  final String instagram;
  final String facebook;
  final String twitter;
  final String pinterest;

  @override
  List<Object?> get props => [instagram, facebook, twitter, pinterest];

  factory SocialMediaConfig.fromMap(Map<String, dynamic>? m) {
    if (m == null) return const SocialMediaConfig(instagram: '', facebook: '', twitter: '', pinterest: '');
    return SocialMediaConfig(
      instagram: (m['instagram'] ?? '').toString(),
      facebook: (m['facebook'] ?? '').toString(),
      twitter: (m['twitter'] ?? '').toString(),
      pinterest: (m['pinterest'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() => {'instagram': instagram, 'facebook': facebook, 'twitter': twitter, 'pinterest': pinterest};
}

class DesignConfig extends Equatable {
  const DesignConfig({
    required this.colors,
    required this.typography,
    required this.layout,
    required this.animations,
  });

  final DesignColorsConfig colors;
  final DesignTypographyConfig typography;
  final DesignLayoutConfig layout;
  final DesignAnimationsConfig animations;

  @override
  List<Object?> get props => [colors, typography, layout, animations];

  factory DesignConfig.fromMap(Map<String, dynamic>? m) {
    if (m == null) {
      return const DesignConfig(
        colors: DesignColorsConfig(primary: '#B4770E', primaryLight: '#D4970E', primaryDark: '#8B5A0B', secondary: '#000000', secondaryGray: '#666666', secondaryLightGray: '#999999', dominant: '#FFFFFF', dominantOffWhite: '#F8F8F8', dominantLight: '#F5F5F5'),
        typography: DesignTypographyConfig(headingFont: 'Inter', bodyFont: 'Inter', baseFontSize: '16', lineHeight: '1.5', letterSpacing: 'normal'),
        layout: DesignLayoutConfig(borderRadius: '0', containerWidth: '1920', sectionSpacing: 'large'),
        animations: DesignAnimationsConfig(enabled: true, speed: 'normal', hoverEffects: 'subtle'),
      );
    }
    return DesignConfig(
      colors: DesignColorsConfig.fromMap(m['colors'] is Map ? Map<String, dynamic>.from(m['colors'] as Map) : null),
      typography: DesignTypographyConfig.fromMap(m['typography'] is Map ? Map<String, dynamic>.from(m['typography'] as Map) : null),
      layout: DesignLayoutConfig.fromMap(m['layout'] is Map ? Map<String, dynamic>.from(m['layout'] as Map) : null),
      animations: DesignAnimationsConfig.fromMap(m['animations'] is Map ? Map<String, dynamic>.from(m['animations'] as Map) : null),
    );
  }

  Map<String, dynamic> toMap() => {
        'colors': colors.toMap(),
        'typography': typography.toMap(),
        'layout': layout.toMap(),
        'animations': animations.toMap(),
      };
}

class DesignColorsConfig extends Equatable {
  const DesignColorsConfig({
    required this.primary,
    required this.primaryLight,
    required this.primaryDark,
    required this.secondary,
    required this.secondaryGray,
    required this.secondaryLightGray,
    required this.dominant,
    required this.dominantOffWhite,
    required this.dominantLight,
  });

  final String primary;
  final String primaryLight;
  final String primaryDark;
  final String secondary;
  final String secondaryGray;
  final String secondaryLightGray;
  final String dominant;
  final String dominantOffWhite;
  final String dominantLight;

  @override
  List<Object?> get props => [primary, primaryLight, primaryDark, secondary, secondaryGray, secondaryLightGray, dominant, dominantOffWhite, dominantLight];

  factory DesignColorsConfig.fromMap(Map<String, dynamic>? m) {
    if (m == null) return const DesignColorsConfig(primary: '#B4770E', primaryLight: '#D4970E', primaryDark: '#8B5A0B', secondary: '#000000', secondaryGray: '#666666', secondaryLightGray: '#999999', dominant: '#FFFFFF', dominantOffWhite: '#F8F8F8', dominantLight: '#F5F5F5');
    return DesignColorsConfig(
      primary: (m['primary'] ?? '#B4770E').toString(),
      primaryLight: (m['primaryLight'] ?? '#D4970E').toString(),
      primaryDark: (m['primaryDark'] ?? '#8B5A0B').toString(),
      secondary: (m['secondary'] ?? '#000000').toString(),
      secondaryGray: (m['secondaryGray'] ?? '#666666').toString(),
      secondaryLightGray: (m['secondaryLightGray'] ?? '#999999').toString(),
      dominant: (m['dominant'] ?? '#FFFFFF').toString(),
      dominantOffWhite: (m['dominantOffWhite'] ?? '#F8F8F8').toString(),
      dominantLight: (m['dominantLight'] ?? '#F5F5F5').toString(),
    );
  }

  Map<String, dynamic> toMap() => {
        'primary': primary,
        'primaryLight': primaryLight,
        'primaryDark': primaryDark,
        'secondary': secondary,
        'secondaryGray': secondaryGray,
        'secondaryLightGray': secondaryLightGray,
        'dominant': dominant,
        'dominantOffWhite': dominantOffWhite,
        'dominantLight': dominantLight,
      };
}

class DesignTypographyConfig extends Equatable {
  const DesignTypographyConfig({
    required this.headingFont,
    required this.bodyFont,
    required this.baseFontSize,
    required this.lineHeight,
    required this.letterSpacing,
  });

  final String headingFont;
  final String bodyFont;
  final String baseFontSize;
  final String lineHeight;
  final String letterSpacing;

  @override
  List<Object?> get props => [headingFont, bodyFont, baseFontSize, lineHeight, letterSpacing];

  factory DesignTypographyConfig.fromMap(Map<String, dynamic>? m) {
    if (m == null) return const DesignTypographyConfig(headingFont: 'Inter', bodyFont: 'Inter', baseFontSize: '16', lineHeight: '1.5', letterSpacing: 'normal');
    return DesignTypographyConfig(
      headingFont: (m['headingFont'] ?? 'Inter').toString(),
      bodyFont: (m['bodyFont'] ?? 'Inter').toString(),
      baseFontSize: (m['baseFontSize'] ?? '16').toString(),
      lineHeight: (m['lineHeight'] ?? '1.5').toString(),
      letterSpacing: (m['letterSpacing'] ?? 'normal').toString(),
    );
  }

  Map<String, dynamic> toMap() => {
        'headingFont': headingFont,
        'bodyFont': bodyFont,
        'baseFontSize': baseFontSize,
        'lineHeight': lineHeight,
        'letterSpacing': letterSpacing,
      };
}

class DesignLayoutConfig extends Equatable {
  const DesignLayoutConfig({
    required this.borderRadius,
    required this.containerWidth,
    required this.sectionSpacing,
  });

  final String borderRadius;
  final String containerWidth;
  final String sectionSpacing;

  @override
  List<Object?> get props => [borderRadius, containerWidth, sectionSpacing];

  factory DesignLayoutConfig.fromMap(Map<String, dynamic>? m) {
    if (m == null) return const DesignLayoutConfig(borderRadius: '0', containerWidth: '1920', sectionSpacing: 'large');
    return DesignLayoutConfig(
      borderRadius: (m['borderRadius'] ?? '0').toString(),
      containerWidth: (m['containerWidth'] ?? '1920').toString(),
      sectionSpacing: (m['sectionSpacing'] ?? 'large').toString(),
    );
  }

  Map<String, dynamic> toMap() => {
        'borderRadius': borderRadius,
        'containerWidth': containerWidth,
        'sectionSpacing': sectionSpacing,
      };
}

class DesignAnimationsConfig extends Equatable {
  const DesignAnimationsConfig({
    required this.enabled,
    required this.speed,
    required this.hoverEffects,
  });

  final bool enabled;
  final String speed;
  final String hoverEffects;

  @override
  List<Object?> get props => [enabled, speed, hoverEffects];

  factory DesignAnimationsConfig.fromMap(Map<String, dynamic>? m) {
    if (m == null) return const DesignAnimationsConfig(enabled: true, speed: 'normal', hoverEffects: 'subtle');
    return DesignAnimationsConfig(
      enabled: m['enabled'] != false,
      speed: (m['speed'] ?? 'normal').toString(),
      hoverEffects: (m['hoverEffects'] ?? 'subtle').toString(),
    );
  }

  Map<String, dynamic> toMap() => {
        'enabled': enabled,
        'speed': speed,
        'hoverEffects': hoverEffects,
      };
}

class HomepageConfig extends Equatable {
  const HomepageConfig({
    required this.hero,
    required this.sections,
    required this.featuredCollections,
  });

  final HeroConfig hero;
  final HomepageSectionsConfig sections;
  final List<String> featuredCollections;

  @override
  List<Object?> get props => [hero, sections, featuredCollections];

  factory HomepageConfig.fromMap(Map<String, dynamic>? m) {
    if (m == null) return SiteConfig.defaultConfig.homepage;
    return HomepageConfig(
      hero: HeroConfig.fromMap(m['hero'] is Map ? Map<String, dynamic>.from(m['hero'] as Map) : null),
      sections: HomepageSectionsConfig.fromMap(m['sections'] is Map ? Map<String, dynamic>.from(m['sections'] as Map) : null),
      featuredCollections: (m['featuredCollections'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? ['new', 'women', 'accessories'],
    );
  }

  Map<String, dynamic> toMap() => {
        'hero': hero.toMap(),
        'sections': sections.toMap(),
        'featuredCollections': featuredCollections,
      };
}

class HeroConfig extends Equatable {
  const HeroConfig({
    required this.enabled,
    required this.heading,
    required this.subheading,
    required this.primaryButtonText,
    required this.primaryButtonLink,
    required this.backgroundImage,
    required this.style,
  });

  final bool enabled;
  final String heading;
  final String subheading;
  final String primaryButtonText;
  final String primaryButtonLink;
  final String backgroundImage;
  final String style;

  @override
  List<Object?> get props => [enabled, heading, subheading, primaryButtonText, primaryButtonLink, backgroundImage, style];

  factory HeroConfig.fromMap(Map<String, dynamic>? m) {
    if (m == null) return SiteConfig.defaultConfig.homepage.hero;
    return HeroConfig(
      enabled: m['enabled'] == true,
      heading: (m['heading'] ?? 'Timeless Elegance Redefined').toString(),
      subheading: (m['subheading'] ?? '').toString(),
      primaryButtonText: (m['primaryButtonText'] ?? 'Shop Collection').toString(),
      primaryButtonLink: (m['primaryButtonLink'] ?? '/shop').toString(),
      backgroundImage: (m['backgroundImage'] ?? '').toString(),
      style: (m['style'] ?? 'fullscreen').toString(),
    );
  }

  Map<String, dynamic> toMap() => {
        'enabled': enabled,
        'heading': heading,
        'subheading': subheading,
        'primaryButtonText': primaryButtonText,
        'primaryButtonLink': primaryButtonLink,
        'backgroundImage': backgroundImage,
        'style': style,
      };
}

class HomepageSectionsConfig extends Equatable {
  const HomepageSectionsConfig({
    required this.featuredProducts,
    required this.newArrivals,
    required this.shopByCategory,
    required this.bestSellers,
    required this.editorialFeatures,
    required this.promotionalBanner,
    required this.testimonials,
    required this.brandStory,
    required this.instagramFeed,
    required this.newsletterSignup,
  });

  final bool featuredProducts;
  final bool newArrivals;
  final bool shopByCategory;
  final bool bestSellers;
  final bool editorialFeatures;
  final bool promotionalBanner;
  final bool testimonials;
  final bool brandStory;
  final bool instagramFeed;
  final bool newsletterSignup;

  @override
  List<Object?> get props => [featuredProducts, newArrivals, shopByCategory, bestSellers, editorialFeatures, promotionalBanner, testimonials, brandStory, instagramFeed, newsletterSignup];

  factory HomepageSectionsConfig.fromMap(Map<String, dynamic>? m) {
    if (m == null) return SiteConfig.defaultConfig.homepage.sections;
    return HomepageSectionsConfig(
      featuredProducts: m['featuredProducts'] != false,
      newArrivals: m['newArrivals'] != false,
      shopByCategory: m['shopByCategory'] != false,
      bestSellers: m['bestSellers'] != false,
      editorialFeatures: m['editorialFeatures'] != false,
      promotionalBanner: m['promotionalBanner'] != false,
      testimonials: m['testimonials'] != false,
      brandStory: m['brandStory'] == true,
      instagramFeed: m['instagramFeed'] == true,
      newsletterSignup: m['newsletterSignup'] != false,
    );
  }

  Map<String, dynamic> toMap() => {
        'featuredProducts': featuredProducts,
        'newArrivals': newArrivals,
        'shopByCategory': shopByCategory,
        'bestSellers': bestSellers,
        'editorialFeatures': editorialFeatures,
        'promotionalBanner': promotionalBanner,
        'testimonials': testimonials,
        'brandStory': brandStory,
        'instagramFeed': instagramFeed,
        'newsletterSignup': newsletterSignup,
      };
}

class NavigationConfig extends Equatable {
  const NavigationConfig({
    required this.header,
    required this.footer,
  });

  final HeaderConfig header;
  final FooterConfig footer;

  @override
  List<Object?> get props => [header, footer];

  factory NavigationConfig.fromMap(Map<String, dynamic>? m) {
    if (m == null) return SiteConfig.defaultConfig.navigation;
    return NavigationConfig(
      header: HeaderConfig.fromMap(m['header'] is Map ? Map<String, dynamic>.from(m['header'] as Map) : null),
      footer: FooterConfig.fromMap(m['footer'] is Map ? Map<String, dynamic>.from(m['footer'] as Map) : null),
    );
  }

  Map<String, dynamic> toMap() => {'header': header.toMap(), 'footer': footer.toMap()};
}

class HeaderConfig extends Equatable {
  const HeaderConfig({
    required this.style,
    required this.height,
    required this.sticky,
    required this.showSearch,
    required this.showCurrency,
  });

  final String style;
  final String height;
  final bool sticky;
  final bool showSearch;
  final bool showCurrency;

  @override
  List<Object?> get props => [style, height, sticky, showSearch, showCurrency];

  factory HeaderConfig.fromMap(Map<String, dynamic>? m) {
    if (m == null) return SiteConfig.defaultConfig.navigation.header;
    return HeaderConfig(
      style: (m['style'] ?? 'transparent').toString(),
      height: (m['height'] ?? '80').toString(),
      sticky: m['sticky'] != false,
      showSearch: m['showSearch'] != false,
      showCurrency: m['showCurrency'] != false,
    );
  }

  Map<String, dynamic> toMap() => {'style': style, 'height': height, 'sticky': sticky, 'showSearch': showSearch, 'showCurrency': showCurrency};
}

class FooterConfig extends Equatable {
  const FooterConfig({
    required this.style,
    required this.showNewsletter,
    required this.showSocial,
    required this.showPaymentIcons,
    required this.copyrightText,
  });

  final String style;
  final bool showNewsletter;
  final bool showSocial;
  final bool showPaymentIcons;
  final String copyrightText;

  @override
  List<Object?> get props => [style, showNewsletter, showSocial, showPaymentIcons, copyrightText];

  factory FooterConfig.fromMap(Map<String, dynamic>? m) {
    if (m == null) return SiteConfig.defaultConfig.navigation.footer;
    return FooterConfig(
      style: (m['style'] ?? 'multi-column').toString(),
      showNewsletter: m['showNewsletter'] != false,
      showSocial: m['showSocial'] != false,
      showPaymentIcons: m['showPaymentIcons'] != false,
      copyrightText: (m['copyrightText'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() => {'style': style, 'showNewsletter': showNewsletter, 'showSocial': showSocial, 'showPaymentIcons': showPaymentIcons, 'copyrightText': copyrightText};
}

class CategoriesConfig extends Equatable {
  const CategoriesConfig({
    required this.women,
    required this.men,
  });

  final CategoryGenderConfig women;
  final CategoryGenderConfig men;

  @override
  List<Object?> get props => [women, men];

  factory CategoriesConfig.fromMap(Map<String, dynamic>? m) {
    if (m == null) {
      return const CategoriesConfig(
        women: CategoryGenderConfig(clothing: ['Dresses', 'Tops', 'Bottoms', 'Outerwear', 'Knitwear'], accessories: ['Shoes', 'Jewelry', 'Bags']),
        men: CategoryGenderConfig(clothing: ['Shirts', 'Tops', 'Bottoms', 'Outerwear', 'Knitwear'], accessories: ['Shoes', 'Accessories']),
      );
    }
    return CategoriesConfig(
      women: CategoryGenderConfig.fromMap(m['women'] is Map ? Map<String, dynamic>.from(m['women'] as Map) : null, forMen: false),
      men: CategoryGenderConfig.fromMap(m['men'] is Map ? Map<String, dynamic>.from(m['men'] as Map) : null, forMen: true),
    );
  }

  Map<String, dynamic> toMap() => {'women': women.toMap(), 'men': men.toMap()};
}

class CategoryGenderConfig extends Equatable {
  const CategoryGenderConfig({
    required this.clothing,
    required this.accessories,
  });

  final List<String> clothing;
  final List<String> accessories;

  @override
  List<Object?> get props => [clothing, accessories];

  factory CategoryGenderConfig.fromMap(Map<String, dynamic>? m, {bool forMen = false}) {
    const womenDefault = CategoryGenderConfig(clothing: ['Dresses', 'Tops', 'Bottoms', 'Outerwear', 'Knitwear'], accessories: ['Shoes', 'Jewelry', 'Bags']);
    const menDefault = CategoryGenderConfig(clothing: ['Shirts', 'Tops', 'Bottoms', 'Outerwear', 'Knitwear'], accessories: ['Shoes', 'Accessories']);
    final def = forMen ? menDefault : womenDefault;
    if (m == null) return def;
    final clothing = (m['clothing'] as List<dynamic>?)?.map((e) => e.toString()).toList();
    final accessories = (m['accessories'] as List<dynamic>?)?.map((e) => e.toString()).toList();
    return CategoryGenderConfig(
      clothing: clothing ?? def.clothing,
      accessories: accessories ?? def.accessories,
    );
  }

  Map<String, dynamic> toMap() => {'clothing': clothing, 'accessories': accessories};
}
