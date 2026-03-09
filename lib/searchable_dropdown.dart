import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';

class SearchableDropdown<T> extends StatelessWidget {
  final List<T> items;
  final T? selectedItem;
  final String label;
  final String hint;
  final bool enabled;
  final String Function(T) itemAsString;
  final void Function(T?) onChanged;

  const SearchableDropdown({
    super.key,
    required this.items,
    required this.selectedItem,
    required this.itemAsString,
    required this.onChanged,
    this.label = '',
    this.hint = 'Search...',
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownSearch<T>(
      items: items,
      selectedItem: selectedItem,
      enabled: enabled,

      itemAsString: itemAsString,

      popupProps: PopupProps.menu(
        showSearchBox: true,
        searchFieldProps: TextFieldProps(
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),

      dropdownButtonProps: const DropdownButtonProps(
        icon: Icon(Icons.arrow_drop_down, color: Color(0xFFE86B24)),
      ),

      dropdownDecoratorProps: DropDownDecoratorProps(
        dropdownSearchDecoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFE86B24), width: 1.5),
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
      ),

      onChanged: onChanged,
    );
  }
}