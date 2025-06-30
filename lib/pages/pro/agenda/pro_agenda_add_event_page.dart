import 'package:flutter/material.dart';

class ProAgendaAddEventPage extends StatefulWidget {
  const ProAgendaAddEventPage({super.key});

  @override
  State<ProAgendaAddEventPage> createState() => _ProAgendaAddEventPageState();
}

class _ProAgendaAddEventPageState extends State<ProAgendaAddEventPage> {
  final _formKey = GlobalKey<FormState>();
  String title = '';
  String type = 'Tatouage';
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();
  String? location;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter un événement'),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Titre',
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white38)),
              ),
              validator: (value) => value == null || value.isEmpty ? 'Champ obligatoire' : null,
              onChanged: (value) => setState(() => title = value),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              dropdownColor: Colors.black,
              value: type,
              items: ['Tatouage', 'Devis', 'Déplacement'].map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type, style: const TextStyle(color: Colors.white)),
                );
              }).toList(),
              onChanged: (value) => setState(() => type = value!),
              decoration: const InputDecoration(
                labelText: 'Type',
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white38)),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              title: Text(
                'Date : ${selectedDate.toLocal().toString().split(' ')[0]}',
                style: const TextStyle(color: Colors.white),
              ),
              trailing: const Icon(Icons.calendar_today, color: Colors.white),
              onTap: _pickDate,
            ),
            ListTile(
              title: Text(
                'Heure : ${selectedTime.format(context)}',
                style: const TextStyle(color: Colors.white),
              ),
              trailing: const Icon(Icons.access_time, color: Colors.white),
              onTap: _pickTime,
            ),
            const SizedBox(height: 20),
            TextFormField(
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Localisation (optionnelle)',
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white38)),
              ),
              onChanged: (value) => setState(() => location = value),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
              ),
              child: const Text('Ajouter'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        selectedDate = date;
      });
    }
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );
    if (time != null) {
      setState(() {
        selectedTime = time;
      });
    }
  }
}
