import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'dart:async';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/services/conversation_service.dart';
import '../../../data/services/socket_service.dart';
import '../../../features/auth/providers/auth_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String conversationId;
  const ChatScreen({super.key, required this.conversationId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _picker = ImagePicker();
  final _recorder = AudioRecorder();
  final _player = AudioPlayer();
  final _conversationService = ConversationService();
  final _socket = SocketService();

  Map<String, dynamic>? _conversation;
  List<Map<String, dynamic>> _messages = [];
  bool _loading = true;

  String? _replyingToId;
  String? _replyingToText;
  bool _isRecording = false;
  int _recordSeconds = 0;
  Timer? _recordTimer;
  String? _playingId;
  bool _sending = false;

  // Offline queue
  final List<Map<String, dynamic>> _offlineQueue = [];
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _init();
    _initConnectivity();
  }

  Future<void> _initConnectivity() async {
    final results = await Connectivity().checkConnectivity();
    if (mounted) setState(() => _isOnline = results.any((r) => r != ConnectivityResult.none));
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final online = results.any((r) => r != ConnectivityResult.none);
      if (!_isOnline && online && mounted) {
        setState(() => _isOnline = true);
        _flushOfflineQueue();
      } else if (mounted) {
        setState(() => _isOnline = online);
      }
    });
  }

  Future<void> _flushOfflineQueue() async {
    if (_offlineQueue.isEmpty) return;
    final pending = List<Map<String, dynamic>>.from(_offlineQueue);
    _offlineQueue.clear();
    for (final msg in pending) {
      await _sendToServer(
        tempId: msg['id'] as String,
        text: msg['text'] as String?,
        imagePath: msg['image'] as String?,
        replyToId: msg['replyToId'] as String?,
      );
    }
  }

  Future<void> _init() async {
    await _socket.connect();

    // Remove any stale listener from a previous session before registering a new one
    _socket.off(AppStrings.eventNewMessage);

    _socket.joinConversation(widget.conversationId);

    _socket.onNewMessage((data) {
      if (!mounted) return;
      final userId = ref.read(authProvider).user?.id;
      final msg = data['message'] as Map<String, dynamic>? ?? data;

      // Skip messages I sent — the optimistic bubble already represents them.
      // The HTTP response (in _sendToServer) updates the temp ID to the real one.
      final senderRaw = msg['sender_id'] ?? msg['sender'];
      final senderId = (senderRaw is Map ? senderRaw['_id'] : senderRaw) as String?;
      if (userId != null && senderId == userId) return;

      // Dedup guard for any other edge cases
      final msgId = msg['_id'] as String? ?? '';
      if (msgId.isNotEmpty && _messages.any((m) => m['id'] == msgId)) return;

      final formatted = _formatMessage(msg, userId: userId);
      setState(() => _messages.add(formatted));
      _scrollToBottom();
    });

    await _loadConversation();
    await _loadMessages();
  }

  Future<void> _loadConversation() async {
    try {
      final conv = await _conversationService.getConversationById(widget.conversationId);
      if (mounted) setState(() => _conversation = conv);
    } catch (_) {}
  }

  Future<void> _loadMessages() async {
    try {
      final list = await _conversationService.getMessages(widget.conversationId, limit: 50);
      final userId = ref.read(authProvider).user?.id;
      if (mounted) {
        setState(() {
          _messages = list.map((m) => _formatMessage(m, userId: userId)).toList();
          _loading = false;
        });
        _scrollToBottom();
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Map<String, dynamic> _formatMessage(Map<String, dynamic> m, {String? userId}) {
    final senderRaw = m['sender_id'] ?? m['sender'];
    final senderId = (senderRaw is Map ? senderRaw['_id'] : senderRaw) as String?;
    final isMe = userId != null ? senderId == userId : m['is_mine'] == true;
    final msgType = m['message_type'] as String? ?? 'text';
    final content = m['content'] as String? ?? m['text'] as String? ?? '';
    final time = _formatTime(m['createdAt'] as String?);

    // Extract reactions from backend format [{user_id, emoji}] → ['❤️', ...]
    final rawReactions = m['reactions'] as List<dynamic>? ?? [];
    final reactions = rawReactions
        .map((r) => (r is Map ? r['emoji'] : r) as String?)
        .whereType<String>()
        .toList();

    // Extract reply_to from backend populated object
    final replyToRaw = m['reply_to'];
    String? replyToText;
    if (replyToRaw is Map<String, dynamic>) {
      final replyType = replyToRaw['message_type'] as String? ?? 'text';
      replyToText = replyType == 'image' ? '📷 Image' : (replyToRaw['content'] as String? ?? '');
    }

    return {
      'id': m['_id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      // image messages: content IS the URL when message_type == 'image'
      'text': msgType == 'image' ? '' : content,
      'imageUrl': msgType == 'image' ? content : null, // network URL from Cloudinary
      'sender': isMe ? 'me' : 'pharmacy',
      'time': time,
      'read': m['read_by'] != null,
      'reactions': reactions,
      'image': null,   // local file path (optimistic only)
      'voice': null,
      'replyTo': replyToText,
    };
  }

  String _formatTime(String? raw) {
    if (raw == null) return _timeNow();
    final dt = DateTime.tryParse(raw);
    if (dt == null) return '';
    return DateFormat('h:mm a').format(dt.toLocal());
  }

  String _pharmacyName() {
    final conv = _conversation;
    if (conv == null) return 'Pharmacy';
    final pharmacy = conv['pharmacy'] as Map<String, dynamic>?;
    if (pharmacy != null) return pharmacy['name'] as String? ?? 'Pharmacy';
    final order = conv['order'] as Map<String, dynamic>?;
    final ph = order?['pharmacy'] as Map<String, dynamic>?;
    return ph?['name'] as String? ?? 'Pharmacy';
  }

  String _orderLabel() {
    final conv = _conversation;
    if (conv == null) return '';
    final order = conv['order'] as Map<String, dynamic>?;
    final id = order?['_id'] as String? ?? '';
    if (id.isEmpty) return '';
    return 'ORD-${id.substring(id.length > 6 ? id.length - 6 : 0).toUpperCase()}';
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  // ── Recording ─────────────────────────────────────────────────────────────
  Future<void> _startRecording() async {
    try {
      if (!await _recorder.hasPermission()) return;
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: path);
      setState(() { _isRecording = true; _recordSeconds = 0; });
      _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() => _recordSeconds++));
      HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  Future<void> _stopRecording() async {
    try {
      _recordTimer?.cancel();
      final path = await _recorder.stop();
      setState(() => _isRecording = false);
      if (path != null) _send(voicePath: path, voiceDuration: _recordSeconds);
    } catch (_) {}
  }

  Future<void> _cancelRecording() async {
    _recordTimer?.cancel();
    await _recorder.stop();
    setState(() { _isRecording = false; _recordSeconds = 0; });
    HapticFeedback.lightImpact();
  }

  Future<void> _playVoice(String id, String path) async {
    if (_playingId == id) {
      await _player.stop();
      setState(() => _playingId = null);
    } else {
      setState(() => _playingId = id);
      await _player.play(DeviceFileSource(path));
      _player.onPlayerComplete.listen((_) { if (mounted) setState(() => _playingId = null); });
    }
  }

  // ── Send ──────────────────────────────────────────────────────────────────
  Future<void> _send({String? imagePath, String? voicePath, int? voiceDuration}) async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty && imagePath == null && voicePath == null) return;
    if (_sending && _isOnline) return;

    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final replyToId   = _replyingToId;
    final replyToText = _replyingToText;

    final optimisticMsg = {
      'id': tempId,
      'text': text,
      'sender': 'me',
      'time': _timeNow(),
      'read': false,
      'reactions': <String>[],
      'image': imagePath,
      'voice': voicePath,
      'voiceDuration': voiceDuration,
      'replyTo': replyToText,
      'replyToId': replyToId,
      'status': _isOnline ? 'sending' : 'queued',
    };

    setState(() {
      _messages.add(optimisticMsg);
      _replyingToId = null;
      _replyingToText = null;
      if (_isOnline) _sending = true;
    });
    _msgCtrl.clear();
    _scrollToBottom();

    if (!_isOnline) {
      // Queue and wait for connectivity
      _offlineQueue.add({...optimisticMsg, 'replyToId': replyToId});
      return;
    }

    await _sendToServer(
      tempId: tempId,
      text: text.isNotEmpty ? text : null,
      imagePath: imagePath,
      replyToId: replyToId,
    );
  }

  Future<void> _sendToServer({
    required String tempId,
    String? text,
    String? imagePath,
    String? replyToId,
  }) async {
    try {
      Map<String, dynamic>? realMsg;
      if (imagePath != null) {
        realMsg = await _conversationService.sendImageMessage(
          conversationId: widget.conversationId,
          imageFile: File(imagePath),
          replyTo: replyToId,
        );
      } else if (text != null && text.isNotEmpty) {
        realMsg = await _conversationService.sendMessage(
          conversationId: widget.conversationId,
          content: text,
          replyTo: replyToId,
        );
      }
      // Replace temp ID with real MongoDB _id so socket dedup prevents duplicate
      final realId = realMsg?['_id'] as String?;
      if (mounted) {
        setState(() {
          final idx = _messages.indexWhere((m) => m['id'] == tempId);
          if (idx != -1) {
            _messages[idx] = {
              ..._messages[idx],
              'id': realId ?? tempId,
              'status': realId != null ? 'sent' : 'failed',
            };
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          final idx = _messages.indexWhere((m) => m['id'] == tempId);
          if (idx != -1) _messages[idx] = {..._messages[idx], 'status': 'failed'};
        });
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _retryMessage(Map<String, dynamic> msg) async {
    if (!_isOnline) return;
    final tempId = msg['id'] as String;
    if (mounted) {
      setState(() {
        final idx = _messages.indexWhere((m) => m['id'] == tempId);
        if (idx != -1) _messages[idx] = {..._messages[idx], 'status': 'sending'};
        _sending = true;
      });
    }
    await _sendToServer(
      tempId: tempId,
      text: msg['text'] as String?,
      imagePath: msg['image'] as String?,
      replyToId: msg['replyToId'] as String?,
    );
  }

  // ── Image picker ──────────────────────────────────────────────────────────
  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.grey300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text('Attach Image', style: GoogleFonts.workSans(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      Navigator.pop(context);
                      final p = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
                      if (p != null) _send(imagePath: p.path);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: AppColors.tealLight, borderRadius: BorderRadius.circular(16)),
                      child: Column(children: [const Icon(Icons.camera_alt_rounded, color: AppColors.teal, size: 32), const SizedBox(height: 8), Text('Camera', style: GoogleFonts.workSans(fontWeight: FontWeight.w600, color: AppColors.tealDark))]),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      Navigator.pop(context);
                      final p = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
                      if (p != null) _send(imagePath: p.path);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: AppColors.primaryPale, borderRadius: BorderRadius.circular(16)),
                      child: Column(children: [const Icon(Icons.photo_library_rounded, color: AppColors.primary, size: 32), const SizedBox(height: 8), Text('Gallery', style: GoogleFonts.workSans(fontWeight: FontWeight.w600, color: AppColors.primary))]),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Reactions ─────────────────────────────────────────────────────────────
  void _showReactions(BuildContext context, Map<String, dynamic> msg) {
    HapticFeedback.mediumImpact();
    const emojis = ['❤️', '👍', '😊', '😮', '😢', '🙏'];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20)]),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.grey300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            if ((msg['text'] as String? ?? '').isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.grey50, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                  child: Text(msg['text'] as String, style: GoogleFonts.workSans(fontSize: 13, color: AppColors.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
                ),
              ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: emojis.map((emoji) {
                  final reactions = msg['reactions'] as List<String>;
                  final selected = reactions.contains(emoji);
                  return GestureDetector(
                    onTap: () async {
                      // Update locally immediately for responsiveness
                      setState(() { selected ? reactions.remove(emoji) : reactions.add(emoji); });
                      Navigator.pop(context);
                      // Persist to backend
                      try {
                        await _conversationService.addReaction(
                          conversationId: widget.conversationId,
                          messageId: msg['id'] as String,
                          emoji: emoji,
                        );
                      } catch (_) {}
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 52, height: 52,
                      decoration: BoxDecoration(color: selected ? AppColors.tealLight : AppColors.grey50, shape: BoxShape.circle, border: Border.all(color: selected ? AppColors.teal : AppColors.border, width: selected ? 2 : 1)),
                      child: Center(child: Text(emoji, style: const TextStyle(fontSize: 24))),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        setState(() {
                          _replyingToId = msg['id'] as String;
                          _replyingToText = (msg['text'] as String? ?? '').isNotEmpty ? msg['text'] as String : '🎤 Voice note';
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(color: AppColors.primaryPale, borderRadius: BorderRadius.circular(12)),
                        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.reply_rounded, color: AppColors.primary, size: 18), const SizedBox(width: 6), Text('Reply', style: GoogleFonts.workSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary))]),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        final t = msg['text'] as String? ?? '';
                        if (t.isNotEmpty) Clipboard.setData(ClipboardData(text: t));
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(color: AppColors.grey100, borderRadius: BorderRadius.circular(12)),
                        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.copy_rounded, color: AppColors.textSecondary, size: 18), const SizedBox(width: 6), Text('Copy', style: GoogleFonts.workSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary))]),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ── Full-screen image viewer ──────────────────────────────────────────────
  void _openImageViewer(BuildContext context, String path, {required bool isNetwork}) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (_, __, ___) => _ImageViewer(path: path, isNetwork: isNetwork),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  String _timeNow() {
    final now = DateTime.now();
    final h = now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
    final m = now.minute.toString().padLeft(2, '0');
    return '$h:$m ${now.hour >= 12 ? 'PM' : 'AM'}';
  }

  String _formatDuration(int s) => '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  @override
  void dispose() {
    _socket.leaveConversation(widget.conversationId);
    _socket.off(AppStrings.eventNewMessage);
    _connectivitySub?.cancel();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    _recorder.dispose();
    _player.dispose();
    _recordTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.of(context).padding;
    final orderLabel = _orderLabel();

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: Column(
        children: [
          // ── Header ────────────────────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF0ABFBC), Color(0xFF0891B2), Color(0xFF1B3A6B)]),
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 46, height: 46,
                      decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(0.5), width: 2)),
                      child: const Icon(Icons.local_pharmacy_rounded, color: AppColors.teal, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_pharmacyName(), style: GoogleFonts.workSans(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                          Row(
                            children: [
                              Container(width: 6, height: 6, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF4ADE80))),
                              const SizedBox(width: 4),
                              Text('Online', style: GoogleFonts.workSans(fontSize: 12, color: Colors.white70)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (orderLabel.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                        child: Text(orderLabel, style: GoogleFonts.workSans(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // ── Offline banner ────────────────────────────────────────────────
          if (!_isOnline)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              color: AppColors.warning,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    _offlineQueue.isEmpty
                        ? 'No internet connection'
                        : 'Offline — ${_offlineQueue.length} message${_offlineQueue.length > 1 ? 's' : ''} queued',
                    style: GoogleFonts.workSans(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ],
              ),
            ),

          // ── Messages ──────────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.teal))
                : _messages.isEmpty
                ? Center(child: Text('No messages yet', style: GoogleFonts.workSans(color: AppColors.textSecondary)))
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    itemCount: _messages.length,
                    itemBuilder: (_, i) {
                      final msg = _messages[i];
                      final isMe = msg['sender'] == 'me';
                      final showAvatar = !isMe && (i == 0 || _messages[i - 1]['sender'] == 'me');
                      return GestureDetector(
                        onLongPress: () => _showReactions(context, msg),
                        child: _MessageBubble(
                          message: msg,
                          isMe: isMe,
                          showAvatar: showAvatar,
                          playingId: _playingId,
                          onPlayVoice: _playVoice,
                          onImageTap: (path, isNetwork) => _openImageViewer(context, path, isNetwork: isNetwork),
                          onRetry: msg['status'] == 'failed' ? () => _retryMessage(msg) : null,
                        ),
                      );
                    },
                  ),
          ),

          // ── Reply preview ─────────────────────────────────────────────────
          if (_replyingToText != null)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              color: Colors.white,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: AppColors.tealLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.teal.withOpacity(0.3))),
                child: Row(
                  children: [
                    Container(width: 3, height: 36, decoration: BoxDecoration(color: AppColors.teal, borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Replying to', style: GoogleFonts.workSans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.teal)),
                          Text(_replyingToText!, style: GoogleFonts.workSans(fontSize: 12, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    GestureDetector(onTap: () => setState(() { _replyingToId = null; _replyingToText = null; }), child: const Icon(Icons.close_rounded, color: AppColors.grey400, size: 18)),
                  ],
                ),
              ),
            ),

          // ── Input ─────────────────────────────────────────────────────────
          Container(
            padding: EdgeInsets.fromLTRB(16, 12, 16, padding.bottom + 12),
            decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, -4))]),
            child: _isRecording
                ? _RecordingBar(seconds: _recordSeconds, onStop: _stopRecording, onCancel: _cancelRecording, format: _formatDuration)
                : Row(
                    children: [
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: 42, height: 42,
                          decoration: BoxDecoration(color: AppColors.grey50, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                          child: const Icon(Icons.attach_file_rounded, color: AppColors.grey400, size: 20),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(color: AppColors.grey50, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.border)),
                          child: TextField(
                            controller: _msgCtrl,
                            maxLines: null,
                            style: GoogleFonts.workSans(fontSize: 14, color: AppColors.textPrimary),
                            decoration: InputDecoration(
                              hintText: 'Type a message...',
                              hintStyle: GoogleFonts.workSans(fontSize: 14, color: AppColors.textHint),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            onSubmitted: (_) => _send(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _msgCtrl,
                        builder: (_, value, __) {
                          final hasText = value.text.trim().isNotEmpty;
                          return GestureDetector(
                            onTap: hasText ? _send : null,
                            onLongPress: hasText ? null : _startRecording,
                            child: Container(
                              width: 42, height: 42,
                              decoration: BoxDecoration(color: AppColors.teal, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: AppColors.teal.withOpacity(0.35), blurRadius: 8, offset: const Offset(0, 3))]),
                              child: Icon(hasText ? Icons.send_rounded : Icons.mic_rounded, color: Colors.white, size: 20),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Recording bar ─────────────────────────────────────────────────────────────
class _RecordingBar extends StatelessWidget {
  final int seconds;
  final VoidCallback onStop;
  final VoidCallback onCancel;
  final String Function(int) format;
  const _RecordingBar({required this.seconds, required this.onStop, required this.onCancel, required this.format});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: onCancel,
          child: Container(width: 42, height: 42, decoration: BoxDecoration(color: AppColors.dangerLight, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 20)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(color: AppColors.dangerLight, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.danger.withOpacity(0.3))),
            child: Row(
              children: [
                _PulsingDot(),
                const SizedBox(width: 8),
                Text('Recording...', style: GoogleFonts.workSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.danger)),
                const Spacer(),
                Text(format(seconds), style: GoogleFonts.workSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.danger)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: onStop,
          child: Container(width: 42, height: 42, decoration: BoxDecoration(color: AppColors.teal, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: AppColors.teal.withOpacity(0.35), blurRadius: 8, offset: const Offset(0, 3))]), child: const Icon(Icons.send_rounded, color: Colors.white, size: 20)),
        ),
      ],
    );
  }
}

class _PulsingDot extends StatefulWidget {
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => FadeTransition(opacity: _anim, child: Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.danger)));
}

// ── Full-screen image viewer ──────────────────────────────────────────────────
class _ImageViewer extends StatefulWidget {
  final String path;
  final bool isNetwork;
  const _ImageViewer({required this.path, required this.isNetwork});

  @override
  State<_ImageViewer> createState() => _ImageViewerState();
}

class _ImageViewerState extends State<_ImageViewer> {
  final _transformCtrl = TransformationController();

  @override
  void dispose() {
    _transformCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // Dimmed background
            const Positioned.fill(child: ColoredBox(color: Colors.black87)),
            // Pinch-to-zoom image
            Center(
              child: GestureDetector(
                onTap: () {}, // prevent tap-through to close
                child: InteractiveViewer(
                  transformationController: _transformCtrl,
                  minScale: 0.5,
                  maxScale: 5.0,
                  child: widget.isNetwork
                      ? Image.network(
                          widget.path,
                          fit: BoxFit.contain,
                          loadingBuilder: (_, child, prog) => prog == null
                              ? child
                              : const SizedBox(
                                  width: 60, height: 60,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                ),
                        )
                      : Image.file(File(widget.path), fit: BoxFit.contain),
                ),
              ),
            ),
            // Close button
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              right: 16,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                  child: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
                ),
              ),
            ),
            // Double-tap to reset zoom
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 20,
              left: 0, right: 0,
              child: Center(
                child: GestureDetector(
                  onDoubleTap: () => setState(() => _transformCtrl.value = Matrix4.identity()),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(20)),
                    child: const Text('Pinch to zoom  •  Double-tap to reset', style: TextStyle(color: Colors.white60, fontSize: 12)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Message bubble ────────────────────────────────────────────────────────────
class _MessageBubble extends StatelessWidget {
  final Map<String, dynamic> message;
  final bool isMe;
  final bool showAvatar;
  final String? playingId;
  final void Function(String, String) onPlayVoice;
  final void Function(String path, bool isNetwork) onImageTap;
  final VoidCallback? onRetry;

  const _MessageBubble({required this.message, required this.isMe, required this.showAvatar, required this.playingId, required this.onPlayVoice, required this.onImageTap, this.onRetry});

  Widget _buildStatusIcon(String? status) {
    switch (status) {
      case 'queued':
        return const Icon(Icons.access_time_rounded, size: 12, color: Colors.white60);
      case 'sending':
        return const SizedBox(
          width: 10, height: 10,
          child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white60),
        );
      case 'failed':
        return GestureDetector(
          onTap: onRetry,
          child: const Icon(Icons.error_outline_rounded, size: 13, color: Colors.orangeAccent),
        );
      default:
        return Icon(
          message['read'] == true ? Icons.done_all_rounded : Icons.done_rounded,
          size: 12,
          color: message['read'] == true ? Colors.white : Colors.white60,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final reactions = message['reactions'] as List<String>? ?? [];
    final replyTo = message['replyTo'] as String?;
    final imagePath = message['image'] as String?;         // local file (optimistic)
    final imageUrl  = message['imageUrl'] as String?;      // Cloudinary URL from backend
    final voicePath = message['voice'] as String?;
    final voiceDur = message['voiceDuration'] as int?;
    final isPlaying = playingId == message['id'];

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMe) ...[
                showAvatar
                    ? Container(width: 32, height: 32, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.tealLight), child: const Icon(Icons.local_pharmacy_rounded, color: AppColors.teal, size: 16))
                    : const SizedBox(width: 32),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
                  decoration: BoxDecoration(
                    color: isMe ? AppColors.teal : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isMe ? 18 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 18),
                    ),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (replyTo != null)
                        Container(
                          margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isMe ? Colors.white.withOpacity(0.2) : AppColors.grey50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border(left: BorderSide(color: isMe ? Colors.white : AppColors.teal, width: 3)),
                          ),
                          child: Text(replyTo, style: GoogleFonts.workSans(fontSize: 11, color: isMe ? Colors.white70 : AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      // Network image (from Cloudinary after upload)
                      if (imageUrl != null)
                        Padding(
                          padding: const EdgeInsets.all(6),
                          child: GestureDetector(
                            onTap: () => onImageTap(imageUrl, true),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                imageUrl,
                                width: 220, height: 160, fit: BoxFit.cover,
                                loadingBuilder: (_, child, progress) => progress == null
                                    ? child
                                    : Container(width: 220, height: 160, color: AppColors.grey100, child: const Center(child: CircularProgressIndicator(color: AppColors.teal, strokeWidth: 2))),
                                errorBuilder: (_, __, ___) => Container(width: 220, height: 80, color: AppColors.grey100, child: const Icon(Icons.broken_image_rounded, color: AppColors.grey400)),
                              ),
                            ),
                          ),
                        ),
                      // Local image (optimistic — before upload completes)
                      if (imagePath != null && imageUrl == null)
                        Padding(
                          padding: const EdgeInsets.all(6),
                          child: GestureDetector(
                            onTap: () => onImageTap(imagePath, false),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(File(imagePath), width: 220, height: 160, fit: BoxFit.cover),
                            ),
                          ),
                        ),
                      if (voicePath != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(10, 10, 10, 4),
                          child: GestureDetector(
                            onTap: () => onPlayVoice(message['id'] as String, voicePath),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 36, height: 36,
                                  decoration: BoxDecoration(shape: BoxShape.circle, color: isMe ? Colors.white.withOpacity(0.2) : AppColors.tealLight),
                                  child: Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: isMe ? Colors.white : AppColors.teal, size: 20),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: List.generate(20, (i) {
                                        const heights = [4.0, 8.0, 12.0, 6.0, 14.0, 10.0, 8.0, 16.0, 6.0, 10.0, 12.0, 8.0, 14.0, 6.0, 10.0, 8.0, 12.0, 6.0, 8.0, 4.0];
                                        return Container(width: 2, height: heights[i], margin: const EdgeInsets.symmetric(horizontal: 1), decoration: BoxDecoration(color: isMe ? Colors.white.withOpacity(isPlaying ? 1 : 0.6) : AppColors.teal.withOpacity(isPlaying ? 1 : 0.4), borderRadius: BorderRadius.circular(2)));
                                      }),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(voiceDur != null ? '${(voiceDur ~/ 60).toString().padLeft(2, '0')}:${(voiceDur % 60).toString().padLeft(2, '0')}' : '0:00', style: GoogleFonts.workSans(fontSize: 10, color: isMe ? Colors.white70 : AppColors.textHint)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      if ((message['text'] as String? ?? '').isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
                          child: Text(message['text'] as String, style: GoogleFonts.workSans(fontSize: 14, color: isMe ? Colors.white : AppColors.textPrimary, height: 1.4)),
                        ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 2, 14, 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(message['time'] as String? ?? '', style: GoogleFonts.workSans(fontSize: 10, color: isMe ? Colors.white70 : AppColors.textHint)),
                            if (isMe) ...[
                              const SizedBox(width: 4),
                              _buildStatusIcon(message['status'] as String?),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (isMe) const SizedBox(width: 4),
            ],
          ),
          if (reactions.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(left: isMe ? 0 : 44, right: isMe ? 8 : 0, top: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 2))]),
                child: Row(mainAxisSize: MainAxisSize.min, children: reactions.map((r) => Padding(padding: const EdgeInsets.symmetric(horizontal: 2), child: Text(r, style: const TextStyle(fontSize: 14)))).toList()),
              ),
            ),
        ],
      ),
    );
  }
}
