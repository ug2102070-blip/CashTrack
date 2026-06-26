// lib/presentation/transactions/calculator_bottom_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CalculatorBottomSheet extends StatefulWidget {
  final String initialValue;

  const CalculatorBottomSheet({
    super.key,
    this.initialValue = '',
  });

  @override
  State<CalculatorBottomSheet> createState() => _CalculatorBottomSheetState();
}

class _CalculatorBottomSheetState extends State<CalculatorBottomSheet> {
  String _expression = '';
  String _result = '';

  @override
  void initState() {
    super.initState();
    // Clean initial value
    var cleanInit = widget.initialValue.trim();
    if (cleanInit == '0') {
      cleanInit = '';
    }
    if (cleanInit.isNotEmpty) {
      _expression = cleanInit;
      final v = _evaluate(_expression);
      if (v != null) {
        _result = _fmtNum(v);
      }
    }
  }

  bool _isOperator(String s) => s == '+' || s == '-' || s == '*' || s == '/';

  void _onKeyTap(String key) {
    HapticFeedback.selectionClick();
    setState(() {
      if (key == 'C') {
        _expression = '';
        _result = '';
      } else if (key == '⌫') {
        if (_expression.isNotEmpty) {
          _expression = _expression.substring(0, _expression.length - 1);
          final v = _evaluate(_expression);
          _result = v != null ? _fmtNum(v) : '';
        }
      } else if (key == 'OK') {
        final finalVal = _evaluate(_expression);
        final resultStr = finalVal != null ? _fmtNum(finalVal) : _expression;
        Navigator.pop(context, resultStr.isEmpty ? '0' : resultStr);
      } else if (key == '%') {
        if (_expression.isNotEmpty) {
          final v = _evaluate(_expression);
          if (v != null) {
            _expression = _fmtNum(v / 100);
            _result = '';
          }
        }
      } else {
        // Map visual operators to logic operators
        var logicKey = key;
        if (key == '×') logicKey = '*';
        if (key == '÷') logicKey = '/';

        final isOp = _isOperator(logicKey);
        if (isOp && _expression.isEmpty) {
          if (logicKey == '-') {
            _expression = '-';
          }
          return;
        }

        if (isOp &&
            _expression.isNotEmpty &&
            _isOperator(_expression[_expression.length - 1])) {
          // Replace last operator
          _expression =
              _expression.substring(0, _expression.length - 1) + logicKey;
          return;
        }

        // Decimal dot constraints
        if (logicKey == '.') {
          // Get the current token
          final tokens = _tokenize(_expression);
          if (tokens.isNotEmpty && tokens.last.contains('.')) {
            return; // Can't add another dot to the current number
          }
          if (_expression.isEmpty || _isOperator(_expression[_expression.length - 1])) {
            _expression += '0';
          }
        }

        _expression += logicKey;

        // Live preview
        if (!isOp) {
          final v = _evaluate(_expression);
          _result = v != null ? _fmtNum(v) : '';
        }
      }
    });
  }

  // ── Evaluation Logic ──
  double? _evaluate(String expr) {
    if (expr.trim().isEmpty) return 0;
    try {
      final tokens = _tokenize(expr);
      if (tokens.isEmpty) return null;
      return _evalRpn(_toRpn(tokens));
    } catch (_) {
      return null;
    }
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

  String _getDisplayExpression() {
    if (_expression.isEmpty) return '0';
    return _expression
        .replaceAll('*', ' × ')
        .replaceAll('/', ' ÷ ')
        .replaceAll('+', ' + ')
        .replaceAll('-', ' - ');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    // Beautiful Color Palette inspired by the screenshot and system theme
    final sheetBg = isDark ? const Color(0xFF191724) : const Color(0xFFF9F6FC);
    final displayBg = isDark ? const Color(0xFF221F35) : const Color(0xFFF1ECF7);

    final fnBg = isDark ? const Color(0xFF482321) : const Color(0xFFFDEAE7);
    final fnFg = isDark ? const Color(0xFFFFB4AB) : const Color(0xFFC93D2C);

    final opBg = isDark ? const Color(0xFF2E274D) : const Color(0xFFEBE6F6);
    final opFg = isDark ? const Color(0xFFD0BCFF) : const Color(0xFF5D4F8D);

    final numBg = isDark ? const Color(0xFF211E2E) : const Color(0xFFF3EDFA);
    final numFg = isDark ? const Color(0xFFE5E1E6) : const Color(0xFF1C1B1F);

    final okBg = theme.colorScheme.primary;
    const okFg = Colors.white;

    final displayVal = _getDisplayExpression();
    final hasResult = _result.isNotEmpty && _result != displayVal && _result != _expression;

    return Container(
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle indicator
          Center(
            child: Container(
              width: 38,
              height: 4.5,
              margin: const EdgeInsets.only(top: 4, bottom: 12),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(2.25),
              ),
            ),
          ),

          // Display container
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
            decoration: BoxDecoration(
              color: displayBg,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Top line: Expression or blank if simple number
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  reverse: true,
                  child: Text(
                    hasResult ? displayVal : '',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                    ),
                  ),
                ),
                if (hasResult) const SizedBox(height: 4),
                // Main display (live result or the current expression)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  reverse: true,
                  child: Text(
                    hasResult ? _result : displayVal,
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF5D4F8D),
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Button Layout (Rows of buttons)
          Column(
            children: [
              // Row 1: C, Backspace, %, /
              Row(
                children: [
                  _CalcButton(
                    label: 'C',
                    bg: fnBg,
                    fg: fnFg,
                    onTap: () => _onKeyTap('C'),
                  ),
                  const SizedBox(width: 10),
                  _CalcButton(
                    icon: Icon(Icons.backspace_outlined, size: 21, color: fnFg),
                    bg: fnBg,
                    fg: fnFg,
                    onTap: () => _onKeyTap('⌫'),
                  ),
                  const SizedBox(width: 10),
                  _CalcButton(
                    label: '%',
                    bg: opBg,
                    fg: opFg,
                    onTap: () => _onKeyTap('%'),
                  ),
                  const SizedBox(width: 10),
                  _CalcButton(
                    label: '÷',
                    bg: opBg,
                    fg: opFg,
                    onTap: () => _onKeyTap('÷'),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Row 2: 7, 8, 9, x
              Row(
                children: [
                  _CalcButton(
                    label: '7',
                    bg: numBg,
                    fg: numFg,
                    onTap: () => _onKeyTap('7'),
                  ),
                  const SizedBox(width: 10),
                  _CalcButton(
                    label: '8',
                    bg: numBg,
                    fg: numFg,
                    onTap: () => _onKeyTap('8'),
                  ),
                  const SizedBox(width: 10),
                  _CalcButton(
                    label: '9',
                    bg: numBg,
                    fg: numFg,
                    onTap: () => _onKeyTap('9'),
                  ),
                  const SizedBox(width: 10),
                  _CalcButton(
                    label: '×',
                    bg: opBg,
                    fg: opFg,
                    onTap: () => _onKeyTap('×'),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Row 3: 4, 5, 6, -
              Row(
                children: [
                  _CalcButton(
                    label: '4',
                    bg: numBg,
                    fg: numFg,
                    onTap: () => _onKeyTap('4'),
                  ),
                  const SizedBox(width: 10),
                  _CalcButton(
                    label: '5',
                    bg: numBg,
                    fg: numFg,
                    onTap: () => _onKeyTap('5'),
                  ),
                  const SizedBox(width: 10),
                  _CalcButton(
                    label: '6',
                    bg: numBg,
                    fg: numFg,
                    onTap: () => _onKeyTap('6'),
                  ),
                  const SizedBox(width: 10),
                  _CalcButton(
                    label: '-',
                    bg: opBg,
                    fg: opFg,
                    onTap: () => _onKeyTap('-'),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Row 4: 1, 2, 3, +
              Row(
                children: [
                  _CalcButton(
                    label: '1',
                    bg: numBg,
                    fg: numFg,
                    onTap: () => _onKeyTap('1'),
                  ),
                  const SizedBox(width: 10),
                  _CalcButton(
                    label: '2',
                    bg: numBg,
                    fg: numFg,
                    onTap: () => _onKeyTap('2'),
                  ),
                  const SizedBox(width: 10),
                  _CalcButton(
                    label: '3',
                    bg: numBg,
                    fg: numFg,
                    onTap: () => _onKeyTap('3'),
                  ),
                  const SizedBox(width: 10),
                  _CalcButton(
                    label: '+',
                    bg: opBg,
                    fg: opFg,
                    onTap: () => _onKeyTap('+'),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Row 5: 0, ., OK
              Row(
                children: [
                  _CalcButton(
                    label: '0',
                    bg: numBg,
                    fg: numFg,
                    onTap: () => _onKeyTap('0'),
                  ),
                  const SizedBox(width: 10),
                  _CalcButton(
                    label: '.',
                    bg: numBg,
                    fg: numFg,
                    onTap: () => _onKeyTap('.'),
                  ),
                  const SizedBox(width: 10),
                  _CalcButton(
                    label: 'OK',
                    bg: okBg,
                    fg: okFg,
                    flex: 2,
                    isOk: true,
                    onTap: () => _onKeyTap('OK'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CalcButton extends StatelessWidget {
  final String? label;
  final Widget? icon;
  final Color bg;
  final Color fg;
  final VoidCallback onTap;
  final int flex;
  final bool isOk;

  const _CalcButton({
    this.label,
    this.icon,
    required this.bg,
    required this.fg,
    required this.onTap,
    this.flex = 1,
    this.isOk = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Center(
              child: icon ?? Text(
                label ?? '',
                style: TextStyle(
                  fontSize: isOk ? 18 : 22,
                  fontWeight: isOk ? FontWeight.w800 : FontWeight.w600,
                  color: fg,
                  letterSpacing: isOk ? 0.5 : null,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
