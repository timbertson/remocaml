(* open Lwt *)
open Pulseaudio_interfaces

module Org_PulseAudio_ServerLookup1 =
struct
  open Org_PulseAudio_ServerLookup1


  let address proxy =
    OBus_property.make p_Address proxy
end

module Org_PulseAudio_Core1 =
struct
  open Org_PulseAudio_Core1

  (* let get_sink_by_name proxy ~name = *)
  (*   let%lwt (context, sink) = OBus_method.call_with_context m_GetSinkByName proxy name in *)
  (*   let sink = OBus_proxy.make (OBus_context.sender context) sink in *)
  (*   return sink *)
  (*  *)
  (* let get_source_by_name proxy ~name = *)
  (*   let%lwt (context, source) = OBus_method.call_with_context m_GetSourceByName proxy name in *)
  (*   let source = OBus_proxy.make (OBus_context.sender context) source in *)
  (*   return source *)
  (*  *)
  (* let get_sample_by_name proxy ~name = *)
  (*   let%lwt (context, sample) = OBus_method.call_with_context m_GetSampleByName proxy name in *)
  (*   let sample = OBus_proxy.make (OBus_context.sender context) sample in *)
  (*   return sample *)
  (*  *)
  (* let upload_sample proxy ~name ~sample_format ~sample_rate ~channels ~default_volume ~property_list ~data = *)
  (*   let sample_format = Int32.of_int sample_format in *)
  (*   let sample_rate = Int32.of_int sample_rate in *)
  (*   let channels = List.map Int32.of_int channels in *)
  (*   let default_volume = List.map Int32.of_int default_volume in *)
  (*   let%lwt (context, sample) = OBus_method.call_with_context m_UploadSample proxy (name, sample_format, sample_rate, channels, default_volume, property_list, data) in *)
  (*   let sample = OBus_proxy.make (OBus_context.sender context) sample in *)
  (*   return sample *)

  let exit proxy =
    OBus_method.call m_Exit proxy ()

  let listen_for_signal proxy ~signal ~objects =
    let objects = List.map OBus_proxy.path objects in
    OBus_method.call m_ListenForSignal proxy (signal, objects)

  let stop_listening_for_signal proxy ~signal =
    OBus_method.call m_StopListeningForSignal proxy signal

  let interface_revision proxy =
    OBus_property.map_r
      (fun x -> Int32.to_int x)
      (OBus_property.make p_InterfaceRevision proxy)

  let name proxy =
    OBus_property.make p_Name proxy

  let version proxy =
    OBus_property.make p_Version proxy

  let is_local proxy =
    OBus_property.make p_IsLocal proxy

  let username proxy =
    OBus_property.make p_Username proxy

  let hostname proxy =
    OBus_property.make p_Hostname proxy

  let default_channels proxy =
    OBus_property.map_rw
      (fun x -> List.map Int32.to_int x)
      (fun x -> List.map Int32.of_int x)
      (OBus_property.make p_DefaultChannels proxy)

  let default_sample_format proxy =
    OBus_property.map_rw
      (fun x -> Int32.to_int x)
      (fun x -> Int32.of_int x)
      (OBus_property.make p_DefaultSampleFormat proxy)

  let default_sample_rate proxy =
    OBus_property.map_rw
      (fun x -> Int32.to_int x)
      (fun x -> Int32.of_int x)
      (OBus_property.make p_DefaultSampleRate proxy)

  let alternate_sample_rate proxy =
    OBus_property.map_rw
      (fun x -> Int32.to_int x)
      (fun x -> Int32.of_int x)
      (OBus_property.make p_AlternateSampleRate proxy)

  (* let sinks proxy = *)
  (*   OBus_property.map_r_with_context *)
  (*     (fun context x -> List.map (OBus_proxy.make (OBus_context.sender context)) x) *)
  (*     (OBus_property.make p_Sinks proxy) *)

  let fallback_sink proxy =
    OBus_property.map_rw_with_context
      (fun context x -> OBus_proxy.make ~peer:(OBus_context.sender context) ~path:x)
      (fun x -> OBus_proxy.path x)
      (OBus_property.make p_FallbackSink proxy)

  let sources proxy =
    OBus_property.map_r_with_context
      (fun context x -> List.map (fun x -> OBus_proxy.make ~peer:(OBus_context.sender context) ~path:x) x)
      (OBus_property.make p_Sources proxy)

(*   let new_sink proxy = *)
(*     OBus_signal.map_with_context *)
(*       (fun context sink -> *)
(*          let sink = OBus_proxy.make ~peer:(OBus_context.sender context) ~path:sink in *)
(*          sink) *)
(*       (OBus_signal.connect s_NewSink proxy) *)
(*  *)
(*   let sink_removed proxy = *)
(*     OBus_signal.map_with_context *)
(*       (fun context sink -> *)
(*          let sink = OBus_proxy.make ~peer:(OBus_context.sender context) ~path:sink in *)
(*          sink) *)
(*       (OBus_signal.connect s_SinkRemoved proxy) *)
(*  *)
(*   let fallback_sink_updated proxy = *)
(*     OBus_signal.map_with_context *)
(*       (fun context sink -> *)
(*          let sink = OBus_proxy.make (OBus_context.sender context) sink in *)
(*          sink) *)
(*       (OBus_signal.connect s_FallbackSinkUpdated proxy) *)
(*  *)
(*   let fallback_sink_unset proxy = *)
(*     OBus_signal.make s_FallbackSinkUnset proxy *)
(*  *)
(*   let new_source proxy = *)
(*     OBus_signal.map_with_context *)
(*       (fun context source -> *)
(*          let source = OBus_proxy.make (OBus_context.sender context) source in *)
(*          source) *)
(*       (OBus_signal.connect s_NewSource proxy) *)
(*  *)
(*   let source_removed proxy = *)
(*     OBus_signal.map_with_context *)
(*       (fun context source -> *)
(*          let source = OBus_proxy.make (OBus_context.sender context) source in *)
(*          source) *)
(*       (OBus_signal.connect s_SourceRemoved proxy) *)
(*  *)
(*   let fallback_source_updated proxy = *)
(*     OBus_signal.map_with_context *)
(*       (fun context source -> *)
(*          let source = OBus_proxy.make (OBus_context.sender context) source in *)
(*          source) *)
(*       (OBus_signal.connect s_FallbackSourceUpdated proxy) *)
(*  *)
(*   let fallback_source_unset proxy = *)
(*     OBus_signal.make s_FallbackSourceUnset proxy *)
(*  *)
(*   let new_playback_stream proxy = *)
(*     OBus_signal.map_with_context *)
(*       (fun context playback_stream -> *)
(*          let playback_stream = OBus_proxy.make (OBus_context.sender context) playback_stream in *)
(*          playback_stream) *)
(*       (OBus_signal.connect s_NewPlaybackStream proxy) *)
(*  *)
(*   let playback_stream_removed proxy = *)
(*     OBus_signal.map_with_context *)
(*       (fun context playback_stream -> *)
(*          let playback_stream = OBus_proxy.make (OBus_context.sender context) playback_stream in *)
(*          playback_stream) *)
(*       (OBus_signal.connect s_PlaybackStreamRemoved proxy) *)
(*  *)
(*   let new_record_stream proxy = *)
(*     OBus_signal.map_with_context *)
(*       (fun context record_stream -> *)
(*          let record_stream = OBus_proxy.make (OBus_context.sender context) record_stream in *)
(*          record_stream) *)
(*       (OBus_signal.connect s_NewRecordStream proxy) *)
(*  *)
(*   let record_stream_removed proxy = *)
(*     OBus_signal.map_with_context *)
(*       (fun context record_stream -> *)
(*          let record_stream = OBus_proxy.make (OBus_context.sender context) record_stream in *)
(*          record_stream) *)
(*       (OBus_signal.connect s_RecordStreamRemoved proxy) *)
(*  *)
(*   let new_sample proxy = *)
(*     OBus_signal.map_with_context *)
(*       (fun context sample -> *)
(*          let sample = OBus_proxy.make (OBus_context.sender context) sample in *)
(*          sample) *)
(*       (OBus_signal.connect s_NewSample proxy) *)
(*  *)
(*   let sample_removed proxy = *)
(*     OBus_signal.map_with_context *)
(*       (fun context sample -> *)
(*          let sample = OBus_proxy.make (OBus_context.sender context) sample in *)
(*          sample) *)
(*       (OBus_signal.connect s_SampleRemoved proxy) *)
(*  *)
(*   let new_client proxy = *)
(*     OBus_signal.map_with_context *)
(*       (fun context client -> *)
(*          let client = OBus_proxy.make (OBus_context.sender context) client in *)
(*          client) *)
(*       (OBus_signal.connect s_NewClient proxy) *)
(*  *)
(*   let client_removed proxy = *)
(*     OBus_signal.map_with_context *)
(*       (fun context client -> *)
(*          let client = OBus_proxy.make (OBus_context.sender context) client in *)
(*          client) *)
(*       (OBus_signal.connect s_ClientRemoved proxy) *)
(*  *)
(*   let new_extension proxy = *)
(*     OBus_signal.make s_NewExtension proxy *)
(*  *)
(*   let extension_removed proxy = *)
(*     OBus_signal.make s_ExtensionRemoved proxy *)
end

module Org_PulseAudio_Core1_Device =
struct
  open Org_PulseAudio_Core1_Device


  let suspend proxy ~suspend =
    OBus_method.call m_Suspend proxy suspend

  (* let get_port_by_name proxy ~name = *)
  (*   let%lwt (context, port) = OBus_method.call_with_context m_GetPortByName proxy name in *)
  (*   let port = OBus_proxy.make (OBus_context.sender context) port in *)
  (*   return port *)

  let index proxy =
    OBus_property.map_r
      (fun x -> Int32.to_int x)
      (OBus_property.make p_Index proxy)

  let name proxy =
    OBus_property.make p_Name proxy

  let driver proxy =
    OBus_property.make p_Driver proxy

  (* let owner_module proxy = *)
  (*   OBus_property.map_r_with_context *)
  (*     (fun context x -> OBus_proxy.make (OBus_context.sender context) x) *)
  (*     (OBus_property.make p_OwnerModule proxy) *)
  (*  *)
  (* let card proxy = *)
  (*   OBus_property.map_r_with_context *)
  (*     (fun context x -> OBus_proxy.make (OBus_context.sender context) x) *)
  (*     (OBus_property.make p_Card proxy) *)
  (*  *)
  (* let sample_format proxy = *)
  (*   OBus_property.map_r *)
  (*     (fun x -> Int32.to_int x) *)
  (*     (OBus_property.make p_SampleFormat proxy) *)
  (*  *)
  (* let sample_rate proxy = *)
  (*   OBus_property.map_r *)
  (*     (fun x -> Int32.to_int x) *)
  (*     (OBus_property.make p_SampleRate proxy) *)
  (*  *)
  (* let channels proxy = *)
  (*   OBus_property.map_r *)
  (*     (fun x -> List.map Int32.to_int x) *)
  (*     (OBus_property.make p_Channels proxy) *)

  let volume proxy =
    OBus_property.map_rw
      (fun x -> List.map Int32.to_int x)
      (fun x -> List.map Int32.of_int x)
      (OBus_property.make p_Volume proxy)

  let has_flat_volume proxy =
    OBus_property.make p_HasFlatVolume proxy

  let has_convertible_to_decibel_volume proxy =
    OBus_property.make p_HasConvertibleToDecibelVolume proxy

  let base_volume proxy =
    OBus_property.map_r
      (fun x -> Int32.to_int x)
      (OBus_property.make p_BaseVolume proxy)

  let volume_steps proxy =
    OBus_property.map_r
      (fun x -> Int32.to_int x)
      (OBus_property.make p_VolumeSteps proxy)

  let mute proxy =
    OBus_property.make p_Mute proxy

  let has_hardware_volume proxy =
    OBus_property.make p_HasHardwareVolume proxy

  let has_hardware_mute proxy =
    OBus_property.make p_HasHardwareMute proxy

  let configured_latency proxy =
    OBus_property.make p_ConfiguredLatency proxy

  let has_dynamic_latency proxy =
    OBus_property.make p_HasDynamicLatency proxy

  let latency proxy =
    OBus_property.make p_Latency proxy

  let is_hardware_device proxy =
    OBus_property.make p_IsHardwareDevice proxy

  let is_network_device proxy =
    OBus_property.make p_IsNetworkDevice proxy

  let state proxy =
    OBus_property.map_r
      (fun x -> Int32.to_int x)
      (OBus_property.make p_State proxy)

  (* let ports proxy = *)
  (*   OBus_property.map_r_with_context *)
  (*     (fun context x -> List.map (OBus_proxy.make (OBus_context.sender context)) x) *)
  (*     (OBus_property.make p_Ports proxy) *)
  (*  *)
  (* let active_port proxy = *)
  (*   OBus_property.map_rw_with_context *)
  (*     (fun context x -> OBus_proxy.make (OBus_context.sender context) x) *)
  (*     (fun x -> OBus_proxy.path x) *)
  (*     (OBus_property.make p_ActivePort proxy) *)
  (*  *)
  (* let property_list proxy = *)
  (*   OBus_property.make p_PropertyList proxy *)
  (*  *)
  (* let volume_updated proxy = *)
  (*   OBus_signal.map *)
  (*     (fun volume -> *)
  (*        let volume = List.map Int32.to_int volume in *)
  (*        volume) *)
  (*     (OBus_signal.connect s_VolumeUpdated proxy) *)
  (*  *)
  (* let mute_updated proxy = *)
  (*   OBus_signal.make s_MuteUpdated proxy *)
  (*  *)
  (* let state_updated proxy = *)
  (*   OBus_signal.map *)
  (*     (fun state -> *)
  (*        let state = Int32.to_int state in *)
  (*        state) *)
  (*     (OBus_signal.connect s_StateUpdated proxy) *)
  (*  *)
  (* let active_port_updated proxy = *)
  (*   OBus_signal.map_with_context *)
  (*     (fun context port -> *)
  (*        let port = OBus_proxy.make (OBus_context.sender context) port in *)
  (*        port) *)
  (*     (OBus_signal.connect s_ActivePortUpdated proxy) *)
  (*  *)
  (* let property_list_updated proxy = *)
  (*   OBus_signal.make s_PropertyListUpdated proxy *)
end

