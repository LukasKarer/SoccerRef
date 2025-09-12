import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:soccer_ref/watch/home_screen.dart';
import 'package:soccer_ref/phone/phone_home_screen.dart';
import 'package:soccer_ref/services/platform_service.dart';
import 'package:soccer_ref/services/sync_service.dart';
import 'package:wear_os_plugin/wear_os_app.dart';
import 'package:wear_os_plugin/wear_os_clipper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize sync service for offline/online functionality
  await SyncService().initialize();

  final bool isWear = await PlatformService().isWearOS();
  if (isWear) {
    runApp(WearOsApp(screenBuilder: (context) => WearApp()));
  } else {
    runApp(PhoneApp());
  }
}

class _BaseApp extends StatelessWidget {
  _BaseApp({
    super.key,
    required this.childBuilder,
    this.wrapWearClipper = false,
  });
  final WidgetBuilder childBuilder;
  final bool wrapWearClipper;
  static final _defaultLightColorScheme = ColorScheme.fromSwatch(
    primarySwatch: Colors.green,
  );
  static final _defaultDarkColorScheme = ColorScheme.fromSwatch(
    primarySwatch: Colors.green,
    brightness: Brightness.dark,
  );

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (lightColorScheme, darkColorScheme) {
        final (
          computedLight,
          computedDark,
        ) = (lightColorScheme != null && darkColorScheme != null)
            ? _generateDynamicColourSchemes(lightColorScheme, darkColorScheme)
            : _generateDynamicColourSchemes(
                _defaultLightColorScheme,
                _defaultDarkColorScheme,
              );

        return MaterialApp(
          title: 'Soccer Referee',
          theme: ThemeData(colorScheme: computedLight, useMaterial3: true),
          darkTheme: ThemeData(colorScheme: computedDark, useMaterial3: true),
          themeMode: ThemeMode.system,
          builder: wrapWearClipper
              ? (context, child) =>
                    WearOsClipper(child: child ?? const SizedBox.shrink())
              : null,
          home: Builder(builder: childBuilder),
        );
      },
    );
  }

  /* Widget _buildViewRecipe(BuildContext context) {
    final recipe = ModalRoute.of(context)!.settings.arguments as Recipe;
    return ViewRecipePage(recipe: recipe);
  }

  Widget _buildEditRecipe(BuildContext context) {
    final recipe = ModalRoute.of(context)!.settings.arguments as Recipe;
    return EditRecipePage(recipe: recipe);
  }

  Widget _buildCookRecipe(BuildContext context) {
    final recipe = ModalRoute.of(context)!.settings.arguments as Recipe;
    return EditRecipePage(recipe: recipe);
  } */

  (ColorScheme light, ColorScheme dark) _generateDynamicColourSchemes(
    ColorScheme lightDynamic,
    ColorScheme darkDynamic,
  ) {
    var lightBase = ColorScheme.fromSeed(seedColor: lightDynamic.primary);
    var darkBase = ColorScheme.fromSeed(
      seedColor: darkDynamic.primary,
      brightness: Brightness.dark,
    );

    var lightAdditionalColours = _extractAdditionalColours(lightBase);
    var darkAdditionalColours = _extractAdditionalColours(darkBase);

    var lightScheme = _insertAdditionalColours(
      lightBase,
      lightAdditionalColours,
    );
    var darkScheme = _insertAdditionalColours(darkBase, darkAdditionalColours);

    return (lightScheme.harmonized(), darkScheme.harmonized());
  }

  List<Color> _extractAdditionalColours(ColorScheme scheme) => [
    scheme.surface,
    scheme.surfaceDim,
    scheme.surfaceBright,
    scheme.surfaceContainerLowest,
    scheme.surfaceContainerLow,
    scheme.surfaceContainer,
    scheme.surfaceContainerHigh,
    scheme.surfaceContainerHighest,
  ];

  ColorScheme _insertAdditionalColours(
    ColorScheme scheme,
    List<Color> additionalColours,
  ) => scheme.copyWith(
    surface: additionalColours[0],
    surfaceDim: additionalColours[1],
    surfaceBright: additionalColours[2],
    surfaceContainerLowest: additionalColours[3],
    surfaceContainerLow: additionalColours[4],
    surfaceContainer: additionalColours[5],
    surfaceContainerHigh: additionalColours[6],
    surfaceContainerHighest: additionalColours[7],
  );
}

class WearApp extends _BaseApp {
  WearApp({super.key})
    : super(
        wrapWearClipper: true,
        childBuilder: (context) => const HomeScreen(),
      );
}

class PhoneApp extends _BaseApp {
  PhoneApp({super.key})
    : super(
        wrapWearClipper: false,
        childBuilder: (context) => const PhoneHomeScreen(),
      );
}
