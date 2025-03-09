// This goes in the Sign up screen (signup_screen.dart file)for users to select a country
import 'package:flutter/material.dart';
import 'package:country_picker/country_picker.dart';

class CountryPickerTile extends StatefulWidget {
  final Function(String) onCountrySelected;

  CountryPickerTile({required this.onCountrySelected});

  @override
  _CountryPickerTileState createState() => _CountryPickerTileState();
}

class _CountryPickerTileState extends State<CountryPickerTile> {
  String selectedCountry = 'Country';

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(selectedCountry),
      onTap: () {
        showCountryPicker(
          context: context,
          exclude: <String>['KN', 'MF'],
          favorite: <String>['SE'],
          showPhoneCode: true,
          onSelect: (Country country) {
            print('Select country: ${country.displayName}');
            widget.onCountrySelected(country.displayName);
            setState(() {
              selectedCountry = country.displayName;
            });
          },
          countryListTheme: CountryListThemeData(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(40.0),
              topRight: Radius.circular(40.0),
            ),
            inputDecoration: InputDecoration(
              labelText: 'Search',
              hintText: 'Start typing to search',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderSide: BorderSide(
                  color: const Color(0xFF8C98A8).withOpacity(0.2),
                ),
              ),
            ),
          ),
        );
      },
      trailing: Icon(Icons.keyboard_arrow_down),
    );
  }
}
