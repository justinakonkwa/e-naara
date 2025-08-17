import 'package:flutter/material.dart';

class CustomSearchBar extends StatefulWidget {
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onFilterTap;
  final VoidCallback? onTap;
  final TextEditingController? controller;
  final bool showFilter;
  final bool enabled;

  const CustomSearchBar({
    super.key,
    this.hintText = 'Rechercher des produits...',
    this.onChanged,
    this.onSubmitted,
    this.onFilterTap,
    this.onTap,
    this.controller,
    this.showFilter = true,
    this.enabled = true,
  });

  @override
  State<CustomSearchBar> createState() => _CustomSearchBarState();
}

class _CustomSearchBarState extends State<CustomSearchBar> {
  late TextEditingController _controller;
  bool _isActive = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: _isActive 
                ? theme.colorScheme.primary 
                : theme.colorScheme.outline.withValues(alpha: 0.2),
            width: _isActive ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                enabled: widget.enabled,
                onChanged: widget.onChanged,
                onSubmitted: widget.onSubmitted,
                onTap: () {
                  widget.onTap?.call();
                  setState(() => _isActive = true);
                },
                onTapOutside: (_) => setState(() => _isActive = false),
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  hintStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    size: 22,
                  ),
                  suffixIcon: _controller.text.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            _controller.clear();
                            widget.onChanged?.call('');
                          },
                          child: Icon(
                            Icons.clear,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            size: 20,
                          ),
                        )
                      : null,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
            if (widget.showFilter) ...[
              Container(
                width: 1,
                height: 24,
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
              ),
              GestureDetector(
                onTap: widget.onFilterTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Icon(
                    Icons.tune,
                    color: theme.colorScheme.primary,
                    size: 22,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class SearchSuggestion extends StatelessWidget {
  final String text;
  final IconData icon;
  final String? subtitle;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const SearchSuggestion({
    super.key,
    required this.text,
    required this.icon,
    this.subtitle,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      onTap: onTap,
      leading: Icon(
        icon,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        size: 20,
      ),
      title: Text(
        text,
        style: theme.textTheme.bodyMedium,
      ),
      subtitle: subtitle != null ? Text(
        subtitle!,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      ) : null,
      trailing: onDelete != null
          ? IconButton(
              onPressed: onDelete,
              icon: Icon(
                Icons.delete_outline,
                color: theme.colorScheme.error,
                size: 20,
              ),
            )
          : Icon(
              Icons.call_made,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              size: 16,
            ),
    );
  }
}
