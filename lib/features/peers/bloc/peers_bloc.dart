import 'dart:async';
import 'package:collection/collection.dart';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:example/features/peers/enitity/peer.dart';
import 'package:example/features/media_devices/bloc/media_devices_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:mediasoup_client_flutter/mediasoup_client_flutter.dart';

part 'peers_event.dart';

part 'peers_state.dart';

class PeersBloc extends Bloc<dynamic, PeersState> {
  final MediaDevicesBloc mediaDevicesBloc;
  String selectedOutputId = '';

  PeersBloc({required this.mediaDevicesBloc}) : super(PeersState()) {
    on<PeerAdd>(_mapPeerAddToState);
    on<PeerRemove>(_mapPeerRemoveToState);
    on<PeerAddConsumer>(_mapConsumerAddToState);
    on<PeerRemoveConsumer>(_mapConsumerRemoveToState);
    on<PeerPausedConsumer>(_mapPeerPausedConsumer);
    on<PeerResumedConsumer>(_mapPeerResumedConsumer);
  }

  _mapPeerAddToState(PeerAdd event, Emitter<PeersState> emit) async {
    final Map<String, Peer> newPeers = Map<String, Peer>.of(state.peers);
    final Peer newPeer = Peer.fromMap(event.newPeer);
    newPeers[newPeer.id] = newPeer;

    emit(PeersState(peers: newPeers));
  }

  _mapPeerRemoveToState(PeerRemove event, Emitter<PeersState> emit) async {
    final Map<String, Peer> newPeers = Map<String, Peer>.of(state.peers);
    newPeers.remove(event.peerId);

    emit(PeersState(peers: newPeers));
  }

  _mapConsumerAddToState(
      PeerAddConsumer event, Emitter<PeersState> emit) async {
    final Map<String, Peer> newPeers = Map<String, Peer>.of(state.peers);

    if (kIsWeb) {
      if (newPeers[event.peerId]!.renderer == null) {
        newPeers[event.peerId!] =
            newPeers[event.peerId]!.copyWith(renderer: RTCVideoRenderer());
        await newPeers[event.peerId]!.renderer!.initialize();
        // newPeers[event.peerId]!.renderer!.audioOutput = selectedOutputId;
      }

      if (event.consumer.kind == 'video') {
        newPeers[event.peerId!] =
            newPeers[event.peerId]!.copyWith(video: event.consumer);
        newPeers[event.peerId]!.renderer!.srcObject =
            newPeers[event.peerId]!.video!.stream;
      }

      if (event.consumer.kind == 'audio') {
        newPeers[event.peerId!] =
            newPeers[event.peerId]!.copyWith(audio: event.consumer);
        if (newPeers[event.peerId]!.video == null) {
          newPeers[event.peerId]!.renderer!.srcObject =
              newPeers[event.peerId]!.audio!.stream;
        }
      }
    } else {
      if (event.consumer.kind == 'video') {
        newPeers[event.peerId!] = newPeers[event.peerId]!.copyWith(
          renderer: RTCVideoRenderer(),
          video: event.consumer,
        );
        await newPeers[event.peerId]!.renderer!.initialize();
        // newPeers[event.peerId]!.renderer!.audioOutput = selectedOutputId;
        newPeers[event.peerId]!.renderer!.srcObject =
            newPeers[event.peerId]!.video!.stream;
      } else {
        newPeers[event.peerId!] = newPeers[event.peerId]!.copyWith(
          audio: event.consumer,
        );
      }
    }

    emit(PeersState(peers: newPeers));
  }

  _mapConsumerRemoveToState(
      PeerRemoveConsumer event, Emitter<PeersState> emit) async {
    final Map<String, Peer> newPeers = Map<String, Peer>.of(state.peers);
    final Peer? peer = newPeers.values
        .firstWhereOrNull((p) => p.consumers.contains(event.consumerId));

    if (peer != null) {
      if (kIsWeb) {
        if (peer.audio?.id == event.consumerId) {
          final consumer = peer.audio;
          if (peer.video == null) {
            final renderer = newPeers[peer.id]?.renderer!;
            newPeers[peer.id] = newPeers[peer.id]!.removeAudioAndRenderer();
            emit(PeersState(peers: newPeers));
            await Future.delayed(Duration(microseconds: 300));
            await renderer?.dispose();
          } else {
            newPeers[peer.id] = newPeers[peer.id]!.removeAudio();
            emit(PeersState(peers: newPeers));
          }
          await consumer?.close();
        } else if (peer.video?.id == event.consumerId) {
          final consumer = peer.video;
          if (peer.audio != null) {
            newPeers[peer.id]!.renderer!.srcObject =
                newPeers[peer.id]!.audio!.stream;
            newPeers[peer.id] = newPeers[peer.id]!.removeVideo();
            emit(PeersState(peers: newPeers));
          } else {
            final renderer = newPeers[peer.id]!.renderer!;
            newPeers[peer.id] = newPeers[peer.id]!.removeVideoAndRenderer();
            emit(PeersState(peers: newPeers));
            await renderer.dispose();
          }
          await consumer?.close();
        }
      } else {
        if (peer.audio?.id == event.consumerId) {
          final consumer = peer.audio;
          newPeers[peer.id] = newPeers[peer.id]!.removeAudio();
          emit(PeersState(peers: newPeers));
          await consumer?.close();
        } else if (peer.video?.id == event.consumerId) {
          final consumer = peer.video;
          final renderer = peer.renderer;
          newPeers[peer.id] = newPeers[peer.id]!.removeVideoAndRenderer();
          emit(PeersState(peers: newPeers));
          consumer
              ?.close()
              .then((_) => Future.delayed(Duration(microseconds: 300)))
              .then((_) async => await renderer?.dispose());
        }
      }
    }
  }

  _mapPeerPausedConsumer(
      PeerPausedConsumer event, Emitter<PeersState> emit) async {
    final Map<String, Peer> newPeers = Map<String, Peer>.of(state.peers);
    final Peer? peer = newPeers.values
        .firstWhereOrNull((p) => p.consumers.contains(event.consumerId));

    if (peer != null) {
      newPeers[peer.id] = newPeers[peer.id]!.copyWith(
        audio: peer.audio!.pauseCopy(),
      );

      emit(PeersState(peers: newPeers));
    }
  }

  _mapPeerResumedConsumer(PeerResumedConsumer event, Emitter<PeersState> emit) async {
    final Map<String, Peer> newPeers = Map<String, Peer>.of(state.peers);
    final Peer? peer = newPeers.values
        .firstWhereOrNull((p) => p.consumers.contains(event.consumerId));

    if (peer != null) {
      newPeers[peer.id] = newPeers[peer.id]!.copyWith(
        audio: peer.audio!.resumeCopy(),
      );

      emit(PeersState(peers: newPeers));
    }
  }

  @override
  Future<void> close() {
    state.peers.values.forEach((peer) {
      peer.renderer?.dispose();
    });
    return super.close();
  }
}
