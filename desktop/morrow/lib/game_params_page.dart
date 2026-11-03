import 'package:flutter/material.dart';
import 'backend.dart';

/// Game-wide switches that are applied to the game's data files.
/// The backend methods already exist in the editor core; this page only
/// exposes them in the Morrow UI.
class GameParamsPage extends StatefulWidget {
  const GameParamsPage({
    super.key,
    required this.backend,
    required this.onError,
    required this.surface,
  });

  final Backend backend;
  final void Function(Object error) onError;
  final Widget Function(Widget child) surface;

  @override
  State<GameParamsPage> createState() => _GameParamsPageState();
}

class _GameParamsPageState extends State<GameParamsPage> {
  bool _loading = true;
  bool _busy = false;
  bool _reticle = false;
  bool _bounce = false;
  bool _foliage = false;
  bool _ragdoll = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final result = await widget.backend.call('tweaks');
      if (!mounted) return;
      final map = result is Map ? result : const {};
      setState(() {
        _reticle = map['reticle'] == true;
        _bounce = map['bounce'] == true;
        _foliage = map['foliage'] == true;
        _loading = false;
      });
    } catch (e) {
      widget.onError(e);
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _setTweak(String name, bool value) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.backend.call('tweaks', [name, value]);
      if (mounted) {
        setState(() {
          if (name == 'reticle') _reticle = value;
          if (name == 'bounce') _bounce = value;
          if (name == 'foliage') _foliage = value;
        });
      }
    } catch (e) {
      widget.onError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _setRagdoll(bool value) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.backend.call('ragdoll_apply', [value]);
      if (mounted) setState(() => _ragdoll = value);
    } catch (e) {
      widget.onError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _section(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: widget.surface(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            for (final child in children) child,
          ],
        ),
      ),
    );
  }

  Widget _switch({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: _busy ? null : onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListView(
      children: [
        _section('瞄准显示', [
          _switch(
            title: '狙击步枪第三人称准星',
            subtitle: '以第三人称瞄准时，狙击步枪显示准星。',
            value: _reticle,
            onChanged: (v) => _setTweak('reticle', v),
          ),
        ]),
        _section('投掷行为', [
          _switch(
            title: '策略球部署限制放宽',
            subtitle: '解除部分战备仅能在导航网格上部署的限制；岩石、高台和物体碰撞仍可能弹开。',
            value: _bounce,
            onChanged: (v) => _setTweak('bounce', v),
          ),
        ]),
        _section('射弹交互', [
          _switch(
            title: '射弹穿过树冠与灌木',
            subtitle: '火箭弹、发射器弹药和战备弹药可穿过树冠和灌木。',
            value: _foliage,
            onChanged: (v) => _setTweak('foliage', v),
          ),
        ]),
        _section('受击与布娃娃（实验性）', [
          _switch(
            title: '受击与布娃娃',
            subtitle: '已校验当前资源版本。实验性：需进入游戏验证；此操作只管理资源补丁，游戏运行中不能切换。',
            value: _ragdoll,
            onChanged: (v) => _setRagdoll(v),
          ),
        ]),
      ],
    );
  }
}
