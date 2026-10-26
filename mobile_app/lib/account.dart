import 'package:flutter/material.dart';

import 'api.dart';
import 'models.dart';
import 'widgets.dart';

/// Profile form (GET/PUT /users/profile) — shared by faculty Profile tab
/// and admin Settings tab.
class ProfileForm extends StatefulWidget {
  const ProfileForm({super.key});

  @override
  State<ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<ProfileForm> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _designation = TextEditingController();
  final _rank = TextEditingController();
  final _contact = TextEditingController();
  final _college = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _designation.dispose();
    _rank.dispose();
    _contact.dispose();
    _college.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final p =
          Map<String, dynamic>.from(await ApiClient.instance.get('/users/profile'));
      final profile = Profile.fromJson(p);
      _name.text = profile.fullName;
      _email.text = profile.email;
      _designation.text = profile.designation ?? '';
      _rank.text = profile.academicRank ?? '';
      _contact.text = profile.contactNumber ?? '';
      _college.text = profile.collegeName ??
          (profile.collegeId != null ? '—' : 'Not assigned');
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ApiClient.instance.put('/users/profile', {
        'full_name': _name.text.trim(),
        'designation': _designation.text.trim().isEmpty ? null : _designation.text.trim(),
        'academic_rank': _rank.text.trim().isEmpty ? null : _rank.text.trim(),
        'contact_number': _contact.text.trim().isEmpty ? null : _contact.text.trim(),
      }, okMsg: 'Profile updated successfully');
      await Session.instance.updateDisplayName(_name.text.trim());
    } catch (e) {
      if (mounted) await showApiError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingBox();
    if (_error != null) return EmptyState(message: 'Error: $_error');
    return SectionCard(
      title: 'Personal & Academic Info',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Full Name *'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _email,
              enabled: false,
              decoration: const InputDecoration(
                  labelText: 'Email', helperText: 'Email cannot be changed'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _designation,
              decoration: const InputDecoration(
                  labelText: 'Designation',
                  hintText: 'e.g. Instructor, Associate Professor'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _rank,
              decoration: const InputDecoration(
                  labelText: 'Academic Rank',
                  hintText: 'e.g. Assistant Professor III'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _contact,
              decoration: const InputDecoration(
                  labelText: 'Contact Number',
                  hintText: 'e.g. +63 912 345 6789'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _college,
              enabled: false,
              decoration: const InputDecoration(labelText: 'College'),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15)),
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save Profile'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Change-password form (POST /users/change-password).
class ChangePasswordForm extends StatefulWidget {
  const ChangePasswordForm({super.key});

  @override
  State<ChangePasswordForm> createState() => _ChangePasswordFormState();
}

class _ChangePasswordFormState extends State<ChangePasswordForm> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ApiClient.instance.post('/users/change-password', {
        'current_password': _current.text,
        'new_password': _new.text,
      }, okMsg: 'Password changed successfully');
      _current.clear();
      _new.clear();
      _confirm.clear();
      _formKey.currentState!.reset();
    } catch (e) {
      if (mounted) await showApiError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Change Password',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _current,
              obscureText: true,
              decoration:
                  const InputDecoration(labelText: 'Current Password *'),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _new,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New Password *'),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                if (v.length < 8) return 'Minimum 8 characters';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _confirm,
              obscureText: true,
              decoration:
                  const InputDecoration(labelText: 'Confirm New Password *'),
              validator: (v) =>
                  (v != _new.text) ? 'Passwords do not match' : null,
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15)),
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Change Password'),
            ),
          ],
        ),
      ),
    );
  }
}
