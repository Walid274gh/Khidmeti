// lib/screens/edit_profile/edit_profile_screen.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../utils/localization.dart';
import '../../utils/system_ui_overlay.dart';
import '../../utils/validation_form.dart';
import '../../providers/edit_profile_provider.dart';

// ============================================================================
// EDIT PROFILE SCREEN — getSurfaceDecoration() deleted, inline BoxDecoration
// ============================================================================

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _nameFocus  = FocusNode();
  final _phoneFocus = FocusNode();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;

  String? _pickedImagePath;

  @override
  void initState() {
    super.initState();
    _nameCtrl  = TextEditingController();
    _phoneCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _nameFocus.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  void _onDataLoaded(EditProfileState state) {
    _nameCtrl.text  = state.name;
    _phoneCtrl.text = state.phone;
  }

  Future<void> _pickImage() async {
    final file = await ImagePicker().pickImage(
      source:       ImageSource.gallery,
      maxWidth:     512,
      maxHeight:    512,
      imageQuality: 85,
    );
    if (file != null && mounted) {
      setState(() => _pickedImagePath = file.path);
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    final success = await ref.read(editProfileProvider.notifier).save(
      name:         _nameCtrl.text,
      phone:        _phoneCtrl.text,
      newImagePath: _pickedImagePath,
    );

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:  Text(context.tr('profile.save_success')),
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<EditProfileState>(editProfileProvider, (prev, next) {
      if (prev?.status == EditProfileStatus.loading &&
          next.status == EditProfileStatus.idle) {
        _onDataLoaded(next);
      }
    });

    final state  = ref.watch(editProfileProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme  = Theme.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemOverlayStyle(isDark),
      child: Scaffold(
        backgroundColor:        theme.colorScheme.surface,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor:        Colors.transparent,
          elevation:              0,
          scrolledUnderElevation: 0,
          title: Text(context.tr('profile.edit_profile'), style: theme.textTheme.titleLarge),
          centerTitle: true,
          leading: Semantics(
            label: context.tr('common.back'),
            child: IconButton(
              icon:     const Icon(AppIcons.back),
              onPressed: () => context.pop(),
              tooltip:  context.tr('common.back'),
            ),
          ),
        ),
        body: switch (state.status) {
          EditProfileStatus.loading => const _LoadingView(),
          EditProfileStatus.error   => _ErrorView(
              message: state.errorMessage,
              onRetry: () => ref.read(editProfileProvider.notifier).retry(),
            ),
          _ => _FormView(
              state:           state,
              isDark:          isDark,
              formKey:         _formKey,
              nameCtrl:        _nameCtrl,
              phoneCtrl:       _phoneCtrl,
              nameFocus:       _nameFocus,
              phoneFocus:      _phoneFocus,
              pickedImagePath: _pickedImagePath,
              isSaving:        state.status == EditProfileStatus.saving,
              onPickImage:     _pickImage,
              onSave:          _save,
            ),
        },
      ),
    );
  }
}

// ============================================================================
// PRIVATE — FORM VIEW
// ============================================================================

class _FormView extends StatelessWidget {
  final EditProfileState      state;
  final bool                  isDark;
  final GlobalKey<FormState>  formKey;
  final TextEditingController nameCtrl;
  final TextEditingController phoneCtrl;
  final FocusNode             nameFocus;
  final FocusNode             phoneFocus;
  final String?               pickedImagePath;
  final bool                  isSaving;
  final VoidCallback          onPickImage;
  final VoidCallback          onSave;

  const _FormView({
    required this.state,
    required this.isDark,
    required this.formKey,
    required this.nameCtrl,
    required this.phoneCtrl,
    required this.nameFocus,
    required this.phoneFocus,
    required this.pickedImagePath,
    required this.isSaving,
    required this.onPickImage,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Form(
      key: formKey,
      child: ListView(
        padding: EdgeInsetsDirectional.only(
          top:    MediaQuery.of(context).padding.top + kToolbarHeight + 24,
          bottom: MediaQuery.of(context).padding.bottom + AppConstants.spacingXl,
          start:  AppConstants.paddingMd,
          end:    AppConstants.paddingMd,
        ),
        children: [
          // ── Avatar picker ─────────────────────────────────────────────────
          Center(
            child: Semantics(
              label:  context.tr('profile.change_photo'),
              button: true,
              child: GestureDetector(
                onTap: isSaving ? null : onPickImage,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width:  96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape:  BoxShape.circle,
                        border: Border.all(
                          color: theme.colorScheme.primary.withOpacity(0.5),
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:      theme.colorScheme.primary.withOpacity(0.2),
                            blurRadius: 16,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: _AvatarImage(
                          pickedPath: pickedImagePath,
                          networkUrl: state.profileImageUrl,
                          name:       state.name,
                        ),
                      ),
                    ),
                    PositionedDirectional(
                      bottom: 0,
                      end:    0,
                      child: Container(
                        width:  30,
                        height: 30,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.colorScheme.primary,
                          border: Border.all(color: theme.colorScheme.surface, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppConstants.spacingXl),

          // ── Email — read-only ─────────────────────────────────────────────
          _ReadOnlyField(
            label: context.tr('auth.email'),
            value: state.email,
            icon:  AppIcons.email,
            isDark: isDark,
          ),
          const SizedBox(height: AppConstants.spacingMd),

          AutofillGroup(
            child: Column(
              children: [
                TextFormField(
                  controller:      nameCtrl,
                  focusNode:       nameFocus,
                  textInputAction: TextInputAction.next,
                  enabled:         !isSaving,
                  maxLength:       AppConstants.maxUsernameLength,
                  autofillHints:   const [AutofillHints.name],
                  onFieldSubmitted: (_) => phoneFocus.requestFocus(),
                  validator: (v) => FormValidators.validateUsername(v, context),
                  decoration: InputDecoration(
                    labelText:  context.tr('profile.full_name'),
                    prefixIcon: const Icon(AppIcons.person),
                  ),
                ),
                const SizedBox(height: AppConstants.spacingMd),
                TextFormField(
                  controller:      phoneCtrl,
                  focusNode:       phoneFocus,
                  textInputAction: TextInputAction.done,
                  enabled:         !isSaving,
                  keyboardType:    TextInputType.phone,
                  autofillHints:   const [AutofillHints.telephoneNumber],
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s()]')),
                  ],
                  validator: (v) => FormValidators.validatePhone(v, context),
                  decoration: InputDecoration(
                    labelText:  context.tr('profile.phone_number'),
                    prefixIcon: const Icon(AppIcons.phone),
                  ),
                ),
              ],
            ),
          ),

          if (state.isWorkerAccount && state.professionLabel != null) ...[
            const SizedBox(height: AppConstants.spacingMd),
            _ReadOnlyField(
              label:   context.tr('profile.profession'),
              value:   context.tr('services.${state.professionLabel}'),
              icon:    AppIcons.jobs,
              isDark:  isDark,
              caption: context.tr('profile.profession_change_note'),
            ),
          ],
          const SizedBox(height: AppConstants.spacingXl),

          Semantics(
            label:  context.tr('profile.save_changes'),
            button: true,
            child: SizedBox(
              width:  double.infinity,
              height: AppConstants.buttonHeight,
              child: ElevatedButton(
                onPressed: isSaving ? null : onSave,
                child: isSaving
                    ? SizedBox(
                        width:  20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color:       theme.colorScheme.onPrimary,
                        ),
                      )
                    : Text(
                        context.tr('profile.save_changes'),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// PRIVATE — AVATAR IMAGE
// ============================================================================

class _AvatarImage extends StatelessWidget {
  final String? pickedPath;
  final String? networkUrl;
  final String  name;

  const _AvatarImage({
    required this.pickedPath,
    required this.networkUrl,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    if (pickedPath != null) {
      return Image.file(
        File(pickedPath!),
        fit:          BoxFit.cover,
        errorBuilder: (_, __, ___) => _Initials(name: name),
      );
    }
    if (networkUrl != null && networkUrl!.isNotEmpty) {
      return Image.network(
        networkUrl!,
        fit: BoxFit.cover,
        loadingBuilder: (_, child, progress) =>
            progress == null ? child : _Initials(name: name),
        errorBuilder: (_, __, ___) => _Initials(name: name),
      );
    }
    return _Initials(name: name);
  }
}

class _Initials extends StatelessWidget {
  final String name;
  const _Initials({required this.name});

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().isEmpty
        ? '?'
        : name.trim()
            .split(' ')
            .where((w) => w.isNotEmpty)
            .map((w) => w[0])
            .take(2)
            .join()
            .toUpperCase();

    return Container(
      color:     Theme.of(context).colorScheme.primaryContainer,
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          fontSize:   28,
          fontWeight: FontWeight.w700,
          color:      Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}

// ============================================================================
// PRIVATE — READ-ONLY FIELD
// ============================================================================

class _ReadOnlyField extends StatelessWidget {
  final String   label;
  final String   value;
  final IconData icon;
  final bool     isDark;
  final String?  caption;

  const _ReadOnlyField({
    required this.label,
    required this.value,
    required this.icon,
    required this.isDark,
    this.caption,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
              width: 0.5,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: theme.colorScheme.outline, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.lock_outline_rounded,
                size:  16,
                color: theme.colorScheme.outline.withOpacity(0.5),
              ),
            ],
          ),
        ),
        if (caption != null) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 4),
            child: Text(
              caption!,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ============================================================================
// PRIVATE — LOADING / ERROR VIEWS
// ============================================================================

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) => Center(
        child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
      );
}

class _ErrorView extends StatelessWidget {
  final String?      message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(AppIcons.error, size: 64, color: theme.colorScheme.error.withOpacity(0.6)),
            const SizedBox(height: AppConstants.paddingMd),
            Text(context.tr('common.error'), style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: AppConstants.spacingSm),
            Text(
              message != null ? context.tr(message!) : context.tr('errors.unknown'),
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.spacingLg),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon:  const Icon(Icons.refresh_rounded),
              label: Text(context.tr('common.retry')),
            ),
          ],
        ),
      ),
    );
  }
}
