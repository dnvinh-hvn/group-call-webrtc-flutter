import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'room_event.dart';
part 'room_state.dart';

class RoomBloc extends Bloc<RoomEvent, RoomState> {
  RoomBloc(String? url)
      : super(
          RoomState(
            url: url != null && url.isNotEmpty
                ? url.replaceAll('roomid', 'roomId')
                : 'https://v3demo.mediasoup.org/?roomId=izn9mwxy',
          ),
        ) {
    on<RoomSetActiveSpeakerId>(_mapRoomSetActiveSpeakerIdToState);
  }

  _mapRoomSetActiveSpeakerIdToState(
      RoomSetActiveSpeakerId event, Emitter<RoomState> emit) async {
    emit(state.newActiveSpeaker(activeSpeakerId: event.speakerId));
  }
}
