import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:social_code/core/theme/app_theme.dart';

class CreatorDropdown extends StatefulWidget {
  final String? initialValue;
  final ValueChanged<String?> onChanged;

  const CreatorDropdown({super.key, this.initialValue, required this.onChanged});

  @override
  State<CreatorDropdown> createState() => _CreatorDropdownState();
}

class _CreatorDropdownState extends State<CreatorDropdown> {
  List<Map<String, dynamic>> _creators = [];
  String? _selected;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCreators();
  }

  Future<void> _loadCreators() async {
    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('id, display_name')
          .eq('role', 'creator');
      if (mounted) {
        setState(() {
          _creators = List<Map<String, dynamic>>.from(response);
          _selected = widget.initialValue;
          
          // Ensure initialValue exists in list
          if (_selected != null && _selected!.isNotEmpty && !_creators.any((c) => c['display_name'] == _selected)) {
            _creators.add({'id': '', 'display_name': _selected});
          }
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('ARTIST / CREATOR NAME', style: GoogleFonts.spaceMono(fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        if (_loading)
          const Center(child: CircularProgressIndicator())
        else
          DropdownButtonFormField<String>(
            value: (_selected != null && _selected!.isNotEmpty) ? _selected : null,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface, width: 2)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppTheme.primaryMagenta, width: 2)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            items: _creators.map((c) {
              final name = c['display_name'] as String;
              return DropdownMenuItem(value: name, child: Text(name));
            }).toList(),
            onChanged: (val) {
              setState(() => _selected = val);
              widget.onChanged(val);
            },
          ),
      ],
    );
  }
}
