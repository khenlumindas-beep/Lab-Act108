/// Shared Navigation Configuration for SmartTrack
/// This configuration is consistent across all platforms (Web, Mobile, Tablet)

class NavigationConfig {
  // Header Configuration
  static const String logoPath = 'assets/images/logo.png';
  static const int logoSize = 56;
  
  static const String institutionName = 'CARAGA STATE UNIVERSITY - CAGDABARAN CAMPUS';
  static const String institutionSubtitle = 'Office of Internationalization and Global Engagement (OIGE)';
  
  static const String brandName = 'SmartTrack';
  static const String brandSubtitle = 'AI-Based International Travel Monitoring System';
  
  // Navigation Items
  static const List<NavItem> navigationItems = [
    NavItem(label: 'Home', icon: '🏠', href: '#', isActive: true),
    NavItem(label: 'About', icon: 'ℹ️', href: '#'),
    NavItem(label: 'Help', icon: '❓', href: '#'),
    NavItem(label: 'EN', icon: '🌐', href: '#'),
  ];
  
  // Footer Configuration
  static const String footerText = 'CSUCC OIGE • SmartTrack';
  static const String copyrightYear = '© 2026';
  
  // Login Form Configuration
  static const String loginTitle = 'Sign in to SmartTrack';
  static const String loginSubtitle = 'Access your travel records, documents and dashboard';
  
  static const LoginField emailField = LoginField(
    name: 'email',
    label: 'Email Address',
    placeholder: 'Enter your email address',
    type: 'email',
    icon: '📧',
  );
  
  static const LoginField passwordField = LoginField(
    name: 'password',
    label: 'Password',
    placeholder: 'Enter your password',
    type: 'password',
    icon: '🔒',
  );
  
  static const String rememberMeText = 'Remember me';
  static const String forgotPasswordText = 'Forgot Password?';
  static const String submitButtonText = 'Sign In';
  static const String authorizedUsersText = 'Authorized CSUCC OIGE users only';
  
  // Benefits Panel Configuration
  static const String benefitsTitle = 'International Travel\nMonitoring';
  static const String benefitsSubtitle = 'Smarter monitoring. Safer journeys.\nGlobal opportunities.';
  
  static const List<BenefitItem> benefitItems = [
    BenefitItem(
      icon: '✈️',
      title: 'Travel Records',
      description: 'Manage and track international\ntravel records.',
    ),
    BenefitItem(
      icon: '📄',
      title: 'Document Monitoring',
      description: 'Upload, verify and monitor\nrequired documents.',
    ),
    BenefitItem(
      icon: '🧠',
      title: 'AI-Assisted Compliance Analysis',
      description: 'Detect risks and ensure compliance\nwith institutional and global standards.',
    ),
  ];
  
  // Panel Background Image
  static const String panelBgImage = 'assets/images/panel-bg.jpg';
}

/// Navigation Item Model
class NavItem {
  final String label;
  final String icon;
  final String href;
  final bool isActive;
  
  const NavItem({
    required this.label,
    required this.icon,
    required this.href,
    this.isActive = false,
  });
}

/// Login Field Model
class LoginField {
  final String name;
  final String label;
  final String placeholder;
  final String type;
  final String icon;
  
  const LoginField({
    required this.name,
    required this.label,
    required this.placeholder,
    required this.type,
    required this.icon,
  });
}

/// Benefit Item Model
class BenefitItem {
  final String icon;
  final String title;
  final String description;
  
  const BenefitItem({
    required this.icon,
    required this.title,
    required this.description,
  });
}

/// Color Configuration
class ColorConfig {
  static const int primary = 0xFF1a5f3f;
  static const int primaryLight = 0xFF2a7a52;
  static const int secondary = 0xFFf5a623;
  static const int accentColor = 0xFF3b82f6;
  static const int textPrimary = 0xFF1e293b;
  static const int textSecondary = 0xFF64748b;
  static const int borderColor = 0xFFe2e8f0;
  static const int panelBg = 0xFFdde9f0;
}
