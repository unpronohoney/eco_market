import 'package:flutter/material.dart';
import 'package:eco_market/core/constants/app_colors.dart';

/// Customer Settings Screen placeholder
class CustomerSettingsScreen extends StatelessWidget {
  const CustomerSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Ayarlar',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: Builder(
        builder: (context) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSettingsSection(
              context: context,
              title: 'Hesap',
              items: [
                _SettingsItem(
                  icon: Icons.person_outline,
                  label: 'Profil Bilgileri',
                ),
                _SettingsItem(
                  icon: Icons.lock_outline,
                  label: 'Şifre Değiştir',
                ),
                _SettingsItem(
                  icon: Icons.notifications_outlined,
                  label: 'Bildirim Tercihleri',
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSettingsSection(
              context: context,
              title: 'Uygulama',
              items: [
                _SettingsItem(icon: Icons.language, label: 'Dil'),
                _SettingsItem(icon: Icons.dark_mode_outlined, label: 'Görünüm'),
                _SettingsItem(
                  icon: Icons.location_on_outlined,
                  label: 'Konum Ayarları',
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSettingsSection(
              context: context,
              title: 'Diğer',
              items: [
                _SettingsItem(
                  icon: Icons.privacy_tip_outlined,
                  label: 'Gizlilik Politikası',
                ),
                _SettingsItem(
                  icon: Icons.description_outlined,
                  label: 'Kullanım Koşulları',
                ),
                _SettingsItem(icon: Icons.info_outline, label: 'Hakkında'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection({
    required BuildContext context,
    required String title,
    required List<_SettingsItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: items.map((item) {
              final isLast = items.last == item;
              return Column(
                children: [
                  ListTile(
                    leading: Icon(item.icon, color: AppColors.primaryGreen),
                    title: Text(
                      item.label,
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: AppColors.textSecondary,
                    ),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${item.label} yakında eklenecek'),
                        ),
                      );
                    },
                  ),
                  if (!isLast) const Divider(height: 1, indent: 56),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _SettingsItem {
  final IconData icon;
  final String label;

  _SettingsItem({required this.icon, required this.label});
}
