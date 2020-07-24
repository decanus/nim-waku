import 
  libp2p/protocols/protocol,
  libp2p/protobuf/minprotobuf,
  stew/results

import ./filter

const
  HistoricMessagesCodec = "/waku/history/1.0.0"

type
  Cursor* = ref object
    before*: seq[byte]
    after*: seq[byte]

  Query* = ref object
    origin*: int32
    to*: int32
    bloom*: seq[byte]
    limit*: int32
    topics*: seq[seq[byte]]
    cursor*: Cursor

  Envelope* = ref object
    expiry*: int32
    ttl*: int32
    nonce*: seq[byte]
    topic*: seq[byte]
    data*: seq[byte]

  Response* = ref object
    envelopes*: seq[Envelope]
    cursor*: Cursor 

  HistoricMessages* = ref object of LPProtocol

proc init*(T: type Query, buf: seq[byte]): Result[T, string] =
  var
    pb = initProtoBuffer(buf)
    query: Query

  var origin: int32
  if pb.getField(1, origin):
    query.origin = some(origin)

  var to: int32
  if pb.getField(2, to):
    query.to = some(to)

  var bloom: seq[byte]
  if pb.getField(3, bloom):
    query.bloom = some(bloom)

  var limit: int32
  if pb.getField(4, limit):
    query.limit = some(limit)

  # @TODO
  discard pb.getRepeatedField(5, query.topics)

  var cursorBuf: seq[byte]
  discard pb.getField(6, cursorBuf)

  var cursorPb = initProtoBuffer(cursorBuf)

  var before: seq[byte]
  if cursorPb.getField(1, before):
    query.cursor.before = before

  var after: seq[byte]
  if cursorPb.getField(2, after):
    query.cursor.after = after

  ok(query)

proc init*(T: type Envelope, buf: seq[byte]): Result[T, string]
  var
    pb = initProtobuf(buf)
    envelope: Envelope

    var expiry: int32
    if pb.getField(1, expiry):
      envelope.expiry = some(expiry)

    var ttl: int32
    if pb.getField(2, ttl):
      envelope.ttl = some(ttl)

    var nonce: seq[byte]
    if pb.getField(3, nonce):
      envelope.nonce = some(nonce)

    var topic: seq[byte]
    if pb.getField(4, topic):
      envelope.topic = some(topic)

    var data: seq[byte]
    if pb.getField(5, data):
      envelope.data = some(data)

method init*(T: type HistoricMessages) = T
  proc handle(conn: Connection, proto: string) {.async, gcsafe, closure.} =
    # @TODO PROBABLY NOT HERE
    var message = conn.readLp(64*1024)
    var result = Query.init(message)
    if result.isError():
      # @TODO ERROR?
      return

    info "received query"

    # @TODO QUERY AND THEN RESPOND

  result.handle = handle
  result.codec = HistoricMessagesCodec

proc filter*(proto: HistoricMessages): Filter =
  proc handle(msg: seq[byte]) =
    discard

  Filter.init(@[], handle)