import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/imoveis_screen.dart';
import 'screens/login_screen.dart';
import 'supabase_client.dart';

// Passados via --dart-define (ou --dart-define-from-file=supabase.public.json)
const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const _supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Em release, erros de build de widget viram uma caixa cinza; mostra o texto.
  ErrorWidget.builder = (details) => Material(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: SelectableText('Erro de tela:\n${details.exception}',
                style: const TextStyle(color: Colors.red)),
          ),
        ),
      );
  // Abre o app na hora; o Supabase inicializa dentro do _Bootstrap.
  runApp(const MeuImovelApp());
}

class MeuImovelApp extends StatelessWidget {
  const MeuImovelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Meu Imóvel',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF2E7D5B),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const _Bootstrap(),
    );
  }
}

/// Inicializa o Supabase com timeout e mostra o erro na tela se falhar.
class _Bootstrap extends StatefulWidget {
  const _Bootstrap();

  @override
  State<_Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends State<_Bootstrap> {
  late Future<void> _init = _inicializar();
  static bool _pronto = false;

  Future<void> _inicializar() async {
    if (_pronto) return;
    if (_supabaseUrl.isEmpty || _supabaseAnonKey.isEmpty) {
      throw StateError(
          'SUPABASE_URL / SUPABASE_ANON_KEY não vieram no build (--dart-define).');
    }
    await Supabase.initialize(url: _supabaseUrl, anonKey: _supabaseAnonKey)
        .timeout(const Duration(seconds: 20));
    _pronto = true;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _init,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.hasError) {
          return Scaffold(
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.error_outline, size: 48),
                    const SizedBox(height: 12),
                    const Text('Não foi possível iniciar o app',
                        textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    SelectableText('${snap.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12)),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () =>
                          setState(() => _init = _inicializar()),
                      child: const Text('Tentar de novo'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        return const AuthGate();
      },
    );
  }
}

/// Mostra login ou a lista de imóveis conforme a sessão.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, _) {
        final logado = supabase.auth.currentSession != null;
        return logado ? const ImoveisScreen() : const LoginScreen();
      },
    );
  }
}
