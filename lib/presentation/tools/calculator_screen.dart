// lib/presentation/tools/calculator_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_l10n.dart';
import '../../core/theme/app_text_styles.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String _expression = '';
  String _result = '';
  bool _justEvaluated = false;

  // Button layout: label, type
  static const _buttons = [
    ['C', 'fn'],
    ['DEL', 'fn'],
    ['%', 'op'],
    ['/', 'op'],
    ['7', 'num'],
    ['8', 'num'],
    ['9', 'num'],
    ['*', 'op'],
    ['4', 'num'],
    ['5', 'num'],
    ['6', 'num'],
    ['-', 'op'],
    ['1', 'num'],
    ['2', 'num'],
    ['3', 'num'],
    ['+', 'op'],
    ['+/-', 'fn'],
    ['0', 'num'],
    ['.', 'num'],
    ['=', 'eq'],
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/tools');
                      }
                    },
                    icon: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.07)
                            : Colors.black.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.arrow_back_rounded,
                        size: 18,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.65),
                      ),
                    ),
                  ),
                  Text(
                    context.t('calculator'),
                    style: AppTextStyles.h2.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),

            // ── Display ──────────────────────────────────────────────
            Expanded(
              flex: 2,
              child: _buildDisplay(context, primary, isDark),
            ),

            // ── Buttons ──────────────────────────────────────────────
            Expanded(
              flex: 5,
              child: _buildButtons(context, primary, isDark),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── Display ───────────────────────────────────────────────────────────────
  Widget _buildDisplay(BuildContext context, Color primary, bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.07)
              : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Expression
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            child: Text(
              _expression.isEmpty ? '0' : _expression,
              style: TextStyle(
                fontSize: _expression.length > 16 ? 20 : 28,
                fontWeight: FontWeight.w400,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 6),
          // Result
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            child: Text(
              _result.isEmpty ? '' : '= $_result',
              key: ValueKey(_result),
              style: TextStyle(
                fontSize: 38,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.5,
                color: primary,
                height: 1.1,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  // ── Buttons grid ──────────────────────────────────────────────────────────
  Widget _buildButtons(BuildContext context, Color primary, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _buttons.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.15,
        ),
        itemBuilder: (_, i) {
          final label = _buttons[i][0];
          final type = _buttons[i][1];
          return _CalcBtn(
            label: label,
            type: type,
            primary: primary,
            isDark: isDark,
            onTap: () => _onTap(label),
          );
        },
      ),
    );
  }

  // ── Logic ─────────────────────────────────────────────────────────────────
  void _onTap(String label) {
    HapticFeedback.selectionClick();
    setState(() {
      switch (label) {
        case 'C':
          _expression = '';
          _result = '';
          _justEvaluated = false;
          break;

        case 'DEL':
          if (_expression.isNotEmpty) {
            _expression = _expression.substring(0, _expression.length - 1);
            _result = '';
          }
          _justEvaluated = false;
          break;

        case '=':
          if (_expression.isEmpty) break;
          final v = _evaluate(_expression);
          if (v == null) {
            _result = context.t('error');
          } else {
            _result = _fmtNum(v);
            _expression = _result;
          }
          _justEvaluated = true;
          break;

        case '%':
          if (_expression.isNotEmpty) {
            final v = _evaluate(_expression);
            if (v != null) {
              _expression = _fmtNum(v / 100);
              _result = '';
            }
          }
          break;

        case '+/-':
          if (_expression.isNotEmpty) {
            final v = _evaluate(_expression);
            if (v != null) {
              _expression = _fmtNum(-v);
              _result = '';
            }
          }
          break;

        default:
          final isOp = _isOperator(label);

          if (_justEvaluated && !isOp) {
            _expression = label;
            _result = '';
            _justEvaluated = false;
            break;
          }
          _justEvaluated = false;

          if (isOp && _expression.isEmpty) {
            if (label == '-') _expression = '-';
            break;
          }

          if (_expression.isNotEmpty &&
              isOp &&
              _isOperator(_expression[_expression.length - 1])) {
            _expression =
                _expression.substring(0, _expression.length - 1) + label;
            break;
          }

          _expression += label;

          // Live preview
          if (!isOp) {
            final v = _evaluate(_expression);
            _result = v != null ? _fmtNum(v) : '';
          }
      }
    });
  }

  bool _isOperator(String s) => s == '+' || s == '-' || s == '*' || s == '/';

  double? _evaluate(String expr) {
    if (expr.trim().isEmpty) return 0;
    final tokens = _tokenize(expr);
    if (tokens.isEmpty) return null;
    return _evalRpn(_toRpn(tokens));
  }

  List<String> _tokenize(String expr) {
    final tokens = <String>[];
    final buf = StringBuffer();
    for (var i = 0; i < expr.length; i++) {
      final ch = expr[i];
      if (ch == ' ') continue;
      if (_isOperator(ch)) {
        if (buf.isEmpty &&
            ch == '-' &&
            (tokens.isEmpty || _isOperator(tokens.last))) {
          buf.write(ch);
          continue;
        }
        if (buf.isNotEmpty) {
          tokens.add(buf.toString());
          buf.clear();
        }
        tokens.add(ch);
      } else {
        buf.write(ch);
      }
    }
    if (buf.isNotEmpty) tokens.add(buf.toString());
    return tokens;
  }

  List<String> _toRpn(List<String> tokens) {
    final out = <String>[];
    final stack = <String>[];
    for (final t in tokens) {
      if (_isOperator(t)) {
        while (stack.isNotEmpty &&
            _isOperator(stack.last) &&
            _prec(stack.last) >= _prec(t)) {
          out.add(stack.removeLast());
        }
        stack.add(t);
      } else {
        out.add(t);
      }
    }
    while (stack.isNotEmpty) {
      out.add(stack.removeLast());
    }
    return out;
  }

  int _prec(String op) => (op == '*' || op == '/') ? 2 : 1;

  double? _evalRpn(List<String> rpn) {
    final stack = <double>[];
    for (final t in rpn) {
      if (_isOperator(t)) {
        if (stack.length < 2) return null;
        final b = stack.removeLast();
        final a = stack.removeLast();
        switch (t) {
          case '+':
            stack.add(a + b);
            break;
          case '-':
            stack.add(a - b);
            break;
          case '*':
            stack.add(a * b);
            break;
          case '/':
            if (b == 0) return null;
            stack.add(a / b);
            break;
          default:
            return null;
        }
      } else {
        final v = double.tryParse(t);
        if (v == null) return null;
        stack.add(v);
      }
    }
    return stack.length == 1 ? stack.single : null;
  }

  String _fmtNum(double v) {
    if (v == v.toInt().toDouble()) return v.toInt().toString();
    return v
        .toStringAsFixed(6)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }
}

// ── Button widget ─────────────────────────────────────────────────────────
class _CalcBtn extends StatefulWidget {
  const _CalcBtn({
    required this.label,
    required this.type,
    required this.primary,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final String type; // 'num' | 'op' | 'fn' | 'eq'
  final Color primary;
  final bool isDark;
  final VoidCallback onTap;

  @override
  State<_CalcBtn> createState() => _CalcBtnState();
}

class _CalcBtnState extends State<_CalcBtn>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      reverseDuration: const Duration(milliseconds: 120),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.92)
        .animate(CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  Color get _bg {
    switch (widget.type) {
      case 'eq':
        return widget.primary;
      case 'op':
        return widget.primary.withValues(alpha: widget.isDark ? 0.18 : 0.1);
      case 'fn':
        return widget.isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.06);
      default:
        return widget.isDark ? const Color(0xFF1B1F23) : Colors.white;
    }
  }

  Color get _fg {
    switch (widget.type) {
      case 'eq':
        return Colors.white;
      case 'op':
        return widget.primary;
      case 'fn':
        return widget.isDark ? Colors.white70 : Colors.black54;
      default:
        return widget.isDark ? Colors.white : Colors.black87;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnim,
      child: GestureDetector(
        onTapDown: (_) => _pressCtrl.forward(),
        onTapUp: (_) {
          _pressCtrl.reverse();
          widget.onTap();
        },
        onTapCancel: () => _pressCtrl.reverse(),
        child: Container(
          decoration: BoxDecoration(
            color: _bg,
            borderRadius: BorderRadius.circular(16),
            border: widget.type == 'num'
                ? Border.all(
                    color: widget.isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.black.withValues(alpha: 0.06),
                  )
                : null,
            boxShadow: widget.type == 'eq'
                ? [
                    BoxShadow(
                      color: widget.primary.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black
                          .withValues(alpha: widget.isDark ? 0.2 : 0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Center(
            child: widget.label == 'DEL'
                ? Icon(Icons.backspace_outlined, color: _fg, size: 20)
                : Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: widget.type == 'eq'
                          ? FontWeight.w800
                          : FontWeight.w500,
                      color: _fg,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
