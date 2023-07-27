import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mediasoup_client_flutter/mediasoup_client_flutter.dart';

part 'producers_event.dart';

part 'producers_state.dart';

class ProducersBloc extends Bloc<ProducersEvent, ProducersState> {
  ProducersBloc() : super(ProducersState()) {
    on<ProducerAdd>(_mapProducerAddToState);
    on<ProducerRemove>(_mapProducerRemoveToState);
    on<ProducerResumed>(_mapProducerResumeToState);
    on<ProducerPaused>(_mapProducerPausedToState);
  }

  _mapProducerAddToState(
      ProducerAdd event, Emitter<ProducersState> emit) async {
    switch (event.producer.source) {
      case 'mic':
        {
          emit(ProducersState.copy(state, mic: event.producer));
          break;
        }
      case 'webcam':
        {
          emit(ProducersState.copy(state, webcam: event.producer));
          break;
        }
      case 'screen':
        {
          emit(ProducersState.copy(state, screen: event.producer));
          break;
        }
      default:
        break;
    }
  }

  _mapProducerRemoveToState(
      ProducerRemove event, Emitter<ProducersState> emit) async {
    switch (event.source) {
      case 'mic':
        {
          state.mic?.close();
          emit(ProducersState.removeMic(state));
          break;
        }
      case 'webcam':
        {
          state.webcam?.close();
          emit(ProducersState.removeWebcam(state));
          break;
        }
      case 'screen':
        {
          state.screen?.close();
          emit(ProducersState.removeScreen(state));
          break;
        }
      default:
        break;
    }
  }

  _mapProducerResumeToState(
      ProducerResumed event, Emitter<ProducersState> emit) async {
    switch (event.source) {
      case 'mic':
        {
          emit(ProducersState.copy(state, mic: state.mic!.resumeCopy()));
          break;
        }
      case 'webcam':
        {
          emit(ProducersState.copy(state, webcam: state.webcam!.resumeCopy()));
          break;
        }
      case 'screen':
        {
          emit(ProducersState.copy(state, screen: state.screen?.resumeCopy()));
          break;
        }
      default:
        break;
    }
  }

  _mapProducerPausedToState(
      ProducerPaused event, Emitter<ProducersState> emit) async {
    switch (event.source) {
      case 'mic':
        {
          emit(ProducersState.copy(state, mic: state.mic!.pauseCopy()));
          break;
        }
      case 'webcam':
        {
          emit(ProducersState.copy(state, webcam: state.webcam!.pauseCopy()));
          break;
        }
      case 'screen':
        {
          emit(ProducersState.copy(state, screen: state.screen!.pauseCopy()));
          break;
        }
      default:
        break;
    }
  }
}
