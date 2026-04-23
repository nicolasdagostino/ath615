part of 'admin_screen.dart';

extension _AdminScreenGymModal on _AdminScreenState {
  void _showGymModal() {
    final nameCtrl = TextEditingController(text: _adminGymName);
    String logoUrl = _adminGymLogoUrl;
    bool saving = false;

    InputDecoration inputDecoration(String label, {String? hint}) {
      return InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        labelStyle: _font(
          12,
          weight: FontWeight.w500,
          color: const Color(0xFF667085),
        ),
        hintStyle: _font(
          13,
          weight: FontWeight.w500,
          color: const Color(0xFF98A2B3),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFB59B6A), width: 1.2),
        ),
      );
    }

    Future<void> pickLogo(StateSetter setLocalState) async {
      try {
        final picked = await _picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 85,
          maxWidth: 1200,
        );
        if (picked == null) return;

        final gymId = await _resolvedGymIdForAdmin();
        if (gymId == null || gymId.isEmpty) {
          throw Exception(_uiText('No se encontró el gym.', 'Gym not found.'));
        }

        setLocalState(() => saving = true);
        final uploaded = await _storageRepo.uploadGymLogo(
          File(picked.path),
          gymId,
        );
        if (!mounted) return;

        setLocalState(() {
          logoUrl = uploaded;
        });
      } catch (e) {
        if (!mounted) return;
        _toast(e.toString().replaceFirst('Exception: ', ''), isError: true);
      } finally {
        if (mounted) {
          setLocalState(() => saving = false);
        }
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  0,
                  16,
                  16 + MediaQuery.of(sheetContext).viewInsets.bottom,
                ),
                child: Container(
                  width: double.infinity,
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(sheetContext).size.height * 0.88,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 42,
                            height: 5,
                            decoration: BoxDecoration(
                              color: const Color(0xFFD7DBE1),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF7F3EA),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.storefront_rounded,
                                color: Color(0xFFB59B6A),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _uiText('Configurar gym', 'Gym settings'),
                                    style: _font(
                                      24,
                                      weight: FontWeight.w800,
                                      color: const Color(0xFF111318),
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _uiText(
                                      'Nombre y logo que verá el atleta.',
                                      'Name and logo athletes will see.',
                                    ),
                                    style: _font(
                                      13,
                                      weight: FontWeight.w500,
                                      color: const Color(0xFF8F96A3),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () => Navigator.pop(sheetContext),
                              child: Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: const Color(0xFFE8EBF0),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  size: 22,
                                  color: Color(0xFF111318),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        Center(
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 44,
                                backgroundColor: const Color(0xFFF3F4F6),
                                backgroundImage: logoUrl.trim().isNotEmpty
                                    ? NetworkImage(logoUrl.trim())
                                    : null,
                                child: logoUrl.trim().isEmpty
                                    ? const Icon(
                                        Icons.fitness_center,
                                        size: 28,
                                        color: Color(0xFF8A90A0),
                                      )
                                    : null,
                              ),
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: saving
                                    ? null
                                    : () => pickLogo(setLocalState),
                                child: Text(
                                  saving
                                      ? _uiText('Subiendo...', 'Uploading...')
                                      : _uiText('Cambiar logo', 'Change logo'),
                                  style: _font(
                                    15,
                                    weight: FontWeight.w700,
                                    color: const Color(0xFFB59B6A),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _uiText('Nombre del gym', 'Gym name'),
                          style: _font(
                            15,
                            weight: FontWeight.w800,
                            color: const Color(0xFF111318),
                            letterSpacing: -0.1,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: nameCtrl,
                          textCapitalization: TextCapitalization.words,
                          decoration: inputDecoration(
                            _uiText('Nombre', 'Name'),
                            hint: _uiText('Athlete 615', 'Athlete 615'),
                          ),
                          style: _font(
                            16,
                            weight: FontWeight.w600,
                            color: const Color(0xFF111318),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: saving
                                ? null
                                : () async {
                                    final cleanName = nameCtrl.text.trim();
                                    if (cleanName.isEmpty) {
                                      _toast(
                                        _uiText(
                                          'El nombre del gym es obligatorio.',
                                          'Gym name is required.',
                                        ),
                                        isError: true,
                                      );
                                      return;
                                    }

                                    final gymId =
                                        await _resolvedGymIdForAdmin();
                                    if (gymId == null || gymId.isEmpty) {
                                      _toast(
                                        _uiText(
                                          'No se encontró el gym.',
                                          'Gym not found.',
                                        ),
                                        isError: true,
                                      );
                                      return;
                                    }

                                    if (!sheetContext.mounted) return;
                                    Navigator.of(sheetContext).pop();

                                    await _runAdminAction(
                                      () => _gymRepo.updateGym(
                                        gymId: gymId,
                                        name: cleanName,
                                        logoUrl: logoUrl,
                                      ),
                                      successMessage: _uiText(
                                        'Gym actualizado correctamente.',
                                        'Gym updated successfully.',
                                      ),
                                    );
                                  },
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor: const Color(0xFFB59B6A),
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(52),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              _uiText('Guardar cambios', 'Save changes'),
                              style: _font(
                                16,
                                weight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: -0.15,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
