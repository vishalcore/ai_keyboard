import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class QuestionnaireScreen extends StatefulWidget {
  const QuestionnaireScreen({super.key});

  @override
  State<QuestionnaireScreen> createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends State<QuestionnaireScreen> {
  final _formKey = GlobalKey<FormState>();

  String name = '';
  String age = '';
  String gender = 'Male'; // default
  String interests = '';

  final List<String> genderOptions = ['Male', 'Female', 'Non-binary', 'Prefer not to say'];

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final box = Hive.box('userProfile');
      await box.put('profile', {
        'name': name,
        'age': age,
        'gender': gender,
        'interests': interests,
      });

      Navigator.pushReplacementNamed(context, '/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tell us about you')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Name'),
                onSaved: (value) => name = value ?? '',
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Age'),
                keyboardType: TextInputType.number,
                onSaved: (value) => age = value ?? '',
              ),
              DropdownButtonFormField<String>(
                value: gender,
                items: genderOptions
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    gender = value!;
                  });
                },
                decoration: const InputDecoration(labelText: 'Gender'),
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Interests'),
                onSaved: (value) => interests = value ?? '',
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitForm,
                child: const Text('Continue'),
              )
            ],
          ),
        ),
      ),
    );
  }
}