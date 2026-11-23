import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';
import '../../data/models/lottery_item.dart';
import '../../services/local_prefs_service.dart';

class LotteryScreen extends ConsumerStatefulWidget {
  const LotteryScreen({super.key});

  @override
  ConsumerState<LotteryScreen> createState() => _LotteryScreenState();
}

class _LotteryScreenState extends ConsumerState<LotteryScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _shakeAnimation;
  bool _isDrawing = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -0.15), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -0.15, end: 0.15), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 0.15, end: -0.1), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -0.1, end: 0.1), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 0.1, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _animController, curve: Curves.easeInOut));

    _ensureAuthAndCode();
  }

  void _ensureAuthAndCode() {
    final code = LocalPrefsService.familyCode;
    if (code != null && code.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && ref.read(familyCodeProvider).isEmpty) {
          ref.read(familyCodeProvider.notifier).state = code;
        }
      });
    }
    if (FirebaseAuth.instance.currentUser == null) {
      FirebaseAuth.instance.signInAnonymously().then((_) {
        if (mounted) {
          ref.invalidate(lotteryTicketsProvider);
          ref.invalidate(lotteryInventoryProvider);
        }
      }).catchError((e) {
        debugPrint('Lottery auto auth error: $e');
      });
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _startDraw(int currentTickets, String familyCode) async {
    if (currentTickets <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('뽑기권이 부족해요! 부모님께 요청해보세요 😊')),
      );
      return;
    }
    if (_isDrawing) return;

    setState(() => _isDrawing = true);
    _animController.repeat();

    try {
      await Future.delayed(const Duration(milliseconds: 1400));
      final prize = await ref.read(lotteryRepositoryProvider).draw(familyCode);
      _animController.stop();
      _animController.reset();

      if (!mounted) return;
      _showResultDialog(prize);
    } catch (e) {
      _animController.stop();
      _animController.reset();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('뽑기 진행 중 오류가 발생했습니다: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isDrawing = false);
    }
  }

  void _showResultDialog(LotteryPrize prize) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          '🎉 ${prize.title} 당첨! 🎉',
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(prize.emoji, style: const TextStyle(fontSize: 64)),
            const SizedBox(height: 12),
            Text(
              prize.reward,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo),
            ),
            const SizedBox(height: 8),
            Text(
              '확률: ${prize.probability}%',
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            const Text(
              '보관함에 저장되었어요! 언제든 사용할 수 있습니다.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ],
        ),
        actions: [
          Center(
            child: FilledButton(
              onPressed: () => Navigator.pop(ctx),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: const Text('확인', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  void _showGiftDialog(String familyCode) {
    int count = 1;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: const Text('🎁 아이에게 뽑기권 주기'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('칭찬이나 숙제 완료 보상으로 뽑기권을 선물하세요!'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton.filledTonal(
                    onPressed: count > 1 ? () => setDlgState(() => count--) : null,
                    icon: const Icon(Icons.remove),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text('$count장',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  ),
                  IconButton.filledTonal(
                    onPressed: () => setDlgState(() => count++),
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await ref.read(lotteryRepositoryProvider).addTickets(familyCode, count);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('뽑기권 $count장을 선물했습니다! 🎟️')),
                  );
                }
              },
              child: const Text('선물하기'),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1: return const Color(0xFFE67E22);
      case 2: return const Color(0xFF8E44AD);
      case 3: return const Color(0xFF2980B9);
      case 4: return const Color(0xFF27AE60);
      case 5: return const Color(0xFFD35400);
      case 6: return const Color(0xFFE91E63);
      case 7: return const Color(0xFF5B5FEF);
      default: return Colors.indigo;
    }
  }

  Color _getRankBgColor(int rank) {
    switch (rank) {
      case 1: return const Color(0xFFFEF9E7);
      case 2: return const Color(0xFFF4ECF7);
      case 3: return const Color(0xFFEBF5FB);
      case 4: return const Color(0xFFE8F8F5);
      case 5: return const Color(0xFFFBEEE6);
      case 6: return const Color(0xFFFCE4EC);
      case 7: return const Color(0xFFEEF2FF);
      default: return const Color(0xFFF5F5F5);
    }
  }

  Future<void> _useItem(LotteryInventoryItem item, String familyCode, bool isParent) async {
    final actionText = isParent ? '사용 완료 처리' : '사용하기';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isParent ? '보상 사용 완료 처리' : '보상 사용'),
        content: Text(
          isParent
              ? '아이가 \'${item.reward}\'을(를) 사용했나요?\n확인을 누르면 보관함에서 삭제됩니다.'
              : '\'${item.reward}\'을(를) 사용하시겠습니까?\n사용하면 보관함에서 삭제됩니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(actionText),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final resolvedCode = familyCode.isNotEmpty ? familyCode : (LocalPrefsService.familyCode ?? '');
    if (resolvedCode.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('가족 코드가 설정되지 않았습니다.')),
        );
      }
      return;
    }

    try {
      await ref.read(lotteryRepositoryProvider).useItem(resolvedCode, item.id);
      ref.invalidate(lotteryInventoryProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('\'${item.reward}\' 사용이 완료되었습니다! ✨')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('사용 처리 중 오류가 발생했습니다: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final familyCode = ref.watch(familyCodeProvider);
    final ticketsAsync = ref.watch(lotteryTicketsProvider);
    final inventoryAsync = ref.watch(lotteryInventoryProvider);
    final isParent = LocalPrefsService.isParent;

    final tickets = ticketsAsync.value ?? 0;
    final inventory = inventoryAsync.value ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('행운의 뽑기 🎰', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(
              familyCode.isNotEmpty ? '가족코드: $familyCode' : '가족코드 연결 필요',
              style: TextStyle(
                fontSize: 11,
                color: familyCode.isNotEmpty ? Colors.black54 : Colors.red,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          if (isParent)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilledButton.tonal(
                onPressed: () => _showGiftDialog(familyCode),
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.card_giftcard, size: 16),
                    SizedBox(width: 4),
                    Text('티켓 선물'),
                  ],
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Modern Voucher Ticket Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C5CE7), Color(0xFF5B5FEF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF5B5FEF).withOpacity(0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      shape: BoxShape.circle,
                    ),
                    child: const Text('🎟️', style: TextStyle(fontSize: 32)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isParent ? '아이 보유 뽑기권' : '보유 뽑기권',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        RichText(
                          text: TextSpan(
                            text: '$tickets',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                            children: const [
                              TextSpan(
                                text: ' 장',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isParent)
                    ElevatedButton(
                      onPressed: () => _showGiftDialog(familyCode),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF5B5FEF),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                      child: const Text('선물하기 🎁', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
            ),

            if (!isParent) ...[
              const SizedBox(height: 24),

              // Dynamic Box Shake Area (아이 전용)
              GestureDetector(
                onTap: _isDrawing ? null : () => _startDraw(tickets, familyCode),
                child: AnimatedBuilder(
                  animation: _shakeAnimation,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _isDrawing ? _shakeAnimation.value : 0.0,
                      child: child,
                    );
                  },
                  child: Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      border: Border.all(color: Colors.amber.shade300, width: 2),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withOpacity(0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _isDrawing ? '🎲' : '🎁',
                          style: const TextStyle(fontSize: 70),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isDrawing ? '두근두근... 뽑는 중!' : '터치해서 행운의 뽑기 시작!',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _isDrawing ? Colors.deepOrange : Colors.brown.shade800,
                          ),
                        ),
                        if (!_isDrawing)
                          Text(
                            tickets > 0 ? '뽑기권 1장 소모' : '뽑기권이 필요해요',
                            style: TextStyle(
                              fontSize: 13,
                              color: tickets > 0 ? Colors.brown.shade400 : Colors.red,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Probability Information Card
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info_outline, size: 18, color: Colors.blueGrey),
                        SizedBox(width: 6),
                        Text(
                          '등수별 당첨 확률 안내',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    ...LotteryPrize.prizes.map((p) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.5),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  p.title,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(p.emoji, style: const TextStyle(fontSize: 15)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  p.reward,
                                  style: const TextStyle(fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '${p.probability}%',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple,
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Inventory (보관함)
            Row(
              children: [
                const Icon(Icons.inventory_2_outlined, color: Colors.indigo),
                const SizedBox(width: 8),
                Text(
                  '당첨 보관함 (${inventory.length}개)',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (inventory.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  children: [
                    Text('📭', style: TextStyle(fontSize: 32)),
                    SizedBox(height: 8),
                    Text(
                      '보관함이 비어있어요. 뽑기에 도전해보세요!',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: inventory.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, idx) {
                  final item = inventory[idx];
                  final rankColor = _getRankColor(item.rank);
                  final rankBgColor = _getRankBgColor(item.rank);

                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: rankColor.withOpacity(0.35), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: rankColor.withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Header: Rank Tag + Won Date
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: rankBgColor,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: rankColor.withOpacity(0.4), width: 1),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(item.emoji, style: const TextStyle(fontSize: 14)),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${item.rank}등 당첨',
                                    style: TextStyle(
                                      color: rankColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${item.wonAt.month}월 ${item.wonAt.day}일 획득',
                              style: const TextStyle(fontSize: 12, color: Colors.black45),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Bottom Content: Full Title + Use Button
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                item.reward,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF191F28),
                                  height: 1.3,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            FilledButton.tonal(
                              onPressed: () => _useItem(item, familyCode, isParent),
                              style: FilledButton.styleFrom(
                                backgroundColor: rankColor.withOpacity(0.12),
                                foregroundColor: rankColor,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                visualDensity: VisualDensity.compact,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Text(
                                isParent ? '사용 처리' : '사용',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
