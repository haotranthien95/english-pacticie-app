# Mobile Implementation Plan - Part 2

**Continuation of**: [mobile-implementation-plan.md](./mobile-implementation-plan.md)

---

## Milestone 3: Navigation & Backend Integration

**Goal**: Implement navigation system, create auth screens, and integrate with backend API.

### Task 3.1: Setup Routing

**Description**: Configure app routing with go_router for navigation.

**Acceptance Criteria**:
- Named routes for all screens
- Protected routes (require authentication)
- Deep linking support
- Proper navigation guards

**Add go_router to pubspec.yaml**:
```yaml
dependencies:
  go_router: ^14.6.2
```

**Files to Create**:

**`lib/core/router/app_router.dart`**:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../di/injection.dart';
import '../../presentation/blocs/auth/auth_bloc.dart';
import '../../presentation/blocs/auth/auth_state.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/register_screen.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/splash_screen.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  
  static GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    debugLogDiagnostics: true,
    initialLocation: '/splash',
    redirect: _guard,
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/auth/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/auth/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) {
          final initialTab = state.uri.queryParameters['tab'];
          return HomeScreen(
            initialTab: initialTab != null ? int.tryParse(initialTab) : null,
          );
        },
        routes: [
          // Game routes will be added in later milestones
        ],
      ),
    ],
  );
  
  static String? _guard(BuildContext context, GoRouterState state) {
    final authBloc = sl<AuthBloc>();
    final authState = authBloc.state;
    
    final isAuthenticated = authState is Authenticated;
    final isOnAuthPage = state.matchedLocation.startsWith('/auth');
    final isOnSplash = state.matchedLocation == '/splash';
    
    // Allow splash screen always
    if (isOnSplash) return null;
    
    // If not authenticated and not on auth page, redirect to login
    if (!isAuthenticated && !isOnAuthPage) {
      return '/auth/login';
    }
    
    // If authenticated and on auth page, redirect to home
    if (isAuthenticated && isOnAuthPage) {
      return '/home';
    }
    
    // No redirect needed
    return null;
  }
}
```

**Update `lib/app.dart`**:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'di/injection.dart';
import 'presentation/blocs/auth/auth_bloc.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AuthBloc>()..add(const AuthCheckRequested()),
      child: MaterialApp.router(
        title: 'English Learning',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        routerConfig: AppRouter.router,
      ),
    );
  }
}
```

**Dependencies**: Milestone 2 (AuthBloc)

---

### Task 3.2: Create Splash Screen

**Description**: Implement splash screen with authentication check.

**Acceptance Criteria**:
- App logo displayed
- Loading indicator
- Automatic navigation based on auth state
- Version number display

**Files to Create**:

**`lib/presentation/screens/splash_screen.dart`**:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_state.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Give splash screen at least 1 second to display
    await Future.delayed(const Duration(seconds: 1));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          context.go('/home');
        } else if (state is Unauthenticated) {
          context.go('/auth/login');
        }
      },
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App logo/icon
              Icon(
                Icons.language,
                size: 100,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 24),
              
              // App name
              Text(
                'English Learning',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 48),
              
              // Loading indicator
              const CircularProgressIndicator(),
              
              const Spacer(),
              
              // Version
              const Padding(
                padding: EdgeInsets.only(bottom: 32.0),
                child: Text(
                  'Version 1.0.0',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

**Dependencies**: Task 3.1 (routing)

---

### Task 3.3: Create Login Screen

**Description**: Implement login screen with email/password and social login.

**Acceptance Criteria**:
- Email and password input fields with validation
- Login button with loading state
- Social login buttons (Google, Apple, Facebook)
- Link to register screen
- Error messages display
- Keyboard handling

**Files to Create**:

**`lib/presentation/screens/auth/login_screen.dart`**:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/validators.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/loading_indicator.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
            AuthLoginRequested(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            ),
          );
    }
  }

  void _socialLogin(SocialProvider provider) {
    context.read<AuthBloc>().add(AuthSocialLoginRequested(provider));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is Authenticated) {
            context.go('/home');
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 48),
                    
                    // Logo
                    Icon(
                      Icons.language,
                      size: 80,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(height: 16),
                    
                    // Title
                    Text(
                      'Welcome Back',
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    
                    Text(
                      'Sign in to continue learning',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),
                    
                    // Email field
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      enabled: !isLoading,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: Validators.email,
                    ),
                    const SizedBox(height: 16),
                    
                    // Password field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      enabled: !isLoading,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) => Validators.required(value, 'Password'),
                      onFieldSubmitted: (_) => _login(),
                    ),
                    const SizedBox(height: 8),
                    
                    // Forgot password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: isLoading ? null : () {
                          // TODO: Implement forgot password
                        },
                        child: const Text('Forgot Password?'),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Login button
                    CustomButton(
                      onPressed: isLoading ? null : _login,
                      isLoading: isLoading,
                      child: const Text('Login'),
                    ),
                    const SizedBox(height: 24),
                    
                    // Divider
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'OR',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Social login buttons
                    _SocialLoginButton(
                      icon: Icons.g_mobiledata,
                      label: 'Continue with Google',
                      onPressed: isLoading
                          ? null
                          : () => _socialLogin(SocialProvider.google),
                    ),
                    const SizedBox(height: 12),
                    
                    _SocialLoginButton(
                      icon: Icons.apple,
                      label: 'Continue with Apple',
                      onPressed: isLoading
                          ? null
                          : () => _socialLogin(SocialProvider.apple),
                    ),
                    const SizedBox(height: 12),
                    
                    _SocialLoginButton(
                      icon: Icons.facebook,
                      label: 'Continue with Facebook',
                      onPressed: isLoading
                          ? null
                          : () => _socialLogin(SocialProvider.facebook),
                    ),
                    const SizedBox(height: 32),
                    
                    // Register link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Don't have an account? "),
                        TextButton(
                          onPressed: isLoading
                              ? null
                              : () => context.go('/auth/register'),
                          child: const Text('Register'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SocialLoginButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  const _SocialLoginButton({
    required this.icon,
    required this.label,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }
}
```

**`lib/presentation/widgets/common/custom_button.dart`**:
```dart
import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final bool isLoading;
  final bool isOutlined;

  const CustomButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.isLoading = false,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isOutlined) {
      return OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : child,
      );
    }

    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : child,
    );
  }
}
```

**Dependencies**: Task 3.2, Milestone 2 (AuthBloc)

---

### Task 3.4: Create Register Screen

**Description**: Implement registration screen with validation.

**Acceptance Criteria**:
- Name, email, password, confirm password fields
- Field validation (name, email format, password strength, match)
- Register button with loading state
- Link to login screen
- Error messages display

**Files to Create**:

**`lib/presentation/screens/auth/register_screen.dart`**:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/validators.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../widgets/common/custom_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _register() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
            AuthRegisterRequested(
              name: _nameController.text.trim(),
              email: _emailController.text.trim(),
              password: _passwordController.text,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/auth/login'),
        ),
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is Authenticated) {
            context.go('/home');
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),
                    
                    // Title
                    Text(
                      'Create Account',
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    
                    Text(
                      'Sign up to start learning',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),
                    
                    // Name field
                    TextFormField(
                      controller: _nameController,
                      keyboardType: TextInputType.name,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.words,
                      enabled: !isLoading,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                      validator: Validators.name,
                    ),
                    const SizedBox(height: 16),
                    
                    // Email field
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      enabled: !isLoading,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: Validators.email,
                    ),
                    const SizedBox(height: 16),
                    
                    // Password field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.next,
                      enabled: !isLoading,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        border: const OutlineInputBorder(),
                        helperText:
                            'Min 8 characters, 1 uppercase, 1 number',
                        helperMaxLines: 2,
                      ),
                      validator: Validators.password,
                    ),
                    const SizedBox(height: 16),
                    
                    // Confirm password field
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      textInputAction: TextInputAction.done,
                      enabled: !isLoading,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword = !_obscureConfirmPassword;
                            });
                          },
                        ),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) => Validators.confirmPassword(
                        value,
                        _passwordController.text,
                      ),
                      onFieldSubmitted: (_) => _register(),
                    ),
                    const SizedBox(height: 32),
                    
                    // Register button
                    CustomButton(
                      onPressed: isLoading ? null : _register,
                      isLoading: isLoading,
                      child: const Text('Register'),
                    ),
                    const SizedBox(height: 24),
                    
                    // Login link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Already have an account? '),
                        TextButton(
                          onPressed: isLoading
                              ? null
                              : () => context.go('/auth/login'),
                          child: const Text('Login'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
```

**Dependencies**: Task 3.3

---

### Task 3.5: Create Home Screen with Bottom Navigation

**Description**: Implement home screen with bottom navigation bar and 4 tabs.

**Acceptance Criteria**:
- Bottom navigation with 4 tabs (Dashboard, Games, Skills, Profile)
- IndexedStack to preserve tab state
- Selected tab persisted in Hive
- Smooth tab switching
- AppBar with title changing based on selected tab

**Files to Create**:

**`lib/presentation/screens/home/home_screen.dart`**:
```dart
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../../core/constants/storage_keys.dart';
import '../../../data/datasources/local/hive_storage.dart';
import 'dashboard_tab.dart';
import 'games_tab.dart';
import 'profile_tab.dart';
import 'skills_tab.dart';

class HomeScreen extends StatefulWidget {
  final int? initialTab;

  const HomeScreen({super.key, this.initialTab});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _currentIndex;
  late final Box _settingsBox;

  final List<String> _titles = [
    'Dashboard',
    'Games',
    'Skills',
    'Profile',
  ];

  final List<Widget> _tabs = const [
    DashboardTab(),
    GamesTab(),
    SkillsTab(),
    ProfileTab(),
  ];

  @override
  void initState() {
    super.initState();
    _settingsBox = HiveStorage.settingsBox;
    
    // Restore last selected tab or use provided initial tab
    _currentIndex = widget.initialTab ??
        _settingsBox.get(StorageKeys.selectedTabKey, defaultValue: 0) as int;
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    
    // Save selected tab
    _settingsBox.put(StorageKeys.selectedTabKey, index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        centerTitle: true,
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).primaryColor,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.games_outlined),
            activeIcon: Icon(Icons.games),
            label: 'Games',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.lightbulb_outline),
            activeIcon: Icon(Icons.lightbulb),
            label: 'Skills',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
```

**`lib/presentation/screens/home/dashboard_tab.dart`**:
```dart
import 'package:flutter/material.dart';

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.construction,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Dashboard',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Coming soon in Phase 2',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
```

**`lib/presentation/screens/home/skills_tab.dart`**:
```dart
import 'package:flutter/material.dart';

class SkillsTab extends StatelessWidget {
  const SkillsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.construction,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Skills',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Coming soon in Phase 2',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
```

**`lib/presentation/screens/home/games_tab.dart`** (placeholder for now):
```dart
import 'package:flutter/material.dart';

class GamesTab extends StatelessWidget {
  const GamesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.games,
            size: 64,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Listen and Repeat',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Game coming in next milestone',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
```

**`lib/presentation/screens/home/profile_tab.dart`** (placeholder for now):
```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is Authenticated) {
          final user = state.user;
          
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // User info card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundImage: user.avatarUrl != null
                            ? NetworkImage(user.avatarUrl!)
                            : null,
                        child: user.avatarUrl == null
                            ? Text(
                                user.name[0].toUpperCase(),
                                style: const TextStyle(fontSize: 32),
                              )
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        user.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Settings section
              const ListTile(
                title: Text(
                  'Account',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit Profile'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Navigate to edit profile screen
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Settings'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Navigate to settings screen
                },
              ),
              const Divider(),
              
              // Actions
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('Logout'),
                      content: const Text('Are you sure you want to logout?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                            context.read<AuthBloc>().add(
                                  const AuthLogoutRequested(),
                                );
                          },
                          child: const Text('Logout'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          );
        }
        
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}
```

**Dependencies**: Task 3.4

---

## Milestone 3 Completion Checklist

- [ ] Task 3.1: Routing setup with go_router
- [ ] Task 3.2: Splash screen created
- [ ] Task 3.3: Login screen implemented
- [ ] Task 3.4: Register screen implemented
- [ ] Task 3.5: Home screen with bottom navigation

**Validation**:
```bash
flutter run
# Test auth flow: login, register, social login
# Test navigation between tabs
# Test logout
```

---

## Milestone 4: Game Configuration Screen

**Goal**: Implement game configuration screen where users select game parameters.

### Task 4.1: Create Game Domain Layer

**Description**: Define game entities, repository interface, and use cases.

**Acceptance Criteria**:
- Speech, Tag, GameSession, GameResult entities
- GameRepository interface
- Use cases for getting tags and random speeches
- Use cases for creating and fetching game sessions

**Files to Create**:

**`lib/domain/entities/tag.dart`**:
```dart
import 'package:equatable/equatable.dart';

class Tag extends Equatable {
  final String id;
  final String name;
  final String category;

  const Tag({
    required this.id,
    required this.name,
    required this.category,
  });

  @override
  List<Object?> get props => [id, name, category];
}
```

**`lib/domain/entities/speech.dart`**:
```dart
import 'package:equatable/equatable.dart';
import 'tag.dart';

class Speech extends Equatable {
  final String id;
  final String audioUrl;
  final String text;
  final String level;
  final String type;
  final List<Tag> tags;

  const Speech({
    required this.id,
    required this.audioUrl,
    required this.text,
    required this.level,
    required this.type,
    required this.tags,
  });

  @override
  List<Object?> get props => [id, audioUrl, text, level, type, tags];
}
```

**`lib/domain/entities/game_session.dart`**:
```dart
import 'package:equatable/equatable.dart';

class GameSession extends Equatable {
  final String id;
  final String userId;
  final String mode;
  final String level;
  final String sentenceType;
  final List<String> tags;
  final int totalSentences;
  final int correctCount;
  final int maxStreak;
  final double? avgPronunciationScore;
  final int durationSeconds;
  final DateTime startedAt;
  final DateTime completedAt;

  const GameSession({
    required this.id,
    required this.userId,
    required this.mode,
    required this.level,
    required this.sentenceType,
    required this.tags,
    required this.totalSentences,
    required this.correctCount,
    required this.maxStreak,
    this.avgPronunciationScore,
    required this.durationSeconds,
    required this.startedAt,
    required this.completedAt,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        mode,
        level,
        sentenceType,
        tags,
        totalSentences,
        correctCount,
        maxStreak,
        avgPronunciationScore,
        durationSeconds,
        startedAt,
        completedAt,
      ];
}
```

**`lib/domain/entities/game_result.dart`**:
```dart
import 'package:equatable/equatable.dart';

class GameResult extends Equatable {
  final String id;
  final String sessionId;
  final String speechId;
  final int sequenceNumber;
  final String userResponse; // correct, incorrect, skipped
  final double? pronunciationScore;
  final String? recognizedText;
  final int responseTimeMs;

  const GameResult({
    required this.id,
    required this.sessionId,
    required this.speechId,
    required this.sequenceNumber,
    required this.userResponse,
    this.pronunciationScore,
    this.recognizedText,
    required this.responseTimeMs,
  });

  @override
  List<Object?> get props => [
        id,
        sessionId,
        speechId,
        sequenceNumber,
        userResponse,
        pronunciationScore,
        recognizedText,
        responseTimeMs,
      ];
}
```

**`lib/domain/repositories/game_repository.dart`**:
```dart
import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/game_session.dart';
import '../entities/speech.dart';
import '../entities/tag.dart';

abstract class GameRepository {
  Future<Either<Failure, List<Tag>>> getTags();
  
  Future<Either<Failure, List<Speech>>> getRandomSpeeches({
    required String level,
    required String type,
    required List<String> tagIds,
    required int count,
  });
  
  Future<Either<Failure, void>> createGameSession(GameSession session);
  
  Future<Either<Failure, List<GameSession>>> getGameHistory({
    int page = 1,
    int limit = 20,
    String? mode,
    String? level,
  });
  
  Future<Either<Failure, GameSession>> getGameDetail(String sessionId);
}
```

**`lib/domain/usecases/game/get_tags_usecase.dart`**:
```dart
import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../entities/tag.dart';
import '../../repositories/game_repository.dart';

class GetTagsUseCase {
  final GameRepository repository;

  GetTagsUseCase(this.repository);

  Future<Either<Failure, List<Tag>>> call() {
    return repository.getTags();
  }
}
```

**`lib/domain/usecases/game/get_random_speeches_usecase.dart`**:
```dart
import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../entities/speech.dart';
import '../../repositories/game_repository.dart';

class GetRandomSpeechesUseCase {
  final GameRepository repository;

  GetRandomSpeechesUseCase(this.repository);

  Future<Either<Failure, List<Speech>>> call({
    required String level,
    required String type,
    required List<String> tagIds,
    required int count,
  }) {
    return repository.getRandomSpeeches(
      level: level,
      type: type,
      tagIds: tagIds,
      count: count,
    );
  }
}
```

**Dependencies**: Milestone 1

---

### Task 4.2: Create Game Data Models

**Description**: Implement data models for game entities with JSON serialization.

**Acceptance Criteria**:
- TagModel, SpeechModel with JSON serialization
- GameSessionModel, GameResultModel for API communication
- toEntity() methods for domain conversion
- Proper null safety

**Files to Create**:

**`lib/data/models/tag_model.dart`**:
```dart
import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/tag.dart';

part 'tag_model.g.dart';

@JsonSerializable()
class TagModel {
  final String id;
  final String name;
  final String category;

  const TagModel({
    required this.id,
    required this.name,
    required this.category,
  });

  factory TagModel.fromJson(Map<String, dynamic> json) =>
      _$TagModelFromJson(json);

  Map<String, dynamic> toJson() => _$TagModelToJson(this);

  Tag toEntity() {
    return Tag(
      id: id,
      name: name,
      category: category,
    );
  }
}
```

**`lib/data/models/speech_model.dart`**:
```dart
import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/speech.dart';
import 'tag_model.dart';

part 'speech_model.g.dart';

@JsonSerializable()
class SpeechModel {
  final String id;
  @JsonKey(name: 'audio_url')
  final String audioUrl;
  final String text;
  final String level;
  final String type;
  final List<TagModel> tags;

  const SpeechModel({
    required this.id,
    required this.audioUrl,
    required this.text,
    required this.level,
    required this.type,
    required this.tags,
  });

  factory SpeechModel.fromJson(Map<String, dynamic> json) =>
      _$SpeechModelFromJson(json);

  Map<String, dynamic> toJson() => _$SpeechModelToJson(this);

  Speech toEntity() {
    return Speech(
      id: id,
      audioUrl: audioUrl,
      text: text,
      level: level,
      type: type,
      tags: tags.map((t) => t.toEntity()).toList(),
    );
  }
}
```

**`lib/data/models/game_session_model.dart`**:
```dart
import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/game_session.dart';

part 'game_session_model.g.dart';

@JsonSerializable()
class GameSessionModel {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  final String mode;
  final String level;
  @JsonKey(name: 'sentence_type')
  final String sentenceType;
  final List<String> tags;
  @JsonKey(name: 'total_sentences')
  final int totalSentences;
  @JsonKey(name: 'correct_count')
  final int correctCount;
  @JsonKey(name: 'max_streak')
  final int maxStreak;
  @JsonKey(name: 'avg_pronunciation_score')
  final double? avgPronunciationScore;
  @JsonKey(name: 'duration_seconds')
  final int durationSeconds;
  @JsonKey(name: 'started_at')
  final String startedAt;
  @JsonKey(name: 'completed_at')
  final String completedAt;

  const GameSessionModel({
    required this.id,
    required this.userId,
    required this.mode,
    required this.level,
    required this.sentenceType,
    required this.tags,
    required this.totalSentences,
    required this.correctCount,
    required this.maxStreak,
    this.avgPronunciationScore,
    required this.durationSeconds,
    required this.startedAt,
    required this.completedAt,
  });

  factory GameSessionModel.fromJson(Map<String, dynamic> json) =>
      _$GameSessionModelFromJson(json);

  Map<String, dynamic> toJson() => _$GameSessionModelToJson(this);

  GameSession toEntity() {
    return GameSession(
      id: id,
      userId: userId,
      mode: mode,
      level: level,
      sentenceType: sentenceType,
      tags: tags,
      totalSentences: totalSentences,
      correctCount: correctCount,
      maxStreak: maxStreak,
      avgPronunciationScore: avgPronunciationScore,
      durationSeconds: durationSeconds,
      startedAt: DateTime.parse(startedAt),
      completedAt: DateTime.parse(completedAt),
    );
  }

  factory GameSessionModel.fromEntity(GameSession session) {
    return GameSessionModel(
      id: session.id,
      userId: session.userId,
      mode: session.mode,
      level: session.level,
      sentenceType: session.sentenceType,
      tags: session.tags,
      totalSentences: session.totalSentences,
      correctCount: session.correctCount,
      maxStreak: session.maxStreak,
      avgPronunciationScore: session.avgPronunciationScore,
      durationSeconds: session.durationSeconds,
      startedAt: session.startedAt.toIso8601String(),
      completedAt: session.completedAt.toIso8601String(),
    );
  }
}
```

**Commands**:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

**Dependencies**: Task 4.1

---

### Task 4.3: Implement Game Remote Data Source

**Description**: Create API endpoints for game operations.

**Acceptance Criteria**:
- API endpoints for tags, random speeches, game sessions
- Error handling
- Proper request/response mapping

**Update `lib/data/datasources/remote/api_client.dart`**:
```dart
// Add to ApiClient class:

@GET(ApiConstants.tagsEndpoint)
Future<List<TagModel>> getTags();

@GET(ApiConstants.randomSpeechesEndpoint)
Future<List<SpeechModel>> getRandomSpeeches(
  @Query('level') String level,
  @Query('type') String type,
  @Query('tag_ids') String tagIds, // comma-separated
  @Query('count') int count,
);

@POST(ApiConstants.gameSessionEndpoint)
Future<void> createGameSession(@Body() Map<String, dynamic> body);

@GET(ApiConstants.gameHistoryEndpoint)
Future<Map<String, dynamic>> getGameHistory(
  @Query('page') int page,
  @Query('limit') int limit,
  @Query('mode') String? mode,
  @Query('level') String? level,
);

@GET('${ApiConstants.gameSessionEndpoint}/{id}')
Future<GameSessionModel> getGameDetail(@Path('id') String id);
```

**Create `lib/data/datasources/remote/game_remote_datasource.dart`**:
```dart
import '../../../core/errors/exceptions.dart';
import '../../../core/utils/logger.dart';
import '../../models/game_session_model.dart';
import '../../models/speech_model.dart';
import '../../models/tag_model.dart';
import 'api_client.dart';

abstract class GameRemoteDataSource {
  Future<List<TagModel>> getTags();
  Future<List<SpeechModel>> getRandomSpeeches({
    required String level,
    required String type,
    required List<String> tagIds,
    required int count,
  });
  Future<void> createGameSession(GameSessionModel session);
  Future<List<GameSessionModel>> getGameHistory({
    required int page,
    required int limit,
    String? mode,
    String? level,
  });
  Future<GameSessionModel> getGameDetail(String sessionId);
}

class GameRemoteDataSourceImpl implements GameRemoteDataSource {
  final ApiClient apiClient;

  GameRemoteDataSourceImpl(this.apiClient);

  @override
  Future<List<TagModel>> getTags() async {
    try {
      final tags = await apiClient.getTags();
      AppLogger.info('Fetched ${tags.length} tags');
      return tags;
    } catch (e) {
      AppLogger.error('Failed to fetch tags', e);
      throw _handleError(e);
    }
  }

  @override
  Future<List<SpeechModel>> getRandomSpeeches({
    required String level,
    required String type,
    required List<String> tagIds,
    required int count,
  }) async {
    try {
      final speeches = await apiClient.getRandomSpeeches(
        level,
        type,
        tagIds.join(','),
        count,
      );
      AppLogger.info('Fetched ${speeches.length} random speeches');
      return speeches;
    } catch (e) {
      AppLogger.error('Failed to fetch random speeches', e);
      throw _handleError(e);
    }
  }

  @override
  Future<void> createGameSession(GameSessionModel session) async {
    try {
      await apiClient.createGameSession(session.toJson());
      AppLogger.info('Game session created: ${session.id}');
    } catch (e) {
      AppLogger.error('Failed to create game session', e);
      throw _handleError(e);
    }
  }

  @override
  Future<List<GameSessionModel>> getGameHistory({
    required int page,
    required int limit,
    String? mode,
    String? level,
  }) async {
    try {
      final response = await apiClient.getGameHistory(page, limit, mode, level);
      final sessions = (response['data'] as List)
          .map((json) => GameSessionModel.fromJson(json))
          .toList();
      AppLogger.info('Fetched ${sessions.length} game sessions');
      return sessions;
    } catch (e) {
      AppLogger.error('Failed to fetch game history', e);
      throw _handleError(e);
    }
  }

  @override
  Future<GameSessionModel> getGameDetail(String sessionId) async {
    try {
      final session = await apiClient.getGameDetail(sessionId);
      AppLogger.info('Fetched game session detail: $sessionId');
      return session;
    } catch (e) {
      AppLogger.error('Failed to fetch game session detail', e);
      throw _handleError(e);
    }
  }

  Exception _handleError(dynamic error) {
    // Same error handling as AuthRemoteDataSource
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
          return const NetworkException('Connection timeout');
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          final message = error.response?.data['message'] ?? 'Server error';
          if (statusCode == 401) {
            return AuthenticationException(message);
          } else if (statusCode == 404) {
            return NotFoundException(message);
          }
          return ServerException(message, statusCode);
        default:
          return const NetworkException();
      }
    }
    return AppException(error.toString());
  }
}
```

**Dependencies**: Task 4.2

---

### Task 4.4: Implement Game Local Data Source

**Description**: Cache tags and game configuration locally.

**Acceptance Criteria**:
- Cache tags to reduce API calls
- Save last game configuration
- Offline queue for game sessions
- Hive box operations

**Create `lib/data/datasources/local/game_local_datasource.dart`**:
```dart
import 'package:hive/hive.dart';
import '../../../core/constants/storage_keys.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/utils/logger.dart';
import '../../models/game_session_model.dart';
import '../../models/tag_model.dart';

abstract class GameLocalDataSource {
  Future<void> cacheTags(List<TagModel> tags);
  Future<List<TagModel>?> getCachedTags();
  Future<void> saveLastGameConfig(Map<String, dynamic> config);
  Future<Map<String, dynamic>?> getLastGameConfig();
  Future<void> queueGameSession(GameSessionModel session);
  Future<List<GameSessionModel>> getQueuedSessions();
  Future<void> removeQueuedSession(String sessionId);
}

class GameLocalDataSourceImpl implements GameLocalDataSource {
  final Box cacheBox;
  final Box gameBox;

  GameLocalDataSourceImpl({
    required this.cacheBox,
    required this.gameBox,
  });

  @override
  Future<void> cacheTags(List<TagModel> tags) async {
    try {
      final tagsJson = tags.map((t) => t.toJson()).toList();
      await cacheBox.put(StorageKeys.tagsKey, tagsJson);
      AppLogger.info('Cached ${tags.length} tags');
    } catch (e) {
      AppLogger.error('Failed to cache tags', e);
      throw CacheException('Failed to cache tags');
    }
  }

  @override
  Future<List<TagModel>?> getCachedTags() async {
    try {
      final tagsJson = cacheBox.get(StorageKeys.tagsKey) as List?;
      if (tagsJson != null) {
        final tags = tagsJson
            .map((json) => TagModel.fromJson(Map<String, dynamic>.from(json)))
            .toList();
        AppLogger.info('Retrieved ${tags.length} cached tags');
        return tags;
      }
      return null;
    } catch (e) {
      AppLogger.error('Failed to get cached tags', e);
      return null;
    }
  }

  @override
  Future<void> saveLastGameConfig(Map<String, dynamic> config) async {
    try {
      await cacheBox.put(StorageKeys.lastGameConfigKey, config);
      AppLogger.info('Saved last game config');
    } catch (e) {
      AppLogger.error('Failed to save last game config', e);
      throw CacheException('Failed to save game config');
    }
  }

  @override
  Future<Map<String, dynamic>?> getLastGameConfig() async {
    try {
      final config = cacheBox.get(StorageKeys.lastGameConfigKey);
      if (config != null) {
        return Map<String, dynamic>.from(config);
      }
      return null;
    } catch (e) {
      AppLogger.error('Failed to get last game config', e);
      return null;
    }
  }

  @override
  Future<void> queueGameSession(GameSessionModel session) async {
    try {
      final queue = await getQueuedSessions();
      queue.add(session);
      final queueJson = queue.map((s) => s.toJson()).toList();
      await gameBox.put('queued_sessions', queueJson);
      AppLogger.info('Queued game session: ${session.id}');
    } catch (e) {
      AppLogger.error('Failed to queue game session', e);
      throw CacheException('Failed to queue game session');
    }
  }

  @override
  Future<List<GameSessionModel>> getQueuedSessions() async {
    try {
      final queueJson = gameBox.get('queued_sessions') as List?;
      if (queueJson != null) {
        return queueJson
            .map((json) =>
                GameSessionModel.fromJson(Map<String, dynamic>.from(json)))
            .toList();
      }
      return [];
    } catch (e) {
      AppLogger.error('Failed to get queued sessions', e);
      return [];
    }
  }

  @override
  Future<void> removeQueuedSession(String sessionId) async {
    try {
      final queue = await getQueuedSessions();
      queue.removeWhere((s) => s.id == sessionId);
      final queueJson = queue.map((s) => s.toJson()).toList();
      await gameBox.put('queued_sessions', queueJson);
      AppLogger.info('Removed queued session: $sessionId');
    } catch (e) {
      AppLogger.error('Failed to remove queued session', e);
    }
  }
}
```

**Dependencies**: Task 4.2

---

### Task 4.5: Implement Game Repository

**Description**: Implement GameRepository combining remote and local data sources.

**Acceptance Criteria**:
- Implements GameRepository interface
- Cache-first strategy for tags
- Offline queue for game sessions
- Proper error handling

**Create `lib/data/repositories/game_repository_impl.dart`**:
```dart
import 'package:dartz/dartz.dart';
import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../core/utils/logger.dart';
import '../../domain/entities/game_session.dart';
import '../../domain/entities/speech.dart';
import '../../domain/entities/tag.dart';
import '../../domain/repositories/game_repository.dart';
import '../datasources/local/game_local_datasource.dart';
import '../datasources/remote/game_remote_datasource.dart';
import '../models/game_session_model.dart';

class GameRepositoryImpl implements GameRepository {
  final GameRemoteDataSource remoteDataSource;
  final GameLocalDataSource localDataSource;

  GameRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, List<Tag>>> getTags() async {
    try {
      // Try cache first
      final cachedTags = await localDataSource.getCachedTags();
      if (cachedTags != null && cachedTags.isNotEmpty) {
        AppLogger.info('Using cached tags');
        return Right(cachedTags.map((t) => t.toEntity()).toList());
      }

      // Fetch from API
      final tags = await remoteDataSource.getTags();
      
      // Cache for next time
      await localDataSource.cacheTags(tags);
      
      return Right(tags.map((t) => t.toEntity()).toList());
    } on NetworkException {
      // If network error, try to return cached data
      final cachedTags = await localDataSource.getCachedTags();
      if (cachedTags != null && cachedTags.isNotEmpty) {
        AppLogger.warning('Using cached tags due to network error');
        return Right(cachedTags.map((t) => t.toEntity()).toList());
      }
      return const Left(NetworkFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      AppLogger.error('Failed to get tags', e);
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, List<Speech>>> getRandomSpeeches({
    required String level,
    required String type,
    required List<String> tagIds,
    required int count,
  }) async {
    try {
      final speeches = await remoteDataSource.getRandomSpeeches(
        level: level,
        type: type,
        tagIds: tagIds,
        count: count,
      );
      
      return Right(speeches.map((s) => s.toEntity()).toList());
    } on NetworkException {
      return const Left(NetworkFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      AppLogger.error('Failed to get random speeches', e);
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, void>> createGameSession(GameSession session) async {
    try {
      final model = GameSessionModel.fromEntity(session);
      await remoteDataSource.createGameSession(model);
      
      return const Right(null);
    } on NetworkException {
      // Queue for later if offline
      try {
        final model = GameSessionModel.fromEntity(session);
        await localDataSource.queueGameSession(model);
        AppLogger.info('Game session queued for offline sync');
        return const Right(null);
      } catch (e) {
        return const Left(NetworkFailure());
      }
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      AppLogger.error('Failed to create game session', e);
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, List<GameSession>>> getGameHistory({
    int page = 1,
    int limit = 20,
    String? mode,
    String? level,
  }) async {
    try {
      final sessions = await remoteDataSource.getGameHistory(
        page: page,
        limit: limit,
        mode: mode,
        level: level,
      );
      
      return Right(sessions.map((s) => s.toEntity()).toList());
    } on NetworkException {
      return const Left(NetworkFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      AppLogger.error('Failed to get game history', e);
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, GameSession>> getGameDetail(String sessionId) async {
    try {
      final session = await remoteDataSource.getGameDetail(sessionId);
      return Right(session.toEntity());
    } on NetworkException {
      return const Left(NetworkFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      AppLogger.error('Failed to get game detail', e);
      return const Left(UnexpectedFailure());
    }
  }
}
```

**Dependencies**: Tasks 4.3, 4.4

---

## Milestone 4 Completion Checklist

- [ ] Task 4.1: Game domain layer created
- [ ] Task 4.2: Game data models with JSON serialization
- [ ] Task 4.3: Game remote data source implemented
- [ ] Task 4.4: Game local data source with caching
- [ ] Task 4.5: Game repository implementation

**Validation**:
```bash
flutter analyze
flutter test
```

---

## Milestone 5: Listen-Only Game Mode

**Goal**: Implement listen-only game mode with audio playback and card swiper.

### Task 5.1: Create GameBloc

**Description**: Implement BLoC for game state management.

**Acceptance Criteria**:
- Events for loading speeches, playing audio, answering
- States for idle, loading, playing, completed
- Timer management for gaps
- Streak tracking

**Create `lib/presentation/blocs/game/game_event.dart`**:
```dart
import 'package:equatable/equatable.dart';

abstract class GameEvent extends Equatable {
  const GameEvent();

  @override
  List<Object?> get props => [];
}

class GameStartRequested extends GameEvent {
  final String level;
  final String type;
  final List<String> tagIds;
  final int count;
  final String mode; // 'listen', 'repeat'

  const GameStartRequested({
    required this.level,
    required this.type,
    required this.tagIds,
    required this.count,
    required this.mode,
  });

  @override
  List<Object?> get props => [level, type, tagIds, count, mode];
}

class GameNextSpeech extends GameEvent {
  const GameNextSpeech();
}

class GameAnswerSubmitted extends GameEvent {
  final bool isCorrect;

  const GameAnswerSubmitted(this.isCorrect);

  @override
  List<Object?> get props => [isCorrect];
}

class GameSkipped extends GameEvent {
  const GameSkipped();
}

class GameCompleted extends GameEvent {
  const GameCompleted();
}

class GameReset extends GameEvent {
  const GameReset();
}
```

**Create `lib/presentation/blocs/game/game_state.dart`**:
```dart
import 'package:equatable/equatable.dart';
import '../../../domain/entities/speech.dart';

abstract class GameState extends Equatable {
  const GameState();

  @override
  List<Object?> get props => [];
}

class GameInitial extends GameState {
  const GameInitial();
}

class GameLoading extends GameState {
  const GameLoading();
}

class GameReady extends GameState {
  final List<Speech> speeches;
  final int currentIndex;
  final int correctCount;
  final int currentStreak;
  final int maxStreak;
  final String mode;
  final DateTime startTime;

  const GameReady({
    required this.speeches,
    required this.currentIndex,
    required this.correctCount,
    required this.currentStreak,
    required this.maxStreak,
    required this.mode,
    required this.startTime,
  });

  Speech get currentSpeech => speeches[currentIndex];
  int get totalCount => speeches.length;
  bool get isLastSpeech => currentIndex >= speeches.length - 1;

  @override
  List<Object?> get props => [
        speeches,
        currentIndex,
        correctCount,
        currentStreak,
        maxStreak,
        mode,
        startTime,
      ];

  GameReady copyWith({
    List<Speech>? speeches,
    int? currentIndex,
    int? correctCount,
    int? currentStreak,
    int? maxStreak,
    String? mode,
    DateTime? startTime,
  }) {
    return GameReady(
      speeches: speeches ?? this.speeches,
      currentIndex: currentIndex ?? this.currentIndex,
      correctCount: correctCount ?? this.correctCount,
      currentStreak: currentStreak ?? this.currentStreak,
      maxStreak: maxStreak ?? this.maxStreak,
      mode: mode ?? this.mode,
      startTime: startTime ?? this.startTime,
    );
  }
}

class GameFinished extends GameState {
  final int totalCount;
  final int correctCount;
  final int maxStreak;
  final Duration duration;
  final double? avgPronunciationScore;

  const GameFinished({
    required this.totalCount,
    required this.correctCount,
    required this.maxStreak,
    required this.duration,
    this.avgPronunciationScore,
  });

  double get accuracy => totalCount > 0 ? correctCount / totalCount : 0;

  @override
  List<Object?> get props => [
        totalCount,
        correctCount,
        maxStreak,
        duration,
        avgPronunciationScore,
      ];
}

class GameError extends GameState {
  final String message;

  const GameError(this.message);

  @override
  List<Object?> get props => [message];
}
```

**Create `lib/presentation/blocs/game/game_bloc.dart`**:
```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils/logger.dart';
import '../../../domain/usecases/game/get_random_speeches_usecase.dart';
import 'game_event.dart';
import 'game_state.dart';

class GameBloc extends Bloc<GameEvent, GameState> {
  final GetRandomSpeechesUseCase getRandomSpeechesUseCase;

  GameBloc({
    required this.getRandomSpeechesUseCase,
  }) : super(const GameInitial()) {
    on<GameStartRequested>(_onGameStartRequested);
    on<GameNextSpeech>(_onGameNextSpeech);
    on<GameAnswerSubmitted>(_onGameAnswerSubmitted);
    on<GameSkipped>(_onGameSkipped);
    on<GameCompleted>(_onGameCompleted);
    on<GameReset>(_onGameReset);
  }

  Future<void> _onGameStartRequested(
    GameStartRequested event,
    Emitter<GameState> emit,
  ) async {
    emit(const GameLoading());

    final result = await getRandomSpeechesUseCase(
      level: event.level,
      type: event.type,
      tagIds: event.tagIds,
      count: event.count,
    );

    result.fold(
      (failure) {
        AppLogger.error('Failed to load speeches: ${failure.message}');
        emit(GameError(failure.message));
      },
      (speeches) {
        AppLogger.info('Game started with ${speeches.length} speeches');
        emit(GameReady(
          speeches: speeches,
          currentIndex: 0,
          correctCount: 0,
          currentStreak: 0,
          maxStreak: 0,
          mode: event.mode,
          startTime: DateTime.now(),
        ));
      },
    );
  }

  void _onGameNextSpeech(
    GameNextSpeech event,
    Emitter<GameState> emit,
  ) {
    if (state is GameReady) {
      final currentState = state as GameReady;
      
      if (currentState.isLastSpeech) {
        add(const GameCompleted());
      } else {
        emit(currentState.copyWith(
          currentIndex: currentState.currentIndex + 1,
        ));
      }
    }
  }

  void _onGameAnswerSubmitted(
    GameAnswerSubmitted event,
    Emitter<GameState> emit,
  ) {
    if (state is GameReady) {
      final currentState = state as GameReady;
      
      final newCorrectCount = event.isCorrect
          ? currentState.correctCount + 1
          : currentState.correctCount;
      
      final newStreak = event.isCorrect ? currentState.currentStreak + 1 : 0;
      
      final newMaxStreak = newStreak > currentState.maxStreak
          ? newStreak
          : currentState.maxStreak;

      emit(currentState.copyWith(
        correctCount: newCorrectCount,
        currentStreak: newStreak,
        maxStreak: newMaxStreak,
      ));

      AppLogger.info(
        'Answer: ${event.isCorrect ? "correct" : "incorrect"}, '
        'streak: $newStreak, correct: $newCorrectCount/${currentState.totalCount}',
      );
    }
  }

  void _onGameSkipped(
    GameSkipped event,
    Emitter<GameState> emit,
  ) {
    if (state is GameReady) {
      final currentState = state as GameReady;
      
      // Reset streak on skip
      emit(currentState.copyWith(currentStreak: 0));
      
      AppLogger.info('Speech skipped');
    }
  }

  void _onGameCompleted(
    GameCompleted event,
    Emitter<GameState> emit,
  ) {
    if (state is GameReady) {
      final currentState = state as GameReady;
      final duration = DateTime.now().difference(currentState.startTime);

      emit(GameFinished(
        totalCount: currentState.totalCount,
        correctCount: currentState.correctCount,
        maxStreak: currentState.maxStreak,
        duration: duration,
      ));

      AppLogger.info(
        'Game completed: ${currentState.correctCount}/${currentState.totalCount} '
        'in ${duration.inSeconds}s',
      );
    }
  }

  void _onGameReset(
    GameReset event,
    Emitter<GameState> emit,
  ) {
    emit(const GameInitial());
    AppLogger.info('Game reset');
  }
}
```

**Dependencies**: Milestone 4 (GetRandomSpeechesUseCase)

---

### Task 5.2: Create Audio Player Service

**Description**: Implement audio player service using just_audio for speech playback.

**Acceptance Criteria**:
- Play audio from URL with pre-caching
- Pause, resume, stop controls
- Audio state management (playing, paused, stopped)
- Error handling for audio loading failures
- Memory management (dispose resources)

**Create `lib/core/services/audio_player_service.dart`**:
```dart
import 'package:just_audio/just_audio.dart';
import '../utils/logger.dart';

enum AudioPlayerState { idle, loading, playing, paused, error }

class AudioPlayerService {
  final AudioPlayer _player;
  AudioPlayerState _state = AudioPlayerState.idle;
  
  AudioPlayerState get state => _state;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;

  AudioPlayerService() : _player = AudioPlayer() {
    _player.playerStateStream.listen((state) {
      if (state.playing) {
        _state = AudioPlayerState.playing;
      } else if (state.processingState == ProcessingState.loading) {
        _state = AudioPlayerState.loading;
      } else if (state.processingState == ProcessingState.completed) {
        _state = AudioPlayerState.idle;
      }
    });
  }

  Future<void> loadAndPlay(String audioUrl) async {
    try {
      _state = AudioPlayerState.loading;
      AppLogger.info('Loading audio: $audioUrl');
      
      await _player.setUrl(audioUrl);
      await _player.play();
      
      _state = AudioPlayerState.playing;
      AppLogger.info('Audio playing');
    } catch (e) {
      _state = AudioPlayerState.error;
      AppLogger.error('Failed to load/play audio', e);
      rethrow;
    }
  }

  Future<void> play() async {
    try {
      await _player.play();
      _state = AudioPlayerState.playing;
    } catch (e) {
      AppLogger.error('Failed to play audio', e);
      rethrow;
    }
  }

  Future<void> pause() async {
    try {
      await _player.pause();
      _state = AudioPlayerState.paused;
    } catch (e) {
      AppLogger.error('Failed to pause audio', e);
      rethrow;
    }
  }

  Future<void> stop() async {
    try {
      await _player.stop();
      await _player.seek(Duration.zero);
      _state = AudioPlayerState.idle;
    } catch (e) {
      AppLogger.error('Failed to stop audio', e);
      rethrow;
    }
  }

  Future<void> seek(Duration position) async {
    try {
      await _player.seek(position);
    } catch (e) {
      AppLogger.error('Failed to seek audio', e);
      rethrow;
    }
  }

  Future<void> dispose() async {
    await _player.dispose();
    AppLogger.info('Audio player disposed');
  }
}
```

**Dependencies**: Task 5.1

---

### Task 5.3: Create Game Config Screen

**Description**: Implement game configuration screen for selecting level, type, tags, and count.

**Acceptance Criteria**:
- Level selector (A1, A2, B1, B2, C1)
- Sentence type selector (question, answer)
- Tag multi-selector with categories
- Question count selector (10, 15, 20)
- Start game button
- Load last configuration from cache

**Create `lib/presentation/screens/game/game_config_screen.dart`**:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/tag.dart';
import '../../blocs/game/game_bloc.dart';
import '../../blocs/game/game_event.dart';
import '../../widgets/common/custom_button.dart';

class GameConfigScreen extends StatefulWidget {
  const GameConfigScreen({super.key});

  @override
  State<GameConfigScreen> createState() => _GameConfigScreenState();
}

class _GameConfigScreenState extends State<GameConfigScreen> {
  String _selectedLevel = AppConstants.levels[2]; // Default B1
  String _selectedType = AppConstants.sentenceTypes[0]; // Default question
  int _selectedCount = AppConstants.defaultQuestionCount;
  final Set<String> _selectedTagIds = {};
  List<Tag> _availableTags = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTags();
    _loadLastConfig();
  }

  Future<void> _loadTags() async {
    // TODO: Load tags from repository via BLoC
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadLastConfig() async {
    // TODO: Load last config from local storage
  }

  void _startGame() {
    if (_selectedTagIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one tag'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    context.read<GameBloc>().add(
          GameStartRequested(
            level: _selectedLevel,
            type: _selectedType,
            tagIds: _selectedTagIds.toList(),
            count: _selectedCount,
            mode: 'listen', // listen-only mode
          ),
        );

    context.push('/game/play');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Configuration'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Level selector
                  const Text(
                    'Select Level',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: AppConstants.levels.map((level) {
                      return ChoiceChip(
                        label: Text(level),
                        selected: _selectedLevel == level,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedLevel = level;
                            });
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Sentence type selector
                  const Text(
                    'Sentence Type',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: AppConstants.sentenceTypes.map((type) {
                      return ChoiceChip(
                        label: Text(type.toUpperCase()),
                        selected: _selectedType == type,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedType = type;
                            });
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Question count selector
                  const Text(
                    'Number of Questions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: AppConstants.questionCounts.map((count) {
                      return ChoiceChip(
                        label: Text('$count'),
                        selected: _selectedCount == count,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedCount = count;
                            });
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Tags selector
                  const Text(
                    'Select Tags',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_availableTags.isEmpty)
                    const Text('No tags available')
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableTags.map((tag) {
                        final isSelected = _selectedTagIds.contains(tag.id);
                        return FilterChip(
                          label: Text(tag.name),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedTagIds.add(tag.id);
                              } else {
                                _selectedTagIds.remove(tag.id);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 32),

                  // Start button
                  CustomButton(
                    onPressed: _startGame,
                    child: const Text('Start Game'),
                  ),
                ],
              ),
            ),
    );
  }
}
```

**Dependencies**: Task 5.1, Milestone 3 (routing)

---

### Task 5.4: Create Game Play Screen (Listen-Only)

**Description**: Implement game play screen with card swiper and audio playback.

**Acceptance Criteria**:
- Card swiper for speeches
- Audio player controls
- Swipe right (correct), swipe left (incorrect)
- Progress indicator
- Streak display
- Compliment overlay on correct answers
- Auto-advance after answer

**Create `lib/presentation/screens/game/game_play_screen.dart`**:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/audio_player_service.dart';
import '../../../domain/entities/speech.dart';
import '../../blocs/game/game_bloc.dart';
import '../../blocs/game/game_event.dart';
import '../../blocs/game/game_state.dart';
import '../../widgets/game/speech_card.dart';
import '../../widgets/game/compliment_overlay.dart';

class GamePlayScreen extends StatefulWidget {
  const GamePlayScreen({super.key});

  @override
  State<GamePlayScreen> createState() => _GamePlayScreenState();
}

class _GamePlayScreenState extends State<GamePlayScreen> {
  final CardSwiperController _swiperController = CardSwiperController();
  final AudioPlayerService _audioPlayer = AudioPlayerService();
  bool _showCompliment = false;
  bool _showText = false;

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playCurrentSpeech(Speech speech) async {
    try {
      await _audioPlayer.loadAndPlay(speech.audioUrl);
      
      // Auto-show text after 2 seconds
      await Future.delayed(AppConstants.showTextDuration);
      if (mounted) {
        setState(() {
          _showText = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to play audio'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onSwipe(int previousIndex, int? currentIndex, CardSwiperDirection direction) {
    final isCorrect = direction == CardSwiperDirection.right;
    
    context.read<GameBloc>().add(GameAnswerSubmitted(isCorrect));
    
    if (isCorrect) {
      setState(() {
        _showCompliment = true;
      });
      
      Future.delayed(AppConstants.complimentDuration, () {
        if (mounted) {
          setState(() {
            _showCompliment = false;
          });
        }
      });
    }
    
    setState(() {
      _showText = false;
    });
    
    // Wait gap before next speech
    Future.delayed(AppConstants.gapBetweenPlays, () {
      context.read<GameBloc>().add(const GameNextSpeech());
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Exit Game?'),
            content: const Text('Your progress will be lost.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Exit'),
              ),
            ],
          ),
        );
        return shouldPop ?? false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Listen & Evaluate'),
        ),
        body: BlocConsumer<GameBloc, GameState>(
          listener: (context, state) {
            if (state is GameReady) {
              _playCurrentSpeech(state.currentSpeech);
            } else if (state is GameFinished) {
              context.pushReplacement('/game/result');
            }
          },
          builder: (context, state) {
            if (state is GameLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is GameError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => context.pop(),
                      child: const Text('Go Back'),
                    ),
                  ],
                ),
              );
            }

            if (state is! GameReady) {
              return const SizedBox.shrink();
            }

            return Stack(
              children: [
                Column(
                  children: [
                    // Progress indicator
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: LinearProgressIndicator(
                              value: (state.currentIndex + 1) / state.totalCount,
                              minHeight: 8,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            '${state.currentIndex + 1}/${state.totalCount}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Streak indicator
                    if (state.currentStreak > 0)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.local_fire_department,
                                color: Colors.orange),
                            const SizedBox(width: 8),
                            Text(
                              'Streak: ${state.currentStreak}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Card swiper
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: CardSwiper(
                          controller: _swiperController,
                          cardsCount: state.speeches.length,
                          onSwipe: _onSwipe,
                          numberOfCardsDisplayed: 2,
                          backCardOffset: const Offset(0, 40),
                          padding: EdgeInsets.zero,
                          cardBuilder: (context, index, _, __) {
                            final speech = state.speeches[index];
                            return SpeechCard(
                              speech: speech,
                              showText: _showText && index == state.currentIndex,
                            );
                          },
                        ),
                      ),
                    ),

                    // Swipe instructions
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            children: [
                              Icon(Icons.arrow_back,
                                  size: 32, color: Colors.red[400]),
                              const SizedBox(height: 8),
                              const Text('Swipe Left\nIncorrect'),
                            ],
                          ),
                          Column(
                            children: [
                              Icon(Icons.arrow_forward,
                                  size: 32, color: Colors.green[400]),
                              const SizedBox(height: 8),
                              const Text('Swipe Right\nCorrect'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Compliment overlay
                if (_showCompliment)
                  ComplimentOverlay(streak: state.currentStreak),
              ],
            );
          },
        ),
      ),
    );
  }
}
```

**Create `lib/presentation/widgets/game/speech_card.dart`**:
```dart
import 'package:flutter/material.dart';
import '../../../domain/entities/speech.dart';

class SpeechCard extends StatelessWidget {
  final Speech speech;
  final bool showText;

  const SpeechCard({
    super.key,
    required this.speech,
    required this.showText,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.1),
              Theme.of(context).primaryColor.withOpacity(0.05),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Audio icon
            Icon(
              Icons.volume_up,
              size: 64,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 24),

            // Level badge
            Chip(
              label: Text(speech.level),
              backgroundColor: Theme.of(context).primaryColor,
              labelStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            // Text (hidden initially)
            AnimatedOpacity(
              opacity: showText ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 500),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  speech.text,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Tags
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: speech.tags.map((tag) {
                return Chip(
                  label: Text(tag.name),
                  labelStyle: const TextStyle(fontSize: 12),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
```

**Create `lib/presentation/widgets/game/compliment_overlay.dart`**:
```dart
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class ComplimentOverlay extends StatelessWidget {
  final int streak;

  const ComplimentOverlay({
    super.key,
    required this.streak,
  });

  String _getCompliment() {
    if (streak >= 10) return 'AMAZING! 🔥';
    if (streak >= 5) return 'FANTASTIC! ⭐';
    if (streak >= 3) return 'GREAT JOB! 👏';
    return 'CORRECT! ✓';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated checkmark or celebration
            Lottie.asset(
              'assets/animations/success.json',
              width: 200,
              height: 200,
              repeat: false,
            ),
            const SizedBox(height: 24),
            
            // Compliment text
            Text(
              _getCompliment(),
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

**Dependencies**: Task 5.2, 5.3

---

### Task 5.5: Create Game Result Screen

**Description**: Implement result screen showing game statistics.

**Acceptance Criteria**:
- Display total questions, correct answers, accuracy
- Show max streak
- Duration display
- Play again and home buttons
- Save session to backend

**Create `lib/presentation/screens/game/game_result_screen.dart`**:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/extensions.dart';
import '../../blocs/game/game_bloc.dart';
import '../../blocs/game/game_event.dart';
import '../../blocs/game/game_state.dart';
import '../../widgets/common/custom_button.dart';

class GameResultScreen extends StatelessWidget {
  const GameResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Results'),
        automaticallyImplyLeading: false,
      ),
      body: BlocBuilder<GameBloc, GameState>(
        builder: (context, state) {
          if (state is! GameFinished) {
            return const Center(
              child: Text('No results available'),
            );
          }

          final accuracy = (state.accuracy * 100).toStringAsFixed(1);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Trophy icon
                Icon(
                  state.accuracy >= 0.8
                      ? Icons.emoji_events
                      : Icons.celebration,
                  size: 100,
                  color: state.accuracy >= 0.8
                      ? Colors.amber
                      : Theme.of(context).primaryColor,
                ),
                const SizedBox(height: 24),

                // Title
                Text(
                  state.accuracy >= 0.8 ? 'Excellent!' : 'Good Job!',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 32),

                // Statistics
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _StatRow(
                          label: 'Questions',
                          value: '${state.totalCount}',
                          icon: Icons.quiz,
                        ),
                        const Divider(),
                        _StatRow(
                          label: 'Correct',
                          value: '${state.correctCount}',
                          icon: Icons.check_circle,
                          valueColor: Colors.green,
                        ),
                        const Divider(),
                        _StatRow(
                          label: 'Accuracy',
                          value: '$accuracy%',
                          icon: Icons.percent,
                          valueColor: state.accuracy >= 0.8
                              ? Colors.green
                              : Colors.orange,
                        ),
                        const Divider(),
                        _StatRow(
                          label: 'Max Streak',
                          value: '${state.maxStreak}',
                          icon: Icons.local_fire_department,
                          valueColor: Colors.orange,
                        ),
                        const Divider(),
                        _StatRow(
                          label: 'Duration',
                          value: state.duration.toFormattedString(),
                          icon: Icons.timer,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Buttons
                CustomButton(
                  onPressed: () {
                    context.read<GameBloc>().add(const GameReset());
                    context.go('/game/config');
                  },
                  child: const Text('Play Again'),
                ),
                const SizedBox(height: 12),
                CustomButton(
                  onPressed: () => context.go('/home'),
                  isOutlined: true,
                  child: const Text('Go Home'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  const _StatRow({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).primaryColor),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
```

**Dependencies**: Task 5.4

---

## Milestone 5 Completion Checklist

- [ ] Task 5.1: GameBloc created
- [ ] Task 5.2: Audio player service implemented
- [ ] Task 5.3: Game config screen created
- [ ] Task 5.4: Game play screen with card swiper
- [ ] Task 5.5: Game result screen implemented

**Validation**:
```bash
flutter analyze
flutter test
flutter run
# Test listen-only game flow
```

---

## Summary & Next Steps

**Completed in Part 2**:
- ✅ Milestone 3: Navigation & Backend Integration (5 tasks)
- ✅ Milestone 4: Game Configuration Screen (5 tasks)
- ✅ Milestone 5: Listen-Only Game Mode (5 tasks)

**Remaining Milestones** (to be completed):
- Milestone 6: Listen-and-Repeat Game Mode (microphone, STT, scoring)
- Milestone 7: Game History & Detail Screens
- Milestone 8: Profile & Settings
- Milestone 9: Theming & Localization
- Milestone 10: Testing & Polish

**Key Achievements**:
- Complete navigation system with protected routes
- Authentication screens (login, register) with social login
- Game domain layer with repository pattern
- Audio player service for speech playback
- Interactive card swiper UI with animations
- Game state management with BLoC
- Result tracking and display

**Technical Highlights**:
- Clean architecture maintained throughout
- Offline-first approach with local caching
- Proper error handling at all layers
- Type-safe dependency injection
- Material 3 UI components
- Smooth animations and transitions

---

## Milestone 6: Listen-and-Repeat Game Mode

**Goal**: Implement listen-and-repeat game mode with microphone recording, speech-to-text, and pronunciation scoring.

### Task 6.1: Setup Microphone Permissions

**Description**: Configure microphone permissions for iOS and Android.

**Acceptance Criteria**:
- Microphone permission handling
- Permission request UI
- Permission denied handling
- Settings redirect

**Add permission_handler to pubspec.yaml**:
```yaml
dependencies:
  permission_handler: ^11.3.1
```

**Update iOS permissions in `ios/Runner/Info.plist`**:
```xml
<key>NSMicrophoneUsageDescription</key>
<string>We need microphone access to record your pronunciation for evaluation</string>
<key>NSSpeechRecognitionUsageDescription</key>
<string>We need speech recognition to evaluate your pronunciation</string>
```

**Update Android permissions in `android/app/src/main/AndroidManifest.xml`**:
```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.INTERNET" />
```

**Create `lib/core/services/permission_service.dart`**:
```dart
import 'package:permission_handler/permission_handler.dart';
import '../utils/logger.dart';

class PermissionService {
  Future<bool> requestMicrophonePermission() async {
    try {
      final status = await Permission.microphone.request();
      
      if (status.isGranted) {
        AppLogger.info('Microphone permission granted');
        return true;
      } else if (status.isDenied) {
        AppLogger.warning('Microphone permission denied');
        return false;
      } else if (status.isPermanentlyDenied) {
        AppLogger.warning('Microphone permission permanently denied');
        return false;
      }
      
      return false;
    } catch (e) {
      AppLogger.error('Failed to request microphone permission', e);
      return false;
    }
  }

  Future<bool> checkMicrophonePermission() async {
    try {
      final status = await Permission.microphone.status;
      return status.isGranted;
    } catch (e) {
      AppLogger.error('Failed to check microphone permission', e);
      return false;
    }
  }

  Future<void> openAppSettings() async {
    try {
      await openAppSettings();
      AppLogger.info('Opened app settings');
    } catch (e) {
      AppLogger.error('Failed to open app settings', e);
    }
  }
}
```

**Dependencies**: Milestone 1

---

### Task 6.2: Create Microphone Recorder Service

**Description**: Implement audio recording service using record package.

**Acceptance Criteria**:
- Start/stop recording
- Save recording to file
- Audio format configuration (WAV/M4A)
- Recording duration tracking
- Amplitude monitoring for visual feedback

**Create `lib/core/services/recorder_service.dart`**:
```dart
import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import '../utils/logger.dart';

enum RecorderState { idle, recording, paused }

class RecorderService {
  final AudioRecorder _recorder;
  RecorderState _state = RecorderState.idle;
  String? _recordingPath;
  Timer? _durationTimer;
  Duration _duration = Duration.zero;
  
  RecorderState get state => _state;
  String? get recordingPath => _recordingPath;
  Duration get duration => _duration;
  
  Stream<Amplitude> get amplitudeStream => _recorder.onAmplitudeChanged(
    const Duration(milliseconds: 200),
  );

  RecorderService() : _recorder = AudioRecorder();

  Future<bool> startRecording() async {
    try {
      if (_state == RecorderState.recording) {
        AppLogger.warning('Already recording');
        return false;
      }

      // Check permission
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        AppLogger.error('Microphone permission not granted');
        return false;
      }

      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _recordingPath = '${tempDir.path}/recording_$timestamp.m4a';

      // Configure recording
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: _recordingPath!,
      );

      _state = RecorderState.recording;
      _duration = Duration.zero;
      
      // Start duration tracking
      _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _duration = Duration(seconds: timer.tick);
      });

      AppLogger.info('Recording started: $_recordingPath');
      return true;
    } catch (e) {
      AppLogger.error('Failed to start recording', e);
      return false;
    }
  }

  Future<String?> stopRecording() async {
    try {
      if (_state != RecorderState.recording) {
        AppLogger.warning('Not recording');
        return null;
      }

      final path = await _recorder.stop();
      _state = RecorderState.idle;
      _durationTimer?.cancel();
      _durationTimer = null;

      if (path != null) {
        final file = File(path);
        final exists = await file.exists();
        if (exists) {
          final size = await file.length();
          AppLogger.info('Recording stopped: $path (${size} bytes, ${_duration.inSeconds}s)');
          return path;
        }
      }

      AppLogger.error('Recording file not found');
      return null;
    } catch (e) {
      AppLogger.error('Failed to stop recording', e);
      return null;
    }
  }

  Future<void> pauseRecording() async {
    try {
      if (_state != RecorderState.recording) {
        return;
      }

      await _recorder.pause();
      _state = RecorderState.paused;
      _durationTimer?.cancel();
      AppLogger.info('Recording paused');
    } catch (e) {
      AppLogger.error('Failed to pause recording', e);
    }
  }

  Future<void> resumeRecording() async {
    try {
      if (_state != RecorderState.paused) {
        return;
      }

      await _recorder.resume();
      _state = RecorderState.recording;
      
      // Resume duration tracking
      final currentSeconds = _duration.inSeconds;
      _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _duration = Duration(seconds: currentSeconds + timer.tick);
      });

      AppLogger.info('Recording resumed');
    } catch (e) {
      AppLogger.error('Failed to resume recording', e);
    }
  }

  Future<void> cancelRecording() async {
    try {
      await _recorder.stop();
      _state = RecorderState.idle;
      _durationTimer?.cancel();
      _durationTimer = null;

      // Delete recording file
      if (_recordingPath != null) {
        final file = File(_recordingPath!);
        if (await file.exists()) {
          await file.delete();
          AppLogger.info('Recording cancelled and deleted');
        }
      }

      _recordingPath = null;
    } catch (e) {
      AppLogger.error('Failed to cancel recording', e);
    }
  }

  Future<void> dispose() async {
    await _recorder.dispose();
    _durationTimer?.cancel();
    AppLogger.info('Recorder service disposed');
  }
}
```

**Dependencies**: Task 6.1

---

### Task 6.3: Integrate Speech-to-Text API

**Description**: Implement speech-to-text transcription using backend API.

**Acceptance Criteria**:
- Upload audio file to backend
- Receive transcription text
- Receive pronunciation score
- Handle transcription errors
- Loading states

**Update `lib/data/datasources/remote/api_client.dart`**:
```dart
// Add to ApiClient class:

@POST(ApiConstants.speechToTextEndpoint)
@MultiPart()
Future<Map<String, dynamic>> transcribeAudio(
  @Part(name: 'audio') File audioFile,
  @Part(name: 'expected_text') String expectedText,
);
```

**Create `lib/domain/entities/transcription_result.dart`**:
```dart
import 'package:equatable/equatable.dart';

class TranscriptionResult extends Equatable {
  final String recognizedText;
  final String expectedText;
  final double pronunciationScore; // 0-100
  final double accuracy; // 0-1
  final List<WordScore> wordScores;

  const TranscriptionResult({
    required this.recognizedText,
    required this.expectedText,
    required this.pronunciationScore,
    required this.accuracy,
    required this.wordScores,
  });

  bool get isPassed => pronunciationScore >= 60;

  @override
  List<Object?> get props => [
        recognizedText,
        expectedText,
        pronunciationScore,
        accuracy,
        wordScores,
      ];
}

class WordScore extends Equatable {
  final String word;
  final double score; // 0-100
  final bool isCorrect;

  const WordScore({
    required this.word,
    required this.score,
    required this.isCorrect,
  });

  @override
  List<Object?> get props => [word, score, isCorrect];
}
```

**Create `lib/data/models/transcription_result_model.dart`**:
```dart
import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/transcription_result.dart';

part 'transcription_result_model.g.dart';

@JsonSerializable()
class TranscriptionResultModel {
  @JsonKey(name: 'recognized_text')
  final String recognizedText;
  @JsonKey(name: 'expected_text')
  final String expectedText;
  @JsonKey(name: 'pronunciation_score')
  final double pronunciationScore;
  final double accuracy;
  @JsonKey(name: 'word_scores')
  final List<WordScoreModel> wordScores;

  const TranscriptionResultModel({
    required this.recognizedText,
    required this.expectedText,
    required this.pronunciationScore,
    required this.accuracy,
    required this.wordScores,
  });

  factory TranscriptionResultModel.fromJson(Map<String, dynamic> json) =>
      _$TranscriptionResultModelFromJson(json);

  Map<String, dynamic> toJson() => _$TranscriptionResultModelToJson(this);

  TranscriptionResult toEntity() {
    return TranscriptionResult(
      recognizedText: recognizedText,
      expectedText: expectedText,
      pronunciationScore: pronunciationScore,
      accuracy: accuracy,
      wordScores: wordScores.map((w) => w.toEntity()).toList(),
    );
  }
}

@JsonSerializable()
class WordScoreModel {
  final String word;
  final double score;
  @JsonKey(name: 'is_correct')
  final bool isCorrect;

  const WordScoreModel({
    required this.word,
    required this.score,
    required this.isCorrect,
  });

  factory WordScoreModel.fromJson(Map<String, dynamic> json) =>
      _$WordScoreModelFromJson(json);

  Map<String, dynamic> toJson() => _$WordScoreModelToJson(this);

  WordScore toEntity() {
    return WordScore(
      word: word,
      score: score,
      isCorrect: isCorrect,
    );
  }
}
```

**Create `lib/core/services/speech_to_text_service.dart`**:
```dart
import 'dart:io';
import '../../data/datasources/remote/api_client.dart';
import '../../data/models/transcription_result_model.dart';
import '../../domain/entities/transcription_result.dart';
import '../errors/exceptions.dart';
import '../utils/logger.dart';

class SpeechToTextService {
  final ApiClient apiClient;

  SpeechToTextService(this.apiClient);

  Future<TranscriptionResult> transcribe({
    required String audioPath,
    required String expectedText,
  }) async {
    try {
      final audioFile = File(audioPath);
      
      if (!await audioFile.exists()) {
        throw AppException('Audio file not found');
      }

      AppLogger.info('Transcribing audio: $audioPath');
      
      final response = await apiClient.transcribeAudio(
        audioFile,
        expectedText,
      );

      final model = TranscriptionResultModel.fromJson(response);
      final result = model.toEntity();

      AppLogger.info(
        'Transcription completed - Score: ${result.pronunciationScore}, '
        'Accuracy: ${(result.accuracy * 100).toStringAsFixed(1)}%',
      );

      return result;
    } catch (e) {
      AppLogger.error('Failed to transcribe audio', e);
      rethrow;
    }
  }
}
```

**Commands**:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

**Dependencies**: Task 6.2

---

### Task 6.4: Update GameBloc for Listen-and-Repeat Mode

**Description**: Extend GameBloc to handle recording and transcription.

**Acceptance Criteria**:
- Events for recording start/stop
- Events for transcription
- States for recording, transcribing
- Pronunciation score tracking
- Average score calculation

**Update `lib/presentation/blocs/game/game_event.dart`**:
```dart
// Add these events:

class GameRecordingStarted extends GameEvent {
  const GameRecordingStarted();
}

class GameRecordingStopped extends GameEvent {
  const GameRecordingStopped();
}

class GameTranscriptionRequested extends GameEvent {
  final String audioPath;
  final String expectedText;

  const GameTranscriptionRequested({
    required this.audioPath,
    required this.expectedText,
  });

  @override
  List<Object?> get props => [audioPath, expectedText];
}

class GameTranscriptionCompleted extends GameEvent {
  final TranscriptionResult result;

  const GameTranscriptionCompleted(this.result);

  @override
  List<Object?> get props => [result];
}
```

**Update `lib/presentation/blocs/game/game_state.dart`**:
```dart
// Add these states:

class GameRecording extends GameState {
  final Speech currentSpeech;
  final int currentIndex;
  final int totalCount;

  const GameRecording({
    required this.currentSpeech,
    required this.currentIndex,
    required this.totalCount,
  });

  @override
  List<Object?> get props => [currentSpeech, currentIndex, totalCount];
}

class GameTranscribing extends GameState {
  final Speech currentSpeech;
  final int currentIndex;
  final int totalCount;

  const GameTranscribing({
    required this.currentSpeech,
    required this.currentIndex,
    required this.totalCount,
  });

  @override
  List<Object?> get props => [currentSpeech, currentIndex, totalCount];
}

class GameTranscriptionResult extends GameState {
  final TranscriptionResult result;
  final Speech currentSpeech;
  final int currentIndex;
  final int totalCount;
  final int correctCount;
  final int currentStreak;

  const GameTranscriptionResult({
    required this.result,
    required this.currentSpeech,
    required this.currentIndex,
    required this.totalCount,
    required this.correctCount,
    required this.currentStreak,
  });

  @override
  List<Object?> get props => [
        result,
        currentSpeech,
        currentIndex,
        totalCount,
        correctCount,
        currentStreak,
      ];
}

// Update GameReady to include pronunciation scores:
class GameReady extends GameState {
  final List<Speech> speeches;
  final int currentIndex;
  final int correctCount;
  final int currentStreak;
  final int maxStreak;
  final String mode;
  final DateTime startTime;
  final List<double> pronunciationScores; // Add this

  const GameReady({
    required this.speeches,
    required this.currentIndex,
    required this.correctCount,
    required this.currentStreak,
    required this.maxStreak,
    required this.mode,
    required this.startTime,
    this.pronunciationScores = const [], // Add this
  });

  // ... rest of the class

  @override
  List<Object?> get props => [
        speeches,
        currentIndex,
        correctCount,
        currentStreak,
        maxStreak,
        mode,
        startTime,
        pronunciationScores, // Add this
      ];

  GameReady copyWith({
    List<Speech>? speeches,
    int? currentIndex,
    int? correctCount,
    int? currentStreak,
    int? maxStreak,
    String? mode,
    DateTime? startTime,
    List<double>? pronunciationScores, // Add this
  }) {
    return GameReady(
      speeches: speeches ?? this.speeches,
      currentIndex: currentIndex ?? this.currentIndex,
      correctCount: correctCount ?? this.correctCount,
      currentStreak: currentStreak ?? this.currentStreak,
      maxStreak: maxStreak ?? this.maxStreak,
      mode: mode ?? this.mode,
      startTime: startTime ?? this.startTime,
      pronunciationScores: pronunciationScores ?? this.pronunciationScores, // Add this
    );
  }
}
```

**Update `lib/presentation/blocs/game/game_bloc.dart`**:
```dart
// Add dependency
import '../../../core/services/speech_to_text_service.dart';
import '../../../domain/entities/transcription_result.dart';

class GameBloc extends Bloc<GameEvent, GameState> {
  final GetRandomSpeechesUseCase getRandomSpeechesUseCase;
  final SpeechToTextService speechToTextService; // Add this

  GameBloc({
    required this.getRandomSpeechesUseCase,
    required this.speechToTextService, // Add this
  }) : super(const GameInitial()) {
    on<GameStartRequested>(_onGameStartRequested);
    on<GameNextSpeech>(_onGameNextSpeech);
    on<GameAnswerSubmitted>(_onGameAnswerSubmitted);
    on<GameSkipped>(_onGameSkipped);
    on<GameRecordingStarted>(_onGameRecordingStarted); // Add this
    on<GameRecordingStopped>(_onGameRecordingStopped); // Add this
    on<GameTranscriptionRequested>(_onGameTranscriptionRequested); // Add this
    on<GameTranscriptionCompleted>(_onGameTranscriptionCompleted); // Add this
    on<GameCompleted>(_onGameCompleted);
    on<GameReset>(_onGameReset);
  }

  // Add new handlers:

  void _onGameRecordingStarted(
    GameRecordingStarted event,
    Emitter<GameState> emit,
  ) {
    if (state is GameReady) {
      final currentState = state as GameReady;
      emit(GameRecording(
        currentSpeech: currentState.currentSpeech,
        currentIndex: currentState.currentIndex,
        totalCount: currentState.totalCount,
      ));
      AppLogger.info('Recording started');
    }
  }

  void _onGameRecordingStopped(
    GameRecordingStopped event,
    Emitter<GameState> emit,
  ) {
    if (state is GameRecording) {
      final currentState = state as GameRecording;
      emit(GameTranscribing(
        currentSpeech: currentState.currentSpeech,
        currentIndex: currentState.currentIndex,
        totalCount: currentState.totalCount,
      ));
      AppLogger.info('Recording stopped, transcribing...');
    }
  }

  Future<void> _onGameTranscriptionRequested(
    GameTranscriptionRequested event,
    Emitter<GameState> emit,
  ) async {
    try {
      final result = await speechToTextService.transcribe(
        audioPath: event.audioPath,
        expectedText: event.expectedText,
      );

      add(GameTranscriptionCompleted(result));
    } catch (e) {
      AppLogger.error('Transcription failed', e);
      emit(GameError('Failed to transcribe audio: ${e.toString()}'));
    }
  }

  void _onGameTranscriptionCompleted(
    GameTranscriptionCompleted event,
    Emitter<GameState> emit,
  ) {
    if (state is GameTranscribing) {
      final transcribingState = state as GameTranscribing;
      
      // Get current game state from before recording
      if (state is GameReady) {
        final gameState = state as GameReady;
        
        final isCorrect = event.result.isPassed;
        final newCorrectCount = isCorrect ? gameState.correctCount + 1 : gameState.correctCount;
        final newStreak = isCorrect ? gameState.currentStreak + 1 : 0;
        
        final newScores = List<double>.from(gameState.pronunciationScores)
          ..add(event.result.pronunciationScore);

        emit(GameTranscriptionResult(
          result: event.result,
          currentSpeech: transcribingState.currentSpeech,
          currentIndex: transcribingState.currentIndex,
          totalCount: transcribingState.totalCount,
          correctCount: newCorrectCount,
          currentStreak: newStreak,
        ));
      }
    }
  }

  // Update GameFinished to include avg pronunciation score:
  void _onGameCompleted(
    GameCompleted event,
    Emitter<GameState> emit,
  ) {
    if (state is GameReady) {
      final currentState = state as GameReady;
      final duration = DateTime.now().difference(currentState.startTime);

      final avgScore = currentState.pronunciationScores.isNotEmpty
          ? currentState.pronunciationScores.reduce((a, b) => a + b) /
              currentState.pronunciationScores.length
          : null;

      emit(GameFinished(
        totalCount: currentState.totalCount,
        correctCount: currentState.correctCount,
        maxStreak: currentState.maxStreak,
        duration: duration,
        avgPronunciationScore: avgScore,
      ));

      AppLogger.info(
        'Game completed: ${currentState.correctCount}/${currentState.totalCount} '
        'in ${duration.inSeconds}s, avg score: ${avgScore?.toStringAsFixed(1)}',
      );
    }
  }
}
```

**Dependencies**: Task 6.3

---

### Task 6.5: Create Listen-and-Repeat Game Play Screen

**Description**: Implement game play screen with recording UI.

**Acceptance Criteria**:
- Record button with animation
- Recording visualization (amplitude bars)
- Transcription result display
- Pronunciation score display
- Word-by-word feedback
- Retry recording option

**Create `lib/presentation/screens/game/listen_repeat_play_screen.dart`**:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/audio_player_service.dart';
import '../../../core/services/permission_service.dart';
import '../../../core/services/recorder_service.dart';
import '../../blocs/game/game_bloc.dart';
import '../../blocs/game/game_event.dart';
import '../../blocs/game/game_state.dart';
import '../../widgets/game/recording_button.dart';
import '../../widgets/game/transcription_result_widget.dart';
import '../../widgets/game/wave_visualizer.dart';

class ListenRepeatPlayScreen extends StatefulWidget {
  const ListenRepeatPlayScreen({super.key});

  @override
  State<ListenRepeatPlayScreen> createState() => _ListenRepeatPlayScreenState();
}

class _ListenRepeatPlayScreenState extends State<ListenRepeatPlayScreen> {
  final AudioPlayerService _audioPlayer = AudioPlayerService();
  final RecorderService _recorder = RecorderService();
  final PermissionService _permission = PermissionService();
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _checkPermission() async {
    final hasPermission = await _permission.checkMicrophonePermission();
    setState(() {
      _hasPermission = hasPermission;
    });
  }

  Future<void> _requestPermission() async {
    final granted = await _permission.requestMicrophonePermission();
    if (!granted) {
      if (mounted) {
        final shouldOpenSettings = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Microphone Permission Required'),
            content: const Text(
              'This game mode requires microphone access to record your pronunciation. '
              'Please grant permission in settings.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Open Settings'),
              ),
            ],
          ),
        );

        if (shouldOpenSettings == true) {
          await _permission.openAppSettings();
        }
      }
    } else {
      setState(() {
        _hasPermission = true;
      });
    }
  }

  Future<void> _startRecording() async {
    if (!_hasPermission) {
      await _requestPermission();
      return;
    }

    final started = await _recorder.startRecording();
    if (started) {
      context.read<GameBloc>().add(const GameRecordingStarted());
    }
  }

  Future<void> _stopRecording() async {
    final path = await _recorder.stopRecording();
    if (path != null && mounted) {
      final bloc = context.read<GameBloc>();
      final state = bloc.state;
      
      if (state is GameRecording) {
        bloc.add(GameRecordingStopped());
        bloc.add(GameTranscriptionRequested(
          audioPath: path,
          expectedText: state.currentSpeech.text,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Listen & Repeat'),
      ),
      body: BlocConsumer<GameBloc, GameState>(
        listener: (context, state) {
          if (state is GameFinished) {
            context.go('/game/result');
          }
        },
        builder: (context, state) {
          if (state is GameLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is GameError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.pop(),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }

          if (state is GameReady) {
            return _buildGameReady(state);
          }

          if (state is GameRecording) {
            return _buildRecording(state);
          }

          if (state is GameTranscribing) {
            return _buildTranscribing(state);
          }

          if (state is GameTranscriptionResult) {
            return _buildTranscriptionResult(state);
          }

          return const Center(child: Text('Unknown state'));
        },
      ),
    );
  }

  Widget _buildGameReady(GameReady state) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildProgress(state.currentIndex + 1, state.totalCount),
          const SizedBox(height: 32),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.headphones, size: 80, color: Colors.blue),
                const SizedBox(height: 24),
                const Text(
                  'Listen to the sentence',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 32),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text(
                          state.currentSpeech.text,
                          style: const TextStyle(fontSize: 18),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        IconButton.filled(
                          onPressed: () => _audioPlayer.loadAndPlay(
                            state.currentSpeech.audioUrl,
                          ),
                          icon: const Icon(Icons.volume_up, size: 32),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                RecordingButton(
                  onPressed: _startRecording,
                  isRecording: false,
                ),
                const SizedBox(height: 16),
                Text(
                  'Tap to record your pronunciation',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecording(GameRecording state) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildProgress(state.currentIndex + 1, state.totalCount),
          const SizedBox(height: 32),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.mic, size: 80, color: Colors.red),
                const SizedBox(height: 24),
                const Text(
                  'Recording...',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 16),
                StreamBuilder<Duration>(
                  stream: Stream.periodic(const Duration(seconds: 1)),
                  builder: (context, snapshot) {
                    return Text(
                      _formatDuration(_recorder.duration),
                      style: const TextStyle(fontSize: 18),
                    );
                  },
                ),
                const SizedBox(height: 32),
                StreamBuilder(
                  stream: _recorder.amplitudeStream,
                  builder: (context, snapshot) {
                    final amplitude = snapshot.data?.current ?? 0;
                    return WaveVisualizer(amplitude: amplitude);
                  },
                ),
                const SizedBox(height: 48),
                RecordingButton(
                  onPressed: _stopRecording,
                  isRecording: true,
                ),
                const SizedBox(height: 16),
                Text(
                  'Tap to stop recording',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTranscribing(GameTranscribing state) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildProgress(state.currentIndex + 1, state.totalCount),
          const Spacer(),
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          const Text(
            'Analyzing your pronunciation...',
            style: TextStyle(fontSize: 18),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildTranscriptionResult(GameTranscriptionResult state) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildProgress(state.currentIndex + 1, state.totalCount),
          const SizedBox(height: 32),
          Expanded(
            child: SingleChildScrollView(
              child: TranscriptionResultWidget(
                result: state.result,
                onNext: () {
                  context.read<GameBloc>().add(const GameNextSpeech());
                },
                onRetry: () {
                  // Reset to GameReady state
                  context.read<GameBloc>().add(const GameReset());
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgress(int current, int total) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Question $current/$total',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              '${((current / total) * 100).toInt()}%',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: current / total,
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
```

**Create `lib/presentation/widgets/game/recording_button.dart`**:
```dart
import 'package:flutter/material.dart';

class RecordingButton extends StatefulWidget {
  final VoidCallback onPressed;
  final bool isRecording;

  const RecordingButton({
    super.key,
    required this.onPressed,
    required this.isRecording,
  });

  @override
  State<RecordingButton> createState() => _RecordingButtonState();
}

class _RecordingButtonState extends State<RecordingButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onPressed,
      child: widget.isRecording
          ? AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: child,
                );
              },
              child: _buildButton(Colors.red, Icons.stop, 80),
            )
          : _buildButton(Colors.blue, Icons.mic, 80),
    );
  }

  Widget _buildButton(Color color, IconData icon, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Icon(
        icon,
        size: size * 0.5,
        color: Colors.white,
      ),
    );
  }
}
```

**Create `lib/presentation/widgets/game/wave_visualizer.dart`**:
```dart
import 'package:flutter/material.dart';
import 'dart:math' as math;

class WaveVisualizer extends StatelessWidget {
  final double amplitude;

  const WaveVisualizer({
    super.key,
    required this.amplitude,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      width: 300,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(20, (index) {
          final height = 20 + (amplitude * 60 * (math.sin(index * 0.5) + 1));
          return AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            width: 4,
            height: height.clamp(20.0, 80.0),
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
      ),
    );
  }
}
```

**Create `lib/presentation/widgets/game/transcription_result_widget.dart`**:
```dart
import 'package:flutter/material.dart';
import '../../../domain/entities/transcription_result.dart';

class TranscriptionResultWidget extends StatelessWidget {
  final TranscriptionResult result;
  final VoidCallback onNext;
  final VoidCallback onRetry;

  const TranscriptionResultWidget({
    super.key,
    required this.result,
    required this.onNext,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildScoreCard(),
        const SizedBox(height: 24),
        _buildTextComparison(),
        const SizedBox(height: 24),
        _buildWordScores(),
        const SizedBox(height: 32),
        _buildActions(),
      ],
    );
  }

  Widget _buildScoreCard() {
    final isPassed = result.isPassed;
    final color = isPassed ? Colors.green : Colors.orange;

    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              isPassed ? Icons.check_circle : Icons.info,
              size: 64,
              color: color,
            ),
            const SizedBox(height: 16),
            Text(
              isPassed ? 'Great Job!' : 'Keep Practicing!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Score: ${result.pronunciationScore.toStringAsFixed(1)}/100',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 4),
            Text(
              'Accuracy: ${(result.accuracy * 100).toStringAsFixed(1)}%',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextComparison() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Expected:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              result.expectedText,
              style: const TextStyle(fontSize: 16),
            ),
            const Divider(height: 24),
            const Text(
              'You said:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              result.recognizedText,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWordScores() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Word Scores:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: result.wordScores.map((wordScore) {
                return Chip(
                  label: Text(wordScore.word),
                  backgroundColor: wordScore.isCorrect
                      ? Colors.green.withOpacity(0.2)
                      : Colors.red.withOpacity(0.2),
                  avatar: CircleAvatar(
                    backgroundColor: wordScore.isCorrect ? Colors.green : Colors.red,
                    child: Text(
                      wordScore.score.toInt().toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: onNext,
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Next Question'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}
```

**Dependencies**: Task 6.4

---

## Milestone 6 Completion Checklist

- [ ] Task 6.1: Microphone permissions configured
- [ ] Task 6.2: Recorder service implemented
- [ ] Task 6.3: Speech-to-text API integrated
- [ ] Task 6.4: GameBloc updated for listen-and-repeat
- [ ] Task 6.5: Listen-and-repeat play screen created

**Validation**:
```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter analyze
flutter run
# Test listen-and-repeat game flow
# Test microphone recording
# Test pronunciation scoring
```

---

## Milestone 7: Game History & Detail Screens

**Goal**: Implement game history list and detail screens to view past game sessions.

### Task 7.1: Create Game History BLoC

**Description**: Implement BLoC for managing game history state.

**Acceptance Criteria**:
- Events for loading history, filtering, pagination
- States for loading, loaded, error
- Filter by mode and level
- Pagination support

**Create `lib/presentation/blocs/history/history_event.dart`**:
```dart
import 'package:equatable/equatable.dart';

abstract class HistoryEvent extends Equatable {
  const HistoryEvent();

  @override
  List<Object?> get props => [];
}

class HistoryLoadRequested extends HistoryEvent {
  final bool refresh;

  const HistoryLoadRequested({this.refresh = false});

  @override
  List<Object?> get props => [refresh];
}

class HistoryLoadMore extends HistoryEvent {
  const HistoryLoadMore();
}

class HistoryFilterChanged extends HistoryEvent {
  final String? mode;
  final String? level;

  const HistoryFilterChanged({
    this.mode,
    this.level,
  });

  @override
  List<Object?> get props => [mode, level];
}

class HistoryDetailRequested extends HistoryEvent {
  final String sessionId;

  const HistoryDetailRequested(this.sessionId);

  @override
  List<Object?> get props => [sessionId];
}
```

**Create `lib/presentation/blocs/history/history_state.dart`**:
```dart
import 'package:equatable/equatable.dart';
import '../../../domain/entities/game_session.dart';

abstract class HistoryState extends Equatable {
  const HistoryState();

  @override
  List<Object?> get props => [];
}

class HistoryInitial extends HistoryState {
  const HistoryInitial();
}

class HistoryLoading extends HistoryState {
  const HistoryLoading();
}

class HistoryLoaded extends HistoryState {
  final List<GameSession> sessions;
  final bool hasMore;
  final int currentPage;
  final String? filterMode;
  final String? filterLevel;

  const HistoryLoaded({
    required this.sessions,
    required this.hasMore,
    required this.currentPage,
    this.filterMode,
    this.filterLevel,
  });

  @override
  List<Object?> get props => [
        sessions,
        hasMore,
        currentPage,
        filterMode,
        filterLevel,
      ];

  HistoryLoaded copyWith({
    List<GameSession>? sessions,
    bool? hasMore,
    int? currentPage,
    String? filterMode,
    String? filterLevel,
  }) {
    return HistoryLoaded(
      sessions: sessions ?? this.sessions,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      filterMode: filterMode ?? this.filterMode,
      filterLevel: filterLevel ?? this.filterLevel,
    );
  }
}

class HistoryLoadingMore extends HistoryState {
  final List<GameSession> currentSessions;

  const HistoryLoadingMore(this.currentSessions);

  @override
  List<Object?> get props => [currentSessions];
}

class HistoryError extends HistoryState {
  final String message;

  const HistoryError(this.message);

  @override
  List<Object?> get props => [message];
}

class HistoryDetailLoading extends HistoryState {
  const HistoryDetailLoading();
}

class HistoryDetailLoaded extends HistoryState {
  final GameSession session;

  const HistoryDetailLoaded(this.session);

  @override
  List<Object?> get props => [session];
}
```

**Create `lib/presentation/blocs/history/history_bloc.dart`**:
```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils/logger.dart';
import '../../../domain/repositories/game_repository.dart';
import 'history_event.dart';
import 'history_state.dart';

class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  final GameRepository gameRepository;
  static const int _pageSize = 20;

  HistoryBloc({
    required this.gameRepository,
  }) : super(const HistoryInitial()) {
    on<HistoryLoadRequested>(_onHistoryLoadRequested);
    on<HistoryLoadMore>(_onHistoryLoadMore);
    on<HistoryFilterChanged>(_onHistoryFilterChanged);
    on<HistoryDetailRequested>(_onHistoryDetailRequested);
  }

  Future<void> _onHistoryLoadRequested(
    HistoryLoadRequested event,
    Emitter<HistoryState> emit,
  ) async {
    if (!event.refresh && state is HistoryLoaded) {
      return;
    }

    emit(const HistoryLoading());

    final currentState = state is HistoryLoaded ? state as HistoryLoaded : null;

    final result = await gameRepository.getGameHistory(
      page: 1,
      limit: _pageSize,
      mode: currentState?.filterMode,
      level: currentState?.filterLevel,
    );

    result.fold(
      (failure) {
        AppLogger.error('Failed to load history: ${failure.message}');
        emit(HistoryError(failure.message));
      },
      (sessions) {
        AppLogger.info('Loaded ${sessions.length} game sessions');
        emit(HistoryLoaded(
          sessions: sessions,
          hasMore: sessions.length >= _pageSize,
          currentPage: 1,
          filterMode: currentState?.filterMode,
          filterLevel: currentState?.filterLevel,
        ));
      },
    );
  }

  Future<void> _onHistoryLoadMore(
    HistoryLoadMore event,
    Emitter<HistoryState> emit,
  ) async {
    if (state is! HistoryLoaded) return;

    final currentState = state as HistoryLoaded;
    if (!currentState.hasMore) return;

    emit(HistoryLoadingMore(currentState.sessions));

    final nextPage = currentState.currentPage + 1;

    final result = await gameRepository.getGameHistory(
      page: nextPage,
      limit: _pageSize,
      mode: currentState.filterMode,
      level: currentState.filterLevel,
    );

    result.fold(
      (failure) {
        AppLogger.error('Failed to load more history: ${failure.message}');
        emit(currentState); // Revert to previous state
      },
      (newSessions) {
        AppLogger.info('Loaded ${newSessions.length} more sessions (page $nextPage)');
        emit(currentState.copyWith(
          sessions: [...currentState.sessions, ...newSessions],
          hasMore: newSessions.length >= _pageSize,
          currentPage: nextPage,
        ));
      },
    );
  }

  Future<void> _onHistoryFilterChanged(
    HistoryFilterChanged event,
    Emitter<HistoryState> emit,
  ) async {
    emit(const HistoryLoading());

    final result = await gameRepository.getGameHistory(
      page: 1,
      limit: _pageSize,
      mode: event.mode,
      level: event.level,
    );

    result.fold(
      (failure) {
        AppLogger.error('Failed to filter history: ${failure.message}');
        emit(HistoryError(failure.message));
      },
      (sessions) {
        AppLogger.info(
          'Filtered history: ${sessions.length} sessions '
          '(mode: ${event.mode}, level: ${event.level})',
        );
        emit(HistoryLoaded(
          sessions: sessions,
          hasMore: sessions.length >= _pageSize,
          currentPage: 1,
          filterMode: event.mode,
          filterLevel: event.level,
        ));
      },
    );
  }

  Future<void> _onHistoryDetailRequested(
    HistoryDetailRequested event,
    Emitter<HistoryState> emit,
  ) async {
    emit(const HistoryDetailLoading());

    final result = await gameRepository.getGameDetail(event.sessionId);

    result.fold(
      (failure) {
        AppLogger.error('Failed to load game detail: ${failure.message}');
        emit(HistoryError(failure.message));
      },
      (session) {
        AppLogger.info('Loaded game session detail: ${event.sessionId}');
        emit(HistoryDetailLoaded(session));
      },
    );
  }
}
```

**Dependencies**: Milestone 4 (GameRepository)

---

### Task 7.2: Create History List Screen

**Description**: Implement history list screen with filtering and pagination.

**Acceptance Criteria**:
- List of past game sessions
- Filter by mode (listen, repeat) and level
- Infinite scroll pagination
- Pull-to-refresh
- Tap to view details
- Empty state

**Create `lib/presentation/screens/history/history_screen.dart`**:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../blocs/history/history_bloc.dart';
import '../../blocs/history/history_event.dart';
import '../../blocs/history/history_state.dart';
import '../../widgets/history/history_item.dart';
import '../../widgets/history/history_filter_sheet.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    context.read<HistoryBloc>().add(const HistoryLoadRequested());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<HistoryBloc>().add(const HistoryLoadMore());
    }
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => HistoryFilterSheet(
        currentMode: (context.read<HistoryBloc>().state as HistoryLoaded?)
            ?.filterMode,
        currentLevel: (context.read<HistoryBloc>().state as HistoryLoaded?)
            ?.filterLevel,
        onApply: (mode, level) {
          context.read<HistoryBloc>().add(
                HistoryFilterChanged(mode: mode, level: level),
              );
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Game History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      body: BlocBuilder<HistoryBloc, HistoryState>(
        builder: (context, state) {
          if (state is HistoryLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is HistoryError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context
                          .read<HistoryBloc>()
                          .add(const HistoryLoadRequested(refresh: true));
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is HistoryLoaded) {
            if (state.sessions.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.history,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No game history yet',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Start playing to see your progress',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                context
                    .read<HistoryBloc>()
                    .add(const HistoryLoadRequested(refresh: true));
              },
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: state.sessions.length + (state.hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= state.sessions.length) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final session = state.sessions[index];
                  return HistoryItem(
                    session: session,
                    onTap: () {
                      context.push('/history/${session.id}');
                    },
                  );
                },
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
```

**Create `lib/presentation/widgets/history/history_item.dart`**:
```dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/game_session.dart';

class HistoryItem extends StatelessWidget {
  final GameSession session;
  final VoidCallback onTap;

  const HistoryItem({
    super.key,
    required this.session,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accuracy = session.totalSentences > 0
        ? (session.correctCount / session.totalSentences * 100)
        : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildModeIcon(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getModeTitle(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('MMM dd, yyyy • HH:mm')
                              .format(session.completedAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildAccuracyBadge(accuracy),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildStat(
                    icon: Icons.stars,
                    label: 'Score',
                    value: '${session.correctCount}/${session.totalSentences}',
                  ),
                  const SizedBox(width: 16),
                  _buildStat(
                    icon: Icons.local_fire_department,
                    label: 'Streak',
                    value: session.maxStreak.toString(),
                  ),
                  const SizedBox(width: 16),
                  _buildStat(
                    icon: Icons.timer,
                    label: 'Time',
                    value: _formatDuration(session.durationSeconds),
                  ),
                  if (session.avgPronunciationScore != null) ...[
                    const SizedBox(width: 16),
                    _buildStat(
                      icon: Icons.mic,
                      label: 'Pronunciation',
                      value:
                          '${session.avgPronunciationScore!.toStringAsFixed(0)}/100',
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  Chip(
                    label: Text(session.level.toUpperCase()),
                    visualDensity: VisualDensity.compact,
                  ),
                  Chip(
                    label: Text(
                      session.sentenceType == 'question'
                          ? 'Questions'
                          : 'Answers',
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeIcon() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: session.mode == 'listen'
            ? Colors.blue.withOpacity(0.1)
            : Colors.purple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        session.mode == 'listen' ? Icons.headphones : Icons.mic,
        color: session.mode == 'listen' ? Colors.blue : Colors.purple,
        size: 24,
      ),
    );
  }

  Widget _buildAccuracyBadge(double accuracy) {
    Color color;
    if (accuracy >= 80) {
      color = Colors.green;
    } else if (accuracy >= 60) {
      color = Colors.orange;
    } else {
      color = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '${accuracy.toStringAsFixed(0)}%',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildStat({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  String _getModeTitle() {
    if (session.mode == 'listen') {
      return 'Listen & Evaluate';
    } else {
      return 'Listen & Repeat';
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    if (minutes > 0) {
      return '${minutes}m ${remainingSeconds}s';
    }
    return '${seconds}s';
  }
}
```

**Create `lib/presentation/widgets/history/history_filter_sheet.dart`**:
```dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';

class HistoryFilterSheet extends StatefulWidget {
  final String? currentMode;
  final String? currentLevel;
  final Function(String?, String?) onApply;

  const HistoryFilterSheet({
    super.key,
    this.currentMode,
    this.currentLevel,
    required this.onApply,
  });

  @override
  State<HistoryFilterSheet> createState() => _HistoryFilterSheetState();
}

class _HistoryFilterSheetState extends State<HistoryFilterSheet> {
  late String? _selectedMode;
  late String? _selectedLevel;

  @override
  void initState() {
    super.initState();
    _selectedMode = widget.currentMode;
    _selectedLevel = widget.currentLevel;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filter History',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedMode = null;
                    _selectedLevel = null;
                  });
                },
                child: const Text('Clear All'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Game Mode',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              FilterChip(
                label: const Text('Listen & Evaluate'),
                selected: _selectedMode == 'listen',
                onSelected: (selected) {
                  setState(() {
                    _selectedMode = selected ? 'listen' : null;
                  });
                },
              ),
              FilterChip(
                label: const Text('Listen & Repeat'),
                selected: _selectedMode == 'repeat',
                onSelected: (selected) {
                  setState(() {
                    _selectedMode = selected ? 'repeat' : null;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Level',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: AppConstants.levels.map((level) {
              return FilterChip(
                label: Text(level.toUpperCase()),
                selected: _selectedLevel == level,
                onSelected: (selected) {
                  setState(() {
                    _selectedLevel = selected ? level : null;
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.onApply(_selectedMode, _selectedLevel);
              },
              child: const Text('Apply Filters'),
            ),
          ),
        ],
      ),
    );
  }
}
```

**Dependencies**: Task 7.1

---

### Task 7.3: Create History Detail Screen

**Description**: Implement detail screen showing comprehensive game session statistics.

**Acceptance Criteria**:
- Display all game metrics
- Show sentence-by-sentence results
- Performance charts (if applicable)
- Share results option
- Play again with same config

**Create `lib/presentation/screens/history/history_detail_screen.dart`**:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../blocs/history/history_bloc.dart';
import '../../blocs/history/history_event.dart';
import '../../blocs/history/history_state.dart';
import '../../widgets/history/stat_card.dart';

class HistoryDetailScreen extends StatelessWidget {
  final String sessionId;

  const HistoryDetailScreen({
    super.key,
    required this.sessionId,
  });

  @override
  Widget build(BuildContext context) {
    // Load detail on init
    context.read<HistoryBloc>().add(HistoryDetailRequested(sessionId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Details'),
      ),
      body: BlocBuilder<HistoryBloc, HistoryState>(
        builder: (context, state) {
          if (state is HistoryDetailLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is HistoryError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.pop(),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }

          if (state is HistoryDetailLoaded) {
            final session = state.session;
            final accuracy = session.totalSentences > 0
                ? (session.correctCount / session.totalSentences * 100)
                : 0.0;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, session),
                  const SizedBox(height: 24),
                  _buildStatsGrid(session, accuracy),
                  const SizedBox(height: 24),
                  _buildInfoSection(session),
                  const SizedBox(height: 24),
                  _buildActions(context, session),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, session) {
    final accuracy = session.totalSentences > 0
        ? (session.correctCount / session.totalSentences * 100)
        : 0.0;

    Color color;
    String title;
    if (accuracy >= 80) {
      color = Colors.green;
      title = 'Excellent!';
    } else if (accuracy >= 60) {
      color = Colors.orange;
      title = 'Good Job!';
    } else {
      color = Colors.red;
      title = 'Keep Practicing!';
    }

    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              accuracy >= 80 ? Icons.emoji_events : Icons.star,
              size: 64,
              color: color,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${accuracy.toStringAsFixed(1)}% Accuracy',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('MMMM dd, yyyy • HH:mm').format(session.completedAt),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(session, double accuracy) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        StatCard(
          icon: Icons.check_circle,
          label: 'Correct',
          value: session.correctCount.toString(),
          color: Colors.green,
        ),
        StatCard(
          icon: Icons.cancel,
          label: 'Incorrect',
          value: (session.totalSentences - session.correctCount).toString(),
          color: Colors.red,
        ),
        StatCard(
          icon: Icons.local_fire_department,
          label: 'Max Streak',
          value: session.maxStreak.toString(),
          color: Colors.orange,
        ),
        StatCard(
          icon: Icons.timer,
          label: 'Duration',
          value: _formatDuration(session.durationSeconds),
          color: Colors.blue,
        ),
        if (session.avgPronunciationScore != null)
          StatCard(
            icon: Icons.mic,
            label: 'Pronunciation',
            value: '${session.avgPronunciationScore!.toStringAsFixed(0)}/100',
            color: Colors.purple,
          ),
        StatCard(
          icon: Icons.percent,
          label: 'Accuracy',
          value: '${accuracy.toStringAsFixed(0)}%',
          color: accuracy >= 80
              ? Colors.green
              : accuracy >= 60
                  ? Colors.orange
                  : Colors.red,
        ),
      ],
    );
  }

  Widget _buildInfoSection(session) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Game Configuration',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Mode', _getModeTitle(session.mode)),
            _buildInfoRow('Level', session.level.toUpperCase()),
            _buildInfoRow(
              'Sentence Type',
              session.sentenceType == 'question' ? 'Questions' : 'Answers',
            ),
            _buildInfoRow('Total Questions', session.totalSentences.toString()),
            if (session.tags.isNotEmpty)
              _buildInfoRow('Tags', session.tags.join(', ')),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context, session) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              // Navigate to game config with same settings
              context.go('/game/config', extra: {
                'level': session.level,
                'type': session.sentenceType,
                'tags': session.tags,
                'mode': session.mode,
              });
            },
            icon: const Icon(Icons.replay),
            label: const Text('Play Again with Same Settings'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              // TODO: Implement share functionality
            },
            icon: const Icon(Icons.share),
            label: const Text('Share Results'),
          ),
        ),
      ],
    );
  }

  String _getModeTitle(String mode) {
    if (mode == 'listen') {
      return 'Listen & Evaluate';
    } else {
      return 'Listen & Repeat';
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}
```

**Create `lib/presentation/widgets/history/stat_card.dart`**:
```dart
import 'package:flutter/material.dart';

class StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const StatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: color,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
```

**Dependencies**: Task 7.2

---

## Milestone 7 Completion Checklist

- [ ] Task 7.1: History BLoC created
- [ ] Task 7.2: History list screen with filtering
- [ ] Task 7.3: History detail screen with stats

**Validation**:
```bash
flutter analyze
flutter test
flutter run
# Test history list, filtering, pagination
# Test detail screen
```

---

## Milestone 8: Profile & Settings

**Goal**: Implement user profile and settings screens.

### Task 8.1: Create Profile Screen

**Description**: Implement user profile screen showing account information.

**Acceptance Criteria**:
- Display user avatar, name, email
- Display account statistics (total games, accuracy, streak)
- Edit profile button
- Logout button
- Account deletion option

**Create `lib/presentation/screens/profile/profile_screen.dart`**:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is! Authenticated) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = state.user;

          return SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(context, user),
                const SizedBox(height: 24),
                _buildStatistics(),
                const SizedBox(height: 16),
                _buildMenuItems(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, user) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.7),
          ],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white,
            backgroundImage:
                user.profileImageUrl != null ? NetworkImage(user.profileImageUrl!) : null,
            child: user.profileImageUrl == null
                ? Text(
                    user.name[0].toUpperCase(),
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            user.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user.email,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              context.push('/profile/edit');
            },
            icon: const Icon(Icons.edit, color: Colors.white),
            label: const Text('Edit Profile', style: TextStyle(color: Colors.white)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatistics() {
    // TODO: Fetch actual statistics from repository
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              icon: Icons.sports_esports,
              label: 'Games Played',
              value: '0',
              color: Colors.blue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.percent,
              label: 'Avg Accuracy',
              value: '0%',
              color: Colors.green,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.local_fire_department,
              label: 'Best Streak',
              value: '0',
              color: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItems(BuildContext context) {
    return Column(
      children: [
        _buildMenuItem(
          context: context,
          icon: Icons.settings,
          title: 'Settings',
          subtitle: 'App preferences and configuration',
          onTap: () => context.push('/settings'),
        ),
        _buildMenuItem(
          context: context,
          icon: Icons.history,
          title: 'Game History',
          subtitle: 'View your past games',
          onTap: () => context.push('/history'),
        ),
        _buildMenuItem(
          context: context,
          icon: Icons.help_outline,
          title: 'Help & Support',
          subtitle: 'FAQs and contact us',
          onTap: () {
            // TODO: Navigate to help screen
          },
        ),
        _buildMenuItem(
          context: context,
          icon: Icons.info_outline,
          title: 'About',
          subtitle: 'App version and information',
          onTap: () {
            // TODO: Show about dialog
          },
        ),
        const Divider(),
        _buildMenuItem(
          context: context,
          icon: Icons.logout,
          title: 'Logout',
          subtitle: 'Sign out of your account',
          iconColor: Colors.red,
          onTap: () => _showLogoutDialog(context),
        ),
        _buildMenuItem(
          context: context,
          icon: Icons.delete_forever,
          title: 'Delete Account',
          subtitle: 'Permanently delete your account',
          iconColor: Colors.red,
          onTap: () => _showDeleteAccountDialog(context),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthBloc>().add(const AuthLogoutRequested());
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              // TODO: Implement account deletion
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
```

**Dependencies**: Milestone 2 (AuthBloc)

---

### Task 8.2: Create Settings Screen

**Description**: Implement settings screen for app preferences.

**Acceptance Criteria**:
- Theme toggle (light/dark)
- Language selector
- Notification settings
- Audio settings (volume, speech rate)
- Cache management
- Version information

**Create `lib/presentation/screens/settings/settings_screen.dart`**:
```dart
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../../core/constants/storage_keys.dart';
import '../../../data/datasources/local/hive_storage.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late Box _settingsBox;
  late bool _isDarkMode;
  late String _language;
  late bool _notificationsEnabled;
  late double _audioVolume;

  @override
  void initState() {
    super.initState();
    _settingsBox = HiveStorage.settingsBox;
    _loadSettings();
  }

  void _loadSettings() {
    setState(() {
      _isDarkMode = _settingsBox.get(StorageKeys.darkModeKey, defaultValue: false) as bool;
      _language = _settingsBox.get(StorageKeys.languageKey, defaultValue: 'en') as String;
      _notificationsEnabled =
          _settingsBox.get(StorageKeys.notificationsKey, defaultValue: true) as bool;
      _audioVolume = _settingsBox.get(StorageKeys.audioVolumeKey, defaultValue: 1.0) as double;
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    await _settingsBox.put(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          _buildSection('Appearance'),
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode),
            title: const Text('Dark Mode'),
            subtitle: const Text('Enable dark theme'),
            value: _isDarkMode,
            onChanged: (value) {
              setState(() {
                _isDarkMode = value;
              });
              _saveSetting(StorageKeys.darkModeKey, value);
              // TODO: Update app theme
            },
          ),
          const Divider(),
          _buildSection('Language'),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('App Language'),
            subtitle: Text(_getLanguageName(_language)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showLanguageDialog(),
          ),
          const Divider(),
          _buildSection('Notifications'),
          SwitchListTile(
            secondary: const Icon(Icons.notifications),
            title: const Text('Push Notifications'),
            subtitle: const Text('Receive game reminders'),
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() {
                _notificationsEnabled = value;
              });
              _saveSetting(StorageKeys.notificationsKey, value);
            },
          ),
          const Divider(),
          _buildSection('Audio'),
          ListTile(
            leading: const Icon(Icons.volume_up),
            title: const Text('Audio Volume'),
            subtitle: Slider(
              value: _audioVolume,
              onChanged: (value) {
                setState(() {
                  _audioVolume = value;
                });
              },
              onChangeEnd: (value) {
                _saveSetting(StorageKeys.audioVolumeKey, value);
              },
            ),
          ),
          const Divider(),
          _buildSection('Data'),
          ListTile(
            leading: const Icon(Icons.cleaning_services),
            title: const Text('Clear Cache'),
            subtitle: const Text('Free up storage space'),
            onTap: () => _showClearCacheDialog(),
          ),
          const Divider(),
          _buildSection('About'),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('Version'),
            subtitle: const Text('1.0.0'), // TODO: Get from package_info
            trailing: TextButton(
              onPressed: () {
                // TODO: Check for updates
              },
              child: const Text('Check for updates'),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('Terms of Service'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Navigate to terms
            },
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Navigate to privacy policy
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'en':
        return 'English';
      case 'vi':
        return 'Tiếng Việt';
      default:
        return 'English';
    }
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('English'),
              value: 'en',
              groupValue: _language,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _language = value;
                  });
                  _saveSetting(StorageKeys.languageKey, value);
                  Navigator.pop(ctx);
                  // TODO: Update app locale
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('Tiếng Việt'),
              value: 'vi',
              groupValue: _language,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _language = value;
                  });
                  _saveSetting(StorageKeys.languageKey, value);
                  Navigator.pop(ctx);
                  // TODO: Update app locale
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text('This will delete all cached data. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // TODO: Clear cache
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cache cleared')),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
```

**Dependencies**: Task 8.1

---

## Milestone 8 Completion Checklist

- [ ] Task 8.1: Profile screen created
- [ ] Task 8.2: Settings screen implemented

**Validation**:
```bash
flutter analyze
flutter run
# Test profile screen
# Test settings changes
```

---

## Milestone 9: Theming & Localization

**Goal**: Implement theming system and multi-language support.

### Task 9.1: Create Theme System

**Description**: Implement comprehensive theme system with light and dark modes.

**Acceptance Criteria**:
- Light and dark themes
- Material 3 design
- Consistent color palette
- Typography system
- Theme persistence
- Dynamic theme switching

**Create `lib/core/theme/app_colors.dart`**:
```dart
import 'package:flutter/material.dart';

class AppColors {
  // Primary colors
  static const Color primaryLight = Color(0xFF2196F3);
  static const Color primaryDark = Color(0xFF1976D2);
  
  // Secondary colors
  static const Color secondaryLight = Color(0xFFFF9800);
  static const Color secondaryDark = Color(0xFFF57C00);
  
  // Background colors
  static const Color backgroundLight = Color(0xFFFAFAFA);
  static const Color backgroundDark = Color(0xFF121212);
  
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  
  // Text colors
  static const Color textPrimaryLight = Color(0xFF212121);
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  
  static const Color textSecondaryLight = Color(0xFF757575);
  static const Color textSecondaryDark = Color(0xFFB0B0B0);
  
  // Status colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFF44336);
  static const Color warning = Color(0xFFFF9800);
  static const Color info = Color(0xFF2196F3);
  
  // Game colors
  static const Color correct = Color(0xFF4CAF50);
  static const Color incorrect = Color(0xFFF44336);
  static const Color streak = Color(0xFFFF5722);
}
```

**Update `lib/core/theme/app_theme.dart`**:
```dart
import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryLight,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AppColors.backgroundLight,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.primaryLight,
        foregroundColor: Colors.white,
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primaryLight, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimaryLight,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimaryLight,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimaryLight,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryLight,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: AppColors.textPrimaryLight,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: AppColors.textSecondaryLight,
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryDark,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: AppColors.backgroundDark,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.surfaceDark,
        foregroundColor: Colors.white,
      ),
      cardTheme: CardTheme(
        elevation: 2,
        color: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[850],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primaryDark, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimaryDark,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimaryDark,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimaryDark,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryDark,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: AppColors.textPrimaryDark,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: AppColors.textSecondaryDark,
        ),
      ),
    );
  }
}
```

**Dependencies**: Milestone 1

---

### Task 9.2: Implement Localization

**Description**: Add multi-language support using flutter_localizations.

**Acceptance Criteria**:
- Support English and Vietnamese
- ARB files for translations
- Language switching
- Locale persistence
- Date/time formatting

**Add dependencies to `pubspec.yaml`**:
```yaml
dependencies:
  flutter_localizations:
    sdk: flutter
  intl: ^0.19.0
```

**Create `lib/l10n/app_en.arb`**:
```json
{
  "@@locale": "en",
  "appTitle": "English Learning",
  "login": "Login",
  "register": "Register",
  "email": "Email",
  "password": "Password",
  "confirmPassword": "Confirm Password",
  "name": "Name",
  "forgotPassword": "Forgot Password?",
  "dontHaveAccount": "Don't have an account?",
  "alreadyHaveAccount": "Already have an account?",
  "continueWithGoogle": "Continue with Google",
  "continueWithApple": "Continue with Apple",
  "continueWithFacebook": "Continue with Facebook",
  "logout": "Logout",
  "profile": "Profile",
  "settings": "Settings",
  "dashboard": "Dashboard",
  "games": "Games",
  "skills": "Skills",
  "history": "History",
  "listenAndEvaluate": "Listen & Evaluate",
  "listenAndRepeat": "Listen & Repeat",
  "selectLevel": "Select Level",
  "selectType": "Select Type",
  "selectTags": "Select Tags",
  "questionCount": "Question Count",
  "startGame": "Start Game",
  "question": "Question",
  "answer": "Answer",
  "correct": "Correct",
  "incorrect": "Incorrect",
  "skip": "Skip",
  "next": "Next",
  "finish": "Finish",
  "playAgain": "Play Again",
  "home": "Home",
  "accuracy": "Accuracy",
  "streak": "Streak",
  "duration": "Duration",
  "pronunciationScore": "Pronunciation Score",
  "gameResults": "Game Results",
  "excellent": "Excellent!",
  "goodJob": "Good Job!",
  "keepPracticing": "Keep Practicing!",
  "darkMode": "Dark Mode",
  "language": "Language",
  "notifications": "Notifications",
  "audioVolume": "Audio Volume",
  "clearCache": "Clear Cache",
  "version": "Version",
  "termsOfService": "Terms of Service",
  "privacyPolicy": "Privacy Policy",
  "deleteAccount": "Delete Account",
  "areYouSure": "Are you sure?",
  "cancel": "Cancel",
  "delete": "Delete",
  "yes": "Yes",
  "no": "No"
}
```

**Create `lib/l10n/app_vi.arb`**:
```json
{
  "@@locale": "vi",
  "appTitle": "Học Tiếng Anh",
  "login": "Đăng Nhập",
  "register": "Đăng Ký",
  "email": "Email",
  "password": "Mật Khẩu",
  "confirmPassword": "Xác Nhận Mật Khẩu",
  "name": "Tên",
  "forgotPassword": "Quên Mật Khẩu?",
  "dontHaveAccount": "Chưa có tài khoản?",
  "alreadyHaveAccount": "Đã có tài khoản?",
  "continueWithGoogle": "Tiếp tục với Google",
  "continueWithApple": "Tiếp tục với Apple",
  "continueWithFacebook": "Tiếp tục với Facebook",
  "logout": "Đăng Xuất",
  "profile": "Hồ Sơ",
  "settings": "Cài Đặt",
  "dashboard": "Trang Chủ",
  "games": "Trò Chơi",
  "skills": "Kỹ Năng",
  "history": "Lịch Sử",
  "listenAndEvaluate": "Nghe & Đánh Giá",
  "listenAndRepeat": "Nghe & Nhắc Lại",
  "selectLevel": "Chọn Cấp Độ",
  "selectType": "Chọn Loại",
  "selectTags": "Chọn Thẻ",
  "questionCount": "Số Câu Hỏi",
  "startGame": "Bắt Đầu",
  "question": "Câu Hỏi",
  "answer": "Câu Trả Lời",
  "correct": "Đúng",
  "incorrect": "Sai",
  "skip": "Bỏ Qua",
  "next": "Tiếp Theo",
  "finish": "Hoàn Thành",
  "playAgain": "Chơi Lại",
  "home": "Trang Chủ",
  "accuracy": "Độ Chính Xác",
  "streak": "Chuỗi",
  "duration": "Thời Gian",
  "pronunciationScore": "Điểm Phát Âm",
  "gameResults": "Kết Quả",
  "excellent": "Xuất Sắc!",
  "goodJob": "Tốt Lắm!",
  "keepPracticing": "Tiếp Tục Luyện Tập!",
  "darkMode": "Chế Độ Tối",
  "language": "Ngôn Ngữ",
  "notifications": "Thông Báo",
  "audioVolume": "Âm Lượng",
  "clearCache": "Xóa Bộ Nhớ Đệm",
  "version": "Phiên Bản",
  "termsOfService": "Điều Khoản Dịch Vụ",
  "privacyPolicy": "Chính Sách Bảo Mật",
  "deleteAccount": "Xóa Tài Khoản",
  "areYouSure": "Bạn có chắc chắn?",
  "cancel": "Hủy",
  "delete": "Xóa",
  "yes": "Có",
  "no": "Không"
}
```

**Update `pubspec.yaml`**:
```yaml
flutter:
  generate: true
```

**Create `l10n.yaml`**:
```yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
```

**Update `lib/app.dart`**:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'di/injection.dart';
import 'l10n/app_localizations.dart';
import 'presentation/blocs/auth/auth_bloc.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AuthBloc>()..add(const AuthCheckRequested()),
      child: MaterialApp.router(
        title: 'English Learning',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system, // TODO: Get from settings
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en'),
          Locale('vi'),
        ],
        locale: const Locale('en'), // TODO: Get from settings
        routerConfig: AppRouter.router,
      ),
    );
  }
}
```

**Commands**:
```bash
flutter pub get
flutter gen-l10n
```

**Dependencies**: Task 9.1

---

## Milestone 9 Completion Checklist

- [ ] Task 9.1: Theme system implemented
- [ ] Task 9.2: Localization setup completed

**Validation**:
```bash
flutter pub get
flutter gen-l10n
flutter analyze
flutter run
# Test theme switching
# Test language switching
```

---

## Milestone 10: Testing & Polish

**Goal**: Add comprehensive tests and polish the app for production.

### Task 10.1: Write Unit Tests

**Description**: Implement unit tests for business logic.

**Acceptance Criteria**:
- Test all use cases
- Test repositories
- Test BLoCs
- Test utilities and helpers
- Minimum 80% code coverage

**Create `test/domain/usecases/auth/login_usecase_test.dart`**:
```dart
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:english_learning_app/core/errors/failures.dart';
import 'package:english_learning_app/domain/entities/user.dart';
import 'package:english_learning_app/domain/repositories/auth_repository.dart';
import 'package:english_learning_app/domain/usecases/auth/login_usecase.dart';

import 'login_usecase_test.mocks.dart';

@GenerateMocks([AuthRepository])
void main() {
  late LoginUseCase useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = LoginUseCase(mockRepository);
  });

  const tEmail = 'test@example.com';
  const tPassword = 'password123';
  const tUser = User(
    id: '1',
    email: tEmail,
    name: 'Test User',
    profileImageUrl: null,
  );

  test('should return User when login is successful', () async {
    // arrange
    when(mockRepository.login(email: tEmail, password: tPassword))
        .thenAnswer((_) async => const Right(tUser));

    // act
    final result = await useCase(email: tEmail, password: tPassword);

    // assert
    expect(result, const Right(tUser));
    verify(mockRepository.login(email: tEmail, password: tPassword));
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return ServerFailure when login fails', () async {
    // arrange
    when(mockRepository.login(email: tEmail, password: tPassword))
        .thenAnswer((_) async => const Left(ServerFailure('Login failed')));

    // act
    final result = await useCase(email: tEmail, password: tPassword);

    // assert
    expect(result, const Left(ServerFailure('Login failed')));
    verify(mockRepository.login(email: tEmail, password: tPassword));
    verifyNoMoreInteractions(mockRepository);
  });
}
```

**Commands**:
```bash
flutter pub add --dev mockito build_runner
flutter pub run build_runner build
flutter test --coverage
```

**Dependencies**: All previous milestones

---

### Task 10.2: Write Widget Tests

**Description**: Implement widget tests for UI components.

**Acceptance Criteria**:
- Test all custom widgets
- Test screen layouts
- Test user interactions
- Test navigation flows

**Create `test/presentation/widgets/custom_button_test.dart`**:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:english_learning_app/presentation/widgets/common/custom_button.dart';

void main() {
  group('CustomButton', () {
    testWidgets('should display child text', (tester) async {
      // arrange
      const buttonText = 'Test Button';

      // act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomButton(
              onPressed: null,
              child: Text(buttonText),
            ),
          ),
        ),
      );

      // assert
      expect(find.text(buttonText), findsOneWidget);
    });

    testWidgets('should call onPressed when tapped', (tester) async {
      // arrange
      var wasPressed = false;
      
      // act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              onPressed: () => wasPressed = true,
              child: const Text('Tap Me'),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(CustomButton));
      await tester.pump();

      // assert
      expect(wasPressed, true);
    });

    testWidgets('should show loading indicator when isLoading is true',
        (tester) async {
      // act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomButton(
              onPressed: null,
              isLoading: true,
              child: Text('Loading'),
            ),
          ),
        ),
      );

      // assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading'), findsNothing);
    });

    testWidgets('should be disabled when onPressed is null', (tester) async {
      // act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomButton(
              onPressed: null,
              child: Text('Disabled'),
            ),
          ),
        ),
      );

      final button = tester.widget<ElevatedButton>(
        find.byType(ElevatedButton),
      );

      // assert
      expect(button.onPressed, null);
    });
  });
}
```

**Commands**:
```bash
flutter test test/presentation/widgets/
```

**Dependencies**: Task 10.1

---

### Task 10.3: Integration Tests

**Description**: Implement integration tests for critical user flows.

**Acceptance Criteria**:
- Test complete authentication flow
- Test game play flow
- Test navigation between screens
- Test offline functionality

**Create `integration_test/app_test.dart`**:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:english_learning_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App Integration Tests', () {
    testWidgets('complete login flow', (tester) async {
      // Start app
      app.main();
      await tester.pumpAndSettle();

      // Wait for splash screen to finish
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Should navigate to login screen
      expect(find.text('Login'), findsOneWidget);

      // Enter credentials
      await tester.enterText(
        find.byType(TextField).first,
        'test@example.com',
      );
      await tester.enterText(
        find.byType(TextField).last,
        'password123',
      );

      // Tap login button
      await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
      await tester.pumpAndSettle();

      // Should navigate to home screen on successful login
      // expect(find.text('Dashboard'), findsOneWidget);
    });

    testWidgets('game play flow', (tester) async {
      // TODO: Implement game play flow test
    });
  });
}
```

**Commands**:
```bash
flutter test integration_test/app_test.dart
```

**Dependencies**: Task 10.2

---

### Task 10.4: Performance Optimization

**Description**: Optimize app performance and reduce bundle size.

**Acceptance Criteria**:
- Optimize image loading
- Reduce app size
- Profile and fix performance bottlenecks
- Implement lazy loading
- Code splitting

**Performance Checklist**:
- [ ] Use `const` constructors wherever possible
- [ ] Implement image caching with `cached_network_image`
- [ ] Use `ListView.builder` for large lists
- [ ] Implement pagination for API calls
- [ ] Profile app with Flutter DevTools
- [ ] Optimize audio loading and caching
- [ ] Minimize widget rebuilds with `const` and keys
- [ ] Use `flutter build` with `--split-debug-info` and `--obfuscate`

**Commands**:
```bash
# Profile app
flutter run --profile

# Analyze app size
flutter build apk --analyze-size
flutter build appbundle --analyze-size

# Build optimized release
flutter build apk --release --split-debug-info=./debug-info --obfuscate
```

**Dependencies**: Task 10.3

---

### Task 10.5: Production Setup

**Description**: Configure app for production release.

**Acceptance Criteria**:
- App icon configured
- Splash screen configured
- App signing setup (Android & iOS)
- Environment configuration
- Error tracking (Firebase Crashlytics)
- Analytics setup

**Install flutter_launcher_icons**:
```yaml
dev_dependencies:
  flutter_launcher_icons: ^0.13.1

flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/images/app_icon.png"
  adaptive_icon_background: "#FFFFFF"
  adaptive_icon_foreground: "assets/images/app_icon_foreground.png"
```

**Commands**:
```bash
flutter pub get
flutter pub run flutter_launcher_icons
```

**Install flutter_native_splash**:
```yaml
dev_dependencies:
  flutter_native_splash: ^2.4.1

flutter_native_splash:
  color: "#2196F3"
  image: assets/images/splash_logo.png
  android: true
  ios: true
```

**Commands**:
```bash
flutter pub get
flutter pub run flutter_native_splash:create
```

**Android Signing (`android/app/build.gradle`)**:
```gradle
signingConfigs {
    release {
        keyAlias keystoreProperties['keyAlias']
        keyPassword keystoreProperties['keyPassword']
        storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
        storePassword keystoreProperties['storePassword']
    }
}

buildTypes {
    release {
        signingConfig signingConfigs.release
        minifyEnabled true
        shrinkResources true
    }
}
```

**Dependencies**: Task 10.4

---

## Milestone 10 Completion Checklist

- [ ] Task 10.1: Unit tests written (80%+ coverage)
- [ ] Task 10.2: Widget tests implemented
- [ ] Task 10.3: Integration tests created
- [ ] Task 10.4: Performance optimized
- [ ] Task 10.5: Production setup completed

**Validation**:
```bash
flutter test --coverage
flutter analyze
flutter build apk --release
flutter build appbundle --release
flutter build ios --release
```

---

## Final Summary

### Completed Implementation Plan

**All Milestones**:
- ✅ Milestone 1: Project Foundation & Setup
- ✅ Milestone 2: Authentication Flow
- ✅ Milestone 3: Navigation & Backend Integration
- ✅ Milestone 4: Game Configuration Screen
- ✅ Milestone 5: Listen-Only Game Mode
- ✅ Milestone 6: Listen-and-Repeat Game Mode
- ✅ Milestone 7: Game History & Detail Screens
- ✅ Milestone 8: Profile & Settings
- ✅ Milestone 9: Theming & Localization
- ✅ Milestone 10: Testing & Polish

**Total Tasks**: 50+ tasks across 10 milestones

**Key Features Implemented**:
- Complete authentication system (email, Google, Apple, Facebook)
- Clean architecture with domain, data, and presentation layers
- Two game modes: Listen-Only and Listen-and-Repeat
- Speech-to-text integration with pronunciation scoring
- Game history with filtering and pagination
- User profile and settings management
- Light/Dark theme support
- Multi-language support (English, Vietnamese)
- Comprehensive testing suite
- Production-ready configuration

**Technical Stack**:
- Flutter 3.24.5 / Dart 3.5.4
- BLoC State Management
- Hive Local Storage
- Firebase Authentication
- Retrofit + Dio for API
- just_audio + record for Audio
- go_router for Navigation
- Material 3 Design

**Architecture**:
```
lib/
├── core/           # Core utilities, theme, constants
├── data/           # Data sources, models, repositories
├── domain/         # Entities, repositories, use cases
├── presentation/   # BLoCs, screens, widgets
├── di/             # Dependency injection
└── l10n/           # Localization files
```

**Next Steps**:
1. Review and implement all tasks sequentially
2. Test each milestone thoroughly before proceeding
3. Integrate with actual backend API
4. Conduct user acceptance testing
5. Prepare for App Store and Play Store submission

---

**End of Mobile Implementation Plan - Part 2**
