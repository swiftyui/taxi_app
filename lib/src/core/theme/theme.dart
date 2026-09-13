import 'package:TaxiApp/src/core/extensions/get_extensions.dart';
import 'package:TaxiApp/src/core/providers/shared_preferences/enums/shared_preference_key.dart';
import 'package:TaxiApp/src/core/theme/app_visual_density.dart';
import 'package:TaxiApp/src/core/theme/constants/colours.dart';
import 'package:TaxiApp/src/core/theme/constants/dimensions.dart';
import 'package:TaxiApp/src/core/theme/text_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Theme settings service will indicate it is in dark mode if the service's
/// value is set to true
class ThemeSettingsService extends GetxController {
  ThemeSettingsService();

  static ThemeSettingsService create() =>
      Get.isRegistered<ThemeSettingsService>()
      ? Get.find<ThemeSettingsService>()
      : Get.put<ThemeSettingsService>(ThemeSettingsService());

  static const _visualDensity = AppVisualDensity.tight;

  final themeMode = Rx<ThemeMode>(
    Get.isDarkMode ? ThemeMode.dark : ThemeMode.light,
  );

  void toggleThemeMode({required bool isDarkMode}) {
    // update the shared preferences
    SharedPreferences.getInstance().then((sharedPreferences) {
      sharedPreferences.setBool(
        SharedPreferenceKey.isDarkMode.value,
        isDarkMode,
      );
      Get.changeTheme(Get.isDarkMode ? lightTheme() : darkTheme());
    });
  }

  /// Getter method for the typography
  Typography get typography => Typography.material2021();

  /// This method creates the light theme for the application
  ThemeData lightTheme() {
    const ColorScheme colorScheme = ColorScheme(
      primary: Colors.black,
      onPrimary: Colors.white,
      secondary: Colors.black,
      onSecondary: Colors.white,
      surface: Colors.white,
      onSurface: Colors.black,
      error: Color.fromARGB(255, 162, 42, 42),
      onError: Colors.white,
      brightness: Brightness.light,
      primaryContainer: Colors.white,
      onPrimaryContainer: Colors.white,
      secondaryContainer: Colors.white,
      onSecondaryContainer: Colors.white,
      tertiaryContainer: Colors.white,
      onTertiaryContainer: Colors.white,
      tertiary: Color.fromARGB(255, 65, 106, 88),
    );

    final textTheme = getTextTheme(colorScheme: colorScheme);

    return ThemeData.light().copyWith(
      canvasColor: Colors.white,
      drawerTheme: _drawerThemeData(
        colorScheme: colorScheme,
        textTheme: textTheme,
      ),
      scrollbarTheme: _scrollbarThemeData(
        colorScheme: colorScheme,
        textTheme: textTheme,
      ),
      visualDensity: _visualDensity,
      textTheme: textTheme,
      scaffoldBackgroundColor: colorScheme.surface,
      brightness: Brightness.light,
      datePickerTheme: _datePickerTheme(
        colorScheme: colorScheme,
        textTheme: textTheme,
      ),
      elevatedButtonTheme: _elevatedButtonTheme(
        colorScheme: colorScheme,
        textTheme: textTheme,
      ),
      filledButtonTheme: _filledButtonTheme(textTheme),
      outlinedButtonTheme: _outlineButtonTheme(
        colorScheme: colorScheme,
        textTheme: textTheme,
      ),
      textButtonTheme: _textButtonThemeData(textTheme),
      popupMenuTheme: _popMenuTheme(
        colorScheme: colorScheme,
        textTheme: textTheme,
      ),
      floatingActionButtonTheme: _floatingActionButtonTheme(
        colorScheme: colorScheme,
      ),
      appBarTheme: _appBarTheme(colorScheme: colorScheme, textTheme: textTheme),
      iconTheme: _iconTheme(colorScheme: colorScheme),
      tabBarTheme: _tabBarTheme(colorScheme: colorScheme, textTheme: textTheme),
      dividerTheme: _dividerTheme(colorScheme: colorScheme),
      typography: typography,
      colorScheme: colorScheme,
      dropdownMenuTheme: _dropdownMenuTheme(
        colorScheme: colorScheme,
        textTheme: textTheme,
      ),
      dialogTheme: _dialogTheme(colorScheme: colorScheme, textTheme: textTheme),
      expansionTileTheme: _expansionTileThemeData(
        colorScheme: colorScheme,
        textTheme: textTheme,
      ),
      bottomSheetTheme: _bottomSheetThemeData(
        colorScheme: colorScheme,
        textTheme: textTheme,
      ),
      listTileTheme: _listTileThemeData(
        colorScheme: colorScheme,
        textTheme: textTheme,
      ),
      inputDecorationTheme: _inputDecorationTheme(
        colorScheme: colorScheme,
        textTheme: textTheme,
      ),
      checkboxTheme: _checkboxThemeData(
        colorScheme: colorScheme,
        textTheme: textTheme,
      ),
      switchTheme: _switchThemeData(
        colorScheme: colorScheme,
        textTheme: textTheme,
      ),
      radioTheme: _radioThemeData,
    );
  }

  ScrollbarThemeData _scrollbarThemeData({
    required ColorScheme colorScheme,
    required TextTheme textTheme,
  }) => ScrollbarThemeData(
    interactive: true,
    thickness: WidgetStateProperty.all<double>(Dimensions.eight),
    thumbColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.selected)
          ? Colors.black.withValues(alpha: 0.2)
          : Colors.black.withValues(alpha: 0.2),
    ),
  );

  DrawerThemeData _drawerThemeData({
    required ColorScheme colorScheme,
    required TextTheme textTheme,
  }) => DrawerThemeData(backgroundColor: colorScheme.tertiaryContainer);

  CheckboxThemeData _checkboxThemeData({
    required ColorScheme colorScheme,
    required TextTheme textTheme,
  }) => CheckboxThemeData(
    fillColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.selected)
          ? colorScheme.primary
          : colorScheme.surface,
    ),
    checkColor: WidgetStateProperty.resolveWith(
      (states) => colorScheme.surface,
    ),
  );

  RadioThemeData get _radioThemeData =>
      RadioThemeData(fillColor: WidgetStateProperty.all(Colors.white));

  SwitchThemeData _switchThemeData({
    required ColorScheme colorScheme,
    required TextTheme textTheme,
  }) => SwitchThemeData(
    thumbColor: WidgetStateProperty.all(Colors.white),
    thumbIcon: WidgetStateProperty.resolveWith(
      (states) => const Icon(Icons.close, color: Colors.transparent),
    ),
    trackColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.selected)
          ? colorScheme.secondary
          : colorScheme.secondary,
    ),
    trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
  );

  /// This method creates the dark theme for the application
  ThemeData darkTheme() {
    const ColorScheme colorScheme = ColorScheme(
      primary: Colors.white,
      onPrimary: Colors.white,
      secondary: Colors.white,
      onSecondary: Colors.white,
      surface: Colors.white,
      onSurface: Colors.white,
      error: Colors.white,
      onError: Colors.white,
      brightness: Brightness.dark,
      primaryContainer: Colors.white,
      onPrimaryContainer: Colors.white,
      secondaryContainer: Colors.white,
      onSecondaryContainer: Colors.white,
      tertiaryContainer: Colors.white,
      onTertiaryContainer: Colors.white,
    );
    final textTheme = getTextTheme(colorScheme: colorScheme);

    return ThemeData.dark().copyWith(
      canvasColor: Colors.white,
      drawerTheme: _drawerThemeData(
        colorScheme: colorScheme,
        textTheme: textTheme,
      ),
      scrollbarTheme: _scrollbarThemeData(
        colorScheme: colorScheme,
        textTheme: textTheme,
      ),
      dividerColor: Colours.errorColour,
      visualDensity: _visualDensity,
      scaffoldBackgroundColor: colorScheme.surface,
      brightness: Brightness.dark,
      datePickerTheme: _datePickerTheme(
        colorScheme: colorScheme,
        textTheme: textTheme,
      ),
      elevatedButtonTheme: _elevatedButtonTheme(
        colorScheme: colorScheme,
        textTheme: textTheme,
      ),
      filledButtonTheme: _filledButtonTheme(textTheme),
      outlinedButtonTheme: _outlineButtonTheme(
        colorScheme: colorScheme,
        textTheme: textTheme,
      ),
      checkboxTheme: _checkboxThemeData(
        colorScheme: colorScheme,
        textTheme: textTheme,
      ),
      textButtonTheme: _textButtonThemeData(textTheme),
      textTheme: textTheme,
      popupMenuTheme: _popMenuTheme(
        colorScheme: colorScheme,
        textTheme: textTheme,
      ),
      dropdownMenuTheme: _dropdownMenuTheme(
        colorScheme: colorScheme,
        textTheme: textTheme,
      ),
      dialogTheme: _dialogTheme(colorScheme: colorScheme, textTheme: textTheme),
      floatingActionButtonTheme: _floatingActionButtonTheme(
        colorScheme: colorScheme,
      ),
      appBarTheme: _appBarTheme(colorScheme: colorScheme, textTheme: textTheme),
      expansionTileTheme: _expansionTileThemeData(
        colorScheme: colorScheme,
        textTheme: textTheme,
      ),
      iconTheme: _iconTheme(colorScheme: colorScheme),
      tabBarTheme: _tabBarTheme(colorScheme: colorScheme, textTheme: textTheme),
      dividerTheme: _dividerTheme(colorScheme: colorScheme),
      typography: typography,
      colorScheme: colorScheme,
      bottomSheetTheme: _bottomSheetThemeData(
        colorScheme: colorScheme,
        textTheme: textTheme,
      ),
      listTileTheme: _listTileThemeData(
        colorScheme: colorScheme,
        textTheme: textTheme,
      ),
      inputDecorationTheme: _inputDecorationTheme(
        colorScheme: colorScheme,
        textTheme: textTheme,
      ),
      switchTheme: _switchThemeData(
        colorScheme: colorScheme,
        textTheme: textTheme,
      ),
      radioTheme: _radioThemeData,
    );
  }

  InputDecorationTheme _inputDecorationTheme({
    required ColorScheme colorScheme,
    required TextTheme textTheme,
  }) => InputDecorationTheme(
    filled: true,
    fillColor: Get.isDarkMode
        ? Colours.primaryTwo
        : Colours.searchBarBackground,
    labelStyle: textTheme.bodySmall?.copyWith(color: Colours.charcoalLight),
    floatingLabelStyle: textTheme.bodySmall?.copyWith(
      color: Colours.blueThree,
      fontWeight: FontWeight.w600,
    ),
    hintStyle: textTheme.bodySmall?.copyWith(
      color: Colours.charcoalLight.withValues(alpha: 0.75),
    ),
    errorStyle: textTheme.labelLarge?.copyWith(color: Colours.errorColour),
    prefixIconColor: Colours.charcoalLight,
    suffixIconColor: Colours.charcoalLight,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(Dimensions.eight),
      borderSide: const BorderSide(color: Colours.containerOne),
    ),
    focusedBorder: const OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(Dimensions.eight)),
      borderSide: BorderSide(color: Colours.blueThree, width: 1.5),
    ),
    errorBorder: const OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(Dimensions.eight)),
      borderSide: BorderSide(color: Colours.errorColour),
    ),
    focusedErrorBorder: const OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(Dimensions.eight)),
      borderSide: BorderSide(color: Colours.errorColour, width: 1.5),
    ),
  );

  ListTileThemeData _listTileThemeData({
    required ColorScheme colorScheme,
    required TextTheme textTheme,
  }) => ListTileThemeData(
    dense: true,
    textColor: colorScheme.onSurface,
    iconColor: colorScheme.onSurface,
  );

  ExpansionTileThemeData _expansionTileThemeData({
    required ColorScheme colorScheme,
    required TextTheme textTheme,
  }) => ExpansionTileThemeData(
    backgroundColor: Colors.transparent,
    iconColor: colorScheme.onSurface,
    collapsedBackgroundColor: Colors.transparent,
    textColor: colorScheme.onSurface,
    shape: const Border(),
  );

  DatePickerThemeData _datePickerTheme({
    required ColorScheme colorScheme,
    required TextTheme textTheme,
  }) => DatePickerThemeData(
    backgroundColor: colorScheme.surface,
    surfaceTintColor: colorScheme.surface,
    headerForegroundColor: colorScheme.primary,
    headerBackgroundColor: colorScheme.surface,
    rangePickerHeaderBackgroundColor: colorScheme.surface,
    rangePickerSurfaceTintColor: colorScheme.surface,
    rangePickerHeaderForegroundColor: colorScheme.primary,
    rangeSelectionBackgroundColor: colorScheme.surface,
    yearOverlayColor: WidgetStateProperty.resolveWith<Color?>(
      (states) => colorScheme.primary,
    ),
    weekdayStyle: textTheme.bodySmall,
    yearStyle: textTheme.bodySmall,
    inputDecorationTheme: InputDecorationTheme(fillColor: colorScheme.primary),
    rangePickerHeaderHeadlineStyle: textTheme.bodySmall,
    rangePickerHeaderHelpStyle: textTheme.bodySmall,
    rangeSelectionOverlayColor: WidgetStateProperty.resolveWith<Color?>(
      (states) => colorScheme.primary,
    ),
    dividerColor: colorScheme.onSurface.withValues(alpha: 0.2),
    yearForegroundColor: WidgetStateProperty.resolveWith((
      Set<WidgetState> states,
    ) {
      if (states.contains(WidgetState.pressed)) {
        return colorScheme.primary.withValues(alpha: 0.5);
      } else if (states.contains(WidgetState.disabled)) {
        return colorScheme.primary.withValues(alpha: 0.3);
      } else if (states.contains(WidgetState.selected)) {
        return colorScheme.onPrimary;
      } else {
        return colorScheme.primary;
      }
    }),
    todayForegroundColor: WidgetStateProperty.resolveWith<Color?>((
      Set<WidgetState> states,
    ) {
      if (states.contains(WidgetState.pressed)) {
        return colorScheme.primary.withValues(alpha: 0.5);
      }
      return null; // Use the component's default.
    }),
    headerHelpStyle: textTheme.bodySmall,
    headerHeadlineStyle: textTheme.bodyLarge,
    dayStyle: textTheme.bodySmall,
    dayForegroundColor: WidgetStateProperty.resolveWith<Color?>((
      Set<WidgetState> states,
    ) {
      if (states.contains(WidgetState.pressed)) {
        return colorScheme.primary.withValues(alpha: 0.5);
      } else if (states.contains(WidgetState.disabled)) {
        return colorScheme.primary.withValues(alpha: 0.3);
      } else if (states.contains(WidgetState.selected)) {
        return colorScheme.onPrimary;
      } else {
        return colorScheme.primary;
      }
    }),
    cancelButtonStyle: ButtonStyle(
      textStyle: WidgetStateProperty.resolveWith(
        (states) => textTheme.bodySmall,
      ),
      backgroundColor: WidgetStateProperty.resolveWith<Color?>((
        Set<WidgetState> states,
      ) {
        if (states.contains(WidgetState.pressed)) {
          return colorScheme.primary.withValues(alpha: 0.5);
        }
        return null; // Use the component's default.
      }),
    ),
    confirmButtonStyle: ButtonStyle(
      textStyle: WidgetStateProperty.resolveWith(
        (states) => textTheme.bodySmall,
      ),
      backgroundColor: WidgetStateProperty.resolveWith<Color?>((
        Set<WidgetState> states,
      ) {
        if (states.contains(WidgetState.pressed)) {
          return colorScheme.primary.withValues(alpha: 0.5);
        }
        return null; // Use the component's default.
      }),
    ),
  );

  DialogThemeData _dialogTheme({
    required ColorScheme colorScheme,
    required TextTheme textTheme,
  }) => DialogThemeData(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.white,
    shadowColor: Colors.black.withValues(alpha: 0.18),
    elevation: 6,
    alignment: Alignment.center,
    insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
    contentTextStyle: textTheme.bodySmall?.copyWith(
      color: Colours.charcoalLight,
      height: 1.4,
    ),
    titleTextStyle: textTheme.bodyLarge?.copyWith(
      color: Colours.primaryOne,
      fontWeight: FontWeight.w700,
    ),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(Dimensions.eight)),
    ),
  );

  FilledButtonThemeData _filledButtonTheme(TextTheme textTheme) =>
      FilledButtonThemeData(
        style: FilledButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colours.blueThree,
          minimumSize: const Size(0, 44),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(Dimensions.eight)),
          ),
        ),
      );

  PopupMenuThemeData _popMenuTheme({
    required ColorScheme colorScheme,
    required TextTheme textTheme,
  }) => PopupMenuThemeData(
    color: colorScheme.surface,
    surfaceTintColor: colorScheme.surface,
    elevation: 2,
    shadowColor: Get.isDarkMode ? Colors.white : Colors.black,
    textStyle: textTheme.labelLarge?.copyWith(color: colorScheme.onSurface),
    labelTextStyle: WidgetStateProperty.resolveWith(
      (states) => textTheme.labelLarge?.copyWith(color: colorScheme.onSurface),
    ),
  );

  /// Sets the theme for the elevated buttons
  ElevatedButtonThemeData _elevatedButtonTheme({
    required ColorScheme colorScheme,
    required TextTheme textTheme,
  }) => ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      disabledBackgroundColor: colorScheme.tertiary,
      disabledForegroundColor: colorScheme.onTertiary,
      minimumSize: const Size.fromHeight(50.0),
      textStyle: textTheme.bodyLarge,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(99)),
      ),
    ),
  );

  DropdownMenuThemeData _dropdownMenuTheme({
    required ColorScheme colorScheme,
    required TextTheme textTheme,
  }) => DropdownMenuThemeData(
    menuStyle: MenuStyle(
      alignment: Alignment.center,
      backgroundColor: WidgetStateProperty.resolveWith<Color?>(
        (states) => colorScheme.surface,
      ),
      surfaceTintColor: WidgetStateProperty.resolveWith<Color?>(
        (states) => colorScheme.surface,
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: Colours.searchBarBackground,
      labelStyle: TextStyle(color: Colours.charcoalLight),
      hintStyle: TextStyle(color: Colours.charcoalLight),
      prefixIconColor: Colours.charcoalLight,
      suffixIconColor: Colours.charcoalLight,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(Dimensions.eight)),
        borderSide: BorderSide(color: Colours.containerOne),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(Dimensions.eight)),
        borderSide: BorderSide(color: Colours.blueThree, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(Dimensions.eight)),
        borderSide: BorderSide(color: Colours.errorColour),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(Dimensions.eight)),
        borderSide: BorderSide(color: Colours.errorColour, width: 1.5),
      ),
    ),
    textStyle: textTheme.bodySmall,
  );

  OutlinedButtonThemeData _outlineButtonTheme({
    required ColorScheme colorScheme,
    required TextTheme textTheme,
  }) => OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: colorScheme.secondary,
      minimumSize: const Size.fromHeight(50.0),
      textStyle: textTheme.bodyLarge,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(99)),
      ),
      side: BorderSide(color: colorScheme.secondary),
    ),
  );

  /// Sets the theme for the floating action buttons
  FloatingActionButtonThemeData _floatingActionButtonTheme({
    required ColorScheme colorScheme,
  }) => FloatingActionButtonThemeData(
    backgroundColor: colorScheme.primary,
    foregroundColor: colorScheme.onPrimary,
  );

  TabBarThemeData _tabBarTheme({
    required ColorScheme colorScheme,
    required TextTheme textTheme,
  }) => TabBarThemeData(
    labelColor: colorScheme.primary,
    indicatorColor: colorScheme.secondary,
    dividerColor: colorScheme.primary.withValues(alpha: 0.2),
    unselectedLabelStyle: textTheme.bodySmall,
    labelStyle: textTheme.bodySmall,
  );

  DividerThemeData _dividerTheme({required ColorScheme colorScheme}) =>
      DividerThemeData(
        color: colorScheme.onSurface.withValues(alpha: 0.2),
        indent: 16,
        endIndent: 16,
        thickness: 1,
      );

  /// creates the icon theme data
  IconThemeData _iconTheme({required ColorScheme colorScheme}) =>
      IconThemeData(color: colorScheme.onSurface);

  /// Sets the theme for the App Bar
  AppBarTheme _appBarTheme({
    required ColorScheme colorScheme,
    required TextTheme textTheme,
  }) => AppBarTheme(
    systemOverlayStyle: Get.isDarkMode == true
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark,
    elevation: 6,
    titleSpacing: 0,
    centerTitle: true,
    backgroundColor: colorScheme.surface,
    surfaceTintColor: colorScheme.surface,
    shadowColor: colorScheme.surface,
    toolbarHeight: kIsWeb ? 64 : 40,
    scrolledUnderElevation: 3,
    foregroundColor: colorScheme.onPrimary,
    iconTheme: IconThemeData(color: colorScheme.onSurface),
    actionsIconTheme: IconThemeData(color: colorScheme.onSurface),
    titleTextStyle: textTheme.bodySmall?.copyWith(color: colorScheme.onSurface),
  );

  BottomSheetThemeData _bottomSheetThemeData({
    required ColorScheme colorScheme,
    required TextTheme textTheme,
  }) => BottomSheetThemeData(
    backgroundColor: colorScheme.surface,
    surfaceTintColor: colorScheme.surface,
    modalBackgroundColor: colorScheme.surface,
    modalBarrierColor: colorScheme.secondary.withValues(alpha: 0.5),
    elevation: 3,
  );

  TextButtonThemeData _textButtonThemeData(TextTheme textTheme) =>
      TextButtonThemeData(
        style: TextButton.styleFrom(
          iconColor: Colours.blueThree,
          foregroundColor: Colours.blueThree,
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      );
}

LinearGradient lightModeShimmerGradient = const LinearGradient(
  colors: [
    Color.fromRGBO(223, 231, 234, 1),
    Color.fromRGBO(212, 222, 226, 1),
    Color.fromRGBO(200, 213, 218, 1),
    Color.fromRGBO(212, 222, 226, 1),
    Color.fromRGBO(223, 231, 234, 1),
  ],
  stops: [0.0, 0.2, 0.5, 0.8, 1],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

LinearGradient darkModeShimmerGradient = const LinearGradient(
  colors: [
    Color.fromRGBO(66, 73, 93, 1),
    Color.fromRGBO(58, 64, 82, 1),
    Color.fromRGBO(50, 55, 70, 1),
    Color.fromRGBO(58, 64, 82, 1),
    Color.fromRGBO(66, 73, 93, 1),
  ],
  stops: [0.0, 0.2, 0.5, 0.8, 1],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

/// [cardBoxShadow] used on all cards
List<BoxShadow> cardBoxShadow = [
  BoxShadow(
    color: Colors.black.withValues(alpha: 0.1),
    blurRadius: 2,
    offset: const Offset(1, 3),
    spreadRadius: 2,
  ),
];

List<BoxShadow> characterCardBoxShadow = [
  BoxShadow(
    color: Colors.black.withValues(alpha: 0.3),
    blurRadius: 1,
    offset: const Offset(-1, 5),
    spreadRadius: 1,
  ),
];

List<BoxShadow> topSheetBoxShadow = [
  BoxShadow(
    color: Colors.black.withValues(alpha: 0.1),
    blurRadius: 1,
    offset: const Offset(-3, 0),
    spreadRadius: 1,
  ),
];

List<BoxShadow> lightBoxShadow = [
  BoxShadow(
    color: Colors.black.withValues(alpha: 0.1),
    blurRadius: 1,
    offset: const Offset(3, 3),
    spreadRadius: 1,
  ),
];

ColorFilter greenColorFilter = const ColorFilter.mode(
  Colors.green,
  BlendMode.srcIn,
);

ColorFilter orangeColorFilter = const ColorFilter.mode(
  Colors.orange,
  BlendMode.srcIn,
);

ColorFilter redColorFilter = const ColorFilter.mode(
  Colors.red,
  BlendMode.srcIn,
);

ColorFilter whiteColorFilter = const ColorFilter.mode(
  Colors.white,
  BlendMode.srcIn,
);

ColorFilter primaryColorFilter = ColorFilter.mode(
  Get.colorScheme.primary,
  BlendMode.srcIn,
);

ColorFilter onSecondaryColorFilter = ColorFilter.mode(
  Get.colorScheme.onSecondary,
  BlendMode.srcIn,
);

ColorFilter onSecondaryContainerColorFilter = ColorFilter.mode(
  Get.colorScheme.onSecondaryContainer,
  BlendMode.srcIn,
);

ColorFilter onTertiaryContainerColorFilter = ColorFilter.mode(
  Get.colorScheme.onTertiaryContainer,
  BlendMode.srcIn,
);

ColorFilter tertiaryContainerColorFilter = ColorFilter.mode(
  Get.colorScheme.tertiaryContainer,
  BlendMode.srcIn,
);

ColorFilter onSurfaceColorFilter = ColorFilter.mode(
  Get.colorScheme.onSurface,
  BlendMode.srcIn,
);

ColorFilter blackColorFilter = const ColorFilter.mode(
  Colors.black,
  BlendMode.srcIn,
);

ColorFilter onPrimaryColorFilter = ColorFilter.mode(
  Get.colorScheme.onPrimary,
  BlendMode.srcIn,
);

ColorFilter secondaryColorFilter = const ColorFilter.mode(
  Colours.secondary,
  BlendMode.srcIn,
);

/// Card Shimmers
Color lightModeShimmerBaseColor = Colors.grey.shade300;
Color lightModeShimmerHighlightColor = Colors.grey.shade100;
Color darkModeShimmerBaseColor = const Color.fromARGB(255, 74, 75, 78);
Color darkModeShimmerHighlightColor = const Color.fromARGB(255, 100, 101, 103);
