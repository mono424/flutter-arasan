import 'dart:async';
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';

import 'ffi.dart';
import 'arasan_state.dart';

/// A wrapper for C++ engine.
class Arasan {
  final Completer<Arasan>? completer;

  final _state = _ArasanState();
  final _stdoutController = StreamController<String>.broadcast();
  final _mainPort = ReceivePort();
  final _stdoutPort = ReceivePort();

  late StreamSubscription _mainSubscription;
  late StreamSubscription _stdoutSubscription;

  Arasan._({this.completer}) {
    _mainSubscription =
        _mainPort.listen((message) => _cleanUp(message is int ? message : 1));
    _stdoutSubscription = _stdoutPort.listen((message) {
      if (message is String) {
        _stdoutController.sink.add(message);
      } else {
        debugPrint('[arasan] The stdout isolate sent $message');
      }
    });
    compute(_spawnIsolates, [_mainPort.sendPort, _stdoutPort.sendPort]).then(
      (success) {
        final state = success ? ArasanState.ready : ArasanState.error;
        _state._setValue(state);
        if (state == ArasanState.ready) {
          completer?.complete(this);
        }
      },
      onError: (error) {
        debugPrint('[arasan] The init isolate encountered an error $error');
        _cleanUp(1);
      },
    );
  }

  static Arasan? _instance;

  /// Creates a C++ engine.
  ///
  /// This may throws a [StateError] if an active instance is being used.
  /// Owner must [dispose] it before a new instance can be created.
  factory Arasan() {
    if (_instance != null) {
      throw new StateError('Multiple instances are not supported, yet.');
    }

    _instance = Arasan._();
    return _instance!;
  }

  /// The current state of the underlying C++ engine.
  ValueListenable<ArasanState> get state => _state;

  /// The standard output stream.
  Stream<String> get stdout => _stdoutController.stream;

  /// The standard input sink.
  set stdin(String line) {
    final stateValue = _state.value;
    if (stateValue != ArasanState.ready) {
      throw StateError('Arasan is not ready ($stateValue)');
    }

    final pointer = '$line\n'.toNativeUtf8();
    nativeStdinWrite(pointer);
    calloc.free(pointer);
  }

  /// Stops the C++ engine.
  void dispose() {
    stdin = 'quit';
  }

  void _cleanUp(int exitCode) {
    _stdoutController.close();

    _mainSubscription.cancel();
    _stdoutSubscription.cancel();

    _state._setValue(
        exitCode == 0 ? ArasanState.disposed : ArasanState.error);

    _instance = null;
  }
}

/// Creates a C++ engine asynchronously.
///
/// This method is different from the factory method [new Arasan] that
/// it will wait for the engine to be ready before returning the instance.
Future<Arasan> arasanAsync() {
  if (Arasan._instance != null) {
    return Future.error(StateError('Only one instance can be used at a time'));
  }

  final completer = Completer<Arasan>();
  Arasan._instance = Arasan._(completer: completer);
  return completer.future;
}

class _ArasanState extends ChangeNotifier
    implements ValueListenable<ArasanState> {
  ArasanState _value = ArasanState.starting;

  @override
  ArasanState get value => _value;

  _setValue(ArasanState v) {
    if (v == _value) return;
    _value = v;
    notifyListeners();
  }
}

void _isolateMain(SendPort mainPort) {
  final exitCode = nativeMain();
  mainPort.send(exitCode);

  debugPrint('[arasan] nativeMain returns $exitCode');
}

void _isolateStdout(SendPort stdoutPort) {
  String previous = '';

  while (true) {
    final pointer = nativeStdoutRead();

    if (pointer.address == 0) {
      debugPrint('[arasan] nativeStdoutRead returns NULL');
      return;
    }

    final data = previous + pointer.toDartString();
    final lines = data.split('\n');
    previous = lines.removeLast();
    for (final line in lines) {
      stdoutPort.send(line);
    }
  }
}

Future<bool> _spawnIsolates(List<SendPort> mainAndStdout) async {
  final initResult = nativeInit();
  if (initResult != 0) {
    debugPrint('[arasan] initResult=$initResult');
    return false;
  }

  try {
    await Isolate.spawn(_isolateStdout, mainAndStdout[1]);
  } catch (error) {
    debugPrint('[arasan] Failed to spawn stdout isolate: $error');
    return false;
  }

  try {
    await Isolate.spawn(_isolateMain, mainAndStdout[0]);
  } catch (error) {
    debugPrint('[arasan] Failed to spawn main isolate: $error');
    return false;
  }

  return true;
}
