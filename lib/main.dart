import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:soccer_ref/screens/home_screen.dart';
import 'package:wear_os_plugin/wear_os_app.dart';
import 'package:wear_os_plugin/wear_os_clipper.dart';

void main() {
  runApp(WearOsApp(screenBuilder: (context) => App()));
}

class App extends StatelessWidget {
  App({super.key});
  static final _defaultLightColorScheme = ColorScheme.fromSwatch(
    primarySwatch: Colors.green,
  );
  static final _defaultDarkColorScheme = ColorScheme.fromSwatch(
    primarySwatch: Colors.green,
    brightness: Brightness.dark,
  );
  late ColorScheme lightScheme;
  late ColorScheme darkScheme;

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (lightColorScheme, darkColorScheme) {
        if (lightColorScheme != null && darkColorScheme != null) {
          final schemes = _generateDynamicColourSchemes(
            lightColorScheme,
            darkColorScheme,
          );
          lightScheme = schemes.$1;
          darkScheme = schemes.$2;
        } else {
          final schemes = _generateDynamicColourSchemes(
            _defaultLightColorScheme,
            _defaultDarkColorScheme,
          );
          lightScheme = schemes.$1;
          darkScheme = schemes.$2;
        }
        return MaterialApp(
          title: 'Soccer Referee',
          theme: ThemeData(colorScheme: lightScheme, useMaterial3: true),
          darkTheme: ThemeData(colorScheme: darkScheme, useMaterial3: true),
          themeMode: ThemeMode.system,
          builder: (context, child) =>
              WearOsClipper(child: child ?? const SizedBox.shrink()),
          initialRoute: '/',
          routes: {
            '/': (context) => const HomeScreen(),
            /* '/login': (context) => const LoginScreen(),
            '/new_recipe': (context) => const NewRecipePage(),
            '/view_recipe': (context) => _buildViewRecipe(context),
            '/edit_recipe': (context) => _buildEditRecipe(context),
            '/cook_recipe': (context) => _buildCookRecipe(context), */
          },
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
