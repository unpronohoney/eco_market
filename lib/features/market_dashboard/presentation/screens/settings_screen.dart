import 'package:flutter/material.dart';
import 'package:eco_market/core/constants/app_colors.dart';

/// Settings Screen for market owners
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSettingsGroup('Hesap', [
            _buildSettingsTile(
              icon: Icons.person_outline,
              title: 'Profil Bilgileri',
              subtitle: 'İsim, e-posta ve telefon',
              onTap: () {},
            ),
            _buildSettingsTile(
              icon: Icons.store_outlined,
              title: 'Mağaza Bilgileri',
              subtitle: 'Adres, çalışma saatleri',
              onTap: () {},
            ),
            _buildSettingsTile(
              icon: Icons.lock_outline,
              title: 'Şifre Değiştir',
              subtitle: 'Hesap güvenliği',
              onTap: () {},
            ),
          ]),
          const SizedBox(height: 16),
          _buildSettingsGroup('Bildirimler', [
            _buildSettingsTile(
              icon: Icons.notifications_outlined,
              title: 'Bildirim Tercihleri',
              subtitle: 'Push bildirimleri ve e-posta',
              onTap: () {},
            ),
          ]),
          const SizedBox(height: 16),
          _buildSettingsGroup('Uygulama', [
            _buildSettingsTile(
              icon: Icons.language,
              title: 'Dil',
              subtitle: 'Türkçe',
              onTap: () {},
            ),
            _buildSettingsTile(
              icon: Icons.info_outline,
              title: 'Sürüm',
              subtitle: 'v1.0.0',
              onTap: () {},
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildSettingsGroup(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primaryGreenLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primaryGreen, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
      onTap: onTap,
    );
  }
}
