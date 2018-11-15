open OBus_value
open OBus_value.C
open OBus_member
open OBus_object
module Org_PulseAudio_ServerLookup1 =
struct
  let interface = "org.PulseAudio.ServerLookup1"
  let p_Address = {
    Property.interface = interface;
    Property.member = "Address";
    Property.typ = basic_string;
    Property.access = Property.readable;
    Property.annotations = [];
  }
  type 'a members = {
    p_Address : 'a OBus_object.t -> string React.signal;
  }
  let make members =
    OBus_object.make_interface_unsafe interface
      [
      ]
      [|
      |]
      [|
      |]
      [|
        property_r_info p_Address members.p_Address;
      |]
end

module Org_PulseAudio_Core1 =
struct
  let interface = "org.PulseAudio.Core1"
  let m_Exit = {
    Method.interface = interface;
    Method.member = "Exit";
    Method.i_args = (arg0);
    Method.o_args = (arg0);
    Method.annotations = [];
  }
  let m_GetCardByName = {
    Method.interface = interface;
    Method.member = "GetCardByName";
    Method.i_args = (arg1
                       (Some "name", basic_string));
    Method.o_args = (arg1
                       (Some "card", basic_object_path));
    Method.annotations = [];
  }
  let m_GetSampleByName = {
    Method.interface = interface;
    Method.member = "GetSampleByName";
    Method.i_args = (arg1
                       (Some "name", basic_string));
    Method.o_args = (arg1
                       (Some "sample", basic_object_path));
    Method.annotations = [];
  }
  let m_GetSinkByName = {
    Method.interface = interface;
    Method.member = "GetSinkByName";
    Method.i_args = (arg1
                       (Some "name", basic_string));
    Method.o_args = (arg1
                       (Some "sink", basic_object_path));
    Method.annotations = [];
  }
  let m_GetSourceByName = {
    Method.interface = interface;
    Method.member = "GetSourceByName";
    Method.i_args = (arg1
                       (Some "name", basic_string));
    Method.o_args = (arg1
                       (Some "source", basic_object_path));
    Method.annotations = [];
  }
  let m_ListenForSignal = {
    Method.interface = interface;
    Method.member = "ListenForSignal";
    Method.i_args = (arg2
                       (Some "signal", basic_string)
                       (Some "objects", array basic_object_path));
    Method.o_args = (arg0);
    Method.annotations = [];
  }
  let m_LoadModule = {
    Method.interface = interface;
    Method.member = "LoadModule";
    Method.i_args = (arg2
                       (Some "name", basic_string)
                       (Some "arguments", dict string basic_string));
    Method.o_args = (arg1
                       (Some "module", basic_object_path));
    Method.annotations = [];
  }
  let m_StopListeningForSignal = {
    Method.interface = interface;
    Method.member = "StopListeningForSignal";
    Method.i_args = (arg1
                       (Some "signal", basic_string));
    Method.o_args = (arg0);
    Method.annotations = [];
  }
  let m_UploadSample = {
    Method.interface = interface;
    Method.member = "UploadSample";
    Method.i_args = (arg7
                       (Some "name", basic_string)
                       (Some "sample_format", basic_uint32)
                       (Some "sample_rate", basic_uint32)
                       (Some "channels", array basic_uint32)
                       (Some "default_volume", array basic_uint32)
                       (Some "property_list", dict string byte_array)
                       (Some "data", byte_array));
    Method.o_args = (arg1
                       (Some "sample", basic_object_path));
    Method.annotations = [];
  }
  let s_CardRemoved = {
    Signal.interface = interface;
    Signal.member = "CardRemoved";
    Signal.args = (arg1
                       (Some "card", basic_object_path));
    Signal.annotations = [];
  }
  let s_ClientRemoved = {
    Signal.interface = interface;
    Signal.member = "ClientRemoved";
    Signal.args = (arg1
                       (Some "client", basic_object_path));
    Signal.annotations = [];
  }
  let s_ExtensionRemoved = {
    Signal.interface = interface;
    Signal.member = "ExtensionRemoved";
    Signal.args = (arg1
                       (Some "extension", basic_string));
    Signal.annotations = [];
  }
  let s_FallbackSinkUnset = {
    Signal.interface = interface;
    Signal.member = "FallbackSinkUnset";
    Signal.args = (arg0);
    Signal.annotations = [];
  }
  let s_FallbackSinkUpdated = {
    Signal.interface = interface;
    Signal.member = "FallbackSinkUpdated";
    Signal.args = (arg1
                       (Some "sink", basic_object_path));
    Signal.annotations = [];
  }
  let s_FallbackSourceUnset = {
    Signal.interface = interface;
    Signal.member = "FallbackSourceUnset";
    Signal.args = (arg0);
    Signal.annotations = [];
  }
  let s_FallbackSourceUpdated = {
    Signal.interface = interface;
    Signal.member = "FallbackSourceUpdated";
    Signal.args = (arg1
                       (Some "source", basic_object_path));
    Signal.annotations = [];
  }
  let s_ModuleRemoved = {
    Signal.interface = interface;
    Signal.member = "ModuleRemoved";
    Signal.args = (arg1
                       (Some "module", basic_object_path));
    Signal.annotations = [];
  }
  let s_NewCard = {
    Signal.interface = interface;
    Signal.member = "NewCard";
    Signal.args = (arg1
                       (Some "card", basic_object_path));
    Signal.annotations = [];
  }
  let s_NewClient = {
    Signal.interface = interface;
    Signal.member = "NewClient";
    Signal.args = (arg1
                       (Some "client", basic_object_path));
    Signal.annotations = [];
  }
  let s_NewExtension = {
    Signal.interface = interface;
    Signal.member = "NewExtension";
    Signal.args = (arg1
                       (Some "extension", basic_string));
    Signal.annotations = [];
  }
  let s_NewModule = {
    Signal.interface = interface;
    Signal.member = "NewModule";
    Signal.args = (arg1
                       (Some "module", basic_object_path));
    Signal.annotations = [];
  }
  let s_NewPlaybackStream = {
    Signal.interface = interface;
    Signal.member = "NewPlaybackStream";
    Signal.args = (arg1
                       (Some "playback_stream", basic_object_path));
    Signal.annotations = [];
  }
  let s_NewRecordStream = {
    Signal.interface = interface;
    Signal.member = "NewRecordStream";
    Signal.args = (arg1
                       (Some "record_stream", basic_object_path));
    Signal.annotations = [];
  }
  let s_NewSample = {
    Signal.interface = interface;
    Signal.member = "NewSample";
    Signal.args = (arg1
                       (Some "sample", basic_object_path));
    Signal.annotations = [];
  }
  let s_NewSink = {
    Signal.interface = interface;
    Signal.member = "NewSink";
    Signal.args = (arg1
                       (Some "sink", basic_object_path));
    Signal.annotations = [];
  }
  let s_NewSource = {
    Signal.interface = interface;
    Signal.member = "NewSource";
    Signal.args = (arg1
                       (Some "source", basic_object_path));
    Signal.annotations = [];
  }
  let s_PlaybackStreamRemoved = {
    Signal.interface = interface;
    Signal.member = "PlaybackStreamRemoved";
    Signal.args = (arg1
                       (Some "playback_stream", basic_object_path));
    Signal.annotations = [];
  }
  let s_RecordStreamRemoved = {
    Signal.interface = interface;
    Signal.member = "RecordStreamRemoved";
    Signal.args = (arg1
                       (Some "record_stream", basic_object_path));
    Signal.annotations = [];
  }
  let s_SampleRemoved = {
    Signal.interface = interface;
    Signal.member = "SampleRemoved";
    Signal.args = (arg1
                       (Some "sample", basic_object_path));
    Signal.annotations = [];
  }
  let s_SinkRemoved = {
    Signal.interface = interface;
    Signal.member = "SinkRemoved";
    Signal.args = (arg1
                       (Some "sink", basic_object_path));
    Signal.annotations = [];
  }
  let s_SourceRemoved = {
    Signal.interface = interface;
    Signal.member = "SourceRemoved";
    Signal.args = (arg1
                       (Some "source", basic_object_path));
    Signal.annotations = [];
  }
  let p_AlternateSampleRate = {
    Property.interface = interface;
    Property.member = "AlternateSampleRate";
    Property.typ = basic_uint32;
    Property.access = Property.readable_writable;
    Property.annotations = [];
  }
  let p_Cards = {
    Property.interface = interface;
    Property.member = "Cards";
    Property.typ = array basic_object_path;
    Property.access = Property.readable;
    Property.annotations = [];
  }
  let p_Clients = {
    Property.interface = interface;
    Property.member = "Clients";
    Property.typ = array basic_object_path;
    Property.access = Property.readable;
    Property.annotations = [];
  }
  let p_DefaultChannels = {
    Property.interface = interface;
    Property.member = "DefaultChannels";
    Property.typ = array basic_uint32;
    Property.access = Property.readable_writable;
    Property.annotations = [];
  }
  let p_DefaultSampleFormat = {
    Property.interface = interface;
    Property.member = "DefaultSampleFormat";
    Property.typ = basic_uint32;
    Property.access = Property.readable_writable;
    Property.annotations = [];
  }
  let p_DefaultSampleRate = {
    Property.interface = interface;
    Property.member = "DefaultSampleRate";
    Property.typ = basic_uint32;
    Property.access = Property.readable_writable;
    Property.annotations = [];
  }
  let p_Extensions = {
    Property.interface = interface;
    Property.member = "Extensions";
    Property.typ = array basic_string;
    Property.access = Property.readable;
    Property.annotations = [];
  }
  let p_FallbackSink = {
    Property.interface = interface;
    Property.member = "FallbackSink";
    Property.typ = basic_object_path;
    Property.access = Property.readable_writable;
    Property.annotations = [];
  }
  let p_FallbackSource = {
    Property.interface = interface;
    Property.member = "FallbackSource";
    Property.typ = basic_object_path;
    Property.access = Property.readable_writable;
    Property.annotations = [];
  }
  let p_Hostname = {
    Property.interface = interface;
    Property.member = "Hostname";
    Property.typ = basic_string;
    Property.access = Property.readable;
    Property.annotations = [];
  }
  let p_InterfaceRevision = {
    Property.interface = interface;
    Property.member = "InterfaceRevision";
    Property.typ = basic_uint32;
    Property.access = Property.readable;
    Property.annotations = [];
  }
  let p_IsLocal = {
    Property.interface = interface;
    Property.member = "IsLocal";
    Property.typ = basic_boolean;
    Property.access = Property.readable;
    Property.annotations = [];
  }
  let p_Modules = {
    Property.interface = interface;
    Property.member = "Modules";
    Property.typ = array basic_object_path;
    Property.access = Property.readable;
    Property.annotations = [];
  }
  let p_MyClient = {
    Property.interface = interface;
    Property.member = "MyClient";
    Property.typ = basic_object_path;
    Property.access = Property.readable;
    Property.annotations = [];
  }
  let p_Name = {
    Property.interface = interface;
    Property.member = "Name";
    Property.typ = basic_string;
    Property.access = Property.readable;
    Property.annotations = [];
  }
  let p_PlaybackStreams = {
    Property.interface = interface;
    Property.member = "PlaybackStreams";
    Property.typ = array basic_object_path;
    Property.access = Property.readable;
    Property.annotations = [];
  }
  let p_RecordStreams = {
    Property.interface = interface;
    Property.member = "RecordStreams";
    Property.typ = array basic_object_path;
    Property.access = Property.readable;
    Property.annotations = [];
  }
  let p_Samples = {
    Property.interface = interface;
    Property.member = "Samples";
    Property.typ = array basic_object_path;
    Property.access = Property.readable;
    Property.annotations = [];
  }
  let p_Sinks = {
    Property.interface = interface;
    Property.member = "Sinks";
    Property.typ = array basic_object_path;
    Property.access = Property.readable;
    Property.annotations = [];
  }
  let p_Sources = {
    Property.interface = interface;
    Property.member = "Sources";
    Property.typ = array basic_object_path;
    Property.access = Property.readable;
    Property.annotations = [];
  }
  let p_Username = {
    Property.interface = interface;
    Property.member = "Username";
    Property.typ = basic_string;
    Property.access = Property.readable;
    Property.annotations = [];
  }
  let p_Version = {
    Property.interface = interface;
    Property.member = "Version";
    Property.typ = basic_string;
    Property.access = Property.readable;
    Property.annotations = [];
  }
  type 'a members = {
    m_Exit : 'a OBus_object.t -> unit -> unit Lwt.t;
    m_GetCardByName : 'a OBus_object.t -> string -> OBus_path.t Lwt.t;
    m_GetSampleByName : 'a OBus_object.t -> string -> OBus_path.t Lwt.t;
    m_GetSinkByName : 'a OBus_object.t -> string -> OBus_path.t Lwt.t;
    m_GetSourceByName : 'a OBus_object.t -> string -> OBus_path.t Lwt.t;
    m_ListenForSignal : 'a OBus_object.t -> string * OBus_path.t list -> unit Lwt.t;
    m_LoadModule : 'a OBus_object.t -> string * (string * string) list -> OBus_path.t Lwt.t;
    m_StopListeningForSignal : 'a OBus_object.t -> string -> unit Lwt.t;
    m_UploadSample : 'a OBus_object.t -> string * int32 * int32 * int32 list * int32 list * (string * string) list * string -> OBus_path.t Lwt.t;
    p_AlternateSampleRate : ('a OBus_object.t -> int32 React.signal) * ('a OBus_object.t -> int32 -> unit Lwt.t);
    p_Cards : 'a OBus_object.t -> OBus_path.t list React.signal;
    p_Clients : 'a OBus_object.t -> OBus_path.t list React.signal;
    p_DefaultChannels : ('a OBus_object.t -> int32 list React.signal) * ('a OBus_object.t -> int32 list -> unit Lwt.t);
    p_DefaultSampleFormat : ('a OBus_object.t -> int32 React.signal) * ('a OBus_object.t -> int32 -> unit Lwt.t);
    p_DefaultSampleRate : ('a OBus_object.t -> int32 React.signal) * ('a OBus_object.t -> int32 -> unit Lwt.t);
    p_Extensions : 'a OBus_object.t -> string list React.signal;
    p_FallbackSink : ('a OBus_object.t -> OBus_path.t React.signal) * ('a OBus_object.t -> OBus_path.t -> unit Lwt.t);
    p_FallbackSource : ('a OBus_object.t -> OBus_path.t React.signal) * ('a OBus_object.t -> OBus_path.t -> unit Lwt.t);
    p_Hostname : 'a OBus_object.t -> string React.signal;
    p_InterfaceRevision : 'a OBus_object.t -> int32 React.signal;
    p_IsLocal : 'a OBus_object.t -> bool React.signal;
    p_Modules : 'a OBus_object.t -> OBus_path.t list React.signal;
    p_MyClient : 'a OBus_object.t -> OBus_path.t React.signal;
    p_Name : 'a OBus_object.t -> string React.signal;
    p_PlaybackStreams : 'a OBus_object.t -> OBus_path.t list React.signal;
    p_RecordStreams : 'a OBus_object.t -> OBus_path.t list React.signal;
    p_Samples : 'a OBus_object.t -> OBus_path.t list React.signal;
    p_Sinks : 'a OBus_object.t -> OBus_path.t list React.signal;
    p_Sources : 'a OBus_object.t -> OBus_path.t list React.signal;
    p_Username : 'a OBus_object.t -> string React.signal;
    p_Version : 'a OBus_object.t -> string React.signal;
  }
  let make members =
    OBus_object.make_interface_unsafe interface
      [
      ]
      [|
        method_info m_Exit members.m_Exit;
        method_info m_GetCardByName members.m_GetCardByName;
        method_info m_GetSampleByName members.m_GetSampleByName;
        method_info m_GetSinkByName members.m_GetSinkByName;
        method_info m_GetSourceByName members.m_GetSourceByName;
        method_info m_ListenForSignal members.m_ListenForSignal;
        method_info m_LoadModule members.m_LoadModule;
        method_info m_StopListeningForSignal members.m_StopListeningForSignal;
        method_info m_UploadSample members.m_UploadSample;
      |]
      [|
        signal_info s_CardRemoved;
        signal_info s_ClientRemoved;
        signal_info s_ExtensionRemoved;
        signal_info s_FallbackSinkUnset;
        signal_info s_FallbackSinkUpdated;
        signal_info s_FallbackSourceUnset;
        signal_info s_FallbackSourceUpdated;
        signal_info s_ModuleRemoved;
        signal_info s_NewCard;
        signal_info s_NewClient;
        signal_info s_NewExtension;
        signal_info s_NewModule;
        signal_info s_NewPlaybackStream;
        signal_info s_NewRecordStream;
        signal_info s_NewSample;
        signal_info s_NewSink;
        signal_info s_NewSource;
        signal_info s_PlaybackStreamRemoved;
        signal_info s_RecordStreamRemoved;
        signal_info s_SampleRemoved;
        signal_info s_SinkRemoved;
        signal_info s_SourceRemoved;
      |]
      [|
        property_rw_info p_AlternateSampleRate (fst members.p_AlternateSampleRate) (snd members.p_AlternateSampleRate);
        property_r_info p_Cards members.p_Cards;
        property_r_info p_Clients members.p_Clients;
        property_rw_info p_DefaultChannels (fst members.p_DefaultChannels) (snd members.p_DefaultChannels);
        property_rw_info p_DefaultSampleFormat (fst members.p_DefaultSampleFormat) (snd members.p_DefaultSampleFormat);
        property_rw_info p_DefaultSampleRate (fst members.p_DefaultSampleRate) (snd members.p_DefaultSampleRate);
        property_r_info p_Extensions members.p_Extensions;
        property_rw_info p_FallbackSink (fst members.p_FallbackSink) (snd members.p_FallbackSink);
        property_rw_info p_FallbackSource (fst members.p_FallbackSource) (snd members.p_FallbackSource);
        property_r_info p_Hostname members.p_Hostname;
        property_r_info p_InterfaceRevision members.p_InterfaceRevision;
        property_r_info p_IsLocal members.p_IsLocal;
        property_r_info p_Modules members.p_Modules;
        property_r_info p_MyClient members.p_MyClient;
        property_r_info p_Name members.p_Name;
        property_r_info p_PlaybackStreams members.p_PlaybackStreams;
        property_r_info p_RecordStreams members.p_RecordStreams;
        property_r_info p_Samples members.p_Samples;
        property_r_info p_Sinks members.p_Sinks;
        property_r_info p_Sources members.p_Sources;
        property_r_info p_Username members.p_Username;
        property_r_info p_Version members.p_Version;
      |]
end

module Org_PulseAudio_Core1_Device =
struct
  let interface = "org.PulseAudio.Core1.Device"
  let m_GetPortByName = {
    Method.interface = interface;
    Method.member = "GetPortByName";
    Method.i_args = (arg1
                       (Some "name", basic_string));
    Method.o_args = (arg1
                       (Some "port", basic_object_path));
    Method.annotations = [];
  }
  let m_Suspend = {
    Method.interface = interface;
    Method.member = "Suspend";
    Method.i_args = (arg1
                       (Some "suspend", basic_boolean));
    Method.o_args = (arg0);
    Method.annotations = [];
  }
  let s_ActivePortUpdated = {
    Signal.interface = interface;
    Signal.member = "ActivePortUpdated";
    Signal.args = (arg1
                       (Some "port", basic_object_path));
    Signal.annotations = [];
  }
  let s_MuteUpdated = {
    Signal.interface = interface;
    Signal.member = "MuteUpdated";
    Signal.args = (arg1
                       (Some "muted", basic_boolean));
    Signal.annotations = [];
  }
  let s_PropertyListUpdated = {
    Signal.interface = interface;
    Signal.member = "PropertyListUpdated";
    Signal.args = (arg1
                       (Some "property_list", dict string byte_array));
    Signal.annotations = [];
  }
  let s_StateUpdated = {
    Signal.interface = interface;
    Signal.member = "StateUpdated";
    Signal.args = (arg1
                       (Some "state", basic_uint32));
    Signal.annotations = [];
  }
  let s_VolumeUpdated = {
    Signal.interface = interface;
    Signal.member = "VolumeUpdated";
    Signal.args = (arg1
                       (Some "volume", array basic_uint32));
    Signal.annotations = [];
  }
  let p_ActivePort = {
    Property.interface = interface;
    Property.member = "ActivePort";
    Property.typ = basic_object_path;
    Property.access = Property.readable_writable;
    Property.annotations = [];
  }
  let p_BaseVolume = {
    Property.interface = interface;
    Property.member = "BaseVolume";
    Property.typ = basic_uint32;
    Property.access = Property.readable;
    Property.annotations = [];
  }
  let p_Card = {
    Property.interface = interface;
    Property.member = "Card";
    Property.typ = basic_object_path;
    Property.access = Property.readable;
    Property.annotations = [];
  }
  let p_Channels = {
    Property.interface = interface;
    Property.member = "Channels";
    Property.typ = array basic_uint32;
    Property.access = Property.readable;
    Property.annotations = [];
  }
  let p_ConfiguredLatency = {
    Property.interface = interface;
    Property.member = "ConfiguredLatency";
    Property.typ = basic_uint64;
    Property.access = Property.readable;
    Property.annotations = [];
  }
  let p_Driver = {
    Property.interface = interface;
    Property.member = "Driver";
    Property.typ = basic_string;
    Property.access = Property.readable;
    Property.annotations = [];
  }
  let p_HasConvertibleToDecibelVolume = {
    Property.interface = interface;
    Property.member = "HasConvertibleToDecibelVolume";
    Property.typ = basic_boolean;
    Property.access = Property.readable;
    Property.annotations = [];
  }
  let p_HasDynamicLatency = {
    Property.interface = interface;
    Property.member = "HasDynamicLatency";
    Property.typ = basic_boolean;
    Property.access = Property.readable;
    Property.annotations = [];
  }
  let p_HasFlatVolume = {
    Property.interface = interface;
    Property.member = "HasFlatVolume";
    Property.typ = basic_boolean;
    Property.access = Property.readable;
    Property.annotations = [];
  }
  let p_HasHardwareMute = {
    Property.interface = interface;
    Property.member = "HasHardwareMute";
    Property.typ = basic_boolean;
    Property.access = Property.readable;
    Property.annotations = [];
  }
  let p_HasHardwareVolume = {
    Property.interface = interface;
    Property.member = "HasHardwareVolume";
    Property.typ = basic_boolean;
    Property.access = Property.readable;
    Property.annotations = [];
  }
  let p_Index = {
    Property.interface = interface;
    Property.member = "Index";
    Property.typ = basic_uint32;
    Property.access = Property.readable;
    Property.annotations = [];
  }
  let p_IsHardwareDevice = {
    Property.interface = interface;
    Property.member = "IsHardwareDevice";
    Property.typ = basic_boolean;
    Property.access = Property.readable;
    Property.annotations = [];
  }
  let p_IsNetworkDevice = {
    Property.interface = interface;
    Property.member = "IsNetworkDevice";
    Property.typ = basic_boolean;
    Property.access = Property.readable;
    Property.annotations = [];
  }
  let p_Latency = {
    Property.interface = interface;
    Property.member = "Latency";
    Property.typ = basic_uint64;
    Property.access = Property.readable;
    Property.annotations = [];
  }
  let p_Mute = {
    Property.interface = interface;
    Property.member = "Mute";
    Property.typ = basic_boolean;
    Property.access = Property.readable_writable;
    Property.annotations = [];
  }
  let p_Name = {
    Property.interface = interface;
    Property.member = "Name";
    Property.typ = basic_string;
    Property.access = Property.readable;
    Property.annotations = [];
  }
  let p_OwnerModule = {
    Property.interface = interface;
    Property.member = "OwnerModule";
    Property.typ = basic_object_path;
    Property.access = Property.readable;
    Property.annotations = [];
  }
  let p_Ports = {
    Property.interface = interface;
    Property.member = "Ports";
    Property.typ = array basic_object_path;
    Property.access = Property.readable;
    Property.annotations = [];
  }
  let p_PropertyList = {
    Property.interface = interface;
    Property.member = "PropertyList";
    Property.typ = dict string byte_array;
    Property.access = Property.readable;
    Property.annotations = [];
  }
  let p_SampleFormat = {
    Property.interface = interface;
    Property.member = "SampleFormat";
    Property.typ = basic_uint32;
    Property.access = Property.readable;
    Property.annotations = [];
  }
  let p_SampleRate = {
    Property.interface = interface;
    Property.member = "SampleRate";
    Property.typ = basic_uint32;
    Property.access = Property.readable;
    Property.annotations = [];
  }
  let p_State = {
    Property.interface = interface;
    Property.member = "State";
    Property.typ = basic_uint32;
    Property.access = Property.readable;
    Property.annotations = [];
  }
  let p_Volume = {
    Property.interface = interface;
    Property.member = "Volume";
    Property.typ = array basic_uint32;
    Property.access = Property.readable_writable;
    Property.annotations = [];
  }
  let p_VolumeSteps = {
    Property.interface = interface;
    Property.member = "VolumeSteps";
    Property.typ = basic_uint32;
    Property.access = Property.readable;
    Property.annotations = [];
  }
  type 'a members = {
    m_GetPortByName : 'a OBus_object.t -> string -> OBus_path.t Lwt.t;
    m_Suspend : 'a OBus_object.t -> bool -> unit Lwt.t;
    p_ActivePort : ('a OBus_object.t -> OBus_path.t React.signal) * ('a OBus_object.t -> OBus_path.t -> unit Lwt.t);
    p_BaseVolume : 'a OBus_object.t -> int32 React.signal;
    p_Card : 'a OBus_object.t -> OBus_path.t React.signal;
    p_Channels : 'a OBus_object.t -> int32 list React.signal;
    p_ConfiguredLatency : 'a OBus_object.t -> int64 React.signal;
    p_Driver : 'a OBus_object.t -> string React.signal;
    p_HasConvertibleToDecibelVolume : 'a OBus_object.t -> bool React.signal;
    p_HasDynamicLatency : 'a OBus_object.t -> bool React.signal;
    p_HasFlatVolume : 'a OBus_object.t -> bool React.signal;
    p_HasHardwareMute : 'a OBus_object.t -> bool React.signal;
    p_HasHardwareVolume : 'a OBus_object.t -> bool React.signal;
    p_Index : 'a OBus_object.t -> int32 React.signal;
    p_IsHardwareDevice : 'a OBus_object.t -> bool React.signal;
    p_IsNetworkDevice : 'a OBus_object.t -> bool React.signal;
    p_Latency : 'a OBus_object.t -> int64 React.signal;
    p_Mute : ('a OBus_object.t -> bool React.signal) * ('a OBus_object.t -> bool -> unit Lwt.t);
    p_Name : 'a OBus_object.t -> string React.signal;
    p_OwnerModule : 'a OBus_object.t -> OBus_path.t React.signal;
    p_Ports : 'a OBus_object.t -> OBus_path.t list React.signal;
    p_PropertyList : 'a OBus_object.t -> (string * string) list React.signal;
    p_SampleFormat : 'a OBus_object.t -> int32 React.signal;
    p_SampleRate : 'a OBus_object.t -> int32 React.signal;
    p_State : 'a OBus_object.t -> int32 React.signal;
    p_Volume : ('a OBus_object.t -> int32 list React.signal) * ('a OBus_object.t -> int32 list -> unit Lwt.t);
    p_VolumeSteps : 'a OBus_object.t -> int32 React.signal;
  }
  let make members =
    OBus_object.make_interface_unsafe interface
      [
      ]
      [|
        method_info m_GetPortByName members.m_GetPortByName;
        method_info m_Suspend members.m_Suspend;
      |]
      [|
        signal_info s_ActivePortUpdated;
        signal_info s_MuteUpdated;
        signal_info s_PropertyListUpdated;
        signal_info s_StateUpdated;
        signal_info s_VolumeUpdated;
      |]
      [|
        property_rw_info p_ActivePort (fst members.p_ActivePort) (snd members.p_ActivePort);
        property_r_info p_BaseVolume members.p_BaseVolume;
        property_r_info p_Card members.p_Card;
        property_r_info p_Channels members.p_Channels;
        property_r_info p_ConfiguredLatency members.p_ConfiguredLatency;
        property_r_info p_Driver members.p_Driver;
        property_r_info p_HasConvertibleToDecibelVolume members.p_HasConvertibleToDecibelVolume;
        property_r_info p_HasDynamicLatency members.p_HasDynamicLatency;
        property_r_info p_HasFlatVolume members.p_HasFlatVolume;
        property_r_info p_HasHardwareMute members.p_HasHardwareMute;
        property_r_info p_HasHardwareVolume members.p_HasHardwareVolume;
        property_r_info p_Index members.p_Index;
        property_r_info p_IsHardwareDevice members.p_IsHardwareDevice;
        property_r_info p_IsNetworkDevice members.p_IsNetworkDevice;
        property_r_info p_Latency members.p_Latency;
        property_rw_info p_Mute (fst members.p_Mute) (snd members.p_Mute);
        property_r_info p_Name members.p_Name;
        property_r_info p_OwnerModule members.p_OwnerModule;
        property_r_info p_Ports members.p_Ports;
        property_r_info p_PropertyList members.p_PropertyList;
        property_r_info p_SampleFormat members.p_SampleFormat;
        property_r_info p_SampleRate members.p_SampleRate;
        property_r_info p_State members.p_State;
        property_rw_info p_Volume (fst members.p_Volume) (snd members.p_Volume);
        property_r_info p_VolumeSteps members.p_VolumeSteps;
      |]
end
