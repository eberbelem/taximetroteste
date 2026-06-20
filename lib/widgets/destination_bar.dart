import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/app_theme.dart';
import '../services/address_service.dart';

class DestinationBar extends StatefulWidget {
  final double? currentLat;
  final double? currentLon;

  const DestinationBar({
    super.key,
    this.currentLat,
    this.currentLon,
  });

  @override
  State<DestinationBar> createState() => _DestinationBarState();
}

class _DestinationBarState extends State<DestinationBar> {
  final _controller = TextEditingController();
  final _addressService = AddressService();
  final _focusNode = FocusNode();

  List<AddressSuggestion> _suggestions = [];
  bool _isLoading = false;
  AddressSuggestion? _selected;
  Timer? _debounce;

  bool get _hasDestino =>
      _selected != null || _controller.text.trim().length >= 3;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    _selected = null;
    _debounce?.cancel();
    final text = _controller.text;
    if (text.trim().length < 3) {
      setState(() => _suggestions = []);
      return;
    }
    _debounce =
        Timer(const Duration(milliseconds: 400), () => _search(text));
  }

  Future<void> _search(String query) async {
    setState(() => _isLoading = true);
    final results = await _addressService.buscarEndereco(
      query: query,
      lat: widget.currentLat,
      lon: widget.currentLon,
    );
    if (!mounted) return;
    setState(() {
      _suggestions = results;
      _isLoading = false;
    });
  }

  void _selecionar(AddressSuggestion addr) {
    setState(() {
      _selected = addr;
      _controller.text = addr.displayName.split(',').take(2).join(',');
      _suggestions = [];
    });
    _focusNode.unfocus();
  }

  Future<void> _navegarGoogle() async {
    final dest = _selected != null
        ? '${_selected!.latitude},${_selected!.longitude}'
        : _controller.text.trim();
    final origin = widget.currentLat != null && widget.currentLon != null
        ? '${widget.currentLat},${widget.currentLon}'
        : '';
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '${origin.isNotEmpty ? '&origin=$origin' : ''}'
      '&destination=${Uri.encodeComponent(dest)}'
      '&travelmode=driving',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _navegarWaze() async {
    final dest = _selected != null
        ? '${_selected!.latitude},${_selected!.longitude}'
        : _controller.text.trim();
    final uri = Uri.parse(
      'https://www.waze.com/ul?q=${Uri.encodeComponent(dest)}&navigate=yes',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _mostrarOpcoesNavegacao() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'ABRIR COM',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: 16),
              _opcaoNavegacao(
                icon: Icons.map_rounded,
                label: 'Google Maps',
                cor: const Color(0xFF34A853),
                onTap: () {
                  Navigator.pop(context);
                  _navegarGoogle();
                },
              ),
              const SizedBox(height: 8),
              _opcaoNavegacao(
                icon: Icons.navigation_rounded,
                label: 'Waze',
                cor: const Color(0xFF33CCFF),
                onTap: () {
                  Navigator.pop(context);
                  _navegarWaze();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _opcaoNavegacao({
    required IconData icon,
    required String label,
    required Color cor,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: cor, size: 22),
        label: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.background,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: AppColors.cardBorder),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_onSearchChanged);
    _controller.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            children: [
              const SizedBox(width: 14),
              Icon(Icons.search_rounded,
                  size: 20, color: AppColors.textTertiary),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Digite o destino...',
                    hintStyle:
                        TextStyle(color: AppColors.textDim, fontSize: 15),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) {
                    if (_hasDestino) _mostrarOpcoesNavegacao();
                  },
                ),
              ),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
              const SizedBox(width: 6),
            ],
          ),
        ),
        if (_suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
            ),
            constraints: const BoxConstraints(maxHeight: 220),
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: _suggestions.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 0, color: AppColors.divider),
              itemBuilder: (_, i) {
                final addr = _suggestions[i];
                return InkWell(
                  onTap: () => _selecionar(addr),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    child: Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: 16, color: AppColors.textTertiary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            addr.displayName.split(',').take(3).join(','),
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        if (_hasDestino)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _mostrarOpcoesNavegacao,
                icon: const Icon(Icons.navigation_rounded,
                    size: 18, color: AppColors.farePrimary),
                label: Text(
                  _selected != null
                      ? 'NAVEGAR (${_controller.text.split(',').first.trim()})'
                      : 'NAVEGAR',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: AppColors.farePrimary,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.surface,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: AppColors.farePrimary.withValues(alpha: 0.3)),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
