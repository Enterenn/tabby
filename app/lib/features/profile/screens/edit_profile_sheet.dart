import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/auth/password_policy.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/models/user.dart';
import '../../../design_system/design_system.dart';
import '../../auth/cubit/auth_cubit.dart';

Future<void> showEditProfileSheet(BuildContext context) {
  return showTabbySheet<void>(
    context,
    isScrollControlled: true,
    builder: (_) => const _EditProfileSheet(),
  );
}

Future<void> pickAndUploadAvatar(BuildContext context) async {
  final l10n = context.l10n;
  final source = await showTabbySheet<ImageSource>(
    context,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(ctx.l10n.changeAvatar, style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Symbols.photo_library_rounded),
              title: Text(ctx.l10n.pickGallery),
              shape: ctx.tabbyShapes.fieldShape,
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Symbols.photo_camera_rounded),
              title: Text(ctx.l10n.pickCamera),
              shape: ctx.tabbyShapes.fieldShape,
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          ],
        ),
      ),
    ),
  );
  if (source == null || !context.mounted) return;

  final picked = await ImagePicker().pickImage(source: source, imageQuality: 92);
  if (picked == null || !context.mounted) return;

  final error = await _validateAvatar(picked.path, l10n);
  if (!context.mounted) return;
  if (error != null) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    return;
  }

  final uploadError =
      await context.read<AuthCubit>().uploadAvatar(picked.path);
  if (!context.mounted) return;
  if (uploadError != null) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(context.l10nError(uploadError))));
  }
}

Future<String?> _validateAvatar(String path, AppLocalizations l10n) async {
  final ext = path.split('.').last.toLowerCase();
  if (ext != 'jpg' && ext != 'jpeg' && ext != 'png' && ext != 'webp') {
    return l10n.avatarInvalidType;
  }
  final file = File(path);
  if (await file.length() > 20 * 1024 * 1024) {
    return l10n.avatarTooLarge;
  }
  return null;
}

class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet();

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  final _profileKey = GlobalKey<FormState>();
  final _passwordKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _savingProfile = false;
  bool _savingPassword = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;

  @override
  void initState() {
    super.initState();
    final user = _user;
    _nameCtrl = TextEditingController(text: user?.name ?? '');
    _emailCtrl = TextEditingController(text: user?.email ?? '');
  }

  User? get _user {
    final state = context.read<AuthCubit>().state;
    return state is AuthAuthenticated ? state.user : null;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_profileKey.currentState!.validate()) return;
    setState(() => _savingProfile = true);
    final err = await context.read<AuthCubit>().updateProfile(
          name: _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
        );
    if (!mounted) return;
    setState(() => _savingProfile = false);
    if (err != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10nError(err))));
      return;
    }
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(context.l10n.profileSaved)));
  }

  Future<void> _savePassword() async {
    if (!_passwordKey.currentState!.validate()) return;
    setState(() => _savingPassword = true);
    final err = await context.read<AuthCubit>().changePassword(
          currentPassword: _currentCtrl.text,
          newPassword: _newCtrl.text,
        );
    if (!mounted) return;
    setState(() => _savingPassword = false);
    if (err != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10nError(err))));
      return;
    }
    _currentCtrl.clear();
    _newCtrl.clear();
    _confirmCtrl.clear();
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(context.l10n.passwordChanged)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 24 + bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            ExpressiveSheetHeader(
              title: l10n.editProfile,
              subtitle: l10n.personalInfoHint,
              onClose: () => Navigator.pop(context),
            ),
            Form(
              key: _profileKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(labelText: l10n.nameLabel),
                    validator: (v) {
                      final name = v?.trim() ?? '';
                      if (name.length < 2) return l10n.nameTooShort;
                      if (name.length > 50) return l10n.nameTooLong;
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(labelText: l10n.loginEmail),
                    validator: (v) =>
                        v == null || !v.contains('@') ? l10n.invalidEmail : null,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _savingProfile ? null : _saveProfile,
                      child: _savingProfile
                          ? const TabbyButtonSpinner()
                          : Text(l10n.save),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Text(l10n.passwordSection, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Form(
              key: _passwordKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _currentCtrl,
                    obscureText: _obscureCurrent,
                    decoration: InputDecoration(
                      labelText: l10n.currentPassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureCurrent
                              ? Symbols.visibility_off_rounded
                              : Symbols.visibility_rounded,
                        ),
                        onPressed: () =>
                            setState(() => _obscureCurrent = !_obscureCurrent),
                      ),
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? l10n.requiredField : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _newCtrl,
                    obscureText: _obscureNew,
                    decoration: InputDecoration(
                      labelText: l10n.newPassword,
                      helperText: l10n.passwordPolicy,
                      helperMaxLines: 2,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureNew
                              ? Symbols.visibility_off_rounded
                              : Symbols.visibility_rounded,
                        ),
                        onPressed: () =>
                            setState(() => _obscureNew = !_obscureNew),
                      ),
                    ),
                    validator: (v) => validatePassword(v, l10n),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _confirmCtrl,
                    obscureText: _obscureNew,
                    decoration: InputDecoration(labelText: l10n.confirmPassword),
                    validator: (v) =>
                        v != _newCtrl.text ? l10n.passwordMismatch : null,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonal(
                      onPressed: _savingPassword ? null : _savePassword,
                      child: _savingPassword
                          ? TabbyButtonSpinner(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                            )
                          : Text(l10n.changePassword),
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
