import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Widget réutilisable pour une BottomNavigationBar personnalisée
class ReusableBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<BottomNavItem> items;
  final Color? backgroundColor;
  final Color? selectedColor;
  final Color? unselectedColor;
  final double? elevation;
  final EdgeInsets? margin;
  final EdgeInsets? padding;
  final BorderRadius? borderRadius;

  const ReusableBottomNavigationBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.backgroundColor = Colors.white,
    this.selectedColor,
    this.unselectedColor,
    this.elevation,
    this.margin = const EdgeInsets.all(20),
    this.padding = const EdgeInsets.all(15),
    this.borderRadius = const BorderRadius.all(Radius.circular(10)),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final double smallScreenWidth = 355.0;

    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius,
        boxShadow: elevation != null
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: elevation!,
                  offset: const Offset(0, -2),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isSelected = currentIndex == index;

          return _BottomNavItemWidget(
            item: item,
            isSelected: isSelected,
            onTap: () => onTap(index),
            selectedColor: selectedColor ?? Theme.of(context).primaryColor,
            unselectedColor: unselectedColor ?? Colors.grey,
            smallScreenWidth: smallScreenWidth,
            screenWidth: screenSize.width,
          );
        }).toList(),
      ),
    );
  }
}

/// Widget pour chaque élément de la navigation
class _BottomNavItemWidget extends StatelessWidget {
  final BottomNavItem item;
  final bool isSelected;
  final VoidCallback onTap;
  final Color selectedColor;
  final Color unselectedColor;
  final double smallScreenWidth;
  final double screenWidth;

  const _BottomNavItemWidget({
    required this.item,
    required this.isSelected,
    required this.onTap,
    required this.selectedColor,
    required this.unselectedColor,
    required this.smallScreenWidth,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    final buttonSize = screenWidth < smallScreenWidth ? 48.0 : 55.0;

    return Tooltip(
      message: item.tooltip,
      textStyle: const TextStyle(
        fontSize: 16,
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
      child: _CustomIconButton(
        onTap: onTap,
        backgroundColor: isSelected
            ? selectedColor.withOpacity(0.5)
            : Colors.transparent,
        fixedSize: Size(buttonSize, 50),
        child: _buildIcon(),
      ),
    );
  }

  Widget _buildIcon() {
    if (item.icon is IconData) {
      return Icon(
        item.icon as IconData,
        color: isSelected ? selectedColor : unselectedColor,
        size: 24,
      );
    } else if (item.icon is String) {
      // Pour les icônes SVG
      return SvgPicture.asset(
        item.icon as String,
        height: 30,
        width: 30,
        color: isSelected ? selectedColor : unselectedColor,
      );
    } else {
      // Pour les widgets personnalisés
      return item.icon as Widget;
    }
  }
}

/// Widget bouton personnalisé pour les éléments de navigation
class _CustomIconButton extends StatelessWidget {
  final VoidCallback? onTap;
  final Color backgroundColor;
  final Size fixedSize;
  final Widget child;

  const _CustomIconButton({
    this.onTap,
    required this.backgroundColor,
    required this.fixedSize,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: fixedSize.height,
      width: fixedSize.width,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Center(child: child),
        ),
      ),
    );
  }
}

/// Classe pour définir les éléments de navigation
class BottomNavItem {
  final dynamic icon; // IconData, String (pour SVG), ou Widget
  final String tooltip;
  final String? label;

  const BottomNavItem({
    required this.icon,
    required this.tooltip,
    this.label,
  });
}

/// Exemple d'utilisation avec des icônes Material
class MaterialBottomNavItem extends BottomNavItem {
  const MaterialBottomNavItem({
    required IconData icon,
    required String tooltip,
    String? label,
  }) : super(
          icon: icon,
          tooltip: tooltip,
          label: label,
        );
}

/// Exemple d'utilisation avec des icônes SVG
class SvgBottomNavItem extends BottomNavItem {
  const SvgBottomNavItem({
    required String svgPath,
    required String tooltip,
    String? label,
  }) : super(
          icon: svgPath,
          tooltip: tooltip,
          label: label,
        );
}

/// Exemple d'utilisation avec des widgets personnalisés
class CustomBottomNavItem extends BottomNavItem {
  const CustomBottomNavItem({
    required Widget widget,
    required String tooltip,
    String? label,
  }) : super(
          icon: widget,
          tooltip: tooltip,
          label: label,
        );
}
