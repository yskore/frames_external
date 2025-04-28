import 'package:flutter/material.dart';

class OwnershipOption {
  final String code;
  final String title;
  final String description;

  OwnershipOption({
    required this.code,
    required this.title,
    required this.description,
  });
}

class OwnershipSelectionWidget extends StatefulWidget {
  final String initialValue;
  final Function(String) onChanged;
  final bool isEditing;

  const OwnershipSelectionWidget({
    Key? key,
    required this.initialValue,
    required this.onChanged,
    this.isEditing = true,
  }) : super(key: key);

  @override
  State<OwnershipSelectionWidget> createState() => _OwnershipSelectionWidgetState();
}

class _OwnershipSelectionWidgetState extends State<OwnershipSelectionWidget> {
  late String _selectedOption;
  
  final List<OwnershipOption> _options = [
    OwnershipOption(
      code: '00',
      title: 'No Original Ownership',
      description: 'I do not own the original physical or digital copy',
    ),
    OwnershipOption(
      code: '10',
      title: 'Physical Original Only',
      description: 'I own the original physical copy but not the digital original',
    ),
    OwnershipOption(
      code: '01',
      title: 'Digital Original Only',
      description: 'I own the original digital copy but not the physical original',
    ),
    OwnershipOption(
      code: '11',
      title: 'Full Original Ownership',
      description: 'I own both the original physical and digital copies',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedOption = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ownership Status',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        if (!widget.isEditing)
          _buildReadOnlyView()
        else
          _buildSelectionList(),
      ],
    );
  }

  Widget _buildReadOnlyView() {
    final option = _options.firstWhere(
      (opt) => opt.code == _selectedOption,
      orElse: () => _options.first,
    );
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            option.title,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4),
          Text(option.description),
        ],
      ),
    );
  }

  Widget _buildSelectionList() {
    return Column(
      children: _options.map((option) => _buildOptionTile(option)).toList(),
    );
  }

  Widget _buildOptionTile(OwnershipOption option) {
    final isSelected = _selectedOption == option.code;
    
    return InkWell(
      onTap: () {
        setState(() {
          _selectedOption = option.code;
        });
        widget.onChanged(option.code);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? Colors.blue.withOpacity(0.05) : null,
        ),
        child: Row(
          children: [
            Radio<String>(
              value: option.code,
              groupValue: _selectedOption,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedOption = value;
                  });
                  widget.onChanged(value);
                }
              },
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.blue : Colors.black,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    option.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}